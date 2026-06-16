/**
 * 统一返回类
 * 默认 T 用 Object（而非 ESObject）：未显式指定泛型时也能通过 arkts-no-any-unknown 严格校验。
 * 需要具体结构时显式传入，如 request<UserInfo>(...)。
 */
export interface ResponseModel<T = Object> {
  message: string
  code: number
  data: T
}

/**
 * 上传文件参数
 */
export interface UploadParams {
  //接口路径
  url: string
  //文件路径，不限制在cacheDir、filesDir等
  filePath: string
  //进度回调
  onProgress?: (value: number) => void
}

/**
 * 下载文件参数
 */
export interface DownloadParams {
  //请求url
  url: string
  //比如：getContext(this).cacheDir}/test并将文件存储在此路径下
  filePath: string
  //进度回调
  onProgress?: (value: number) => void
}
