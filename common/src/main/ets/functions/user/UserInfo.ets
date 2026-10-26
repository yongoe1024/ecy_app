/**
 * 用户信息（DTO，从接口 res.data 反序列化得到，故用 interface 而非 class）
 */
export interface UserInfo {
  id?: string
  phone?: string
  name?: string
  avatar?: string
}