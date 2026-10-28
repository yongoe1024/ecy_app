import { EnvironmentManager, GlobalState, PreferenceManager, RouteManager, RouteTable } from 'common';
import { AppStorageV2 } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PrivacyPage } from './PrivacyPage';
import { EnvFloatingButton } from '../components/EnvFloatingButton';

const DOMAIN = 0x0000;
const TAG = 'Index';

@Entry
@ComponentV2
struct Index {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!
  // 隐私同意状态：未同意时整屏渲染隐私页，同意后切换为 Navigation（响应式，无页面跳转）
  @Local agreed: boolean = false
  private showEnvButton: boolean = EnvironmentManager.getInstance().getBuildEnv() !== 'PROD'

  aboutToAppear(): void {
    try {
      this.agreed = PreferenceManager.hasSync('agreePrivacy')
    } catch (e) {
      this.agreed = false
      hilog.error(DOMAIN, TAG, `hasSync agreePrivacy ：${e?.message}`)
    }
  }

  private consumeDeepLink(): void {
    const params = this.globalState.wantParameters
    if (params && params.toUrl) {
      RouteManager.getInstance().pushDeepLink(String(params.toUrl))
      this.globalState.wantParameters = undefined
    }
  }

  build() {
    Stack() {
      if (!this.agreed) {
        // 隐私门：同意前不挂载 Navigation，深链自然无法绕过
        PrivacyPage({
          onAgreed: () => {
            this.agreed = true
            this.consumeDeepLink()
          }
        })
      } else {
        // Navigation 以 ecy://entry/main 为首页目的地（router_map 注册的 Main）渲染首屏；
        // 二级页（Login/Web/深链）经路由栈压在首页之上
        Navigation(RouteManager.getInstance().getStack(), { name: RouteTable.ENTRY_MAIN }) {
        }
        .mode(NavigationMode.Stack)
        .onAppear(() => {
          this.consumeDeepLink()
        })
      }
      // 屏幕最顶层的调试悬浮球：不随启动分流/路由页切换消失。
      // 须窗口尺寸就绪后再挂载：球的初始位置在 aboutToAppear 一次性计算，
      // 冷启动时 windowWidth 可能晚于页面就绪，未就绪挂载会把球定位到屏幕外且无法自行恢复
      if (this.showEnvButton && this.globalState.windowWidth > 0) {
        EnvFloatingButton()
      }
    }
    .width('100%')
    .height('100%')
  }
}
