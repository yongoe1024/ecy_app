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

/** 统一的计时引擎：正计时/倒计时，按 triggerTime 间隔回调。 */
export class TimeHelper {
  private triggerTime: number = DEFAULT_TRIGGER_TIME_MS
  private timerId: number = -1;
  private type: TimerType = TimerType.COUNT_UP;
  private maxTimeMs: number = 0;
  // 毫秒
  private timeMs: number = 0;
  // 本轮 interval 的起始墙钟时间与起始计时值，用真实时间差换算 timeMs，避免按 tick 累加产生漂移
  private startTimestamp: number = 0;
  private baseTimeMs: number = 0;
  private onTick?: Callback<number>
  private onReachLimit?: Callback<void>

  /** 把毫秒格式化为 mm:ss，负值按 0 处理 */
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

  /** 获取当前计时值（毫秒），正计时返回已用时，倒计时返回剩余时长。 */
  getTimeMs(): number {
    return this.timeMs
  }

  public setTimeMs(value: number) {
    this.timeMs = value;
  }

  /** 从头启动一个计时阶段，并根据当前模式初始化计时值。 */
  start(): void {
    this.stop();
    this.timeMs = this.type === TimerType.COUNT_UP ? 0 : this.maxTimeMs;
    this.tick();
    this.startInterval();
  }

  /** 触发一次时间回调，把当前计时值（毫秒）同步给页面或业务层。 */
  private tick(): void {
    this.onTick?.(this.timeMs);
  }

  private startInterval(): void {
    // 以本轮起点为基准，按真实经过时间换算，避免 setInterval 抖动累积导致计时漂移
    this.baseTimeMs = this.timeMs;
    this.startTimestamp = Date.now();
    this.timerId = setInterval(() => {
      const elapsed = Date.now() - this.startTimestamp;
      if (this.type === TimerType.COUNT_UP) {
        // 向下取整到 triggerTime 的整数倍，与倒计时分支对称（onTick 恒得整数倍值）
        this.timeMs = this.baseTimeMs + Math.floor(elapsed / this.triggerTime) * this.triggerTime;
        if (this.maxTimeMs > 0 && this.timeMs >= this.maxTimeMs) {
          this.timeMs = this.maxTimeMs;
          this.tick();
          this.stop();
          this.onReachLimit?.();
          return;
        }
        this.tick();
      } else {
        const remaining = this.baseTimeMs - elapsed;
        if (remaining <= 0) {
          this.timeMs = 0;
          this.tick();
          this.stop();
          this.onReachLimit?.();
          return;
        }
        // 向上取整到 triggerTime 的整数倍：让相邻 tick 的剩余值正好相差一个 triggerTime
        this.timeMs = Math.ceil(remaining / this.triggerTime) * this.triggerTime;
        this.tick();
      }
    }, this.triggerTime) as number;
  }

  /** 停止当前计时任务，但保留当前计时值以便后续恢复。 */
  stop(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  /** 按当前模式从上次暂停的计时值继续计时（正计时累加、倒计时递减）。 */
  resume(): void {
    this.stop();
    this.tick();
    this.startInterval();
  }

  /** 销毁实例：停止计时并清空回调引用，避免泄漏。页面 aboutToDisappear 中应调用。 */
  destroy(): void {
    this.stop();
    this.onTick = undefined;
    this.onReachLimit = undefined;
  }
}
