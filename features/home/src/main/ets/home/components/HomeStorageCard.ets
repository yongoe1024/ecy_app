import { PreferenceManager, Toast } from 'common';
import { SectionCard } from '../SectionCard';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'HomeStorageCard';
const DEMO_NOTE_KEY: string = 'demo_note'

@ComponentV2
export struct HomeStorageCard {
  @Local noteDraft: string = 'common 能力测试。'
  @Local noteValue: string = '尚未读取'

  aboutToAppear(): void {
    this.loadStoredValues()
  }

  loadStoredValues(): void {
    try {
      this.noteValue = PreferenceManager.getSync(DEMO_NOTE_KEY, '点击写入一条演示数据') as string
    } catch (e) {
      hilog.error(DOMAIN, TAG, `loadStoredValues ：${e?.message}`);
      this.noteValue = '读取失败'
    }
  }

  saveNote(): void {
    try {
      PreferenceManager.putSync(DEMO_NOTE_KEY, this.noteDraft)
      this.noteValue = PreferenceManager.getSync(DEMO_NOTE_KEY, '') as string
      Toast.show('已写入首选项')
    } catch (e) {
      hilog.error(DOMAIN, TAG, `saveNote ：${e?.message}`);
      Toast.show('写入失败，请重试')
    }
  }

  clearNote(): void {
    try {
      PreferenceManager.deleteSync(DEMO_NOTE_KEY)
      this.noteValue = '已清除'
      Toast.show('已删除首选项')
    } catch (e) {
      hilog.error(DOMAIN, TAG, `clearNote ：${e?.message}`);
      Toast.show('删除失败，请重试')
    }
  }

  @LocalBuilder
  cardContent() {
    TextInput({ text: this.noteDraft, placeholder: '写一条调试笔记' })
      .onChange((value: string) => {
        this.noteDraft = value
      })
    Text(`当前笔记：${this.noteValue}`)
      .fontSize(12)
      .fontColor('#475569')
    Row({ space: 8 }) {
      Button('保存笔记').onClick(() => this.saveNote()).backgroundColor('#0F172A')
      Button('清空笔记').onClick(() => this.clearNote()).backgroundColor('#CBD5E1').fontColor('#0F172A')
    }
  }

  build() {
    SectionCard({
      title: '首选项与 Token',
      desc: '覆盖 PreferenceManager 与 UserManager 的本地持久化能力。',
      content: this.cardContent
    })
  }
}
