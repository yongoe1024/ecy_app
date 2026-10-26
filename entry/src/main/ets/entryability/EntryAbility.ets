import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, window } from '@kit.ArkUI';
import { EnvEnum, EnvironmentManager, GlobalState, PreferenceManager, RouteManager, } from 'common';
import { webview } from '@kit.ArkWeb';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility'

export default class EntryAbility extends UIAbility {
  globalState = AppStorageV2.connect(GlobalState)!;
  // 持有主窗口引用，便于在 onWindowStageDestroy 中反注册监听
  private mainWindow?: window.Window

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.globalState.uiAbilityContext = this.context
    // 深链不在热启动处理：冷启动时隐私未同意 / Navigation 未挂载，仅暂存，
    // 由 Index 在隐私同意与挂载后消费（见 handleDeepLink 与 Index）
    this.globalState.wantParameters = want.parameters
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
    if (EnvironmentManager.getInstance().getEnv() === EnvEnum.DEV) {
      webview.WebviewController.setWebDebuggingAccess(true);
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.globalState.wantParameters = want.parameters
    // 应用已在运行，Navigation 已挂载，可直接处理深链（内部仍校验隐私同意）
    this.handleDeepLink()
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onNewWant');
  }

  /**
   * 处理 want 携带的深链（热启动场景）：仅在已同意隐私后跳转，避免绕过隐私门。
   * 冷启动由 Index 在隐私同意与 Navigation 挂载后消费
   * （onAgreed 回调与 onAppear 两处调 consumeDeepLink）。
   */
  private handleDeepLink(): void {
    try {
      if (!PreferenceManager.hasSync('agreePrivacy')) {
        return
      }
    } catch (e) {
      return
    }
    if (RouteManager.getInstance().consumeWantDeepLink(this.globalState.wantParameters)) {
      // 消费后清空，避免重复跳转
      this.globalState.wantParameters = undefined
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');
    this.globalState.windowStage = windowStage
    // 启动只加载唯一 @Entry 页面；隐私门由 Index 内部条件渲染（未同意时整屏 PrivacyPage 组件）
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'windowStage Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      try {
        this.updateWinInfo(windowStage.getMainWindowSync())
      } catch (error) {
        hilog.error(DOMAIN, TAG, '获取windowStage失败');
      }
    });
  }

  onWindowStageDestroy(): void {
    // 反注册窗口监听，避免泄漏
    try {
      this.mainWindow?.off('avoidAreaChange')
      this.mainWindow?.off('windowSizeChange')
      this.mainWindow?.off('keyboardHeightChange')
    } catch (e) {
      hilog.error(DOMAIN, TAG, `off window listeners ：${e.code} ${e.message}`);
    }
    this.mainWindow = undefined
    this.globalState.windowStage = undefined;
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }

  /** 记录窗口尺寸与避让区，并注册窗口变化监听 */
  updateWinInfo(windowClass: window.Window) {
    try {
      this.mainWindow = windowClass
      const uiContext = windowClass.getUIContext()
      // 全屏布局（内容延伸至状态栏/导航条下）
      windowClass.setWindowLayoutFullScreen(true)
        .catch(() => {
          hilog.error(DOMAIN, TAG, 'Failed to 设置窗口全屏');
        })
      // 获取避让区域
      const statusBar = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
      const navigationArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      // 状态栏高度
      this.globalState.topRectHeight = uiContext.px2vp(statusBar.topRect.height)
      // 导航条高度
      this.globalState.bottomRectHeight = uiContext.px2vp(navigationArea.bottomRect.height)
      // 窗口尺寸
      const props = windowClass.getWindowProperties()
      this.globalState.windowWidth = uiContext.px2vp(props.windowRect.width)
      this.globalState.windowHeight = uiContext.px2vp(props.windowRect.height)
      // 初始化断点：windowSizeChange 仅在尺寸变化时回调，首屏需先取一次，否则响应式布局会按默认 XS 渲染
      this.globalState.widthBreakpoint = uiContext.getWindowWidthBreakpoint();
      this.globalState.heightBreakpoint = uiContext.getWindowHeightBreakpoint();
      // 监听避让区变化
      windowClass.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          const topRectHeight = data.area.topRect.height;
          this.globalState.topRectHeight = uiContext.px2vp(topRectHeight)
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          const bottomRectHeight = data.area.bottomRect.height;
          this.globalState.bottomRectHeight = uiContext.px2vp(bottomRectHeight)
        }
      })
      // 监听窗口尺寸变化
      windowClass.on('windowSizeChange', (data) => {
        this.globalState.windowWidth = uiContext.px2vp(data.width)
        this.globalState.windowHeight = uiContext.px2vp(data.height)
        this.globalState.widthBreakpoint = uiContext.getWindowWidthBreakpoint();
        this.globalState.heightBreakpoint = uiContext.getWindowHeightBreakpoint();
      });
      // 监听键盘高度变化
      windowClass.on('keyboardHeightChange', (data: number) => {
        this.globalState.keyboardHeight = uiContext.px2vp(data)
      })
    } catch (e) {
      hilog.error(DOMAIN, TAG, `updateWinInfo ：${e.code} ${e.message}`);
    }
  }
}