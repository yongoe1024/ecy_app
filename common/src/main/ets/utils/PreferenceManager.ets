import { preferences } from '@kit.ArkData';
import { AppStorageV2 } from '@kit.ArkUI';
import { EnvironmentManager } from '../functions/environment/EnvironmentManager';
import { GlobalState } from '../functions/environment/GlobalModel';

const PREFERENCES_NAME: string = 'ECY_APP'

/**
 * 用户首选项
 */
export class PreferenceManager {
  // 缓存 Preferences 实例：uiAbilityContext 启动后即固定，无需每次调用重新解析
  private static prefs?: preferences.Preferences

  private static getPrefs(): preferences.Preferences {
    if (PreferenceManager.prefs) {
      return PreferenceManager.prefs
    }
    const state = AppStorageV2.connect(GlobalState)!;
    // uiAbilityContext 尚未就绪时给出明确错误，避免底层抛出难以定位的异常
    if (!state.uiAbilityContext) {
      throw new Error('PreferenceManager: uiAbilityContext 未初始化，请在 Ability 创建后调用');
    }
    try {
      PreferenceManager.prefs = preferences.getPreferencesSync(state.uiAbilityContext, { name: PREFERENCES_NAME });
    } catch (error) {
      throw new Error(`getPreferencesSync 失败：${error.code} ${error.message}`);
    }
    return PreferenceManager.prefs;
  }

  /** 带环境前缀的 key（如 DEV_tokenInfo）：同 key 按环境隔离；enableEnv=false 用原始 key（如 env 自身——前缀依赖它，不能再带前缀） */
  private static prefixedKey(key: string, enableEnv: boolean): string {
    return enableEnv ? `${EnvironmentManager.getInstance().getEnv()}_${key}` : key
  }

  /** @throws Error */
  static getSync(key: string, defaultValue?: preferences.ValueType, enableEnv: boolean = true): preferences.ValueType {
    return PreferenceManager.getPrefs().getSync(PreferenceManager.prefixedKey(key, enableEnv), defaultValue);
  }

  /** @throws Error */
  static putSync(key: string, value: preferences.ValueType, enableEnv: boolean = true): void {
    const pre = PreferenceManager.getPrefs();
    pre.putSync(PreferenceManager.prefixedKey(key, enableEnv), value);
    pre.flushSync();
  }

  /** @throws Error */
  static hasSync(key: string, enableEnv: boolean = true): boolean {
    return PreferenceManager.getPrefs().hasSync(PreferenceManager.prefixedKey(key, enableEnv));
  }

  /** @throws Error */
  static deleteSync(key: string, enableEnv: boolean = true): void {
    const pre = PreferenceManager.getPrefs();
    pre.deleteSync(PreferenceManager.prefixedKey(key, enableEnv));
    pre.flushSync();
  }
}