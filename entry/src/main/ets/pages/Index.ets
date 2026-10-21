import { GlobalState, PreferenceManager, RouteManager, RouteTable } from 'common';
import { AppStorageV2 } from '@kit.ArkUI';
import { PrivacyPage } from './PrivacyPage';

@Entry
@ComponentV2
struct Index {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!
  // 隐私同意状态：未同意时整屏渲染隐私页，同意后切换为 Navigation（响应式，无页面跳转）
  @Local agreed: boolean = false

  aboutToAppear(): void {
    try {
      this.agreed = PreferenceManager.hasSync('agreePrivacy')
    } catch {
      this.agreed = false
    }
  }

  private consumeDeepLink(): void {
    if (RouteManager.getInstance().consumeWantDeepLink(this.globalState.wantParameters)) {
      // 消费后清空，避免重复跳转
      this.globalState.wantParameters = undefined
    }
  }

  build() {
    if (!this.agreed) {
      // 隐私门：同意前不挂载 Navigation，深链自然无法绕过
      PrivacyPage({ onAgreed: () => {
        this.agreed = true
        this.consumeDeepLink()
      } })
    } else {
      // Navigation 内容区即首屏（MainTabs），引擎直接渲染，三端一致；
      // 二级页（Login/Web/深链）经路由栈压在内容区之上
      Navigation(RouteManager.getInstance().getStack(), { name: RouteTable.ENTRY_MAIN }) {
      }
      .mode(NavigationMode.Stack)
      .onAppear(() => {
        this.consumeDeepLink()
      })
    }
  }
}
