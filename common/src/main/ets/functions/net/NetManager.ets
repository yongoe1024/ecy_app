import axios, {
  AxiosError,
  AxiosInstance,
  AxiosProgressEvent,
  AxiosRequestConfig,
  AxiosResponse,
  FormData,
  InternalAxiosRequestConfig
} from "@ohos/axios";
import { UserManager } from "../user/UserManager";
import { DownloadParams, ResponseModel, UploadParams } from "./NetModel";
import { fileIo } from "@kit.CoreFileKit";
import { util } from "@kit.ArkTS";
import { EnvEnum } from "../environment/GlobalModel";
import { EnvironmentManager } from "../environment/EnvironmentManager";
import { hilog } from "@kit.PerformanceAnalysisKit";

const DOMAIN: number = 0x0000;
const TAG: string = 'NetManager';

/**
 * 网络请求管理器
 */
export class NetManager {
  private static instance: NetManager
  private axiosInstance: AxiosInstance
  private readonly isDebug: boolean = EnvironmentManager.getInstance().getEnv() === EnvEnum.DEV

  private constructor() {
    this.axiosInstance = axios.create({
      baseURL: EnvironmentManager.getInstance().getBaseUrl(),
      timeout: 10000,
    })
    // 添加请求拦截器
    this.axiosInstance.interceptors.request.use((config: InternalAxiosRequestConfig) => {
      // 对请求数据做点什么
      const token = UserManager.getInstance().getToken()
      if (token) {
        config.headers['Authorization'] = token
      }
      this.logRequest(config)
      return config;
    });
    // 添加响应拦截器
    this.axiosInstance.interceptors.response.use((response: AxiosResponse) => {
      // 对响应数据做点什么
      this.logResponse(response)
      return response.data
    }, (error: AxiosError) => {
      // 对响应错误做点什么：仅记录日志，Toast 由调用方按需展示
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
   * 自定义请求。
   * 约定（传输层）：只要服务器有响应就 resolve（**即使业务码 res.code !== 200**）；
   * 仅网络错误 / 超时走 catch。因此调用方必须先检查 res.code，再消费 res.data。
   * @param config axios配置
   * @returns ResponseModel（resolve 不代表业务成功）
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
    // 脱敏后再打印：避免 token 等敏感头泄漏到日志
    hilog.debug(DOMAIN, TAG, `request | Headers: ${NetManager.maskHeaders(config.headers)}`);
    hilog.debug(DOMAIN, TAG, `request | Params: ${JSON.stringify(config.params)}`);
    hilog.debug(DOMAIN, TAG, `request | Body: ${JSON.stringify(config.data)}`);
  }

  /** 脱敏请求头：Authorization 以 *** 替代，避免 token 泄漏到日志 */
  private static maskHeaders(headers: Object): string {
    if (!headers) {
      return '{}'
    }
    try {
      const source = headers as Record<string, Object>
      const masked: Record<string, Object> = {}
      Object.keys(source).forEach((key: string) => {
        masked[key] = key.toLowerCase() === 'authorization' ? '***' : source[key]
      })
      return JSON.stringify(masked)
    } catch (e) {
      return '[unserializable headers]'
    }
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
   * 上传文件
   * @throws BusinessError
   * @param context 上下文
   * @param params 上传参数
   * @returns ResponseModel
   */
  async upload(context: Context, params: UploadParams): Promise<ResponseModel> {
    // 真实落盘路径，上传结束后需删除，避免缓存目录堆积
    const fileName = await this.copyToCache(context, params.filePath)
    const realPath = `${context.cacheDir}/${fileName}`
    let formData = new FormData()
    formData.append('file', `internal://cache/${fileName}`);
    try {
      // 发送请求
      return await this.request({
        url: params.url,
        method: 'post',
        data: formData,
        headers: { 'Content-Type': 'multipart/form-data' },
        context: context,
        onUploadProgress: (progressEvent: AxiosProgressEvent): void => {
          if (progressEvent && progressEvent.loaded && progressEvent.total) {
            params.onProgress?.(progressEvent.loaded / progressEvent.total * 100)
          }
        }
      })
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
   * 下载到 cacheDir 目录；目标文件已存在时先删除，避免下载失败
   * @throws BusinessError
   * @param context 上下文
   * @param params 下载参数
   * @returns ResponseModel
   */
  async download(context: Context, params: DownloadParams): Promise<ResponseModel> {
    // 目标文件已存在时先删除，避免 axios 下载失败；删除失败不应中断下载
    try {
      if (fileIo.accessSync(params.filePath)) {
        fileIo.unlinkSync(params.filePath)
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, `download 预清理旧文件失败 ：${e?.code} ${e?.message}`);
    }
    return this.request({
      url: params.url,
      method: 'get',
      context: context,
      filePath: params.filePath,
      onDownloadProgress: (progressEvent: AxiosProgressEvent): void => {
        if (progressEvent && progressEvent.loaded && progressEvent.total) {
          params.onProgress?.(progressEvent.loaded / progressEvent.total * 100)
        }
      }
    })
  }

  /**
   * 将文件复制到缓存并重命名，返回缓存内的文件名（uuid + 扩展名）。
   * 调用方据此拼出上传用的 internal://cache/<name> 以及真实路径 <cacheDir>/<name>。
   * @throws BusinessError
   */
  private async copyToCache(context: Context, path: string): Promise<string> {
    let dir = context.cacheDir
    let dotIndex = path.lastIndexOf('.')
    let ext = dotIndex >= 0 ? path.substring(dotIndex) : ''
    let uuid = util.generateRandomUUID() + ext
    let pathIO = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY)
    try {
      fileIo.copyFileSync(pathIO.fd, `${dir}/${uuid}`)
    } finally {
      fileIo.closeSync(pathIO)
    }
    return uuid
  }
}
