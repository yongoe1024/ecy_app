import { webview } from "@kit.ArkWeb"
import { hilog } from "@kit.PerformanceAnalysisKit";

/** Demo
WebComponent({
src: this.src,
loadProgress: this.loadProgress!!,
title: this.title!!
})
 */
const DOMAIN: number = 0x0000;
const TAG: string = 'WebComponent';

@ComponentV2
export struct WebComponent {
  @Require @Once @Param src: string
  @Param controller: webview.WebviewController = new webview.WebviewController()
  @Param title: string = ''
  @Event $title: Callback<string>
  // 进度条
  @Param loadProgress: number = 0
  @Event $loadProgress: Callback<number>

  build() {
    Web({
      controller: this.controller, renderMode: RenderMode.SYNC_RENDER,
      src: this.src
    })
      .width('100%')
      .height('100%')
      .javaScriptAccess(true)//允许javascript
      .domStorageAccess(true)//允许dom存放数据
      .geolocationAccess(true)//允许定位
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
