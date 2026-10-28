import { EnvironmentManager } from '../EnvironmentManager';
import { GlobalState } from '../GlobalModel';
import { RouteManager } from '../../router/RouteManager';
import { UserManager } from '../../user/UserManager';
import { TokenInfo, UserInfo } from '../../user/UserModel';
import { Toast } from '../../../utils/Toast';
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
  // 会话快照（页面存续期间无法登录/登出，无需响应式跟踪）
  @Local tokenInfo?: TokenInfo
  @Local userInfo?: UserInfo
  @Local loading: boolean = false

  aboutToAppear(): void {
    this.tokenInfo = UserManager.getInstance().getToken()
    void this.loadUserInfo(false)
  }

  /**
   * 加载用户信息：缓存优先，强刷走 refreshUserInfo；未登录不发请求。
   * 失败 Toast 提示（占位域名下属预期）。
   */
  private async loadUserInfo(force: boolean): Promise<void> {
    if (!this.tokenInfo) {
      return
    }
    this.loading = true
    try {
      if (force) {
        await UserManager.getInstance().refreshUserInfo()
      }
      this.userInfo = await UserManager.getInstance().getUserInfo()
    } catch (e) {
      hilog.warn(DOMAIN, TAG, `loadUserInfo ：${e?.message}`);
      Toast.show('用户信息获取失败')
    } finally {
      this.loading = false
    }
  }

  /** 会话板短值行：左侧定宽标签 + 右侧自适应值 */
  @Builder
  infoRow(label: string, value?: string) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(13)
        .fontColor('#8F95A7')
        .width(96)
      Text(value ? value : '-')
        .fontSize(13)
        .fontColor('#172033')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 9, bottom: 9 })
  }

  /** 会话板长值行（token 类）：值独占一行换行展示，长按可复制 */
  @Builder
  tokenRow(label: string, value?: string) {
    Column({ space: 6 }) {
      Text(label)
        .fontSize(13)
        .fontColor('#8F95A7')
        .width('100%')
      Text(value ? value : '-')
        .fontSize(12)
        .fontColor('#172033')
        .copyOption(CopyOptions.InApp)
        .width('100%')
    }
    .width('100%')
    .padding({ top: 9, bottom: 9 })
    .border({ width: { bottom: 0.5 }, color: '#F0F1F5' })
  }


  /** 会话与 token 展示板（调试用：核对登录态/身份/令牌，不对外发布） */
  @Builder
  sessionBoard() {
    Column({ space: 2 }) {
      Text('用户信息（会话）')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#172033')
        .width('100%')
        .padding({ bottom: 6 })

      this.infoRow('登录状态', this.tokenInfo ? '已登录' : '未登录')
      this.infoRow('userId', this.userInfo?.id)
      this.infoRow('手机号', this.userInfo?.phone)
      this.infoRow('昵称', this.userInfo?.name)
      this.infoRow('expireTime', `${this.tokenInfo?.expireTime ?? ''}`)
      this.infoRow('refreshExpireTime', `${this.tokenInfo?.refreshExpireTime ?? ''}`)
      this.tokenRow('头像 avatar', this.userInfo?.avatar)
      this.tokenRow('accessToken', this.tokenInfo?.accessToken)
      this.tokenRow('refreshToken', this.tokenInfo?.refreshToken)

      Button(this.loading ? '刷新中...' : '刷新用户信息')
        .fontSize(13)
        .backgroundColor('#F0F5FF')
        .fontColor('#2b6aff')
        .borderRadius(10)
        .width('100%')
        .margin({ top: 10 })
        .enabled(!this.loading)
        .onClick(() => {
          void this.loadUserInfo(true)
        })
    }
    .padding(16)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
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
            this.sessionBoard()
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
