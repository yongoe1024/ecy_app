import { EnvironmentManager, GlobalState, RouteManager } from '../..';
import { AppStorageV2 } from '@kit.ArkUI';
import { envConfig } from '../EnvConfig';

const DOMAIN: number = 0x0000;
const TAG: string = 'DebugPage';

const ENV_OPTIONS: string[] = Object.keys(envConfig);

@Builder
export function DebugPageBuilder() {
  DebugPage()
}

/**
 * 调试页（ecy://common/debug，悬浮球入口，仅非 PRD 环境可达）：当前提供环境切换。
 * 点击目标环境即 setEnv：EnvironmentManager 持久化后自动重启应用生效。
 * 避让约定：顶部避让只在本页最外层 Column 做一次，navBar 不再叠加。
 */
@ComponentV2
export struct DebugPage {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState, () => new GlobalState())!
  // 当前环境快照（页面存续期间环境变更会重启应用，无需响应式跟踪）
  private current: string = EnvironmentManager.getInstance().getEnv()

  @Builder
  navBar() {
    Row() {
      Text('‹')
        .fontSize(30)
        .width(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          RouteManager.getInstance().pop()
        })
      Text('环境切换')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .layoutWeight(1)
      // 占位平衡左侧返回按钮宽度，保证标题居中
      Text('').width(44)
    }
    .height(48)
    .width('100%')
  }

  @Builder
  envItem(env: string) {
    Row({ space: 10 }) {
      Text(env)
        .fontSize(15)
        .fontColor(this.current === env ? '#2b6aff' : '#172033')
        .fontWeight(this.current === env ? FontWeight.Medium : FontWeight.Normal)
        .layoutWeight(1)
      if (this.current === env) {
        Text('当前')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .backgroundColor('#2b6aff')
          .borderRadius(10)
          .padding({
            left: 8,
            right: 8,
            top: 3,
            bottom: 3
          })
      }
    }
    .height(54)
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.current === env ? '#F0F5FF' : '#FFFFFF')
    .borderRadius(12)
    .border({
      width: 1,
      color: this.current === env ? '#2b6aff' : Color.Transparent
    })
    .onClick(() => {
      EnvironmentManager.getInstance().setEnv(env)
    })
  }

  build() {
    NavDestination() {
      // 顶部避让：最外层统一 padding（状态栏高度取自 GlobalState.topRectHeight）
      Column() {
        this.navBar()
        Column({ space: 12 }) {
          Text('点击目标环境将保存设置并自动重启应用')
            .fontSize(12)
            .fontColor('#999999')
            .width('100%')
            .padding({ left: 4, right: 4 })
          ForEach(ENV_OPTIONS, (env: string) => {
            this.envItem(env)
          })
        }
        .padding(16)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.globalState.topRectHeight })
      .backgroundColor('#F7F9FC')
    }
    .hideTitleBar(true)
  }
}
