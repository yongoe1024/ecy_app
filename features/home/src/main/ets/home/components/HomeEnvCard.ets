import { EnvironmentManager, GlobalState } from 'common';
import { AppStorageV2 } from '@kit.ArkUI';
import { SectionCard } from '../SectionCard';

@ComponentV2
export struct HomeEnvCard {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  @LocalBuilder
  cardContent() {
    Text(`Base URL: ${EnvironmentManager.getInstance().getEnvConfig().baseUrl}`)
      .fontSize(13)
      .fontColor('#334155')
    Row({ space: 8 }) {
      Button('DEV')
        .onClick(() => EnvironmentManager.getInstance().setEnv('DEV'))
        .backgroundColor('#DBEAFE')
        .fontColor('#1D4ED8')
      Button('TEST')
        .onClick(() => EnvironmentManager.getInstance().setEnv('TEST'))
        .backgroundColor('#FEF3C7')
        .fontColor('#B45309')
      Button('PROD')
        .onClick(() => EnvironmentManager.getInstance().setEnv('PROD'))
        .backgroundColor('#DCFCE7')
        .fontColor('#15803D')
    }
  }

  build() {
    SectionCard({
      title: '环境切换',
      desc: '覆盖 EnvironmentManager 的环境读取与切换（切换后会重启应用）。',
      content: this.cardContent
    })
  }
}
