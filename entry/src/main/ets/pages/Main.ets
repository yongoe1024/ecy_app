import { GlobalState } from "common";
import { AppStorageV2 } from "@kit.ArkUI";
import { Home, Mine } from "home";

@Builder
export function MainBuilder() {
  Main();
}

@ComponentV2
struct Main {
  @Local selectIndex: number = 0
  @Local state: GlobalState = AppStorageV2.connect(GlobalState)!

  @Builder
  tabBar(title: string, icon: Resource, active: Resource, index: number) {
    Column({ space: 8 }) {
      Image(this.selectIndex === index ? active : icon)
        .width(18)
      Text(title)
        .fontSize(14)
        .fontColor(index === this.selectIndex ? '#e89297' : '#999')
    }
    .onClick(() => {
      this.selectIndex = index
    })
  }

  build() {
    NavDestination() {
      Tabs({ index: this.selectIndex!! }) {

        TabContent() {
          Home()
        }

        TabContent() {
          // Shop()
        }

        TabContent() {
          Mine()
        }
      }
      .layoutWeight(1)
      .barHeight(0)

      Row({ space: 30 }) {
        this.tabBar('首页', $r("app.media.entry_ic_main_home"), $r("app.media.entry_ic_main_home_active"), 0)
        this.tabBar('购物', $r("app.media.entry_ic_main_shop"), $r("app.media.entry_ic_main_shop_active"), 1)
        this.tabBar('我的', $r("app.media.entry_ic_main_mine"), $r("app.media.entry_ic_main_mine_active"), 2)
      }
      .padding({ top: 10, bottom: this.state.bottomRectHeight })
      .borderColor('#eee')
      .borderWidth({ top: 1 })
      .justifyContent(FlexAlign.SpaceAround)
      .width('100%')
    }
    .hideTitleBar(true)
  }
}