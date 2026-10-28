import { GlobalState, RouteManager, Toast, UserManager } from 'common';
import { AppStorageV2 } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'LoginPage';

interface LoginPageParams {
  targetPage?: string
  targetParams?: Record<string, ESObject>
}

interface LoginSuccessResult {
  loginSuccess: boolean
  targetPage: string
  targetParams?: Record<string, ESObject>
}

@Builder
export function LoginPageBuilder() {
  LoginPage()
}

/**
 * 登录演示页：覆盖 UserManager.login 调用与登录后 popResult 回传目标页。
 * 注：需配合真实后端 login 接口，未联通后端时会走失败提示。
 */
@ComponentV2
export struct LoginPage {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!
  @Local phone: string = ''
  @Local code: string = ''
  @Local loading: boolean = false
  @Local targetPage: string = ''
  targetParams?: Record<string, ESObject>

  async doLogin(): Promise<void> {
    if (!this.phone || !this.code) {
      Toast.show('请输入手机号与验证码')
      return
    }
    this.loading = true
    try {
      await UserManager.getInstance().login(this.phone, this.code)
      Toast.show('登录成功')
      if (this.targetPage) {
        let result: LoginSuccessResult = {
          loginSuccess: true,
          targetPage: this.targetPage
        }
        if (this.targetParams) {
          result.targetParams = this.targetParams
        }
        RouteManager.getInstance().popResult(result)
      } else {
        RouteManager.getInstance().pop()
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `login ：${e?.message}`);
      Toast.show('登录失败，请检查网络或账号')
    } finally {
      this.loading = false
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
      Text('登录')
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
      // 占位平衡左侧返回按钮宽度，保证标题居中
      Text('').width(44)
    }
    .height(48)
    .width('100%')
  }

  build() {
    NavDestination() {
      Column() {
        this.navBar()
        Column({ space: 16 }) {
          TextInput({ text: this.phone, placeholder: '请输入手机号' })
            .type(InputType.PhoneNumber)
            .onChange((value: string) => {
              this.phone = value
            })
          TextInput({ text: this.code, placeholder: '请输入验证码' })
            .type(InputType.Number)
            .onChange((value: string) => {
              this.code = value
            })
          Button(this.loading ? '登录中...' : '登录')
            .width('100%')
            .height(44)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor('#2563EB')
            .borderRadius(22)
            .enabled(!this.loading)
            .onClick(() => {
              this.doLogin()
            })
        }
        .padding(20)
        .width('100%')
      }
      .width('100%')
      .height('100%')
      // 顶部避让只在本层做一次（状态栏高度取自 GlobalState.topRectHeight），navBar 不再叠加
      .padding({ top: this.globalState.topRectHeight })
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      const params = context.pathInfo.param as LoginPageParams
      const targetPage = params?.targetPage
      if (targetPage) {
        this.targetPage = targetPage
      }
      this.targetParams = params?.targetParams
    })
  }
}
