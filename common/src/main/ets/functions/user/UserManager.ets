import { UserCallback } from './UserCallback';
import { TokenInfo, UserInfo } from './UserModel';
import { PreferenceManager } from '../../utils/PreferenceManager';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { UserApi } from './UserApi';

const DOMAIN: number = 0x0000;
const TAG: string = 'UserManager';
const KEY_TOKEN_INFO = 'tokenInfo';
const KEY_USER_INFO = 'userInfo';

/**
 * 会话与用户信息
 */
export class UserManager {
  private static instance: UserManager
  private listeners: UserCallback[] = []
  private userInfo?: UserInfo
  private tokenInfo?: TokenInfo

  private constructor() {
    this.userInfo = this.getJsonPref<UserInfo>(KEY_USER_INFO)
    this.tokenInfo = this.getJsonPref<TokenInfo>(KEY_TOKEN_INFO)
  }

  public static getInstance(): UserManager {
    if (!UserManager.instance) {
      UserManager.instance = new UserManager()
    }
    return UserManager.instance
  }

  /** 注册登录/用户信息回调；重复注册同一回调自动忽略 */
  registerListener(listener: UserCallback): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  /** 注销注册回调 */
  unRegisterListener(listener: UserCallback): void {
    const index = this.listeners.findIndex(cb => cb === listener);
    if (index !== -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 登录：确立会话。网络/业务失败 reject（透传 UserApi 的错误）。
   */
  async login(phone: string, code: string): Promise<void> {
    this.tokenInfo = await UserApi.login(phone, code)
    this.setJsonPref(KEY_TOKEN_INFO, this.tokenInfo)
    this.listeners.forEach((item) => {
      try {
        item.onLogin?.()
      } catch (e) {
        hilog.error(DOMAIN, TAG, `login listener ：${e?.message}`);
      }
    })
  }

  /**
   * 退出登录。先清内存并通知监听者；持久化删除失败仅记日志（内存态为准，残留 token 下次冷启动会恢复）。
   */
  async logout(): Promise<void> {
    this.userInfo = undefined
    this.tokenInfo = undefined
    try {
      PreferenceManager.deleteSync(KEY_TOKEN_INFO)
      PreferenceManager.deleteSync(KEY_USER_INFO)
    } catch (e) {
      hilog.error(DOMAIN, TAG, `logout deleteSync ：${e?.message}`);
    }
    this.listeners.forEach((item) => {
      try {
        item.onUserInfoChanged?.(this.userInfo)
        item.onLogout?.()
      } catch (e) {
        hilog.error(DOMAIN, TAG, `logout listener ：${e?.message}`);
      }
    })
  }

  /** 获取 token 信息（内存缓存，冷启动自偏好恢复）；未登录返回 undefined */
  getToken(): TokenInfo | undefined {
    return this.tokenInfo
  }

  /**
   * 获取用户信息：缓存优先，未命中拉取接口并落盘。未登录返回 undefined；失败 reject。
   */
  async getUserInfo(): Promise<UserInfo | undefined> {
    if (!this.tokenInfo) {
      return undefined
    }
    if (this.userInfo) {
      return this.userInfo
    }
    await this.refreshUserInfo()
    return this.userInfo
  }

  /**
   * 从接口刷新用户信息并更新缓存。
   * 网络/业务失败 reject。
   */
  async refreshUserInfo(): Promise<void> {
    if (!this.tokenInfo) {
      return
    }
    this.userInfo = await UserApi.getUserInfo()
    this.setJsonPref(KEY_USER_INFO, this.userInfo)
    this.notifyUserInfoChanged()
  }

  /** 通知监听者用户信息已变化（拉取/刷新得到新值，或退出登录被清空） */
  private notifyUserInfoChanged(): void {
    this.listeners.forEach((item) => {
      try {
        item.onUserInfoChanged?.(this.userInfo)
      } catch (e) {
        hilog.error(DOMAIN, TAG, `onUserInfoChanged listener ：${e?.message}`);
      }
    })
  }

  /** 读取首选项 */
  private getJsonPref<T extends Object>(key: string): T | undefined {
    try {
      const str = PreferenceManager.getSync(key, undefined) as string
      return str == undefined ? undefined : JSON.parse(str) as T
    } catch (error) {
      hilog.error(DOMAIN, TAG, `getJsonPref ${key} ：${error?.message}`);
      return undefined
    }
  }

  /** 写首选项 */
  private setJsonPref(key: string, value: Object): void {
    try {
      PreferenceManager.putSync(key, JSON.stringify(value))
    } catch (error) {
      hilog.error(DOMAIN, TAG, `setJsonPref ${key} ：${error?.message}`);
    }
  }
}
