import { LocationManager } from 'common'
import { SectionCard } from '../SectionCard'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN: number = 0x0000;
const TAG: string = 'HomeLocationCard';

@ComponentV2
export struct HomeLocationCard {
  @Local locationKeyword: string = '上海中心'
  @Local locationSummary: string = '等待操作'
  @Local busy: boolean = false

  async ensureLocationPermission(): Promise<void> {
    if (this.busy) {
      return
    }
    this.busy = true
    this.locationSummary = '检查定位权限中...'
    try {
      await LocationManager.getInstance().checkAndRequest()
      this.locationSummary = '定位权限已准备好'
    } catch (e) {
      hilog.error(DOMAIN, TAG, `ensureLocationPermission ：${e?.message}`);
      this.locationSummary = '定位权限未授予'
    } finally {
      this.busy = false
    }
  }

  async reverseGeocode(): Promise<void> {
    if (this.busy) {
      return
    }
    this.busy = true
    this.locationSummary = '逆地理编码中...'
    try {
      const address = await LocationManager.getInstance().getAddressByLatLon(39.904989, 116.405285)
      const text = `${address.locality || ''}${address.subLocality || ''}${address.roadName || ''}`
      this.locationSummary = text || '未获取到地址'
    } catch (e) {
      hilog.error(DOMAIN, TAG, `reverseGeocode ：${e?.message}`);
      this.locationSummary = '逆地理编码失败'
    } finally {
      this.busy = false
    }
  }

  async geocodeByName(): Promise<void> {
    if (this.busy) {
      return
    }
    this.busy = true
    this.locationSummary = '地理编码中...'
    try {
      const address = await LocationManager.getInstance().getAddressesFromName(this.locationKeyword)
      this.locationSummary = `${address.latitude}, ${address.longitude}`
    } catch (e) {
      hilog.error(DOMAIN, TAG, `geocodeByName ：${e?.message}`);
      this.locationSummary = '地理编码失败'
    } finally {
      this.busy = false
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
      Button('权限检测').enabled(!this.busy).onClick(() => {
        void this.ensureLocationPermission()
      }).backgroundColor('#1D4ED8')
      Button('逆地理编码').enabled(!this.busy).onClick(() => {
        void this.reverseGeocode()
      }).backgroundColor('#7C3AED')
      Button('地理编码').enabled(!this.busy).onClick(() => {
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
