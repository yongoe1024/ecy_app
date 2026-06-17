import { NetManager } from '../net/NetManager';
import { UserCallback } from './UserCallback';
import { UserInfo } from './UserInfo';
import { PreferenceManager } from '../../utils';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { bundleManager } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { ResponseModel } from '..';
import { AppError } from '../AppError';

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
   * 获取 token（会读取持久化）。
   * 约定：读查询，存储异常按「未登录」处理——返回 '' 并记日志（被请求拦截器同步调用，故不抛出）。
   */
  getToken(): string {
    // 已登录
    if (this.token) {
      return this.token
    }
    try {
      // 重启app拿历史记录
      let token = PreferenceManager.getStringSync('token', '')
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
   * 设置 token，并持久化。持久化成功后才更新内存，避免落盘失败导致内存与磁盘不一致。
   * 约定：写变更不静默吞错——持久化失败时抛出，调用方需感知（如 login/logout 会因此 reject）。
   * @throws Error 持久化失败
   */
  setToken(str: string): void {
    PreferenceManager.putSync('token', str)
    this.token = str
  }

  /**
   * 登录：确立会话。
   * 约定：失败时 reject——业务码非 200 → AppError；setToken 持久化失败 → 透传底层错误。
   * @param phone 手机号
   * @param code 验证码
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
      return Promise.reject(new AppError(res.code, `login failed: code=${res.code}`))
    }
  }

  /**
   * 获取用户信息：优先返回内存缓存，未缓存时调用接口拉取一次（懒加载）。
   * 由使用者按需调用，登录流程不再预取。
   * 约定：未登录返回 undefined（非错误）；网络/业务失败走 Promise.reject(AppError)。
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
   * 约定：未登录返回 undefined（非错误）；网络/业务失败走 Promise.reject(AppError)。
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
      return Promise.reject(new AppError(res.code, `getUserInfo failed: code=${res.code}`))
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
   * 退出登录。
   * 约定：先清持久化 token，失败则整体 reject（避免「UI 已登出但磁盘仍存 token」的幽灵会话）；
   * 清理成功后再清内存缓存、通知监听者。
   * @throws Error setToken 持久化失败时透传
   */
  async logout(): Promise<void> {
    // 先清持久化 token：失败则 reject，后续内存清理/通知都不执行
    this.setToken('')
    this.userInfo = undefined
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
