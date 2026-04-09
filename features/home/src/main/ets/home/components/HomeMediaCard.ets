import { MediaManager, MediaState } from 'common'
import { SectionCard } from '../SectionCard'

const DEMO_AUDIO: string = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'

@ComponentV2
export struct HomeMediaCard {
  @Local mediaSummary: string = '等待初始化'
  @Local mediaReady: boolean = false
  mediaManager?: MediaManager

  aboutToAppear(): void {
    void this.prepareMedia()
  }

  aboutToDisappear(): void {
    if (this.mediaManager) {
      void this.mediaManager.release()
      this.mediaManager = undefined
    }
  }

  async prepareMedia(): Promise<void> {
    try {
      this.mediaManager = await MediaManager.create(getContext(this), {
        mediaList: [DEMO_AUDIO],
        playMode: 'SINGLE',
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

  formatMs(value: number): string {
    const safeValue = value > 0 ? Math.floor(value / 1000) : 0
    const minute = Math.floor(safeValue / 60).toString().padStart(2, '0')
    const second = (safeValue % 60).toString().padStart(2, '0')
    return `${minute}:${second}`
  }

  async playMedia(): Promise<void> {
    if (!this.mediaManager) {
      await this.prepareMedia()
    }
    await this.mediaManager?.setAndPlay(0)
  }

  async pauseMedia(): Promise<void> {
    await this.mediaManager?.pause()
  }

  async resumeMedia(): Promise<void> {
    await this.mediaManager?.play()
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
      Button('播放').onClick(() => {
        void this.playMedia()
      }).backgroundColor('#111827')
      Button('暂停').onClick(() => {
        void this.pauseMedia()
      }).backgroundColor('#F59E0B')
      Button('继续').onClick(() => {
        void this.resumeMedia()
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
