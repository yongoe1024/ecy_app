import { NetManager } from '../net/NetManager';
import { UserCallback } from './UserCallback';
import { UserInfo } from './UserInfo';
import { PreferenceManager } from '../../utils';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { bundleManager } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { ResponseModel } from '..';

const DOMAIN: number = 0x0000;
const TAG: string = 'UserManager';

/**
 * 用户管理器
 */
export class UserManager {
  private static instance: UserManager
  private listeners: UserCallback[] = []
  private userInfo?: UserInfo
  private token?: string

  /** 应用版本号（versionName，如 "1.0.0"），取自 AppScope/app.json5 */
  getAppVersion(): string {
    try {
      return bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      ).versionName
    } catch (e) {
      hilog.error(DOMAIN, TAG, `getAppVersion ：${e.code} ${e.message}`);
      return ''
    }
  }

  /**
   * 设备匿名标识 ODID（去掉连字符）。
   * 注意：这不是设备序列号（真 SN 需 ohos.permission.sn + deviceInfo.serial）；
   * ODID 在应用卸载重装后会变化，且属设备信息，采集前应在隐私政策中披露。
   */
  getDeviceOdid(): string {
    return deviceInfo.ODID.replace(/-/ig, '');
  }

  // 系统版本
  getOsVersion(): string {
    return deviceInfo.distributionOSVersion;
  }

  // 设备名
  getDeviceModel(): string {
    return deviceInfo.marketName;
  }


  private constructor() {
  }

  public static getInstance(): UserManager {
    if (!UserManager.instance) {
      UserManager.instance = new UserManager()
    }
    return UserManager.instance
  }

  /**
   * 注册登陆事件
   */
  registerListener(listener: UserCallback): void {
    // 避免重复添加相同回调
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  /**
   * 取消注册
   */
  unRegisterListener(listener: UserCallback): void {
    // 找到回调在数组中的索引并删除
    const index = this.listeners.findIndex(cb => cb === listener);
    if (index !== -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 获取token，会持久化
   */
  getToken(): string {
    // 已登录
    if (this.token) {
      return this.token
    }
    try {
      // 重启app拿历史记录
      let token = PreferenceManager.getSync('token', '') as string
      if (token) {
        this.token = token
        return token
      } else {
        return ''
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `getToken ：${e.code} ${e.message}`);
      return ''
    }
  }

  /**
   * 设置token，会持久化
   */
  setToken(str: string): void {
    try {
      PreferenceManager.putSync('token', str)
      // 持久化成功后再更新内存，避免落盘失败导致内存与磁盘不一致
      this.token = str
    } catch (e) {
      hilog.error(DOMAIN, TAG, `setToken ：${e.code} ${e.message}`);
    }
  }

  /**
   * 登录
   * @param phone 手机号
   * @param code 验证码
   * @returns 登录结果
   */
  async login(phone: string, code: string): Promise<void> {
    // const res = await NetManager.getInstance().request<string>({
    //   method: 'post',
    //   url: 'login',
    //   data: {
    //     phone: phone,
    //     code: code
    //   }
    // })
    const res: ResponseModel<string> = {
      code: 200,
      data: 'token123',
      message: ''
    }
    if (res.code === 200) {
      // 演示占位：直接把 data 当 token 字符串。接入真实后端时应校验/解析返回结构
      this.setToken(res.data)
      // 登录只负责确立会话；用户信息由使用者按需调用 getUserInfo()/refreshUserInfo() 拉取，二者解耦
      this.listeners.forEach((item) => {
        try {
          item.onLogin?.()
        } catch (e) {
          hilog.error(DOMAIN, TAG, `onLogin listener ：${e?.message}`);
        }
      })
    } else {
      return Promise.reject(new Error(`login failed: code=${res.code}`))
    }
  }

  /**
   * 获取用户信息：优先返回内存缓存，未缓存时调用接口拉取一次（懒加载）。
   * 由使用者按需调用，登录流程不再预取。
   * @returns 未登录返回 undefined
   */
  async getUserInfo(): Promise<UserInfo | undefined> {
    if (!this.getToken()) {
      this.userInfo = undefined
      return undefined
    }
    if (this.userInfo) {
      return this.userInfo
    }
    return this.fetchUserInfo()
  }

  /**
   * 强制从接口刷新用户信息并更新缓存。
   * @returns 未登录返回 undefined
   */
  async refreshUserInfo(): Promise<UserInfo | undefined> {
    if (!this.getToken()) {
      this.userInfo = undefined
      return undefined
    }
    return this.fetchUserInfo()
  }

  /**
   * 请求用户信息并写入内存缓存，供 getUserInfo / refreshUserInfo 复用。
   * @returns 接口返回的用户信息
   */
  private async fetchUserInfo(): Promise<UserInfo | undefined> {
    const res = await NetManager.getInstance().request<UserInfo>({
      method: 'post',
      url: 'getUserInfo',
    })
    if (res.code === 200) {
      // 演示占位：直接整体赋值后端返回。接入真实后端时应按字段解析/校验
      this.userInfo = res.data
      this.notifyUserInfoChanged()
      return this.userInfo
    } else {
      return Promise.reject(new Error(`getUserInfo failed: code=${res.code}`))
    }
  }

  /**
   * 通知监听者用户信息已变化（拉取/刷新得到新值，或退出登录被清空）
   */
  private notifyUserInfoChanged(): void {
    this.listeners.forEach((item) => {
      try {
        item.onUserInfoChanged?.(this.userInfo)
      } catch (e) {
        hilog.error(DOMAIN, TAG, `onUserInfoChanged listener ：${e?.message}`);
      }
    })
  }

  /**
   * 退出登录
   * @returns
   */
  async logout(): Promise<void> {
    // 无论服务端是否成功，都清理本地登录态
    this.userInfo = undefined
    this.setToken('')
    this.notifyUserInfoChanged()
    this.listeners.forEach((item) => {
      try {
        item.onLogout?.()
      } catch (e) {
        hilog.error(DOMAIN, TAG, `onLogout listener ：${e?.message}`);
      }
    })
  }
}
