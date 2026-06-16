import { IBestButton, IBestNavBar, IBestToast } from '@ibestservices/ibest-ui-v2';
import { RouteManager, UserManager } from 'common';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'LoginPage';

@Builder
export function LoginPageBuilder() {
  LoginPage()
}

/**
 * 登录演示页：覆盖 UserManager.login 的调用与登录态回调。
 * 注：需配合真实后端 login 接口，未联通后端时会走失败提示。
 */
@ComponentV2
export struct LoginPage {
  @Local phone: string = ''
  @Local code: string = ''
  @Local loading: boolean = false

  async doLogin(): Promise<void> {
    if (!this.phone || !this.code) {
      IBestToast.show('请输入手机号与验证码')
      return
    }
    this.loading = true
    try {
      await UserManager.getInstance().login(this.phone, this.code)
      IBestToast.show('登录成功')
      RouteManager.getInstance().pop()
    } catch (e) {
      hilog.error(DOMAIN, TAG, `login ：${e?.code} ${e?.message}`);
      IBestToast.show('登录失败，请检查网络或账号')
    } finally {
      this.loading = false
    }
  }

  build() {
    NavDestination() {
      IBestNavBar({
        title: '登录',
        isShowStatusBar: true,
        onLeftClick: () => {
          RouteManager.getInstance().pop()
        }
      })
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
        IBestButton({
          text: '登录',
          type: 'primary',
          btnWidth: '100%',
          loading: this.loading,
          onBtnClick: () => {
            this.doLogin()
          }
        })
      }
      .padding(20)
      .width('100%')
    }
    .hideTitleBar(true)
  }
}
