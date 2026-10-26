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

/** 上传文件参数 */
export interface UploadParams {
  url: string
  /** 待上传文件路径，不限于 cacheDir / filesDir */
  filePath: string
  /** 进度回调，参数为百分比 0-100 */
  onProgress?: (value: number) => void
}

/** 下载文件参数 */
export interface DownloadParams {
  url: string
  /** 下载落盘路径，如 `${getContext(this).cacheDir}/test` */
  filePath: string
  /** 进度回调，参数为百分比 0-100 */
  onProgress?: (value: number) => void
}
