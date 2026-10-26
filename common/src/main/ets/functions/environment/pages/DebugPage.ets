import { EnvEnum, EnvironmentManager, GlobalState, RouteManager } from '../..';
import { Toast } from '../../../utils';
import { AppStorageV2 } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'DebugPage';

/** 环境选项（顺序即页面展示顺序） */
const ENV_OPTIONS: EnvEnum[] = [EnvEnum.DEV, EnvEnum.TEST, EnvEnum.PRD];

/** 环境显示名 */
function envLabel(env: EnvEnum): string {
  switch (env) {
    case EnvEnum.DEV:
      return '开发环境 DEV'
    case EnvEnum.TEST:
      return '测试环境 TEST'
    case EnvEnum.PRD:
      return '正式环境 PRD'
    default:
      return env
  }
}

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
  private current: EnvEnum = EnvironmentManager.getInstance().getEnv()

  private select(env: EnvEnum): void {
    if (env === this.current) {
      Toast.show('已是当前环境')
      return
    }
    try {
      EnvironmentManager.getInstance().setEnv(env)
      // setEnv 成功即重启；走到这里说明重启失败（已落盘），提示手动重启
      Toast.show('环境已保存，重启应用后生效')
    } catch (e) {
      hilog.error(DOMAIN, TAG, `setEnv ：${e?.code} ${e?.message}`);
      Toast.show('需手动重启')
    }
  }

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
  envItem(env: EnvEnum) {
    Row({ space: 10 }) {
      Text(envLabel(env))
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
      this.select(env)
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
          ForEach(ENV_OPTIONS, (env: EnvEnum) => {
            this.envItem(env)
          }, (env: EnvEnum): string => env)
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
