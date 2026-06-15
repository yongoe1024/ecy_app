import { MediaManager, MediaState, PlayMode, TimeHelper } from 'common'
import { IBestToast } from '@ibestservices/ibest-ui-v2'
import { SectionCard } from '../SectionCard'

const DEMO_AUDIO: string = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'

@ComponentV2
export struct HomeMediaCard {
  @Local mediaSummary: string = '等待初始化'
  @Local mediaReady: boolean = false
  mediaManager?: MediaManager
  // 组件是否已销毁，用于拦截异步创建/回调对已销毁组件的写入
  private destroyed: boolean = false

  async aboutToAppear(): Promise<void> {
    try {
      const manager = await MediaManager.create(getContext(this), {
        mediaList: [DEMO_AUDIO],
        playMode: PlayMode.SINGLE,
        onChange: (state: MediaState) => {
          if (this.destroyed) {
            return
          }
          this.mediaReady = true
          this.mediaSummary =
            `索引 ${state.index} | ${TimeHelper.formatClock(state.time)} / ${TimeHelper.formatClock(state.duration)} | ${state.isPlay ?
              '播放中' : '暂停'}`
        }
      })
      // 创建期间组件可能已销毁：立即释放，避免 avPlayer 泄漏
      if (this.destroyed) {
        void manager.clear()
        return
      }
      this.mediaManager = manager
      this.mediaReady = true
      this.mediaSummary = '播放器已就绪，可直接播放在线音频'
    } catch (e) {
      if (this.destroyed) {
        return
      }
      this.mediaReady = false
      this.mediaSummary = '播放器初始化失败'
    }
  }

  aboutToDisappear(): void {
    this.destroyed = true
    void this.mediaManager?.clear()
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
        try {
          await this.mediaManager?.setAndPrepare(0)
          await this.mediaManager?.play()
        } catch (e) {
          IBestToast.show('音频加载失败')
        }
      }).backgroundColor('#111827')
      Button('暂停').onClick(async () => {
        try {
          await this.mediaManager?.pause()
        } catch (e) {
          IBestToast.show('暂停失败')
        }
      }).backgroundColor('#F59E0B')
      Button('播放').onClick(async () => {
        try {
          await this.mediaManager?.play()
        } catch (e) {
          IBestToast.show('播放失败')
        }
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
