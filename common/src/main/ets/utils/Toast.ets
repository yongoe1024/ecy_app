import { AppStorageV2 } from "@kit.ArkUI";
import { GlobalState } from "../functions";
import { hilog } from "@kit.PerformanceAnalysisKit";

const DOMAIN: number = 0x0000;
const TAG: string = 'Toast';

/**
 * 全局 Toast（替代三方 IBestToast）。
 *
 * 非组件环境（Manager/工具类）拿不到 UIContext，经 EntryAbility 注入的
 * windowStage 取主窗口 UIContext 弹出；windowStage 未就绪时静默跳过。
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
