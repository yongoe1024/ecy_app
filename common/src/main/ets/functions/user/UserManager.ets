import { NetManager } from '../net/NetManager';
import { UserCallback } from './UserCallback';
import { UserInfo } from './UserModel';
import { PreferenceManager } from '../../utils';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { bundleManager } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';

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

  getAppVersion(): string {
    return bundleManager.getBundleInfoForSelfSync(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    ).versionName
  }

  // 设备信息
  getDeviceSn(): string {
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
    if (this.token) {
      return this.token
    }
    try {
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
    const res = await NetManager.getInstance().request<string>({
      method: 'post',
      url: 'login',
      data: {
        phone: phone,
        code: code
      }
    })
    if (res.code === 200) {
      // 演示占位：直接把 data 当 token 字符串。接入真实后端时应校验/解析返回结构
      this.setToken(res.data)
      try {
        this.userInfo = await this.getUserInfo(true)
      } catch (e) {
        this.userInfo = undefined
        this.setToken('')
        return Promise.reject(e)
      }
      // 登录成功即通知监听者：不依赖 userInfo 真值，避免后端返回 200 但 data 为空时登录态不同步
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
   * 用户信息
   * @param refresh 是否请求接口刷新数据
   * @returns 不存在则返回undefined
   */
  async getUserInfo(refresh: boolean = false): Promise<UserInfo | undefined> {
    if (!this.getToken()) {
      this.userInfo = undefined
      return undefined
    }
    if (this.userInfo && !refresh) {
      return this.userInfo
    }
    let res = await NetManager.getInstance().request<UserInfo>({
      method: 'post',
      url: 'getUserInfo',
    })
    if (res.code === 200) {
      // 演示占位：ESObject 直接赋给 userInfo。接入真实后端时应按字段解析/校验
      this.userInfo = res.data
      return this.userInfo
    } else {
      return Promise.reject(new Error(`getUserInfo failed: code=${res.code}`))
    }
  }

  /**
   * 退出登录
   * @returns
   */
  async logout(): Promise<void> {
    try {
      const res = await NetManager.getInstance().request({
        method: 'post',
        url: 'logout',
      })
      if (res.code !== 200) {
        hilog.warn(DOMAIN, TAG, `logout 服务端返回非 200：code=${res.code}`);
      }
    } catch (e) {
      // 网络异常时仍清理本地状态，避免用户无法退出
      hilog.warn(DOMAIN, TAG, `logout 网络异常，清理本地状态：${e?.message}`);
    }
    // 无论服务端是否成功，都清理本地登录态
    this.userInfo = undefined
    this.setToken('')
    this.listeners.forEach((item) => {
      try {
        item.onLogout?.()
      } catch (e) {
        hilog.error(DOMAIN, TAG, `onLogout listener ：${e?.message}`);
      }
    })
  }
}
