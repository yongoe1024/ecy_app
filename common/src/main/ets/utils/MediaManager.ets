import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { audio } from '@kit.AudioKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'MediaManager';

/**
 * 初始化配置,ONCE需要重新setup
 */
export enum PlayMode {
  // 单个循环
  SINGLE,
  // 顺序播放
  ORDER,
  // 随机播放
  RANDOM,
  // 可以重新调用play播放
  ONCE
}

/**
 * 播放器配置
 */
export interface MediaConfig {
  playMode: PlayMode
  // 支持http链接、rawfile的文件名
  mediaList?: string[]
  onChange?: Callback<MediaState>
  surfaceID?: string
  audioRendererInfo?: audio.AudioRendererInfo
}

/**
 * 播放器状态
 * ps: 声音、倍速等没有
 */
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
 * 音视频管理器
 */
export class MediaManager {
  private onChange?: Callback<MediaState>
  private avPlayer: media.AVPlayer
  private context: Context
  private state: MediaState
  private resolve?: (value: void | PromiseLike<void>) => void;
  private reject?: (reason?: Object) => void;

  constructor(avPlayer: media.AVPlayer, context: Context, state: MediaState) {
    this.avPlayer = avPlayer;
    this.context = context;
    this.state = state;
  }

  /**
   * 创建实例
   * @throws BusinessError
   */
  static async create(context: Context, config: MediaConfig): Promise<MediaManager> {
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
    ins.onChange = config.onChange
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
   * 设置并准备播放（加载资源，可得到时长）
   * @throws BusinessError
   */
  async setAndPrepare(index: number, config?: MediaConfig): Promise<void> {
    // 取消上一个仍在等待的 prepare，避免其 Promise 因 resolve/reject 被覆盖而永久挂起
    this.settle(new Error('setAndPrepare 被新的调用取消'))
    return new Promise<void>((resolve, reject) => {
      this.resolve = resolve
      this.reject = reject
      // 异步逻辑放到独立方法，避免 async Promise executor 反模式吞掉异常
      this.runPrepare(index, config)
    })
  }

  /**
   * setAndPrepare 的异步执行体：重置播放器、应用配置并设置资源。
   * 真正的结算由 stateChange/error 回调通过 settle() 完成。
   */
  private async runPrepare(index: number, config?: MediaConfig): Promise<void> {
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
        this.settle()
        return
      }
      if (this.state.index >= 0 && this.state.mediaList.length > 0) {
        await this.setUrl(this.state.mediaList[this.state.index])
      }
    } catch (e) {
      this.settle(e)
    }
  }

  /**
   * 统一结算 setAndPrepare 返回的 Promise，确保只调用一次并清空引用，
   * 避免 prepare/error 失败时外层 Promise 永远挂起。
   */
  private settle(err?: Object): void {
    if (err) {
      this.reject?.(err)
    } else {
      this.resolve?.()
    }
    this.resolve = undefined
    this.reject = undefined
  }

  /**
   * 重置
   * @throws BusinessError
   */
  async reset() {
    return this.avPlayer.reset()
  }

  /**
   * 销毁，释放底层 AVPlayer 资源
   * @throws BusinessError
   */
  async clear(): Promise<void> {
    return this.avPlayer.release()
  }

  /**
   * 播放
   * @throws BusinessError
   */
  async play(): Promise<void> {
    if (!this.state.isPlay) {
      await this.avPlayer.play()
    }
  }

  /**
   * 暂停播放
   * @throws BusinessError
   */
  async pause(): Promise<void> {
    if (this.state.isPlay) {
      await this.avPlayer.pause()
    }
  }

  /**
   * 跳转播放位置
   * @throws BusinessError
   */
  seek(time: number): void {
    this.avPlayer.seek(time)
  }

  /**
   * 初始化回调
   */
  private async initCallback(): Promise<void> {
    // 此时create后，为idle状态
    // 状态机变化回调函数
    this.avPlayer.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      switch (state) {
        case 'idle':
          //成功调用reset接口后触发该状态机上报
          //在这里设置url，就进入初始化
          this.state.isPlay = false
          this.state.time = 0
          this.state.duration = 0
          this.onChange?.(this.state)
          break;
        //初始化
        case 'initialized':
          // 设置显示画面，当播放的资源为纯音频时无需设置
          if (this.state.surfaceID) {
            this.avPlayer.surfaceId = this.state.surfaceID;
          }
          if (this.state.audioRendererInfo) {
            this.avPlayer.audioRendererInfo = this.state.audioRendererInfo
          }
          this.avPlayer.prepare()
            .then(() => {
              this.settle()
            })
            .catch((e: BusinessError) => {
              hilog.error(DOMAIN, TAG, `initialized - prepare ：${e.code} ${e.message}`);
              // 关键修复：prepare 失败必须结算 Promise，否则 setAndPrepare 永久挂起
              this.settle(e)
            })
            .finally(() => {
              this.onChange?.(this.state)
            })
          break;
        //准备完毕
        case 'prepared':
          break;
        // play成功调用后触发该状态机上报
        case 'playing':
          this.state.isPlay = true
          this.onChange?.(this.state)
          break;
        // pause成功调用后触发该状态机上报
        case 'paused':
          this.state.isPlay = false
          this.onChange?.(this.state)
          break;
        // 播放结束
        case 'completed':
          try {
            // 循环
            if (this.state.playMode === PlayMode.SINGLE) {
              await this.play()
            } else if (this.state.playMode === PlayMode.ORDER) {
              this.state.index++
              if (this.state.index >= this.state.mediaList.length) {
                this.state.index = 0
              }
              await this.setAndPrepare(this.state.index)
              await this.play()
            } else if (this.state.playMode === PlayMode.RANDOM) {
              let index: number = 0
              //do_while循环，求出新的索引
              do {
                index = Math.floor(Math.random() * this.state.mediaList.length)
              } while (this.state.mediaList.length > 1 && index === this.state.index)
              this.state.index = index
              await this.setAndPrepare(this.state.index)
              await this.play()
            } else if (this.state.playMode === PlayMode.ONCE) {
              await this.avPlayer.reset()
            }
            this.onChange?.(this.state)
          } catch (e) {
            hilog.error(DOMAIN, TAG, `completed：${e.code} ${e.message}`);
          }
          break
        case 'stopped':
          // 停止状态，需要再次prepare
          break;
        case 'released':
          // 销毁状态，需要重新create
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
    // 必要事件，idle状态下、未调用设置资源接口前完成设置监听
    this.avPlayer.on('error', (e: BusinessError) => {
      hilog.error(DOMAIN, TAG, `error ：${e.code} ${e.message}`);
      // 若有挂起的 setAndPrepare，结算它，避免调用方卡死
      this.settle(e)
      this.avPlayer.reset().catch(() => {
        hilog.error(DOMAIN, TAG, `error：${e.code} ${e.message}`);
      });
    });
    // 监听进度条长度，刷新资源时长
    this.avPlayer.on('durationUpdate', (duration: number) => {
      this.state.duration = duration
      this.onChange?.(this.state)
    });
    // 监听进度条当前位置，刷新当前时间
    this.avPlayer.on('timeUpdate', (time: number) => {
      this.state.time = time
      this.onChange?.(this.state)
    });
    // 使用seek()跳转到指定播放位置后，如果seek操作成功
    this.avPlayer.on('seekDone', (time: number) => {
      this.onChange?.(this.state)
    });
    // 使用setSpeed()设置播放倍速后，如果setSpeed操作成功
    this.avPlayer.on('speedDone', (speed: number) => {
    });
    // 使用setVolume()调节播放音量后，如果setVolume操作成功
    this.avPlayer.on('volumeChange', (vol: number) => {
    });
    // 监听网络播放缓冲信息，用于上报缓冲百分比以及缓存播放进度
    this.avPlayer.on('bufferingUpdate', (infoType: media.BufferingInfoType, value: number) => {
    });
    // 监听音频焦点切换信息，搭配属性audioInterruptMode使用
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
    // 本地 和 网络url
    if (url.startsWith('http')) {
      this.avPlayer.url = url
    } else {
      this.avPlayer.fdSrc = await this.context.resourceManager.getRawFd(url);
    }
  }
}
