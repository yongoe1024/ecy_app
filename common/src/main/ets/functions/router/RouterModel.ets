/**
 * 路由参数
 */
export interface RouterParams {
  url: string
  //需要登录
  needLogin?: boolean
  // 转场动画
  animated?: boolean
  // 在页面出栈时获取返回信息
  onPop?: Callback<PopInfo>
  // 参数
  params?: Record<string, ESObject>
}
