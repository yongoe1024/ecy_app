import { IBestButton } from "@ibestservices/ibest-ui-v2"
import { GlobalState, PreferenceManager } from "common"
import { AppStorageV2, router } from "@kit.ArkUI"
import { common } from "@kit.AbilityKit"
import { hilog } from "@kit.PerformanceAnalysisKit";

const DOMAIN = 0x0000;
const TAG = 'PrivacyPage'

@Entry
@ComponentV2
struct PrivacyPage {
  @Local state: GlobalState = AppStorageV2.connect(GlobalState)!

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column()
        .width('100%')
        .height(320)
        .linearGradient({
          angle: 180,
          colors: [['#F4F8FF', 0], ['#E6F0FF', 0.45], ['#FFF7ED', 1]]
        })

      Column()
        .width(180)
        .height(180)
        .borderRadius(90)
        .backgroundColor('#33FFFFFF')
        .position({ top: 72 + this.state.topRectHeight, right: -48 })

      Column()
        .width(120)
        .height(120)
        .borderRadius(60)
        .backgroundColor('#22FFFFFF')
        .position({ top: 196 + this.state.topRectHeight, left: -32 })

      Scroll() {
        Column({ space: 20 }) {
          Column({ space: 14 }) {
            Row() {
              Stack({ alignContent: Alignment.Center }) {
                Column()
                  .width(52)
                  .height(52)
                  .borderRadius(26)
                  .backgroundColor('#FFFFFF')
                  .shadow({
                    radius: 16,
                    color: '#14325D1A',
                    offsetX: 0,
                    offsetY: 10
                  })

                Text('隐')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1D4ED8')
              }

              Blank()

              Text('隐私保护说明')
                .fontSize(12)
                .fontColor('#5B6B83')
                .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                .backgroundColor('#F6F9FF')
                .borderRadius(999)
            }
            .width('100%')

            Text('我们重视你的个人信息与使用体验')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#172033')
              .lineHeight(38)
              .width('100%')

            Text('在继续使用 ECY-APP 前，请先了解服务协议与隐私政策。我们会按照法律法规要求，尽力保障你的个人信息安全、透明、可控。')
              .fontSize(15)
              .fontColor('#526077')
              .lineHeight(24)
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 4, right: 4, top: 8 })

          Column({ space: 16 }) {
            Column({ space: 10 }) {
              Row({ space: 10 }) {
                Column()
                  .width(10)
                  .height(10)
                  .borderRadius(5)
                  .backgroundColor('#1D4ED8')

                Text('在你同意后，我们将为你提供完整服务')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1F2937')
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)

              Text('不同意隐私政策将无法继续进入应用。你可以先查看相关协议内容，再决定是否继续。')
                .fontSize(14)
                .fontColor('#667085')
                .lineHeight(22)
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(18)
            .width('100%')
            .backgroundColor('#F8FAFF')
            .borderRadius(20)

            Column({ space: 12 }) {
              Text('请阅读以下内容')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1F2937')
                .width('100%')

              Text() {
                Span('继续使用即表示你已阅读并同意 ')
                  .fontSize(14)
                  .fontColor('#4B5563')

                Span('《ECY-APP服务协议》')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#2563EB')
                  .decoration({ type: TextDecorationType.Underline, color: '#2563EB' })
                  .onClick(() => {
                    // todo 协议跳转占位
                  })

                Span(' 与 ')
                  .fontSize(14)
                  .fontColor('#4B5563')

                Span('《隐私政策》')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#2563EB')
                  .decoration({ type: TextDecorationType.Underline, color: '#2563EB' })
                  .onClick(() => {
                    // todo 协议跳转占位
                  })

                Span('。')
                  .fontSize(14)
                  .fontColor('#4B5563')
              }
              .fontSize(14)
              .lineHeight(24)
              .textAlign(TextAlign.Start)
              .width('100%')

              Text('我们仅在必要范围内收集和使用信息，并持续优化你的隐私与数据安全体验。')
                .fontSize(13)
                .fontColor('#7A8699')
                .lineHeight(22)
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .padding(20)
            .width('100%')
            .backgroundColor('#FFFFFF')
            .borderRadius(24)
            .shadow({
              radius: 24,
              color: '#102A4312',
              offsetX: 0,
              offsetY: 12
            })
          }
          .width('100%')

          Column({ space: 10 }) {
            IBestButton({
              text: '同意并继续',
              type: 'primary',
              btnWidth: '100%',
              onBtnClick: () => {
                try {
                  PreferenceManager.putSync('agreePrivacy', true)
                  router.replace({ url: 'pages/Index' })
                } catch (e) {
                  hilog.error(DOMAIN, TAG, `onBtnClick ：${e.code} ${e.message}`);
                }
              }
            })
            IBestButton({
              btnWidth: '100%',
              text: '暂不同意',
              onBtnClick: () => {
                const context = this.getUIContext().getHostContext() as common.UIAbilityContext
                context.terminateSelf().catch(() => {
                  hilog.error(DOMAIN, TAG, 'terminateSelf失败');
                })
              }
            })
          }
          .margin({ top: 4, bottom: 28 })
          .width('100%')
        }
        .padding({
          left: 20,
          right: 20,
          top: 24 + this.state.topRectHeight,
          bottom: 12
        })
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FDFEFE')
  }
}
