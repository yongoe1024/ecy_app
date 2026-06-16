import { UserInfo } from './UserInfo'

export interface UserCallback {
  /**
   * 登录
   */
  onLogin?: Callback<void>
  /**
   * 退出登录
   */
  onLogout?: Callback<void>
  /**
   * 用户信息变化：拉取/刷新得到新值，或退出登录被清空（此时回传 undefined）
   */
  onUserInfoChanged?: Callback<UserInfo | undefined>
}
