import { AppStorageV2 } from '@kit.ArkUI'
import { GlobalState } from 'common'

@ComponentV2
export struct Mine {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!
  @Local userName: string = '访客用户'
  @Local loginTip: string = '登录后可同步订单、地址与会员权益'

  @Builder
  actionButton(text: string) {
    Button(text)
      .width('100%')
      .height(44)
      .borderRadius(14)
      .backgroundColor('#1D4ED8')
      .fontColor('#FFFFFF')
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
  }

  @Builder
  statItem(value: string, label: string) {
    Column({ space: 6 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')

      Text(label)
        .fontSize(12)
        .fontColor('#6B7280')
    }
    .layoutWeight(1)
  }

  @Builder
  featureItem(icon: string, title: string, desc: string) {
    Row({ space: 14 }) {
      Text(icon)
        .fontSize(18)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(12)
        .backgroundColor('#F3F6FB')

      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#172033')

        Text(desc)
          .fontSize(12)
          .fontColor('#7B8794')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({
      top: 14,
      bottom: 14,
      left: 14,
      right: 14
    })
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
  }

  @Builder
  sectionTitle(title: string, desc: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#172033')

      Text(desc)
        .fontSize(12)
        .fontColor('#7B8794')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 18 }) {
          Stack({ alignContent: Alignment.TopStart }) {
            Column()
              .width('100%')
              .height(180)
              .linearGradient({
                angle: 135,
                colors: [['#0F172A', 0], ['#1D4ED8', 0.55], ['#60A5FA', 1]]
              })
              .borderRadius(28)

            Column({ space: 18 }) {
              Row({ space: 14 }) {
                Image($r('app.media.avatar'))
                  .width(72)
                  .height(72)
                  .borderRadius(36)
                  .backgroundColor('#FFFFFF')

                Column({ space: 6 }) {
                  Text(this.userName)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')

                  Text(this.loginTip)
                    .fontSize(13)
                    .lineHeight(20)
                    .fontColor('#DCE7FF')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .alignItems(VerticalAlign.Center)
              .width('100%')

              Row({ space: 10 }) {
                this.actionButton('请登录')
              }
              .width('100%')
            }
            .padding(20)
            .width('100%')
          }

          Row() {
            this.statItem('12', '收藏')
            this.statItem('3', '优惠券')
            this.statItem('8', '足迹')
            this.statItem('99+', '积分')
          }
          .width('100%')
          .padding({ top: 18, bottom: 18 })
          .backgroundColor('#FFFFFF')
          .borderRadius(24)

          Column({ space: 12 }) {
            this.sectionTitle('我的服务', '以下入口仅做页面展示，暂不接真实业务逻辑')

            this.featureItem('📦', '我的订单', '查看待付款、待发货、售后服务')
            this.featureItem('📍', '收货地址', '管理常用收货地址与联系人')
            this.featureItem('💬', '消息通知', '活动提醒、订单动态与系统消息')
            this.featureItem('🎫', '优惠券', '查看可用优惠券与历史使用记录')
          }
          .width('100%')

          Column({ space: 12 }) {
            this.sectionTitle('更多设置', '账号与应用相关设置入口')

            this.featureItem('⚙', '账号设置', '修改资料、隐私与安全设置')
            this.featureItem('🛡', '隐私中心', '查看隐私说明与授权状态')
            this.featureItem('📞', '联系客服', '问题反馈与人工支持入口')
            this.featureItem('⭐', '关于我们', '版本信息、用户协议与帮助中心')
          }
          .width('100%')
          .padding({ bottom: 20 })
        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 16,
          bottom: 20
        })
      }
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.globalState.topRectHeight })
    .linearGradient({
      angle: 180,
      colors: [['#F8FBFF', 0], ['#EEF4FF', 1]]
    })
  }
}
