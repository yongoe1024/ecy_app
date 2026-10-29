import { Toast } from '../../utils/Toast';
import { RouterParams } from './RouterModel';
import { RouteTable } from './RouteTable';
import { GlobalState } from '../environment/GlobalModel';
import { AppStorageV2 } from '@kit.ArkUI';
import { uri } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'RouteManager';

/**
 * 路由管理类。
 */
export class RouteManager {
  private static instance: RouteManager
  private pageStack: NavPathStack = new NavPathStack()
  // 首页返回双击计时（毫秒）
  private lastBackTime: number = 0

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

  /**
   * 首页（栈 [0] = Main，经 onBackPressed 调用）返回处理：恒返回 true 拦截，
   * 防止 pop 后露出 Navigation 空白根页面；2 秒内双击退出应用，首次按提示。
   */
  handleBackPress(): boolean {
    const now = Date.now()
    if (now - this.lastBackTime < 2000) {
      const context = AppStorageV2.connect(GlobalState)!.uiAbilityContext
      context?.terminateSelf().catch((e: BusinessError) => {
        hilog.error(DOMAIN, TAG, `terminateSelf ：${e.code} ${e.message}`);
      })
    } else {
      Toast.show('再按一次退出程序')
    }
    this.lastBackTime = now
    return true
  }

  /** 跳转；url 为 http(s) 链接时经 COMMON_WEB 打开 */
  public push(options: RouterParams): void {
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
