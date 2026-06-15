import { GlobalState, RouteManager, RouteTable } from 'common';
import { AppStorageV2 } from '@kit.ArkUI';

@Entry
@ComponentV2
struct Index {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  aboutToAppear(): void {
    // 冷启动深链：Index 是「已同意隐私」后两条路径（直接进入 / 隐私页同意后 replace）的汇合点，
    // 在此消费 want 携带的 toUrl 并清空，避免重复跳转。
    const params = this.globalState.wantParameters
    if (params && params.toUrl) {
      // 仅允许应用内部 scheme 深链，避免外部诱导打开任意网页
      RouteManager.getInstance().pushDeepLink(String(params.toUrl))
      this.globalState.wantParameters = undefined
    }
  }

  build() {
    Navigation(RouteManager.getInstance().getStack(), { name: RouteTable.ENTRY_MAIN }) {
    }
    .mode(NavigationMode.Stack)
  }
}
