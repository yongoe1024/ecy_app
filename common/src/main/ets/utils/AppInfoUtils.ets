import { deviceInfo } from "@kit.BasicServicesKit";
import { bundleManager } from "@kit.AbilityKit";
import { hilog } from "@kit.PerformanceAnalysisKit";

const DOMAIN: number = 0x0000;
const TAG: string = 'AppInfoUtils';

export class AppInfoUtils {
  /** 应用版本号（versionName，如 "1.0.0"），取自 AppScope/app.json5 */
  static getAppVersion(): string {
    try {
      return bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      ).versionName
    } catch (e) {
      hilog.error(DOMAIN, TAG, `getAppVersion ：${e.code} ${e.message}`);
      return ''
    }
  }

  /**
   * 设备匿名标识 ODID（去掉连字符）。
   * 注意：这不是设备序列号（真 SN 需 ohos.permission.sn + deviceInfo.serial）；
   * ODID 在应用卸载重装后会变化，且属设备信息，采集前应在隐私政策中披露。
   */
  static getDeviceOdid(): string {
    return deviceInfo.ODID.replace(/-/ig, '');
  }

  static getOsVersion(): string {
    return deviceInfo.distributionOSVersion;
  }

  static getDeviceModel(): string {
    return deviceInfo.marketName;
  }
}