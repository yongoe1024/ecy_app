import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 统一错误类型。
 *
 * 为什么需要它：ArkTS 的 `arkts-limited-throw` 规则下，`throw` 只接受 Error 及其子类，
 * 而 `BusinessError` 是接口、不可直接 `new`/`throw`。本类继承 Error 并实现 BusinessError 形态，
 * 使其既能被 `throw`，也能被 `Promise.reject`，且调用方可统一读取 `e.code` / `e.message`。
 *
 * 约定（详见 README「错误处理约定」）：
 * - 同步写变更（如 PreferenceManager.putSync、UserManager.setToken）失败时 throw；
 * - 领域层异步方法（如 UserManager.login、LocationManager.*）失败时 Promise.reject(new AppError(...))。
 */
export class AppError extends Error implements BusinessError {
  code: number

  constructor(code: number, message: string) {
    super(message)
    this.name = 'AppError'
    this.code = code
  }
}
