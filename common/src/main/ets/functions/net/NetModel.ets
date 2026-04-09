/**
 * 统一返回类
 */
export interface ResponseModel {
  message: string
  code: number
  data: ESObject
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
