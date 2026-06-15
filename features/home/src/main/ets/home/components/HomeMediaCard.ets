import { MediaManager, MediaState, PlayMode } from 'common'
import { SectionCard } from '../SectionCard'

const DEMO_AUDIO: string = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'

@ComponentV2
export struct HomeMediaCard {
  @Local mediaSummary: string = '等待初始化'
  @Local mediaReady: boolean = false
  mediaManager?: MediaManager

  async aboutToAppear(): Promise<void> {
    try {
      this.mediaManager = await MediaManager.create(getContext(this), {
        mediaList: [DEMO_AUDIO],
        playMode: PlayMode.SINGLE,
        onChange: (state: MediaState) => {
          this.mediaReady = true
          this.mediaSummary =
            `索引 ${state.index} | ${this.formatMs(state.time)} / ${this.formatMs(state.duration)} | ${state.isPlay ?
              '播放中' : '暂停'}`
        }
      })
      this.mediaReady = true
      this.mediaSummary = '播放器已就绪，可直接播放在线音频'
    } catch (e) {
      this.mediaReady = false
      this.mediaSummary = '播放器初始化失败'
    }
  }

  aboutToDisappear(): void {
    void this.mediaManager?.clear()
  }

  formatMs(value: number): string {
    const safeValue = value > 0 ? Math.floor(value / 1000) : 0
    const minute = Math.floor(safeValue / 60).toString().padStart(2, '0')
    const second = (safeValue % 60).toString().padStart(2, '0')
    return `${minute}:${second}`
  }

  @LocalBuilder
  cardContent() {
    Text(this.mediaSummary)
      .fontSize(12)
      .lineHeight(18)
      .fontColor('#475569')
    Text(this.mediaReady ? '已挂载在线音频' : '尚未就绪')
      .fontSize(12)
      .fontColor('#64748B')
    Row({ space: 8 }) {
      Button('选择音乐').onClick(async () => {
        await this.mediaManager?.setAndPrepare(0)
        await this.mediaManager?.play()
      }).backgroundColor('#111827')
      Button('暂停').onClick(() => {
        this.mediaManager?.pause()
      }).backgroundColor('#F59E0B')
      Button('播放').onClick(() => {
        this.mediaManager?.play()
      }).backgroundColor('#2563EB')
    }
  }

  build() {
    SectionCard({
      title: '媒体播放',
      desc: '覆盖 MediaManager 的创建、播放、暂停与状态回调。',
      content: this.cardContent
    })
  }
}
