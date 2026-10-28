/**
 * 统一响应结构
 */
export interface ResponseModel<T = Object> {
  message: string
  code: number
  data: T
}
