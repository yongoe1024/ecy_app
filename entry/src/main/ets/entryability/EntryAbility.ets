import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, window } from '@kit.ArkUI';
import { IBestInit } from '@ibestservices/ibest-ui-v2/Index';
import { GlobalState, PreferenceManager, RouteManager, } from 'common';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility'

export default class EntryAbility extends UIAbility {
  globalState = AppStorageV2.connect(GlobalState)!;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.globalState.uiAbilityContext = this.context
    this.globalState.wantParameters = want.parameters
    if (want.parameters && want.parameters.toUrl) {
      RouteManager.getInstance().push({ url: want.parameters.toUrl + '' })
    }
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.globalState.wantParameters = want.parameters
    if (want.parameters && want.parameters.toUrl) {
      RouteManager.getInstance().push({ url: want.parameters.toUrl + '' })
    }
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onNewWant');
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
    this.globalState.windowStage = undefined;
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
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
        } else if (data.type == window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
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
        this.globalState.keyboardHeight = px2vp(data)
      })
    } catch (e) {
      hilog.error(DOMAIN, TAG, `updateWinInfo ：${e.code} ${e.message}`);

    }
  }
}
