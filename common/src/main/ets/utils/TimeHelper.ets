const DEFAULT_TRIGGER_TIME_MS = 1000

export enum TimerType {
  COUNT_UP,
  COUNT_DOWN
}

export interface TimeBuildOptions {
  type?: TimerType
  maxTimeMs: number
  onTick?: Callback<number>
  onReachLimit?: Callback<void>
  triggerTime?: number
}

/** 统一的计时引擎，负责专注正计时、休息倒计时以及每秒回调分发。 */
export class TimeHelper {
  private triggerTime: number = DEFAULT_TRIGGER_TIME_MS
  private timerId: number = -1;
  private type: TimerType = TimerType.COUNT_UP;
  private maxTimeMs: number = 0;
  // 毫秒
  private timeMs: number = 0;
  private onTick?: Callback<number>
  private onReachLimit?: Callback<void>

  /** 把毫秒格式化为 mm:ss，负值按 0 处理。供计时/媒体等场景复用。 */
  static formatClock(ms: number): string {
    const totalSeconds = ms > 0 ? Math.floor(ms / 1000) : 0
    const minute = Math.floor(totalSeconds / 60).toString().padStart(2, '0')
    const second = (totalSeconds % 60).toString().padStart(2, '0')
    return `${minute}:${second}`
  }

  public setMaxTimeMs(value: number) {
    this.maxTimeMs = value;
  }


  static build(option: TimeBuildOptions) {
    let time = new TimeHelper()
    time.type = option.type ?? TimerType.COUNT_UP;
    time.maxTimeMs = option.maxTimeMs
    time.onTick = option.onTick
    time.onReachLimit = option.onReachLimit
    time.triggerTime = option.triggerTime ?? DEFAULT_TRIGGER_TIME_MS
    return time
  }

  private constructor() {
  }

  /** 获取当前计时秒数，正计时返回已用时，倒计时返回剩余时长。 */
  getTimeMs(): number {
    return this.timeMs
  }

  public setTimeMs(value: number) {
    this.timeMs = value;
  }

  /** 从头启动一个计时阶段，并根据当前模式初始化秒数。 */
  start(): void {
    this.stop();
    this.timeMs = this.type === TimerType.COUNT_UP ? 0 : this.maxTimeMs;
    this.tick();
    this.startInterval();
  }

  /** 触发一次时间回调，把当前秒数同步给页面或业务层。 */
  private tick(): void {
    this.onTick?.(this.timeMs);
  }

  private startInterval(): void {
    this.timerId = setInterval(() => {
      if (this.type === TimerType.COUNT_UP) {
        this.timeMs += this.triggerTime;
        this.tick();
        if (this.maxTimeMs > 0 && this.timeMs >= this.maxTimeMs) {
          this.stop();
          this.onReachLimit?.();
        }
      } else {
        this.timeMs -= this.triggerTime;
        this.tick();
        if (this.timeMs <= 0) {
          this.stop();
          this.onReachLimit?.();
        }
      }
    }, this.triggerTime) as number;
  }

  /** 停止当前计时任务，但保留当前秒数以便后续恢复。 */
  stop(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  /** 恢复正计时模式下的计时任务，从上次暂停秒数继续累加。 */
  resume(): void {
    this.stop();
    this.tick();
    this.startInterval();
  }
}
