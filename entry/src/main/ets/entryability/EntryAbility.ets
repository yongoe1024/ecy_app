import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, window } from '@kit.ArkUI';
import { IBestInit } from '@ibestservices/ibest-ui-v2/Index';
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
    this.globalState.wantParameters = want.parameters
    // 深链推迟到内容加载且隐私已同意后处理，避免绕过隐私门 / 早于 Navigation 挂载
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
   * 冷启动由 Index 页面在导航挂载后消费，见 Index.aboutToAppear。
   */
  private handleDeepLink(): void {
    try {
      if (!PreferenceManager.hasSync('agreePrivacy')) {
        return
      }
    } catch (e) {
      return
    }
    const params = this.globalState.wantParameters
    if (params && params.toUrl) {
      // 仅允许应用内部 scheme 深链，避免外部诱导打开任意网页
      RouteManager.getInstance().pushDeepLink(String(params.toUrl))
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
    let page = ''
    try {
      if (PreferenceManager.hasSync('agreePrivacy')) {
        page = 'pages/Index'
      } else {
        page = 'pages/PrivacyPage'
      }
    } catch (e) {
      page = 'pages/PrivacyPage'
      hilog.error(DOMAIN, TAG, '获取agreePrivacy失败');
    }
    windowStage.loadContent(page, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'windowStage Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      // 初始化UI组件库
      IBestInit(windowStage, this.context)
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

  /**
   * 存储窗口高度
   */
  updateWinInfo(windowClass: window.Window) {
    try {
      this.mainWindow = windowClass
      let uiContext = windowClass.getUIContext()
      // 设置窗口全屏
      windowClass.setWindowLayoutFullScreen(true)
        .catch(() => {
          hilog.error(DOMAIN, TAG, 'Failed to 设置窗口全屏');
        })
      // 获取避让区域、窗口高度
      const statusBar = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM)
      const navigationArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      // 获取状态栏高度
      this.globalState.topRectHeight = uiContext.px2vp(statusBar.topRect.height)
      // 获取导航条高度
      this.globalState.bottomRectHeight = uiContext.px2vp(navigationArea.bottomRect.height)
      // 获取窗口高度
      const props = windowClass.getWindowProperties()
      this.globalState.windowWidth = uiContext.px2vp(props.windowRect.width)
      this.globalState.windowHeight = uiContext.px2vp(props.windowRect.height)
      // 注册监听避让区
      windowClass.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          const topRectHeight = data.area.topRect.height;
          this.globalState.topRectHeight = uiContext.px2vp(topRectHeight)
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          const bottomRectHeight = data.area.bottomRect.height;
          this.globalState.bottomRectHeight = uiContext.px2vp(bottomRectHeight)
        }
      })
      // 监听窗口高度
      windowClass.on('windowSizeChange', (data) => {
        this.globalState.windowWidth = uiContext.px2vp(data.width)
        this.globalState.windowHeight = uiContext.px2vp(data.height)
        this.globalState.widthBreakpoint = uiContext.getWindowWidthBreakpoint();
        this.globalState.heightBreakpoint = uiContext.getWindowHeightBreakpoint();
      });
      // 监听键盘高度
      windowClass.on('keyboardHeightChange', (data: number) => {
        this.globalState.keyboardHeight = uiContext.px2vp(data)
      })
    } catch (e) {
      hilog.error(DOMAIN, TAG, `updateWinInfo ：${e.code} ${e.message}`);

    }
  }
}
