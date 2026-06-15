import { IBestToast } from '@ibestservices/ibest-ui-v2'
import { TimeHelper, TimerType } from 'common'
import { SectionCard } from '../SectionCard'

const TIMER_DURATION_MS = 90 * 1000

@ComponentV2
export struct HomeTimerCard {
  @Local timerLabel: string = '01:30'
  @Local timerRunning: boolean = false
  timer?: TimeHelper

  aboutToAppear(): void {
    this.prepareTimer()
  }

  aboutToDisappear(): void {
    this.timer?.stop()
  }

  prepareTimer(): void {
    this.timer = TimeHelper.build({
      type: TimerType.COUNT_DOWN,
      maxTimeMs: TIMER_DURATION_MS,
      triggerTime: 1000,
      onTick: (value: number) => {
        this.timerLabel = TimeHelper.formatClock(value)
      },
      onReachLimit: () => {
        this.timerRunning = false
        IBestToast.show('倒计时结束')
      }
    })
    this.timerLabel = TimeHelper.formatClock(TIMER_DURATION_MS)
  }

  startTimer(): void {
    this.timer?.start()
    this.timerRunning = true
  }

  pauseTimer(): void {
    this.timer?.stop()
    this.timerRunning = false
  }

  resumeTimer(): void {
    this.timer?.resume()
    this.timerRunning = true
  }

  resetTimer(): void {
    this.timer?.stop()
    this.timer?.setTimeMs(TIMER_DURATION_MS)
    this.timerLabel = TimeHelper.formatClock(TIMER_DURATION_MS)
    this.timerRunning = false
  }

  @LocalBuilder
  cardContent() {
    Text(this.timerLabel)
      .fontSize(32)
      .fontWeight(500)
      .fontColor('#111827')
    Text(this.timerRunning ? '计时进行中' : '计时已暂停')
      .fontSize(12)
      .fontColor('#64748B')
    Row({ space: 8 }) {
      Button('开始').onClick(() => this.startTimer()).backgroundColor('#111827')
      Button('暂停').onClick(() => this.pauseTimer()).backgroundColor('#F59E0B')
      Button('恢复').onClick(() => this.resumeTimer()).backgroundColor('#2563EB')
      Button('重置').onClick(() => this.resetTimer()).backgroundColor('#E2E8F0').fontColor('#0F172A')
    }
  }

  build() {
    SectionCard({
      title: '计时引擎',
      desc: '覆盖 TimeHelper 倒计时、暂停、恢复与重置。',
      content: this.cardContent
    })
  }
}
