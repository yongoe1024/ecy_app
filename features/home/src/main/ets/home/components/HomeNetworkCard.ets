import { NetManager } from 'common'
import { SectionCard } from '../SectionCard'

@ComponentV2
export struct HomeNetworkCard {
  @Local networkSummary: string = '等待请求'
  @Local busy: boolean = false

  async requestNetDemo(): Promise<void> {
    if (this.busy) {
      return
    }
    this.busy = true
    this.networkSummary = '请求中...'
    try {
      // 注：此处直接命中公网回显接口，返回结构并不遵循 ResponseModel 的 {code,message,data} 信封
      const res = await NetManager.getInstance().request({
        method: 'get',
        url: 'https://httpbin.org/get?source=common-lab'
      })
      const text = JSON.stringify(res)
      // 回显体可能很大，截断展示避免撑爆 UI
      this.networkSummary = text.length > 300 ? `${text.substring(0, 300)}…（已截断）` : text
    } catch (e) {
      this.networkSummary = '网络请求失败，请检查网络或证书环境'
    } finally {
      this.busy = false
    }
  }

  @LocalBuilder
  cardContent() {
    Text(this.networkSummary)
      .fontSize(12)
      .lineHeight(18)
      .fontColor('#475569')
    Button(this.busy ? '请求中…' : '发起请求')
      .enabled(!this.busy)
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
