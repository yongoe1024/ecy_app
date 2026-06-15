import { geoLocationManager } from "@kit.LocationKit";
import { abilityAccessCtrl } from '@kit.AbilityKit';
import { PermissionManager } from "../../utils";
import { AppStorageV2 } from "@kit.ArkUI";
import { GlobalState } from "./..";

const DOMAIN: number = 0x0000;
const TAG: string = 'LocationManager';

/**
 * 定位
 */
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
   * 检查权限与定位开关
   * @throws
   */
  async checkAndRequest(): Promise<void> {
    // 请求权限
    let res = await PermissionManager.requestPermissions(
      ["ohos.permission.APPROXIMATELY_LOCATION", "ohos.permission.LOCATION"],
      '无法获取定位权限，请前往系统设置中开启')
    if (!res) {
      return Promise.reject(new Error('定位权限未授予'))
    }
    let locationEnabled = geoLocationManager.isLocationEnabled();
    if (!locationEnabled) {
      // 打开定位设置
      res = await this.openSet()
      if (!res) {
        return Promise.reject(new Error('系统定位开关未开启'))
      }
    }
    return Promise.resolve()
  }

  /**
   * 逆地理编码
   * @throws
   */
  async getAddressByLatLon(lat: number, lon: number): Promise<geoLocationManager.GeoAddress> {
    // 判断服务可用
    if (!geoLocationManager.isGeocoderAvailable()) {
      return Promise.reject(new Error('逆地理编码服务不可用'))
    }
    let res = await geoLocationManager.getAddressesFromLocation({ "latitude": lat, "longitude": lon, "maxItems": 1 })
    if (res.length > 0) {
      return res[0]
    }
    return Promise.reject(new Error('未查询到对应地址'))
  }

  /**
   * 地理编码
   * @throws
   */
  async getAddressesFromName(addressName: string): Promise<geoLocationManager.GeoAddress> {
    // 判断服务可用
    if (!geoLocationManager.isGeocoderAvailable()) {
      return Promise.reject(new Error('地理编码服务不可用'))
    }
    let res = await geoLocationManager.getAddressesFromLocationName({ "description": addressName, "maxItems": 1 })
    if (res.length > 0) {
      return res[0]
    }
    return Promise.reject(new Error('未查询到对应坐标'))
  }

  /**
   * 打开定位
   * @throws
   */
  private openSet(): Promise<boolean> {
    const context = this.globalState.uiAbilityContext
    if (!context) {
      return Promise.reject(new Error('uiAbilityContext 未初始化，无法打开定位开关'))
    }
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    return atManager.requestGlobalSwitch(context, abilityAccessCtrl.SwitchType.LOCATION)
  }
}
