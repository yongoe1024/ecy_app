import { HomeEnvCard } from './components/HomeEnvCard'
import { HomeHeroSection } from './components/HomeHeroSection'
import { HomeLocationCard } from './components/HomeLocationCard'
import { HomeMediaCard } from './components/HomeMediaCard'
import { HomeNetworkCard } from './components/HomeNetworkCard'
import { HomeRouteCard } from './components/HomeRouteCard'
import { HomeStorageCard } from './components/HomeStorageCard'
import { HomeTimerCard } from './components/HomeTimerCard'
import { HomeWebPreviewSection } from './components/HomeWebPreviewSection'
import { AppStorageV2, LengthMetrics } from '@kit.ArkUI'
import { GlobalState } from 'common'

@ComponentV2
export struct Home {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  build() {
    Column() {
      Scroll() {
        Column({ space: 18 }) {
          HomeHeroSection()

          Flex({
            wrap: FlexWrap.Wrap,
            space: {
              main: LengthMetrics.vp(15),
              cross: LengthMetrics.vp(15),
            }
          }) {
            HomeEnvCard()
            HomeStorageCard()
            HomeTimerCard()
            HomeNetworkCard()
            HomeRouteCard()
            HomeLocationCard()
            HomeMediaCard()
          }
          .width('100%')

          HomeWebPreviewSection()
        }
        .width('100%')
        .padding({
          left: 20,
          right: 20,
          top: 20,
          bottom: 28
        })
      }
      .scrollBar(BarState.Off)
    }
    .padding({ top: this.globalState.topRectHeight })
    .height('100%')
    .width('100%')
    .linearGradient({
      angle: 180,
      colors: [['#F8FAFC', 0], ['#E2E8F0', 1]]
    })
  }
}
