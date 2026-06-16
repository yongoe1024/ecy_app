import { preferences } from '@kit.ArkData';
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalState } from '../functions';

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
      throw new Error('PreferenceManager: uiAbilityContext 未初始化，请在 Ability 创建后调用');
    }
    try {
      PreferenceManager.prefs = preferences.getPreferencesSync(state.uiAbilityContext, { name: PREFERENCES_NAME });
    } catch (error) {
      throw new Error(`getPreferencesSync:失败：${error.code} ${error.message}`);
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

  /**
   * 读取字符串：key 不存在或存储的不是字符串时返回 defaultValue。
   * @throws Error
   */
  static getStringSync(key: string, defaultValue: string = ''): string {
    const value = PreferenceManager.getPrefs().getSync(key, defaultValue);
    return typeof value === 'string' ? value : defaultValue;
  }

  /**
   * 读取布尔：key 不存在或存储的不是布尔时返回 defaultValue。
   * @throws Error
   */
  static getBooleanSync(key: string, defaultValue: boolean = false): boolean {
    const value = PreferenceManager.getPrefs().getSync(key, defaultValue);
    return typeof value === 'boolean' ? value : defaultValue;
  }

  /**
   * 读取数字：key 不存在或存储的不是数字时返回 defaultValue。
   * @throws Error
   */
  static getNumberSync(key: string, defaultValue: number = 0): number {
    const value = PreferenceManager.getPrefs().getSync(key, defaultValue);
    return typeof value === 'number' ? value : defaultValue;
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