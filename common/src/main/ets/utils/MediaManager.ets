import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { audio } from '@kit.AudioKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'MediaManager';

export enum PlayMode {
  /** 单曲循环 */
  SINGLE,
  /** 顺序播放 */
  ORDER,
  /** 随机播放 */
  RANDOM,
  /** 播完即 reset 回 idle，需重新 setAndPlay 才能再播 */
  ONCE
}

/**
 * 播放器配置
 */
export interface MediaConfig {
  playMode: PlayMode
  /** 支持 http 链接或 rawfile 文件名 */
  mediaList?: string[]
  surfaceID?: string
  audioRendererInfo?: audio.AudioRendererInfo
}

/** 播放器状态 */
export interface MediaState {
  index: number
  time: number
  duration: number
  isPlay: boolean
  playMode: PlayMode
  mediaList: string[]
  width?: number
  height?: number
  surfaceID?: string
  audioRendererInfo?: audio.AudioRendererInfo
}

/**
 * 链路进行中收到的待续播请求（最新胜出）
 */
interface PendingPlay {
  index: number
  config?: MediaConfig
}

/**
 * 音视频管理器
 */
export class MediaManager {
  private onChange?: Callback<MediaState>
  private avPlayer: media.AVPlayer
  private context: Context
  private state: MediaState
  // 链路互斥：实测连点时两条链的 reset/setUrl 与 prepare/play 重叠会互相打死（5400102），任意时刻只允许一条链
  private chaining: boolean = false
  // 链路进行中收到的最新请求，当前链终点自动续播（最新胜出）
  private pendingPlay?: PendingPlay

  constructor(avPlayer: media.AVPlayer, context: Context, state: MediaState) {
    this.avPlayer = avPlayer;
    this.context = context;
    this.state = state;
  }

  /**
   * 创建实例并注册播放器回调。
   * @param config 初始配置
   * @throws BusinessError
   */
  static async create(context: Context, config: MediaConfig, onChange?: Callback<MediaState>): Promise<MediaManager> {
    const avPlayer = await media.createAVPlayer()
    const ins: MediaManager = new MediaManager(avPlayer, context, {
      index: -1,
      time: 0,
      duration: 0,
      isPlay: false,
      playMode: config.playMode,
      mediaList: config.mediaList ?? [],
      surfaceID: config.surfaceID,
      audioRendererInfo: config.audioRendererInfo
    })
    // 先赋值 onChange，再注册事件回调，避免 initCallback 内同步触发的事件丢失
    ins.onChange = onChange
    ins.initCallback()
    return ins
  }

  /**
   * 更新播放模式
   */
  updateMode(mode: PlayMode): void {
    this.state.playMode = mode
  }

  /**
   * 初始化后可以在prepared/playing/paused/completed/stopped状态下重新设置
   * @param id
   */
  updateSurfaceId(id: string) {
    this.avPlayer.surfaceId = id
  }

  /**
   * 初始化 并准备播放（prepare/play 由状态事件自动续接）
   * 链路失败仅记日志，不 reject；链路进行中调用时仅记录最新请求，当前链结束后自动续播
   */
  async setAndPlay(index: number, config?: MediaConfig): Promise<void> {
    if (this.chaining) {
      this.pendingPlay = { index: index, config: config }
      return
    }
    this.chaining = true
    await this.runChain(index, config)
  }

  /**
   * 单条链路执行体：reset → 设置资源；后续 prepare/play 由 initialized/prepared 事件续接，
   * 链路终点（play 结束 / prepare 失败 / error / 非法索引 / reset·setUrl 抛错）调 finishChain
   */
  private async runChain(index: number, config?: MediaConfig): Promise<void> {
    try {
      await this.avPlayer.reset()
      if (config) {
        this.state.mediaList = config.mediaList ?? this.state.mediaList
        this.state.playMode = config.playMode ?? this.state.playMode
        this.state.audioRendererInfo = config.audioRendererInfo
        this.state.surfaceID = config.surfaceID
      }
      this.state.index = index
      if (index < 0 || index >= this.state.mediaList.length) {
        this.state.index = -1
        this.finishChain()
        return
      }
      await this.setUrl(this.state.mediaList[this.state.index])
    } catch (e) {
      hilog.error(DOMAIN, TAG, `runChain ：${e.code} ${e.message}`);
      this.finishChain()
    }
  }

  /**
   * 链路终点：有挂起请求则续播下一条，否则释放互斥标志
   */
  private finishChain(): void {
    if (!this.chaining) {
      return
    }
    const pending = this.pendingPlay
    this.pendingPlay = undefined
    if (pending) {
      this.runChain(pending.index, pending.config)
    } else {
      this.chaining = false
    }
  }

  /**
   * 释放
   * @throws BusinessError
   */
  release(): Promise<void> {
    return this.avPlayer.release()
  }

  /**
   * 恢复播放
   * @throws BusinessError
   */
  async play(): Promise<void> {
    // 链路进行中不下发：链路终点会自动起播，意图已覆盖
    if (this.chaining) {
      return
    }
    if (!this.state.isPlay) {
      await this.avPlayer.play()
    }
  }

  /**
   * 暂停播放
   * @throws BusinessError
   */
  async pause(): Promise<void> {
    // 链路进行中不下发：reset 迁移期（isPlay 尚未清零的窗口）pause 会撞非法状态（5400102）；
    // 链路终点自动起播，暂停意图不挂起（新资源下旧意图无明确指向）
    if (this.chaining) {
      hilog.warn(DOMAIN, TAG, 'pause ignored: chaining');
      return
    }
    if (this.state.isPlay) {
      await this.avPlayer.pause()
    }
  }

  /**
   * 跳转播放位置
   * @throws BusinessError
   */
  seek(time: number): void {
    // 链路进行中不下发：正在切换资源，旧资源进度对新资源无意义，且 idle/initialized 态 seek 非法（5400102）
    if (this.chaining) {
      hilog.warn(DOMAIN, TAG, 'seek ignored: chaining');
      return
    }
    this.avPlayer.seek(time)
  }

  /**
   * 初始化回调
   */
  private async initCallback(): Promise<void> {
    // create 后处于 idle 态，注册状态机与事件回调
    this.avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      switch (state) {
        // reset 成功后进入：清 UI 进度态
        case 'idle':
          this.state.isPlay = false
          this.state.time = 0
          this.state.duration = 0
          this.onChange?.(this.state)
          break;
        // url 设置完成后进入：配好画面/音频属性再 prepare
        case 'initialized':
          // 视频画面：纯音频资源无需设置
          if (this.state.surfaceID) {
            this.avPlayer.surfaceId = this.state.surfaceID;
          }
          if (this.state.audioRendererInfo) {
            this.avPlayer.audioRendererInfo = this.state.audioRendererInfo
          }
          this.avPlayer.prepare().catch((e: BusinessError) => {
            hilog.error(DOMAIN, TAG, `initialized - prepare ：${e.code} ${e.message}`);
            this.finishChain()
          }).finally(() => {
            this.onChange?.(this.state)
          })
          break;
        // prepare 完成：起播
        case 'prepared':
          this.avPlayer.play().catch((e: BusinessError) => {
            hilog.error(DOMAIN, TAG, `prepared - play ：${e.code} ${e.message}`);
          }).finally(() => {
            this.onChange?.(this.state)
            this.finishChain()
          })
          break;
        // play() 成功后上报
        case 'playing':
          this.state.isPlay = true
          this.onChange?.(this.state)
          break;
        // pause() 成功后上报
        case 'paused':
          this.state.isPlay = false
          this.onChange?.(this.state)
          break;
        // 播放结束
        case 'completed':
          try {
            // 播放已结束，清 isPlay，play() 的守卫才能对 SINGLE 放行重播
            this.state.isPlay = false
            // 按播放模式续接下一首
            if (this.state.playMode === PlayMode.SINGLE) {
              await this.play()
            } else if (this.state.playMode === PlayMode.ORDER) {
              this.state.index++
              if (this.state.index >= this.state.mediaList.length) {
                this.state.index = 0
              }
              await this.setAndPlay(this.state.index)
            } else if (this.state.playMode === PlayMode.RANDOM) {
              let index: number = 0
              // 随机取新索引（多个资源时避免与当前重复）
              do {
                index = Math.floor(Math.random() * this.state.mediaList.length)
              } while (this.state.mediaList.length > 1 && index === this.state.index)
              this.state.index = index
              await this.setAndPlay(this.state.index)
            } else if (this.state.playMode === PlayMode.ONCE) {
              await this.avPlayer.reset()
            }
            this.onChange?.(this.state)
          } catch (e) {
            hilog.error(DOMAIN, TAG, `completed：${e.code} ${e.message}`);
          }
          break
        // stopped / released 后均需重新 setAndPlay 从头走链路
        case 'stopped':
        case 'released':
          this.state.index = -1
          this.state.duration = 0
          this.state.time = 0
          this.state.isPlay = false
          this.onChange?.(this.state)
          break;
        default:
          break;
      }
    });
    // error 必须在 idle 态（设置资源前）注册
    this.avPlayer.on('error', (e: BusinessError) => {
      hilog.error(DOMAIN, TAG, `error ：${e.code} ${e.message}`);
      this.avPlayer.reset().catch((resetErr: BusinessError) => {
        hilog.error(DOMAIN, TAG, `reset ：${resetErr.code} ${resetErr.message}`);
      }).then(() => {
        // 错误恢复完成后终结当前链（如 set url 失败走 error 事件而非抛错，链路只能在此收尾）
        this.finishChain()
      });
    });
    // 资源时长上报
    this.avPlayer.on('durationUpdate', (duration: number) => {
      this.state.duration = duration
      this.onChange?.(this.state)
    });
    // 播放进度上报
    this.avPlayer.on('timeUpdate', (time: number) => {
      this.state.time = time
      this.onChange?.(this.state)
    });
    // seek 完成
    this.avPlayer.on('seekDone', (time: number) => {
      this.onChange?.(this.state)
    });
    // 音频焦点切换（来电、其它媒体抢占）
    this.avPlayer.on('audioInterrupt', (info: audio.InterruptEvent) => {
      // 音频焦点被抢占（来电、其它媒体播放等）：标记为暂停并通知 UI，避免状态与实际不一致
      if (info.eventType === audio.InterruptType.INTERRUPT_TYPE_BEGIN) {
        this.state.isPlay = false
        this.onChange?.(this.state)
      }
    });
    this.avPlayer.on('videoSizeChange', (width: number, height: number) => {
      this.state.width = width
      this.state.height = height
      this.onChange?.(this.state)
    });
  }

  /**
   * http链接或传入rawfile文件名
   * @throws BusinessError
   */
  private async setUrl(url: string): Promise<void> {
    // 网络链接直接设 url；本地资源走 rawfile fd
    if (url.startsWith('http')) {
      this.avPlayer.url = url
    } else {
      this.avPlayer.fdSrc = await this.context.resourceManager.getRawFd(url);
    }
  }
}
