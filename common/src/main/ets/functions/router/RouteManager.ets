import { RouterParams } from "./RouterModel";
import { RouteTable } from "./RouteTable";
import { UserManager } from '../user/UserManager';
import { uri } from '@kit.ArkTS';
import { IBestToast } from "@ibestservices/ibest-ui-v2";

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
   * 跳转，支持http目标
   */
  public push(options: RouterParams): void {
    // 需要登录
    if (options?.needLogin && !UserManager.getInstance().getToken()) {
      this.pageStack?.pushPathByName(RouteTable.ENTRY_LOGIN, undefined, true)
      return
    }
    // web页面
    if (options.url.startsWith("http")) {
      // 打开Web
      this.pageStack?.pushDestinationByName(RouteTable.COMMON_WEB, { src: options.url }, (popInfo: PopInfo) => {
        options?.onPop?.(popInfo)
      }, options?.animated).catch((e: BusinessError) => {
        IBestToast.show('WEB页面跳转失败')
      })
    } else {
      // 解析问号传参
      const uriInstance = new uri.URI(options.url);
      const paramNames = uriInstance.getQueryNames();
      let params = options.params ?? {}
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
        IBestToast.show('目标页面不存在')
      })
    }
  }
}