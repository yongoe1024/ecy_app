import { preferences } from '@kit.ArkData';
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalState } from '../functions';

const PREFERENCES_NAME: string = 'ECY_APP';

/**
 * 用户首选项
 **/
export class PreferenceManager {
  /**
   * @throws
   */
  static getSync(key: string, defaultValue?: preferences.ValueType): preferences.ValueType {
    const state = AppStorageV2.connect(GlobalState)!;
    const pre = preferences.getPreferencesSync(state.uiAbilityContext, { name: PREFERENCES_NAME })
    return pre.getSync(key, defaultValue)
  }

  /**
   * @throws
   */
  static putSync(key: string, value: preferences.ValueType): void {
    const state = AppStorageV2.connect(GlobalState)!;
    const pre = preferences.getPreferencesSync(state.uiAbilityContext, { name: PREFERENCES_NAME })
    pre.putSync(key, value)
    pre.flushSync()
  }

  /**
   * @throws
   */
  static hasSync(key: string): boolean {
    const state = AppStorageV2.connect(GlobalState)!;
    const pre = preferences.getPreferencesSync(state.uiAbilityContext, { name: PREFERENCES_NAME })
    return pre.hasSync(key)
  }

  /**
   * @throws
   */
  static deleteSync(key: string): void {
    const state = AppStorageV2.connect(GlobalState)!;
    const pre = preferences.getPreferencesSync(state.uiAbilityContext, { name: PREFERENCES_NAME })
    pre.deleteSync(key)
    pre.flushSync()
  }
}