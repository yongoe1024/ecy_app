import { IBestToast } from '@ibestservices/ibest-ui-v2'
import { PreferenceManager, UserManager } from 'common'
import { SectionCard } from '../SectionCard'

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
    this.tokenValue = UserManager.getInstance().getToken() || '尚未写入'
    this.noteValue = String(PreferenceManager.getSync(DEMO_NOTE_KEY, '点击写入一条演示数据'))
  }

  saveNote(): void {
    PreferenceManager.putSync(DEMO_NOTE_KEY, this.noteDraft)
    this.noteValue = String(PreferenceManager.getSync(DEMO_NOTE_KEY, ''))
    IBestToast.show('已写入首选项')
  }

  clearNote(): void {
    PreferenceManager.deleteSync(DEMO_NOTE_KEY)
    this.noteValue = '已清除'
    IBestToast.show('已删除首选项')
  }

  saveToken(): void {
    UserManager.getInstance().setToken(this.tokenDraft)
    this.tokenValue = UserManager.getInstance().getToken() || '尚未写入'
    IBestToast.show('Token 已写入')
  }

  clearToken(): void {
    UserManager.getInstance().setToken('')
    this.tokenValue = '已清空'
    IBestToast.show('Token 已清空')
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
