import { Toast } from '../../../utils';
import { webview } from '@kit.ArkWeb';
import { WebComponent } from '../components/WebComponent';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GlobalState, RouteManager } from '../..';
import { AppStorageV2 } from '@kit.ArkUI';

const DOMAIN: number = 0x0000;
const TAG: string = 'WebViewPage';

@Builder
export function WebViewPageBuilder() {
  WebViewPage()
}

/**
 * 通用 WebView 容器页（ecy://common/web）：接收 src 参数，原生导航栏 + WebComponent。
 * 返回键优先回退网页历史，无历史时出栈。
 */
@ComponentV2
export struct WebViewPage {
  @Local src: string = ''
  @Local loadProgress: number = 0
  @Local title: string = ''
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!
  controller: webview.WebviewController = new webview.WebviewController()

  pop() {
    try {
      const result = this.controller.accessBackward();
      if (result) {
        this.controller.backward();
      } else {
        RouteManager.getInstance().pop()
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `pop ：${e.code} ${e.message}`);
    }
  }

  // 原生导航栏（替代三方 IBestNavBar）：状态栏避让 + 返回/关闭 + 标题
  @Builder
  navBar() {
    Row() {
      Text('‹')
        .fontSize(30)
        .width(40)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.pop()
        })
      Text('✕')
        .fontSize(18)
        .width(32)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          RouteManager.getInstance().pop()
        })
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      // 占位平衡左侧操作区宽度，保证标题视觉居中
      Text('').width(72)
    }
    .height(48)
    .width('100%')
    .padding({ top: this.globalState.topRectHeight })
  }

  build() {
    NavDestination() {
      Column() {
        this.navBar()
        Stack({ alignContent: Alignment.Top }) {
          // 对齐官方 WebExample：Web 首次创建即持有效 src（初始空串在安卓
          // AceWeb 适配层行为未验证），src 就绪后才挂载 Web
          if (this.src !== '') {
            WebComponent({
              src: this.src,
              loadProgress: this.loadProgress!!,
              title: this.title!!,
              controller: this.controller
            })
          }
          Progress({ value: 0, total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(2)
            .value(this.loadProgress)
            .visibility(this.loadProgress == 100 || this.loadProgress == 0 ? Visibility.Hidden : Visibility.Visible)
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      const params = context.pathInfo.param as Record<string, string>
      const src = params?.src
      // 校验 src 为 http(s) 链接，避免加载空串 / 非法地址
      if (src && (src.startsWith('http://') || src.startsWith('https://'))) {
        this.src = src
      } else {
        hilog.error(DOMAIN, TAG, `onReady 缺少有效 src：${src}`);
        Toast.show('无效的网页地址')
        RouteManager.getInstance().pop()
      }
    })
    .onBackPressed(() => {
      this.pop()
      return true
    })
  }
}
