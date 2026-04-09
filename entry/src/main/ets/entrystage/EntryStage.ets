import { AbilityStage } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalState } from 'common';

export default class MyAbilityStage extends AbilityStage {
  onCreate(): void {
    let abilityStageContext = this.context;
    const stage = AppStorageV2.connect(GlobalState, () => new GlobalState())!;
    stage.abilityStageContext = abilityStageContext
  }
}