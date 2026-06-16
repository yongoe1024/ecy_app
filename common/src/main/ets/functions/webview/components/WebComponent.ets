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

@ComponentV2
export struct WebComponent {
  @Require @Param src: string
  @Param controller: webview.WebviewController = new webview.WebviewController()
  @Param title: string = ''
  @Event $title: Callback<string>
  // 进度条
  @Param loadProgress: number = 0
  @Event $loadProgress: Callback<number>
  // 安全相关能力默认按需开启：加载任意外链时应谨慎放开
  // JS 与 DOM 存储多数页面需要，默认开启；定位、文件访问较敏感，默认关闭
  @Param javaScriptAccess: boolean = true
  @Param domStorageAccess: boolean = true
  @Param geolocationAccess: boolean = false
  // 文件访问默认关闭，避免外链页面读取本地文件
  @Param fileAccess: boolean = false

  build() {
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
  }
}
