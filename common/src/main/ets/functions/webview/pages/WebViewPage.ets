import { webview } from "@kit.ArkWeb"
import { IBestIcon, IBestNavBar } from "@ibestservices/ibest-ui-v2"
import { WebComponent } from "../components/WebComponent"
import { RouteManager } from "../.."
import { hilog } from "@kit.PerformanceAnalysisKit"

const DOMAIN: number = 0x0000;
const TAG: string = 'WebViewPage';

@Builder
export function WebViewPageBuilder() {
  WebViewPage()
}

/**
 * web框架
 */
@ComponentV2
export struct WebViewPage {
  @Local src: string = ''
  @Local loadProgress: number = 0
  @Local title: string = ''
  controller: webview.WebviewController = new webview.WebviewController()

  pop() {
    try {
      let result = this.controller.accessBackward();
      if (result) {
        this.controller.backward();
      } else {
        RouteManager.getInstance().pop()
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `pop ：${e.code} ${e.message}`);
    }
  }

  @Builder
  leftBuilder() {
    Row({ space: 10 }) {
      IBestIcon({
        name: 'arrow-left', iconSize: 20, onIconClick: () => {
          this.pop()
        }
      })

      IBestIcon({
        name: 'cross', iconSize: 20, onIconClick: () => {
          RouteManager.getInstance().pop()
        }
      })
    }
  }

  build() {
    NavDestination() {
      IBestNavBar({
        leftBuilder: (): void => this.leftBuilder(),
        isShowStatusBar: true,
        title: this.title,
        onLeftClick: () => {
          this.pop()
        }
      })
      Stack({ alignContent: Alignment.Top }) {
        WebComponent({
          src: this.src,
          loadProgress: this.loadProgress!!,
          title: this.title!!,
          controller: this.controller
        })
        Progress({ value: 0, total: 100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .value(this.loadProgress)
          .visibility(this.loadProgress == 100 || this.loadProgress == 0 ? Visibility.Hidden : Visibility.Visible)
      }
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      const params = context.pathInfo.param as Record<string, string>
      const src = params?.src
      // 校验 src 为 http(s) 链接，避免加载空串 / 非法地址
      if (src && src.startsWith('http')) {
        this.src = src
      } else {
        hilog.error(DOMAIN, TAG, `onReady 缺少有效 src：${src}`);
        RouteManager.getInstance().pop()
      }
    })
    .onBackPressed(() => {
      this.pop()
      return true
    })
  }
}
