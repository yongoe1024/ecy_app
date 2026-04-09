import { Breakpoint, GlobalState } from "common"
import { AppStorageV2 } from "@kit.ArkUI"

@ComponentV2
export struct SectionCard {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!
  @BuilderParam
  content: () => void
  @Param title: string = ''
  @Param desc: string = ''

  build() {
    Column({ space: 14 }) {
      Column({ space: 6 }) {
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bolder)
          .fontColor('#0F172A')
        Text(this.desc)
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#475569')
      }

      Column({ space: 12 }) {
        this.content()
      }
      .alignItems(HorizontalAlign.Start)
    }
    .padding(18)
    .width(Breakpoint.ofWidth(this.globalState.widthBreakpoint, '100%', '100%', '48%', '48%', '31%'))
    .constraintSize({ minHeight: Breakpoint.ofWidth(this.globalState.widthBreakpoint, 0, 0, 280, 280, 300) })
    .backgroundColor('#F8FAFC')
    .borderRadius(24)
    .border({
      width: 1,
      color: '#E2E8F0'
    })
    .shadow({
      radius: 24,
      color: '#1E293B22',
      offsetX: 0,
      offsetY: 10
    })
  }
}