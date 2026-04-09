import { RouteManager } from 'common'
import { SectionCard } from '../SectionCard'

const DEMO_WEB: string = 'https://developer.harmonyos.com/'

@ComponentV2
export struct HomeRouteCard {
  openFullWebDemo(): void {
    RouteManager.getInstance().push({
      url: DEMO_WEB,
      animated: true
    })
  }

  @LocalBuilder
  cardContent() {
    Button('路由到 不存在 页面')
      .onClick(() => {
        RouteManager.getInstance().push({
          url: '/abc',
          animated: true
        })
      })
      .backgroundColor('#7C3AED')
    Button('路由到 Web 页面')
      .onClick(() => this.openFullWebDemo())
      .backgroundColor('#7C3AED')
  }

  build() {
    SectionCard({
      title: '路由与页面跳转',
      desc: '验证 RouteManager 跳转能力与 WebViewPage',
      content: this.cardContent
    })
  }
}
