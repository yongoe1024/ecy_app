import axios, {
  AxiosError,
  AxiosInstance,
  AxiosProgressEvent,
  AxiosRequestConfig,
  AxiosResponse,
  FormData,
  InternalAxiosRequestConfig
} from '@ohos/axios';
import { UserManager } from '../user/UserManager';
import { ResponseModel } from './NetModel';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { EnvironmentManager } from '../environment/EnvironmentManager';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'NetManager';

/**
 * 网络请求管理器：axios 封装、上传/下载
 */
export class NetManager {
  private static instance: NetManager
  private axiosInstance: AxiosInstance
  private readonly isDebug: boolean = EnvironmentManager.getInstance().getEnv() !== 'PROD'

  private constructor() {
    this.axiosInstance = axios.create({
      baseURL: EnvironmentManager.getInstance().getEnvConfig().baseUrl,
      timeout: 10000,
    })
    // 请求拦截器：注入认证头
    this.axiosInstance.interceptors.request.use((config: InternalAxiosRequestConfig) => {
      const token = UserManager.getInstance().getToken()
      if (token) {
        config.headers['Authorization'] = token.accessToken
      }
      this.logRequest(config)
      return config;
    });
    // 响应拦截器：剥壳返回业务体（ResponseModel）而非 AxiosResponse
    this.axiosInstance.interceptors.response.use((response: AxiosResponse) => {
      this.logResponse(response)
      return response.data
    }, (error: AxiosError) => {
      // 仅记录日志，Toast 由调用方按需展示
      this.logError(error)
      return Promise.reject(error);
    });
  }

  public static getInstance(): NetManager {
    if (!NetManager.instance) {
      NetManager.instance = new NetManager()
    }
    return NetManager.instance
  }

  /**
   * 自定义请求：HTTP 2xx 即 resolve（**即使业务码 res.code !== 200**）；4xx/5xx、网络错误、超时走 catch。
   */
  request<T = Object>(config: AxiosRequestConfig): Promise<ResponseModel<T>> {
    return this.axiosInstance.request<ResponseModel<T>, ResponseModel<T>>(config)
  }

  private logRequest(config: InternalAxiosRequestConfig): void {
    if (!this.isDebug) {
      return
    }
    hilog.debug(DOMAIN, TAG, `request | URL: ${config.url}`);
    hilog.debug(DOMAIN, TAG, `request | Method: ${config.method?.toUpperCase()}`);
    // 原样打印，debug 日志中可见 Authorization
    hilog.debug(DOMAIN, TAG, `request | Headers: ${config.headers}`);
    hilog.debug(DOMAIN, TAG, `request | Params: ${JSON.stringify(config.params)}`);
    hilog.debug(DOMAIN, TAG, `request | Body: ${JSON.stringify(config.data)}`);
  }

  private logResponse(response: AxiosResponse): void {
    if (!this.isDebug) {
      return
    }
    hilog.debug(DOMAIN, TAG, `response | URL: ${response.config.url}`);
    hilog.debug(DOMAIN, TAG, `response | Status: ${response.status} ${response.statusText}`);
    hilog.debug(DOMAIN, TAG, `response | Data: ${JSON.stringify(response.data)}`);
  }

  private logError(error: AxiosError): void {
    hilog.error(DOMAIN, TAG, `response | URL: ${error?.config?.url}`);
    hilog.error(DOMAIN, TAG, `response | Error: ${error.message || String(error)}`);
    if (error.response) {
      hilog.error(DOMAIN, TAG, `response | Status: ${error.response.status} ${error.response.statusText}`);
      // 响应体可能较大或含敏感信息，仅在调试环境打印
      if (this.isDebug) {
        hilog.error(DOMAIN, TAG, `response | Data: ${JSON.stringify(error.response.data)}`);
      }
    }
  }


  /**
   * 上传文件（multipart）：filePath 复制进缓存后以 FormData 发送，表单字段名固定 file。
   * method 未指定默认 post；调用方 headers 的额外头保留，Content-Type 由 multipart 机制绑定、冲突时以固定头为准。
   * @param config 必传 url；可携带 headers / timeout / method 等常规配置
   */
  async upload(context: Context, filePath: string, config: AxiosRequestConfig,
    onProgress?: (value: number) => void): Promise<ResponseModel> {
    // 真实落盘路径，上传结束后需删除，避免缓存目录堆积
    const fileName = await this.copyToCache(context, filePath)
    const realPath = `${context.cacheDir}/${fileName}`
    const formData = new FormData()
    formData.append('file', `internal://cache/${fileName}`);
    config.method = config.method ?? 'post'
    config.data = formData
    config.context = context
    // 合并调用方额外头（ArkTS 无展开/Object.assign，只能 keys 循环）
    const headers: Record<string, string> = { 'Content-Type': 'multipart/form-data' }
    const extra = config.headers as Record<string, string> | undefined
    if (extra) {
      Object.keys(extra).forEach((key: string) => {
        if (key.toLowerCase() !== 'content-type') {
          headers[key] = extra[key]
        }
      })
    }
    config.headers = headers
    config.onUploadProgress = (event: AxiosProgressEvent): void => {
      NetManager.percentOf(event, onProgress)
    }
    try {
      // 发送请求
      return await this.request(config)
    } finally {
      // 上传已结束（成功/失败均到此），清理临时文件；删除失败不影响上传结果
      try {
        if (fileIo.accessSync(realPath)) {
          fileIo.unlinkSync(realPath)
        }
      } catch (e) {
        hilog.warn(DOMAIN, TAG, `upload 清理缓存文件失败 ：${e?.code} ${e?.message}`);
      }
    }
  }

  /**
   * 下载到 filePath（默认 get，POST 下载经 config.method 指定）。
   * filePath 须为 cacheDir 内绝对路径（适配层限制：非 cacheDir 路径会被强制拼进 cacheDir）。
   * 成功即落盘；适配层无响应体可读，判断成败用 catch，勿依赖返回值。
   */
  async download(context: Context, filePath: string, config: AxiosRequestConfig,
    onProgress?: (value: number) => void): Promise<void> {
    // 适配层对已存在文件直接报错、且落盘是追加模式：先删旧文件；删除失败不中断（后续由适配层报出）
    try {
      if (fileIo.accessSync(filePath)) {
        fileIo.unlinkSync(filePath)
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, `download 预清理旧文件失败 ：${e?.code} ${e?.message}`);
    }
    config.method = config.method ?? 'get'
    config.context = context
    config.filePath = filePath
    config.onDownloadProgress = (event: AxiosProgressEvent): void => {
      NetManager.percentOf(event, onProgress)
    }
    await this.request(config)
  }


  /** 进度事件换算百分比回调（total 未知时不触发） */
  private static percentOf(event: AxiosProgressEvent, onProgress?: (value: number) => void): void {
    if (onProgress && event && event.loaded && event.total) {
      onProgress(event.loaded / event.total * 100)
    }
  }

  /**
   * 将文件复制到缓存并重命名，返回缓存内的文件名（uuid + 扩展名）。
   * 调用方据此拼出上传用的 internal://cache/<name> 以及真实路径 <cacheDir>/<name>。
   * @throws BusinessError
   */
  private async copyToCache(context: Context, path: string): Promise<string> {
    const dir = context.cacheDir
    const dotIndex = path.lastIndexOf('.')
    const ext = dotIndex >= 0 ? path.substring(dotIndex) : ''
    const uuid = util.generateRandomUUID() + ext
    const pathIO = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY)
    try {
      fileIo.copyFileSync(pathIO.fd, `${dir}/${uuid}`)
    } finally {
      fileIo.closeSync(pathIO)
    }
    return uuid
  }
}
