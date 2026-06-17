import { preferences } from '@kit.ArkData';
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalState } from '../functions';
import { AppError } from '../functions/AppError';

const PREFERENCES_NAME: string = 'ECY_APP';

/**
 * 用户首选项
 **/
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
      throw new AppError(1101, 'PreferenceManager: uiAbilityContext 未初始化，请在 Ability 创建后调用');
    }
    try {
      PreferenceManager.prefs = preferences.getPreferencesSync(state.uiAbilityContext, { name: PREFERENCES_NAME });
    } catch (error) {
      throw new AppError(1102, `getPreferencesSync 失败：${error.code} ${error.message}`);
    }
    return PreferenceManager.prefs;
  }

  /**
   * 读取原始值（联合类型 ValueType）。多数场景建议改用类型化的
   * getStringSync / getBooleanSync / getNumberSync，避免在调用处强转。
   * @throws Error
   */
  static getSync(key: string, defaultValue?: preferences.ValueType): preferences.ValueType {
    return PreferenceManager.getPrefs().getSync(key, defaultValue);
  }

  /** @throws Error */
  static putSync(key: string, value: preferences.ValueType): void {
    const pre = PreferenceManager.getPrefs();
    pre.putSync(key, value);
    pre.flushSync();
  }

  /** @throws Error */
  static hasSync(key: string): boolean {
    return PreferenceManager.getPrefs().hasSync(key);
  }

  /** @throws Error */
  static deleteSync(key: string): void {
    const pre = PreferenceManager.getPrefs();
    pre.deleteSync(key);
    pre.flushSync();
  }
}