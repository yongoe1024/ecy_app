import { Toast } from '../../utils/Toast';
import { RouterParams } from './RouterModel';
import { RouteTable } from './RouteTable';
import { UserManager } from '../user/UserManager';
import { uri } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'RouteManager';

interface LoginPopResult {
  loginSuccess?: boolean
  targetPage?: string
  targetParams?: Record<string, ESObject>
}

interface LoginRouteParams {
  targetPage: string
  targetParams?: Record<string, ESObject>
}

/**
 * 路由管理类。
 */
export class RouteManager {
  private static instance: RouteManager
  private pageStack: NavPathStack = new NavPathStack()

  public static getInstance(): RouteManager {
    if (!RouteManager.instance) {
      RouteManager.instance = new RouteManager()
    }
    return RouteManager.instance;
  }

  getStack(): NavPathStack {
    return this.pageStack
  }

  /**
   * 当前栈顶页面名
   */
  public getCurrentPageName(): string | undefined {
    const names = this.pageStack?.getAllPathName()
    if (!names || names.length === 0) {
      return undefined
    }
    return names[names.length - 1]
  }

  /** 出栈返回上一页 */
  public pop(animated?: boolean): void {
    this.pageStack?.pop(animated)
  }

  /** 返回上一页并回传结果 */
  public popResult(result: Object, animated?: boolean): void {
    this.pageStack?.pop(result, animated)
  }

  /** 返回到栈内指定名称页面 */
  public popTo(pathName: string, animated?: boolean): void {
    if (this.pageStack?.popToName(pathName, animated) == -1) {
      Toast.show('目标页面不存在')
    }
  }

  /** 返回到根页面 */
  public popToRoot(animated?: boolean): void {
    this.pageStack?.popToIndex(0, animated)
  }

  /**
   * 处理外部深链跳转：仅允许应用内部 scheme。
   * @param url want 携带的目标地址
   */
  public pushDeepLink(url: string): void {
    if (!url || !url.startsWith(RouteTable.SCHEME)) {
      hilog.warn(DOMAIN, TAG, `拒绝非法深链：${url}`);
      return
    }
    this.push({ url })
  }

  /** 跳转；url 为 http(s) 链接时经 COMMON_WEB 打开；needLogin 未登录时先经登录页 */
  public push(options: RouterParams): void {
    // 需要登录：未登录时先跳登录页，登录成功后再导向原目标页面
    if (options?.needLogin && !UserManager.getInstance().getToken()) {
      const loginParams: LoginRouteParams = {
        targetPage: options.url
      }
      if (options.params) {
        loginParams.targetParams = options.params
      }
      this.pageStack?.pushDestinationByName(RouteTable.MINE_LOGIN, loginParams, (popInfo: PopInfo) => {
        const result = popInfo.result as LoginPopResult
        if (result?.loginSuccess && result.targetPage) {
          this.push({
            url: result.targetPage,
            params: result.targetParams,
            animated: options.animated,
            onPop: options.onPop
          })
        }
      }, options.animated)
        .catch((e: BusinessError) => {
          hilog.error(DOMAIN, TAG, `push login ：${e.code} ${e.message}`);
          Toast.show('登录页面不存在')
        })
      return
    }
    // http 链接经内置 WebView 打开
    if (options.url.startsWith('http://') || options.url.startsWith('https://')) {
      this.pageStack?.pushDestinationByName(RouteTable.COMMON_WEB, { src: options.url }, (popInfo: PopInfo) => {
        options?.onPop?.(popInfo)
      }, options?.animated).catch((e: BusinessError) => {
        hilog.error(DOMAIN, TAG, `push web ：${e.code} ${e.message}`);
        Toast.show('WEB页面跳转失败')
      })
    } else {
      try {
        // 解析问号传参（query 并入 params）
        const uriInstance = new uri.URI(options.url);
        const paramNames = uriInstance.getQueryNames();
        // 浅拷贝，避免改写调用方传入的 params 对象（ArkTS 不支持对象展开）
        const params: Record<string, ESObject> = {}
        const sourceParams = options.params
        if (sourceParams) {
          Object.keys(sourceParams).forEach((key: string) => {
            params[key] = sourceParams[key]
          })
        }
        paramNames.forEach(item => {
          const value = uriInstance.getQueryValue(item)
          params[item] = value
        })
        // 路由名去掉 ?query 部分后跳转
        this.pageStack?.pushDestinationByName(
          options.url.split('?')[0],
          params,
          options.onPop,
          options?.animated
        ).catch((e: BusinessError) => {
          hilog.error(DOMAIN, TAG, `push ：${e.code} ${e.message}`);
          Toast.show('目标页面不存在')
        })
      } catch (e) {
        hilog.error(DOMAIN, TAG, `push parse url ：${e?.message}`);
        Toast.show('目标页面不存在')
      }
    }
  }
}
