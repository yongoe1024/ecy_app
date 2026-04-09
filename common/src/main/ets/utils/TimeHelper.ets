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
  private triggerTime: number = 1000
  private timerId: number = -1;
  private type: TimerType = TimerType.COUNT_UP;
  private maxTimeMs: number = 0;
  // 毫秒
  private timeMs: number = 0;
  private onTick?: Callback<number>
  private onReachLimit?: Callback<void>

  public setMaxTimeMs(value: number) {
    this.maxTimeMs = value;
  }


  static build(option: TimeBuildOptions) {
    let time = new TimeHelper()
    time.type = option.type ?? TimerType.COUNT_UP;
    time.maxTimeMs = option.maxTimeMs
    time.onTick = option.onTick
    time.onReachLimit = option.onReachLimit
    time.triggerTime = option.triggerTime ?? 1000
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
    if (this.type === TimerType.COUNT_UP) {
      this.timeMs = 0;
    } else {
      this.timeMs = this.maxTimeMs;
    }
    this.tick();
    this.timerId = setInterval(() => {
      if (this.type === TimerType.COUNT_UP) {
        this.timeMs += this.triggerTime
        this.tick();
        if (this.maxTimeMs > 0 && this.timeMs >= this.maxTimeMs) {
          this.stop();
          this.onReachLimit?.();
        }
      } else {
        this.timeMs -= this.triggerTime
        this.tick();
        if (this.timeMs <= 0) {
          this.stop();
          this.onReachLimit?.();
        }
      }
    }, this.triggerTime) as number;
  }

  /** 触发一次时间回调，把当前秒数同步给页面或业务层。 */
  private tick(): void {
    this.onTick?.(this.timeMs);
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
    this.timerId = setInterval(() => {
      if (this.type === TimerType.COUNT_UP) {
        this.timeMs += this.triggerTime
        this.tick();
        if (this.maxTimeMs > 0 && this.timeMs >= this.maxTimeMs) {
          this.stop();
          this.onReachLimit?.();
        }
      } else {
        this.timeMs -= this.triggerTime
        this.tick();
        if (this.timeMs <= 0) {
          this.stop();
          this.onReachLimit?.();
        }
      }
    }, this.triggerTime) as number;
  }
}
