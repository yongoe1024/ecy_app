import { GlobalState, RouteManager } from 'common';
import { AppStorageV2 } from '@kit.ArkUI';
import { Home, Mine } from 'home';

@Builder
export function MainBuilder() {
  Main();
}

/**
 * 底部 Tab 主页面（ecy://entry/main，见 entry 的 router_map.json）：
 * 启动时经路由压栈作为首页 [0]（见 Index.ensureRootPage）；返回被拦截，双击退出应用。
 */
@ComponentV2
struct Main {
  @Local selectIndex: number = 0
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  @Builder
  tabBar(title: string, icon: Resource, active: Resource, index: number) {
    Column({ space: 8 }) {
      Image(this.selectIndex === index ? active : icon)
        .width(18)
      Text(title)
        .fontSize(14)
        .fontColor(index === this.selectIndex ? '#1D4ED8' : '#999')
    }
    .onClick(() => {
      this.selectIndex = index
    })
  }

  build() {
    NavDestination() {
      Column() {
        Tabs({ index: this.selectIndex }) {

          TabContent() {
            Home()
          }

          TabContent() {
            Column() {
              Text('购物模块占位')
                .fontSize(16)
                .fontColor('#999')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }

          TabContent() {
            Mine()
          }
        }
        .layoutWeight(1)
        .barHeight(0)
        .edgeEffect(EdgeEffect.Fade)
        .onChange((index: number) => {
          this.selectIndex = index
        })

        Row({ space: 30 }) {
          this.tabBar('首页', $r("app.media.entry_ic_main_home"), $r("app.media.entry_ic_main_home_active"), 0)
          this.tabBar('购物', $r("app.media.entry_ic_main_shop"), $r("app.media.entry_ic_main_shop_active"), 1)
          this.tabBar('我的', $r("app.media.entry_ic_main_mine"), $r("app.media.entry_ic_main_mine_active"), 2)
        }
        .padding({ top: 10, bottom: this.globalState.bottomRectHeight })
        .borderColor('#eee')
        .borderWidth({ top: 1 })
        .justifyContent(FlexAlign.SpaceAround)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    }
    .hideTitleBar(true)
    // 路由操作（冷启动深链消费）待本页显示后再执行，避免与首页入场转场叠加；消费后置空防重复
    .onAppear(() => {
      const params = this.globalState.wantParameters
      if (params && params.toUrl) {
        RouteManager.getInstance().pushDeepLink(String(params.toUrl))
        this.globalState.wantParameters = undefined
      }
    })
    // 拦截返回（返回键与侧滑均走此处）：阻止 pop 露出 Navigation 空白根页面；2 秒双击退出
    .onBackPressed(() => {
      return RouteManager.getInstance().handleBackPress()
    })

  }
}
