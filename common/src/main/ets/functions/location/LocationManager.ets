import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import { PermissionManager } from '../../utils/PermissionManager';
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalState } from '../environment/GlobalModel';

const DOMAIN: number = 0x0000;
const TAG: string = 'LocationManager';

/** 定位：权限与开关检查、地理/逆地理编码 */
export class LocationManager {
  private static instance: LocationManager;
  globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  private constructor() {
  }

  public static getInstance(): LocationManager {
    if (!LocationManager.instance) {
      LocationManager.instance = new LocationManager();
    }
    return LocationManager.instance;
  }


  /**
   * 检查权限与定位开关（未开启时弹系统开关弹窗）。
   * 约定：失败 Promise.reject(Error)；底层 SDK 错误以 BusinessError 透传。
   */
  async checkAndRequest(): Promise<void> {
    // 请求定位权限
    const granted = await PermissionManager.requestPermissions(
      ["ohos.permission.APPROXIMATELY_LOCATION", "ohos.permission.LOCATION"],
      '无法获取定位权限，请前往系统设置中开启')
    if (!granted) {
      return Promise.reject(new Error('定位权限未授予'))
    }
    if (!geoLocationManager.isLocationEnabled()) {
      // 打开定位开关（系统弹窗）
      const enabled = await this.openSet()
      if (!enabled) {
        return Promise.reject(new Error('系统定位开关未开启'))
      }
    }
  }

  /** 逆地理编码：经纬度 → 地址 */
  async getAddressByLatLon(lat: number, lon: number): Promise<geoLocationManager.GeoAddress> {
    // 判断编码服务可用
    if (!geoLocationManager.isGeocoderAvailable()) {
      return Promise.reject(new Error('逆地理编码服务不可用'))
    }
    let res = await geoLocationManager.getAddressesFromLocation({ "latitude": lat, "longitude": lon, "maxItems": 1 })
    if (res.length > 0) {
      return res[0]
    }
    return Promise.reject(new Error('未查询到对应地址'))
  }

  /** 地理编码：地址 → 经纬度 */
  async getAddressesFromName(addressName: string): Promise<geoLocationManager.GeoAddress> {
    // 判断编码服务可用
    if (!geoLocationManager.isGeocoderAvailable()) {
      return Promise.reject(new Error('地理编码服务不可用'))
    }
    let res = await geoLocationManager.getAddressesFromLocationName({ "description": addressName, "maxItems": 1 })
    if (res.length > 0) {
      return res[0]
    }
    return Promise.reject(new Error('未查询到对应坐标'))
  }

  /** 请求系统弹窗打开定位开关，返回开关的最终状态 */
  private openSet(): Promise<boolean> {
    const context = this.globalState.uiAbilityContext
    if (!context) {
      return Promise.reject(new Error('uiAbilityContext 未初始化，无法打开定位开关'))
    }
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    // 系统弹窗就地授权，返回值即开关的最终状态：用户未开启时为 false
    return atManager.requestGlobalSwitch(context, abilityAccessCtrl.SwitchType.LOCATION)
  }
}
