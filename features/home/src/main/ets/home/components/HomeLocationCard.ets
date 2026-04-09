import { LocationManager } from 'common'
import { SectionCard } from '../SectionCard'

@ComponentV2
export struct HomeLocationCard {
  @Local locationKeyword: string = '上海中心'
  @Local locationSummary: string = '等待操作'

  async ensureLocationPermission(): Promise<void> {
    this.locationSummary = '检查定位权限中...'
    try {
      await LocationManager.getInstance().checkAndRequest()
      this.locationSummary = '定位权限已准备好'
    } catch (e) {
      this.locationSummary = '定位权限未授予'
    }
  }

  async reverseGeocode(): Promise<void> {
    this.locationSummary = '逆地理编码中...'
    try {
      const address = await LocationManager.getInstance().getAddressByLatLon(39.904989, 116.405285)
      this.locationSummary = `${address.locality || ''}${address.subLocality || ''}${address.roadName || ''}`
    } catch (e) {
      this.locationSummary = '逆地理编码失败'
    }
  }

  async geocodeByName(): Promise<void> {
    this.locationSummary = '地理编码中...'
    try {
      const address = await LocationManager.getInstance().getAddressesFromName(this.locationKeyword)
      this.locationSummary = `${address.latitude}, ${address.longitude}`
    } catch (e) {
      this.locationSummary = '地理编码失败'
    }
  }

  @LocalBuilder
  cardContent() {
    Column() {
      TextInput({ text: this.locationKeyword, placeholder: '输入地点关键字' })
        .onChange((value: string) => {
          this.locationKeyword = value
        })
      Text(this.locationSummary)
        .fontSize(12)
        .lineHeight(18)
        .fontColor('#475569')
      Button('权限检测').onClick(() => {
        void this.ensureLocationPermission()
      }).backgroundColor('#1D4ED8')
      Button('逆地理编码').onClick(() => {
        void this.reverseGeocode()
      }).backgroundColor('#7C3AED')
      Button('地理编码').onClick(() => {
        void this.geocodeByName()
      }).backgroundColor('#059669')
    }.width('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    SectionCard({
      title: '定位与地理编码',
      desc: '覆盖权限申请、逆地理编码与地理编码。',
      content: this.cardContent
    })
  }
}
