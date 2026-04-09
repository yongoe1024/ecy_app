import { NetManager } from 'common'
import { SectionCard } from '../SectionCard'

@ComponentV2
export struct HomeNetworkCard {
  @Local networkSummary: string = '等待请求'

  aboutToAppear(): void {
    this.networkSummary = '等待请求'
  }

  async requestNetDemo(): Promise<void> {
    this.networkSummary = '请求中...'
    try {
      const res = await NetManager.getInstance().request({
        method: 'get',
        url: 'https://httpbin.org/get?source=common-lab'
      })
      this.networkSummary = JSON.stringify(res)
    } catch (e) {
      this.networkSummary = '网络请求失败，请检查网络或证书环境'
    }
  }

  @LocalBuilder
  cardContent() {
    Text(this.networkSummary)
      .fontSize(12)
      .lineHeight(18)
      .fontColor('#475569')
    Button('发起请求')
      .onClick(() => {
        void this.requestNetDemo()
      })
      .backgroundColor('#0F766E')
  }

  build() {
    SectionCard({
      title: '网络验证',
      desc: '覆盖 NetManager 的通用请求能力，使用公网接口做回显。',
      content: this.cardContent
    })
  }
}
