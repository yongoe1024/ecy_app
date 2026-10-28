import { AppStorageV2 } from "@kit.ArkUI";
import { GlobalState } from '../functions/environment/GlobalModel';
import { hilog } from "@kit.PerformanceAnalysisKit";

const DOMAIN: number = 0x0000;
const TAG: string = 'Toast';

/**
 * 全局 Toast
 */
export class Toast {
  static show(message: string): void {
    const windowStage = AppStorageV2.connect(GlobalState)!.windowStage
    if (!windowStage) {
      return
    }
    try {
      windowStage.getMainWindowSync().getUIContext().getPromptAction().showToast({ message })
    } catch (e) {
      hilog.error(DOMAIN, TAG, `showToast ：${e?.code} ${e?.message}`);
    }
  }
}
