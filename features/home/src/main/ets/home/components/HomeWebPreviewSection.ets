import { WebComponent } from 'common'

const DEMO_WEB: string = 'https://developer.harmonyos.com/'

@ComponentV2
export struct HomeWebPreviewSection {
  build() {
    Column({ space: 12 }) {
      Column() {
        Text('Web 组件预览')
          .fontSize(22)
          .fontWeight(500)
          .fontColor('#0F172A')
      }

      WebComponent({
        src: DEMO_WEB,
      })
        .height(400)
    }
    .padding(20)
    .backgroundColor('#F8FAFC')
    .borderRadius(28)
    .border({
      width: 1,
      color: '#E2E8F0'
    })
  }
}
