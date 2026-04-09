import { IBestToast } from "@ibestservices/ibest-ui-v2";
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
import { EnvironmentManger } from "../environment/EnvironmentManger";
import { hilog } from "@kit.PerformanceAnalysisKit";

const DOMAIN: number = 0x0000;
const TAG: string = 'NetManager';

/**
 * 网络请求管理器
 */
export class NetManager {
  private static instance: NetManager
  private axiosInstance: AxiosInstance
  private readonly isDebug: boolean = EnvironmentManger.getInstance().getEnv() === 'DEV'

  private constructor() {
    this.axiosInstance = axios.create({
      baseURL: EnvironmentManger.getInstance().getBaseUrl(),
      timeout: 5000,
      // headers: {'X-Custom-Header': 'foobar'}
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
      // 对响应错误做点什么
      IBestToast.show(error.message)
      // 打印所有请求的错误响应信息
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
   * 自定义请求
   * @param config axios配置
   * @returns 请求结果，只要服务器返回，都算成功，网络错误走catch
   */
  request(config: AxiosRequestConfig): Promise<ResponseModel> {
    return this.axiosInstance.request<ResponseModel, ResponseModel>(config)
  }

  private logRequest(config: InternalAxiosRequestConfig): void {
    if (!this.isDebug) {
      return
    }
    hilog.debug(DOMAIN, TAG, `request | URL: ${config.baseURL}${config.url}`);
    hilog.debug(DOMAIN, TAG, `request | Method: ${config.method?.toUpperCase() || 'GET'}`);
    hilog.debug(DOMAIN, TAG, `request | Headers: ${JSON.stringify(config.headers)}`);
    hilog.debug(DOMAIN, TAG, `request | Params: ${JSON.stringify(config.params)}`);
    hilog.debug(DOMAIN, TAG, `request | Body: ${JSON.stringify(config.data)}`);
  }

  private logResponse(response: AxiosResponse): void {
    if (!this.isDebug) {
      return
    }
    hilog.debug(DOMAIN, TAG, `response | URL: ${response.config.baseURL}${response.config.url}`);
    hilog.debug(DOMAIN, TAG, `response | Status: ${response.status} ${response.statusText}`);
    hilog.debug(DOMAIN, TAG, `response | Data: ${JSON.stringify(response.data)}`);
  }

  private logError(error: AxiosError): void {
    hilog.error(DOMAIN, TAG, `response | URL: ${error?.config?.baseURL}${error?.config?.url}`);
    if (error.response) {
      hilog.error(DOMAIN, TAG, `response | Status: ${error.response.status} ${error.response.statusText}`);
      if (this.isDebug) {
        hilog.error(DOMAIN, TAG, `response | Data: ${JSON.stringify(error.response.data)}`);
      }
    } else {
      hilog.error(DOMAIN, TAG, `response | Error: ${error.message || String(error)}`);
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
    const cachePath = await this.copyToCache(context, params.filePath)
    let formData = new FormData()
    formData.append('file', cachePath);
    // 发送请求
    return this.request({
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
  }

  /**
   * 下载，仅能下载到cacheDir目录,已存在会下载失败
   * @param context 上下文
   * @param params 下载参数
   * @returns ResponseModel
   */
  async download(context: Context, params: DownloadParams): Promise<ResponseModel> {
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
   * 将文件复制到缓存，重命名，得到 internal://cache
   * @throws BusinessError
   */
  private async copyToCache(context: Context, path: string): Promise<string> {
    let dir = context.cacheDir
    let type = path.split('.').pop()
    let uuid = util.generateRandomUUID() + '.' + type
    let pathIO = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY)
    fileIo.copyFileSync(pathIO.fd, `${dir}/${uuid}`)
    fileIo.closeSync(pathIO);
    return `internal://cache/${uuid}`
  }
}
