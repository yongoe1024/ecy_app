import { PreferenceManager } from '../../utils';
import { EnvEnum, GlobalState } from './GlobalModel';
import { AppStorageV2 } from '@kit.ArkUI';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'EnvironmentManager';

// deveco虚拟机网关
const DEV_BASE_URL = 'http://10.0.2.2:8080'
// TODO: 替换为真实生产环境地址
const PRD_BASE_URL = 'https://myprod.com'
// TODO: 替换为真实测试环境地址
const TEST_BASE_URL = 'https://mytest.com'

/**
 * app环境管理器
 */
export class EnvironmentManager {
  private static instance: EnvironmentManager
  private env?: EnvEnum
  globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  private constructor() {
  }

  public static getInstance(): EnvironmentManager {
    if (!EnvironmentManager.instance) {
      EnvironmentManager.instance = new EnvironmentManager()
    }
    return EnvironmentManager.instance
  }

  getEnv(): EnvEnum {
    if (this.env !== undefined) {
      return this.env
    }
    try {
      const stored = PreferenceManager.getSync('env', EnvEnum.DEV) as string
      this.env = EnvironmentManager.toEnvEnum(stored)
    } catch (e) {
      hilog.error(DOMAIN, TAG, `getEnv ：${e.code} ${e.message}`);
      this.env = EnvEnum.DEV
    }
    return this.env
  }

  /** 把持久化的字符串安全转换为 EnvEnum，非法/历史遗留值回退 DEV */
  private static toEnvEnum(value: string): EnvEnum {
    switch (value) {
      case EnvEnum.TEST:
        return EnvEnum.TEST
      case EnvEnum.PRD:
        return EnvEnum.PRD
      case EnvEnum.DEV:
        return EnvEnum.DEV
      default:
        return EnvEnum.DEV
    }
  }

  setEnv(e: EnvEnum): void {
    const currentEnv = this.getEnv()
    if (currentEnv !== e) {
      try {
        PreferenceManager.putSync('env', e)
        this.env = e
        // 设置环境后重启应用
        this.restartApp()
      } catch (err) {
        hilog.error(DOMAIN, TAG, `setEnv ：${err.code} ${err.message}`);
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
        return DEV_BASE_URL
      case EnvEnum.PRD:
        return PRD_BASE_URL
      case EnvEnum.TEST:
        return TEST_BASE_URL
      default:
      // getEnv 已保证返回合法枚举，这里回退到 DEV 而非抛错
        return DEV_BASE_URL
    }
  }
}
