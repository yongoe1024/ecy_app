import { IBestToast } from '@ibestservices/ibest-ui-v2'
import { PreferenceManager, UserManager } from 'common'
import { SectionCard } from '../SectionCard'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN: number = 0x0000;
const TAG: string = 'HomeStorageCard';
const DEMO_NOTE_KEY: string = 'demo_note'

@ComponentV2
export struct HomeStorageCard {
  @Local noteDraft: string = 'common 能力测试。'
  @Local noteValue: string = '尚未读取'
  @Local tokenDraft: string = 'demo-token-2026'
  @Local tokenValue: string = '尚未写入'

  aboutToAppear(): void {
    this.loadStoredValues()
  }

  loadStoredValues(): void {
    try {
      this.tokenValue = UserManager.getInstance().getToken() || '尚未写入'
      this.noteValue = PreferenceManager.getStringSync(DEMO_NOTE_KEY, '点击写入一条演示数据')
    } catch (e) {
      hilog.error(DOMAIN, TAG, `loadStoredValues ：${e.code} ${e.message}`);
      this.noteValue = '读取失败'
    }
  }

  saveNote(): void {
    try {
      PreferenceManager.putSync(DEMO_NOTE_KEY, this.noteDraft)
      this.noteValue = PreferenceManager.getStringSync(DEMO_NOTE_KEY, '')
      IBestToast.show('已写入首选项')
    } catch (e) {
      hilog.error(DOMAIN, TAG, `saveNote ：${e.code} ${e.message}`);
      IBestToast.show('写入失败，请重试')
    }
  }

  clearNote(): void {
    try {
      PreferenceManager.deleteSync(DEMO_NOTE_KEY)
      this.noteValue = '已清除'
      IBestToast.show('已删除首选项')
    } catch (e) {
      hilog.error(DOMAIN, TAG, `clearNote ：${e.code} ${e.message}`);
      IBestToast.show('删除失败，请重试')
    }
  }

  saveToken(): void {
    try {
      UserManager.getInstance().setToken(this.tokenDraft)
      this.tokenValue = UserManager.getInstance().getToken() || '尚未写入'
      IBestToast.show('Token 已写入')
    } catch (e) {
      hilog.error(DOMAIN, TAG, `saveToken ：${e.code} ${e.message}`);
      IBestToast.show('写入失败，请重试')
    }
  }

  clearToken(): void {
    try {
      UserManager.getInstance().setToken('')
      this.tokenValue = '已清空'
      IBestToast.show('Token 已清空')
    } catch (e) {
      hilog.error(DOMAIN, TAG, `clearToken ：${e.code} ${e.message}`);
      IBestToast.show('清空失败，请重试')
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

    TextInput({ text: this.tokenDraft, placeholder: '写入一个演示 token' })
      .onChange((value: string) => {
        this.tokenDraft = value
      })
    Text(`Token：${this.tokenValue}`)
      .fontSize(12)
      .fontColor('#475569')
    Row({ space: 8 }) {
      Button('写入 Token').onClick(() => this.saveToken()).backgroundColor('#1D4ED8')
      Button('清空 Token').onClick(() => this.clearToken()).backgroundColor('#E2E8F0').fontColor('#0F172A')
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
