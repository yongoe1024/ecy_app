import { EnvEnum, EnvironmentManger, GlobalState } from 'common'
import { AppStorageV2 } from '@kit.ArkUI'
import { SectionCard } from '../SectionCard'

@ComponentV2
export struct HomeEnvCard {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  switchEnv(env: EnvEnum): void {
    EnvironmentManger.getInstance().setEnv(env)
  }

  @LocalBuilder
  cardContent() {
    Text(`Base URL: ${EnvironmentManger.getInstance().getBaseUrl()}`)
      .fontSize(13)
      .fontColor('#334155')
    Row({ space: 8 }) {
      Button('DEV')
        .onClick(() => this.switchEnv(EnvEnum.DEV))
        .backgroundColor('#DBEAFE')
        .fontColor('#1D4ED8')
      Button('TEST')
        .onClick(() => this.switchEnv(EnvEnum.TEST))
        .backgroundColor('#FEF3C7')
        .fontColor('#B45309')
      Button('PRD')
        .onClick(() => this.switchEnv(EnvEnum.PRD))
        .backgroundColor('#DCFCE7')
        .fontColor('#15803D')
    }
  }

  build() {
    SectionCard({
      title: '环境切换',
      content: () => {
        this.cardContent()
      }
    })
  }
}
