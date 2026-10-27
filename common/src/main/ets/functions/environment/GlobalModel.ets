import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

/** 全局窗口/设备状态与主 Ability 上下文：EntryAbility 写入，UI 层经 AppStorageV2.connect 读取 */
@ObservedV2
export class GlobalState {
  // 屏幕宽度
  @Trace windowWidth: number = 0
  // 屏幕高度
  @Trace windowHeight: number = 0
  // 键盘高度
  @Trace keyboardHeight: number = 0
  // 底部导航条避让高度
  @Trace bottomRectHeight: number = 0
  // 状态栏高度
  @Trace topRectHeight: number = 0
  // 宽度断点
  @Trace widthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_XS
  // 高度断点
  @Trace heightBreakpoint: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM
  // 主 Ability want 参数
  wantParameters?: Record<string, Object>
  // 主 Ability context
  uiAbilityContext?: common.UIAbilityContext;
  // 主 Ability windowStage
  windowStage?: window.WindowStage
  // 主 AbilityStageContext
  abilityStageContext?: common.AbilityStageContext
}