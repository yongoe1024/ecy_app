import { NetManager } from "../net/NetManager";
import { UserCallback } from "./UserCallback";
import { UserModel } from "./UserModel";
import { PreferenceManager } from "../../utils";
import { hilog } from "@kit.PerformanceAnalysisKit";

const DOMAIN: number = 0x0000;
const TAG: string = 'UserManager';

/**
 * 用户管理器
 */
export class UserManager {
  private static instance: UserManager
  private listeners: UserCallback[] = []
  private userModel?: UserModel
  private token?: string

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
    } catch (e) {
      hilog.error(DOMAIN, TAG, `setToken ：${e.code} ${e.message}`);
    }
    this.token = str
  }

  /**
   * 登录
   * @param phone 手机号
   * @param code 验证码
   * @returns 登录结果
   */
  async login(phone: string, code: string): Promise<void> {
    const res = await NetManager.getInstance().request({
      method: 'post',
      url: 'login',
      data: {
        phone: phone,
        code: code
      }
    })
    if (res.code == 200) {
      this.setToken(res.data as string)
      try {
        this.userModel = await this.getUserInfo(true)
        if (this.userModel) {
          this.listeners.forEach((item) => {
            item.onLogin?.()
          })
        }
      } catch (e) {
        this.userModel = undefined
        this.setToken('')
        return Promise.reject(e)
      }
    } else {
      return Promise.reject()
    }
  }

  /**
   * 用户信息
   * @param refresh 是否请求接口刷新数据
   * @returns 不存在则返回undefined
   */
  async getUserInfo(refresh: boolean = false): Promise<UserModel | undefined> {
    if (!this.getToken()) {
      this.userModel = undefined
      return undefined
    }
    if (this.userModel && !refresh) {
      return this.userModel
    }
    let res = await NetManager.getInstance().request({
      method: 'post',
      url: 'getUserInfo',
    })
    if (res.code == 200) {
      this.userModel = res.data
      return this.userModel
    } else {
      return Promise.reject()
    }
  }

  /**
   * 退出登录
   * @returns
   */
  async logout(): Promise<void> {
    let res = await NetManager.getInstance().request({
      method: 'post',
      url: 'logout',
    })
    if (res.code == 200) {
      this.userModel = undefined
      this.setToken('')
      this.listeners.forEach((item) => {
        item.onLogout?.()
      })
    } else {
      return Promise.reject()
    }
  }
}
