import { PreferenceManager } from "../../utils";
import { EnvEnum, GlobalState } from "./GlobalModel";
import { AppStorageV2 } from "@kit.ArkUI";
import { Want } from "@kit.AbilityKit";
import { hilog } from "@kit.PerformanceAnalysisKit";

const DOMAIN: number = 0x0000;
const TAG: string = 'EnvironmentManger';

/**
 * app环境管理器
 */
export class EnvironmentManger {
  private static instance: EnvironmentManger
  private env?: EnvEnum
  globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  private constructor() {
  }

  public static getInstance(): EnvironmentManger {
    if (!EnvironmentManger.instance) {
      EnvironmentManger.instance = new EnvironmentManger()
    }
    return EnvironmentManger.instance
  }

  getEnv(): EnvEnum {
    if (this.env !== undefined) {
      return this.env
    }
    try {
      this.env = PreferenceManager.getSync('env', EnvEnum.DEV) as EnvEnum
    } catch (e) {
      hilog.error(DOMAIN, TAG, `getEnv ：${e.code} ${e.message}`);
      this.env = EnvEnum.DEV
    }
    return this.env
  }

  setEnv(e: EnvEnum): void {
    const currentEnv = this.getEnv()
    if (currentEnv !== e) {
      try {
        PreferenceManager.putSync('env', e)
        this.env = e
        // 设置环境后重启应用
        this.restartApp()
      } catch (e) {
        hilog.error(DOMAIN, TAG, `setEnv ：${e.code} ${e.message}`);
      }
    }
  }

  /**
   * 重启应用
   */
  private restartApp(): void {
    let applicationContext = this.globalState.uiAbilityContext?.getApplicationContext();
    if (applicationContext) {
      // 包名
      let want: Want = {
        bundleName: this.globalState.uiAbilityContext?.abilityInfo.bundleName,
        abilityName: this.globalState.uiAbilityContext?.abilityInfo.name
      };
      try {
        applicationContext.restartApp(want);
      } catch (e) {
        hilog.error(DOMAIN, TAG, `restartApp ：${e.code} ${e.message}`);
      }
    }
  }

  getBaseUrl(): string {
    switch (this.getEnv()) {
      case EnvEnum.DEV:
        return "http://10.0.2.2:8080"
      case EnvEnum.PRD:
        return "http://myprod.com"
      case EnvEnum.TEST:
        return "http://mytest.com"
      default:
        throw new Error("getBaseUrl:不存在的环境")
    }
  }
}
