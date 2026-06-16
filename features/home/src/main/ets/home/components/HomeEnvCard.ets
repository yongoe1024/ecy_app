import { EnvEnum, EnvironmentManager, GlobalState } from 'common'
import { AppStorageV2 } from '@kit.ArkUI'
import { IBestToast } from '@ibestservices/ibest-ui-v2'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { SectionCard } from '../SectionCard'

const DOMAIN: number = 0x0000;
const TAG: string = 'HomeEnvCard';

@ComponentV2
export struct HomeEnvCard {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  switchEnv(env: EnvEnum): void {
    // setEnv 持久化失败会抛出（写变更不静默吞错），此处兜底提示
    try {
      EnvironmentManager.getInstance().setEnv(env)
    } catch (e) {
      hilog.error(DOMAIN, TAG, `switchEnv ：${e.code} ${e.message}`);
      IBestToast.show('环境切换失败，请重试')
    }
  }

  @LocalBuilder
  cardContent() {
    Text(`Base URL: ${EnvironmentManager.getInstance().getBaseUrl()}`)
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
      desc: '覆盖 EnvironmentManager 的环境读取与切换（切换后会重启应用）。',
      content: this.cardContent
    })
  }
}
