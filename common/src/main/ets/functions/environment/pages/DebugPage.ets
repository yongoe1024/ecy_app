import { EnvironmentManager } from '../EnvironmentManager';
import { GlobalState } from '../GlobalModel';
import { RouteManager } from '../../router/RouteManager';
import { UserManager } from '../../user/UserManager';
import { TokenInfo } from '../../user/UserModel';
import { AppStorageV2 } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { envConfig } from '../EnvConfig';

const DOMAIN: number = 0x0000;
const TAG: string = 'DebugPage';

const ENV_OPTIONS: string[] = Object.keys(envConfig);

@Builder
export function DebugPageBuilder() {
  DebugPage()
}

/**
 * 调试页（ecy://common/debug，悬浮球入口，仅非 PROD 构建包可达）
 */
@ComponentV2
export struct DebugPage {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState, () => new GlobalState())!
  // 当前环境快照（页面存续期间环境变更会重启应用，无需响应式跟踪）
  private current: string = EnvironmentManager.getInstance().getEnv()
  // 登录态快照（页面存续期间无法登录/登出，无需响应式跟踪）
  @Local loggedIn: boolean = false
  @Local tokenText: string = '未登录'
  @Local userText: string = '加载中...'

  aboutToAppear(): void {
    this.refreshTokenText()
    void this.loadUserInfo(false)
  }

  /** 只读展示当前 Token（内存缓存，冷启动自偏好恢复） */
  private refreshTokenText(): void {
    const token: TokenInfo | undefined = UserManager.getInstance().getToken()
    this.loggedIn = token !== undefined
    this.tokenText = token
      ?
      `accessToken: ${token.accessToken}\nrefreshToken: ${token.refreshToken}\nexpireTime: ${token.expireTime}\nrefreshExpireTime: ${token.refreshExpireTime}`
      : '未登录'
  }

  /**
   * 加载用户信息：缓存优先；未登录显示未登录，接口失败显示获取失败（占位域名下属预期）。
   */
  private async loadUserInfo(force: boolean): Promise<void> {
    try {
      if (force) {
        await UserManager.getInstance().refreshUserInfo()
      }
      const info = await UserManager.getInstance().getUserInfo()
      this.userText = info
        ? `id: ${info.id ?? '-'}\nname: ${info.name ?? '-'}\nphone: ${info.phone ?? '-'}`
        : '未登录'
    } catch (e) {
      hilog.warn(DOMAIN, TAG, `loadUserInfo ：${e?.message}`);
      this.userText = '获取失败（未登录或接口不可用）'
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
      Text('debug')
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

  @Builder
  userTokenCard() {
    Column({ space: 10 }) {
      Text('用户信息与 Token')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#172033')
        .width('100%')

      Text(`登录状态：${this.loggedIn ? '已登录' : '未登录'}`)
        .fontSize(12)
        .fontColor(this.loggedIn ? '#2b6aff' : '#999999')
        .width('100%')

      Text('Token')
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
      // copyOption：调试时可直接长按复制 token 值
      Text(this.tokenText)
        .fontSize(12)
        .fontColor('#475569')
        .width('100%')
        .copyOption(CopyOptions.InApp)

      Text('用户信息')
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
      Text(this.userText)
        .fontSize(12)
        .fontColor('#475569')
        .width('100%')
        .copyOption(CopyOptions.InApp)

      Button('刷新用户信息')
        .fontSize(13)
        .backgroundColor('#F0F5FF')
        .fontColor('#2b6aff')
        .borderRadius(10)
        .width('100%')
        .onClick(() => {
          void this.loadUserInfo(true)
        })
    }
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  build() {
    NavDestination() {
      // 顶部避让：最外层统一 padding（状态栏高度取自 GlobalState.topRectHeight）
      Column() {
        this.navBar()
        Scroll() {
          Column({ space: 12 }) {
            Text('点击目标环境将保存设置并自动重启应用')
              .fontSize(12)
              .fontColor('#999999')
              .width('100%')
              .padding({ left: 4, right: 4 })
            ForEach(ENV_OPTIONS, (env: string) => {
              this.envItem(env)
            })
            this.userTokenCard()
          }
          .padding(16)
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.globalState.topRectHeight })
      .backgroundColor('#F7F9FC')
    }
    .hideTitleBar(true)
  }
}
