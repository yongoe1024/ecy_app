import { EnvironmentManger, GlobalState } from 'common'
import { AppStorageV2, LengthMetrics } from '@kit.ArkUI'

@ComponentV2
export struct HomeHeroSection {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  @LocalBuilder
  lab(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor('#431407')
      .backgroundColor('#FED7AA')
      .padding({
        left: 10,
        right: 10,
        top: 6,
        bottom: 6
      })
      .borderRadius(999)
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column({ space: 14 }) {
        Text('Common Lab')
          .fontSize(34)
          .fontWeight(500)
          .fontColor('#F8FAFC')
        Text('验证状态、存储、权限、网络、媒体与 Web。')
          .fontSize(14)
          .lineHeight(22)
          .fontColor('#E2E8F0')
        Flex({
          wrap: FlexWrap.Wrap,
          space: {
            main: LengthMetrics.vp(5),
            cross: LengthMetrics.vp(5),
          }
        }) {
          this.lab(`环境：${EnvironmentManger.getInstance().getEnv()}`)
          this.lab(`宽度 ${Math.floor(this.globalState.windowWidth)}vp`)
          this.lab(`高度 ${Math.floor(this.globalState.windowHeight)}vp`)
          this.lab(`导航栏${Math.floor(this.globalState.topRectHeight)}vp`)
          this.lab(`状态栏${Math.floor(this.globalState.bottomRectHeight)}vp`)
          this.lab(`宽度断点${this.globalState.widthBreakpoint.toString()}`)
          this.lab(`高度断点${this.globalState.heightBreakpoint.toString()}`)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .padding(14)
      .width('100%')
    }
    .height(220)
    .width('100%')
    .linearGradient({
      angle: 135,
      colors: [['#0F172A', 0], ['#1D4ED8', 0.55], ['#22C55E', 1]]
    })
    .borderRadius(16)
    .shadow({
      radius: 36,
      color: '#0F172A33',
      offsetX: 0,
      offsetY: 16
    })
  }
}
