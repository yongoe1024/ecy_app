import { WebComponent } from 'common'
import { SectionCard } from '../SectionCard'

const DEMO_WEB: string = 'https://developer.harmonyos.com/'

@ComponentV2
export struct HomeWebPreviewSection {
  build() {
    SectionCard() {
      Column() {
        Text('Web 组件预览')
          .fontSize(22)
          .fontWeight(500)
          .fontColor('#0F172A')
        WebComponent({
          src: DEMO_WEB,
        })
          .height(400)
      }
    }
  }
}
