import { Toast } from '../../utils';
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
 *
 * 错误处理约定（UI 命令层）：所有导航方法均为 best-effort 的 void 命令，
 * **永不 throw / reject**——失败时仅记录日志，必要时以 Toast 提示用户（如目标页不存在）。
 * 调用方无需 try/catch；如需在出栈后拿返回值，用 RouterParams.onPop 回调。
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
   * 当前栈顶页面名（Navigation 栈自底向上，末位即当前页）。
   * Navigation 首页（如 entry 的 Index）不压栈，栈空时返回 undefined。
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
   * 处理外部深链跳转：仅允许应用内部 scheme，避免被外部诱导打开任意网页（开放重定向）。
   * @param url want 携带的目标地址
   */
  public pushDeepLink(url: string): void {
    if (!url || !url.startsWith(RouteTable.SCHEME)) {
      hilog.warn(DOMAIN, TAG, `拒绝非法深链：${url}`);
      return
    }
    // 深链可能通过 ?src= 携带外链（如 ecy://common/web?src=...），经内部 WebView 路由打开任意网页。
    // 默认不允许深链打开外链，避免开放重定向 / 钓鱼；如需放开，在 isDeepLinkSrcSafe 内加 host 白名单。
    if (!RouteManager.isDeepLinkSrcSafe(url)) {
      hilog.warn(DOMAIN, TAG, `拒绝深链携带的外链 src：${url}`);
      return
    }
    this.push({ url })
  }

  /**
   * 消费主 Ability want 携带的深链（toUrl 参数）：存在则按内部 scheme 跳转。
   * 隐私门校验由调用方保证：EntryAbility 热启动查偏好，Index 由渲染分支天然保证。
   * @returns 是否消费了深链（true 时调用方应清空 wantParameters，防止重复跳转）
   */
  public consumeWantDeepLink(params?: Record<string, Object>): boolean {
    if (params && params.toUrl) {
      this.pushDeepLink(String(params.toUrl))
      return true
    }
    return false
  }

  /** 深链不得携带 http(s) 外链 src，防止经内部 WebView 路由打开任意网页 */
  private static isDeepLinkSrcSafe(url: string): boolean {
    try {
      const u = new uri.URI(url)
      if (!u.getQueryNames().includes('src')) {
        return true
      }
      const src = u.getQueryValue('src')
      return !src || !src.startsWith('http')
    } catch (e) {
      return false
    }
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
      }, true)
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
