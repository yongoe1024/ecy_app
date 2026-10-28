import { NetManager } from '../net/NetManager';
import { TokenInfo, UserInfo } from './UserModel';

export class UserApi {
  /**
   * 登录，返回 token 信息。
   * 演示占位：accessToken/refreshToken 取同一响应串，过期时间为假数据；接入真实后端时改为解析完整 TokenInfo。
   */
  static async login(phone: string, code: string): Promise<TokenInfo> {
    const res = await NetManager.getInstance().request<string>({
      method: 'post',
      url: 'login',
      data: {
        phone: phone,
        code: code
      }
    })
    if (res.code === 200) {
      return {
        accessToken: res.data,
        refreshToken: res.data,
        expireTime: 1000,
        refreshExpireTime: 1000
      }
    }
    return Promise.reject(new Error(`登录失败 ${res.code}：${res.message}`))
  }

  /**
   * 获取用户信息
   */
  static async getUserInfo(): Promise<UserInfo> {
    const res = await NetManager.getInstance().request<UserInfo>({
      method: 'post',
      url: 'getUserInfo',
    })
    if (res.code === 200) {
      return res.data
    }
    return Promise.reject(new Error(`获取用户信息失败 ${res.code}：${res.message}`))
  }
}
