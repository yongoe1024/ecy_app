import { RouterParams } from "./RouterModel";
import { RouteTable } from "./RouteTable";
import { UserManager } from '../user/UserManager';
import { uri } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { IBestToast } from "@ibestservices/ibest-ui-v2";
import { hilog } from "@kit.PerformanceAnalysisKit";

const DOMAIN: number = 0x0000;
const TAG: string = 'RouteManager';

/**
 * 路由管理类
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
   * 返回页面
   */
  public pop(animated?: boolean): void {
    this.pageStack?.pop(animated)
  }

  /**
   * 返回页面：带参数
   */
  public popResult(result: Object, animated?: boolean): void {
    this.pageStack?.pop(result, animated)
  }

  /**
   * 返回到指定页面
   */
  public popTo(pathName: string, animated?: boolean): void {
    if (this.pageStack?.popToName(pathName, animated) == -1) {
      IBestToast.show('目标页面不存在')
    }
  }

  /**
   * 返回到根页面
   */
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

  /**
   * 跳转，支持http目标
   */
  public push(options: RouterParams): void {
    // 需要登录：未登录时跳登录页，并把原 onPop 透传给登录页，避免调用方回调被静默丢弃
    if (options?.needLogin && !UserManager.getInstance().getToken()) {
      this.pageStack?.pushDestinationByName(RouteTable.MINE_LOGIN, undefined, (popInfo: PopInfo) => {
        options?.onPop?.(popInfo)
      }, true)
        .catch((e: BusinessError) => {
          hilog.error(DOMAIN, TAG, `push login ：${e.code} ${e.message}`);
          IBestToast.show('登录页面不存在')
        })
      return
    }
    // web页面
    if (options.url.startsWith("http")) {
      // 打开Web
      this.pageStack?.pushDestinationByName(RouteTable.COMMON_WEB, { src: options.url }, (popInfo: PopInfo) => {
        options?.onPop?.(popInfo)
      }, options?.animated).catch((e: BusinessError) => {
        hilog.error(DOMAIN, TAG, `push web ：${e.code} ${e.message}`);
        IBestToast.show('WEB页面跳转失败')
      })
    } else {
      // 解析问号传参
      const uriInstance = new uri.URI(options.url);
      const paramNames = uriInstance.getQueryNames();
      // 浅拷贝，避免改写调用方传入的 params 对象（ArkTS 不支持对象展开）
      let params: Record<string, ESObject> = {}
      const sourceParams = options.params
      if (sourceParams) {
        Object.keys(sourceParams).forEach((key: string) => {
          params[key] = sourceParams[key]
        })
      }
      paramNames.forEach(item => {
        let value = uriInstance.getQueryValue(item)
        params[item] = value
      })
      // 开始跳转，传入 真实路由参数
      this.pageStack?.pushDestinationByName(
        options.url.split('?')[0],
        params,
        options.onPop,
        options?.animated
      ).catch((e: BusinessError) => {
        hilog.error(DOMAIN, TAG, `push ：${e.code} ${e.message}`);
        IBestToast.show('目标页面不存在')
      })
    }
  }
}