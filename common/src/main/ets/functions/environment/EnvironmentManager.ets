import { PreferenceManager, Toast } from '../../utils';
import { GlobalState } from './GlobalModel';
import { AppStorageV2 } from '@kit.ArkUI';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import BuildProfile from '../../../../../BuildProfile';
import { AppConfig, envConfig } from './EnvConfig';

const DOMAIN: number = 0x0000;
const TAG: string = 'EnvironmentManager';

/**
 * app环境管理器
 */
export class EnvironmentManager {
  private static instance: EnvironmentManager
  private buildEnv: string = BuildProfile.ENV
  private env: string = BuildProfile.ENV
  globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  private constructor() {
    try {
      this.env = PreferenceManager.getSync('env', 'DEV') as string
    } catch (e) {
      hilog.error(DOMAIN, TAG, `getInstance ：${e.code} ${e.message}`);
    }
  }

  public static getInstance(): EnvironmentManager {
    if (!EnvironmentManager.instance) {
      EnvironmentManager.instance = new EnvironmentManager()
    }
    return EnvironmentManager.instance
  }

  /**
   * 构建环境
   */
  getBuildEnv() {
    return this.buildEnv
  }

  /**
   * 应用内环境 可改
   */
  getEnv(): string {
    if (this.buildEnv === 'PROD') {
      return 'PROD'
    }
    return this.env
  }

  /**
   * 切换环境并重启应用使其生效。
   * 约定：写变更不静默吞错——失败时抛出，调用方需感知。
   */
  setEnv(e: string): void {
    if (this.buildEnv === 'PROD') {
      return
    }
    if (this.env === e) {
      return
    }
    try {
      PreferenceManager.putSync('env', e)
    } catch (e) {
      hilog.error(DOMAIN, TAG, `setEnv ：${e.code} ${e.message}`);
    }
    this.env = e
    this.restartApp()
  }

  /**
   * 重启应用。
   */
  private restartApp(): void {
    const applicationContext = this.globalState.uiAbilityContext?.getApplicationContext();
    if (applicationContext) {
      // 包名
      const want: Want = {
        bundleName: this.globalState.uiAbilityContext?.abilityInfo.bundleName,
        abilityName: this.globalState.uiAbilityContext?.abilityInfo.name
      };
      try {
        applicationContext.restartApp(want);
      } catch (e) {
        hilog.error(DOMAIN, TAG, `restartApp ：${e.code} ${e.message}`);
      }
    }
    Toast.show('需手动重启')
  }

  getEnvConfig(): AppConfig {
    if (this.buildEnv === 'PROD') {
      return envConfig['PROD']
    }
    return envConfig[this.env]
  }
}
