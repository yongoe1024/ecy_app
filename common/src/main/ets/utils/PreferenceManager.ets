import { preferences } from '@kit.ArkData';
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalState } from '../functions';

const PREFERENCES_NAME: string = 'ECY_APP';

/**
 * 用户首选项
 **/
export class PreferenceManager {
  private static getPrefs(): preferences.Preferences {
    const state = AppStorageV2.connect(GlobalState)!;
    // uiAbilityContext 尚未就绪时给出明确错误，避免底层抛出难以定位的异常
    if (!state.uiAbilityContext) {
      throw new Error('PreferenceManager: uiAbilityContext 未初始化，请在 Ability 创建后调用');
    }
    return preferences.getPreferencesSync(state.uiAbilityContext, { name: PREFERENCES_NAME });
  }

  /** @throws */
  static getSync(key: string, defaultValue?: preferences.ValueType): preferences.ValueType {
    return PreferenceManager.getPrefs().getSync(key, defaultValue);
  }

  /** @throws */
  static putSync(key: string, value: preferences.ValueType): void {
    const pre = PreferenceManager.getPrefs();
    pre.putSync(key, value);
    pre.flushSync();
  }

  /** @throws */
  static hasSync(key: string): boolean {
    return PreferenceManager.getPrefs().hasSync(key);
  }

  /** @throws */
  static deleteSync(key: string): void {
    const pre = PreferenceManager.getPrefs();
    pre.deleteSync(key);
    pre.flushSync();
  }
}