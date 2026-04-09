import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@ObservedV2
export class GlobalState {
  // 屏幕宽
  @Trace windowWidth: number = 0
  // 屏幕高
  @Trace windowHeight: number = 0
  // 键盘高度
  @Trace keyboardHeight: number = 0
  // 导航栏高度
  @Trace bottomRectHeight: number = 0
  // 状态栏高度
  @Trace topRectHeight: number = 0
  // 宽度断点
  @Trace widthBreakpoint: WidthBreakpoint = WidthBreakpoint.WIDTH_XS
  // 高度断点
  @Trace heightBreakpoint: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM
  // 主ability want参数
  wantParameters?: Record<string, Object>
  // 主ability context
  uiAbilityContext?: common.UIAbilityContext;
  // 主ability windowStage
  windowStage?: window.WindowStage
  // 主 AbilityStageContext
  abilityStageContext?: common.AbilityStageContext
}

/**
 * 系统环境
 */
export enum EnvEnum {
  DEV = 'DEV',
  TEST = 'TEST',
  PRD = 'PRD'
}
