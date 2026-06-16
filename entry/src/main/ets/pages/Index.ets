import { GlobalState, RouteManager, RouteTable } from 'common';
import { AppStorageV2 } from '@kit.ArkUI';

@Entry
@ComponentV2
struct Index {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  private consumeDeepLink(): void {
    const params = this.globalState.wantParameters
    if (params && params.toUrl) {
      // 仅允许应用内部 scheme 深链，避免外部诱导打开任意网页
      RouteManager.getInstance().pushDeepLink(String(params.toUrl))
      this.globalState.wantParameters = undefined
    }
  }

  build() {
    // 冷启动深链：Index 是「已同意隐私」后两条路径（直接进入 / 隐私页同意后 replace）的汇合点，
    // 在 Navigation 生命周期中消费，确保启动容器已挂载。
    Navigation(RouteManager.getInstance().getStack(), { name: RouteTable.ENTRY_MAIN }) {
    }
    .mode(NavigationMode.Stack)
    .onAppear(() => {
      this.consumeDeepLink()
    })
  }
}
