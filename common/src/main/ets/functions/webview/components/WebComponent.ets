import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';

/** Demo
 * WebComponent({
 * src: this.src,
 * loadProgress: this.loadProgress!!,
 * title: this.title!!
 * })
 */
const DOMAIN: number = 0x0000;
const TAG: string = 'WebComponent';

/** 主框架加载失败信息：network 级错误透传 errorCode，HTTP 级错误透传响应码 */
export interface WebLoadError {
  code: number
  message: string
}

@ComponentV2
export struct WebComponent {
  @Require @Param src: string
  @Param controller: webview.WebviewController = new webview.WebviewController()
  @Param title: string = ''
  @Event $title: Callback<string>
  // 进度条
  @Param loadProgress: number = 0
  @Event $loadProgress: Callback<number>
  // 主框架加载失败回调（可选）：调用方可据此自定义错误处理；与内置兜底层互不影响
  @Event onError: Callback<WebLoadError>
  // 是否启用内置「加载失败」兜底层（默认开启）；置 false 时仅触发 onError / 记日志，由调用方自行提示
  @Param showErrorPage: boolean = true
  // 主框架是否加载失败，用于显示兜底层。每次主框架开始加载时重置
  @Local loadError: boolean = false
  @Local errorMsg: string = ''
  // 安全相关能力默认按需开启：加载任意外链时应谨慎放开
  // JS 与 DOM 存储多数页面需要，默认开启；定位、文件访问较敏感，默认关闭
  @Param javaScriptAccess: boolean = true
  @Param domStorageAccess: boolean = true
  @Param geolocationAccess: boolean = false
  // 文件访问默认关闭，避免外链页面读取本地文件
  @Param fileAccess: boolean = false

  @Builder
  errorOverlay() {
    Column({ space: 12 }) {
      Text('网页加载失败')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#172033')
      Text(this.errorMsg || '请检查网络后重试')
        .fontSize(13)
        .lineHeight(20)
        .fontColor('#7B8794')
        .textAlign(TextAlign.Center)
        .padding({ left: 32, right: 32 })
      Button('重试')
        .fontSize(14)
        .backgroundColor('#1D4ED8')
        .onClick(() => {
          // 先隐藏兜底层再触发重新加载；下一次 onPageBegin 也会重置 loadError
          this.loadError = false
          try {
            this.controller.refresh()
          } catch (e) {
            hilog.error(DOMAIN, TAG, `refresh ：${e.code} ${e.message}`);
          }
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
  }

  build() {
    Stack() {
      Web({
        controller: this.controller, renderMode: RenderMode.SYNC_RENDER,
        src: this.src
      })
        .width('100%')
        .height('100%')
        .javaScriptAccess(this.javaScriptAccess)//允许javascript
        .domStorageAccess(this.domStorageAccess)//允许dom存放数据
        .geolocationAccess(this.geolocationAccess)//允许定位
        .fileAccess(this.fileAccess)//允许访问本地文件
        .mixedMode(MixedMode.None)//禁止 https 页面加载 http 资源（混合内容）
        .cacheMode(CacheMode.Online)//设置缓存模式
        .overScrollMode(OverScrollMode.NEVER)
        .onPageBegin(() => {
          // 主框架开始加载：清掉上一次的失败状态，使重试 / 重新导航后兜底层消失
          this.loadError = false
        })
        .onPageEnd(() => {
          try {
            this.$title(this.controller.getTitle())
          } catch (e) {
            hilog.error(DOMAIN, TAG, `onPageEnd ：${e.code} ${e.message}`);
          }
        })
        .onProgressChange((event) => {
          if (event) {
            this.$loadProgress(event.newProgress)
            if (event.newProgress == 100) {
              this.$loadProgress(0)
            }
          }
        })
        .onErrorReceive((event) => {
          // 仅处理主框架的网络级错误（断网 / DNS / SSL 等）；子资源错误（图标等）忽略，避免误报
          if (event && event.request.isMainFrame()) {
            const code = event.error.getErrorCode()
            const info = event.error.getErrorInfo()
            hilog.error(DOMAIN, TAG, `onErrorReceive ：${code} ${info}`);
            this.errorMsg = info
            this.loadError = true
            this.onError({ code: code, message: info })
          }
        })
        .onHttpErrorReceive((event) => {
          // 主框架 HTTP 错误：仅记录并上抛，不强制盖兜底层——服务器错误页通常仍会渲染
          if (event && event.request.isMainFrame()) {
            const code = event.response.getResponseCode()
            if (code >= 400) {
              hilog.error(DOMAIN, TAG, `onHttpErrorReceive ：${code}`);
              this.onError({ code: code, message: `HTTP ${code}` })
            }
          }
        })

      if (this.loadError && this.showErrorPage) {
        this.errorOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }
}
