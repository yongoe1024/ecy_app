# ecy app

基于 HarmonyOS / ArkTS 的多模块脚手架，轻量封装了常用能力，可作为新项目的起点。

## 技术栈

| 类型 | 内容 |
|------|------|
| 开发语言 | ArkTS |
| 构建工具 | Hvigor |
| SDK | HarmonyOS 6.0.2 |
| HTTP | `@ohos/axios` ^2.2.6 |
| UI 组件库 | `@ibestservices/ibest-ui-v2` ^1.0.5 |

## 目录结构

```text
ecy_app
├── AppScope                 # 应用全局配置与资源
├── entry                    # 应用入口模块（可执行）
├── common                   # 通用 HAR 模块（工具与业务能力）
├── features/home            # 业务 HAR 模块（首页、我的）
├── build-profile.json5
└── oh-package.json5
```

## 运行说明

1. 使用 DevEco Studio 打开项目。
2. 选择 `entry` 模块运行到模拟器或真机。

> 默认环境地址配置在 `common/src/main/ets/functions/environment/EnvironmentManager.ets`。

## 启动流程

1. `EntryStage` 创建全局状态 `GlobalState`（`AppStorageV2`）。
2. `EntryAbility.onWindowStageCreate` 依据首选项 `agreePrivacy` 选择首屏：未同意 → `PrivacyPage`，已同意 → `Index`。
3. 通过 `want.parameters.toUrl` 携带的深链会在隐私同意后、进入 `Index` 时消费跳转（热启动经 `onNewWant` 处理）。

## 页面与路由

| 页面 | 路径 / 路由 | 说明 |
|------|------|------|
| PrivacyPage | `pages/PrivacyPage` | 隐私同意页，首次启动显示 |
| Index | `pages/Index` | 导航容器入口（`Navigation` + `NavPathStack`） |
| Main | `RouteTable.ENTRY_MAIN` (`ecy://entry/main`) | 底部 Tab 主页面（首页 / 购物 / 我的） |
| WebViewPage | `RouteTable.COMMON_WEB` (`ecy://common/web`) | 通用 WebView，`RouteManager` 打开 http 链接时自动进入 |
| LoginPage | `RouteTable.MINE_LOGIN` (`ecy://mine/login`) | 登录演示页，`push({ needLogin: true })` 未登录时自动跳转 |

> 首页（`features/home` 的 Common Lab）以卡片形式演示了下列全部能力，可作为各 Manager 用法的活文档。

---

## 错误处理约定

对外 API 按「层」统一错误处理，按下表处理即可正确消费结果。失败时：领域层异步方法 reject `AppError`（继承 `Error`、带 `code`）；同步工具写失败与底层 SDK（avPlayer、定位、Preferences 等）错误以原生 `Error` / `BusinessError` 透传。均可读 `e.message`（多数含 `e.code`）。

| 层 | 代表方法 | 失败时 | 调用方处理 |
|----|---------|--------|-----------|
| 同步工具·读查询 | `PreferenceManager.getStringSync` / `UserManager.getToken` / `EnvironmentManager.getEnv` | 记日志并返回安全默认值（`''`/`false`/`DEV`） | 直接用返回值，默认值即「无 / 未登录」 |
| 同步工具·写变更 | `PreferenceManager.putSync/deleteSync` / `UserManager.setToken` / `EnvironmentManager.setEnv` | **throw**（不静默吞错） | `try/catch` |
| 传输层 | `NetManager.request/upload/download` | 有响应即 resolve（**即使 `res.code !== 200`**）；仅网络 / 超时 reject | **先查 `res.code`** + `catch` 网络错误 |
| 领域层（异步） | `UserManager.login` / `LocationManager.*` / `MediaManager.*` | `Promise.reject(AppError)` | `try/catch` 或 `.catch` |
| UI 命令 | `RouteManager.push / pop*` | best-effort：记日志 + Toast，**永不抛 / reject** | 直接调用 |
| 状态查询（异步） | `UserManager.getUserInfo / refreshUserInfo` | `undefined` = 未登录（非错误）；出错走 reject | 先判 `undefined`，再 `try/catch` |

> ⚠️ 安全提示：`UserManager` 的 token 当前以**明文**存储于 Preferences（HarmonyOS Preferences 无加密层），仅适合脚手架演示；上生产请替换为加密存储（HUKS / 关系型数据库加密）。`EnvironmentManager` 中生产 / 测试地址为占位（`myprod.com` / `mytest.com`），DEV 为明文 http，请按需替换并配置网络安全策略。

---

## API 使用示例

### 1. 环境切换

```ts
import { EnvironmentManager, EnvEnum } from 'common'

const env = EnvironmentManager.getInstance().getEnv()       // 获取当前环境
const baseUrl = EnvironmentManager.getInstance().getBaseUrl() // 获取 baseURL
EnvironmentManager.getInstance().setEnv(EnvEnum.DEV)        // 切换环境（会重启应用）
```

### 2. 本地存储

```ts
import { PreferenceManager } from 'common'

try {
  PreferenceManager.putSync('demo_key', 'demo_value')           // 写变更：失败会抛出
  const value = PreferenceManager.getStringSync('demo_key', '') // 类型化读取，免强转
  PreferenceManager.deleteSync('demo_key')
} catch (e) {
  // 处理存储异常
}
```

### 3. 用户 Token

```ts
import { UserManager } from 'common'

UserManager.getInstance().setToken('token-demo')
const token = UserManager.getInstance().getToken()
```

### 4. 路由跳转

```ts
import { RouteManager, RouteTable } from 'common'

RouteManager.getInstance().push({ url: RouteTable.ENTRY_MAIN })
RouteManager.getInstance().push({ url: 'https://developer.harmonyos.com/' }) // http 链接自动打开 WebView
RouteManager.getInstance().push({ url: 'ecy://some/page', needLogin: true })  // 未登录时自动跳转登录页
RouteManager.getInstance().pop()
```

### 5. 网络请求

```ts
import { NetManager } from 'common'

try {
  const res = await NetManager.getInstance().request({
    method: 'get',
    url: 'https://httpbin.org/get'
  })
  // 传输层只保证「服务器有响应」，业务是否成功要看 res.code
  if (res.code === 200) {
    // 消费 res.data
  }
} catch (e) {
  // 仅网络错误 / 超时会走到这里
}
```

### 6. 权限申请

```ts
import { PermissionManager } from 'common'

const granted = await PermissionManager.requestPermissions(
  ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'],
  '需要定位权限以继续使用相关功能'
)
```

### 7. 计时器

```ts
import { TimeHelper, TimerType } from 'common'

const timer = TimeHelper.build({
  type: TimerType.COUNT_DOWN,
  maxTimeMs: 60 * 1000,
  triggerTime: 1000,
  onTick: (value: number) => { /* 每秒更新 UI */ },
  onReachLimit: () => { /* 倒计时结束 */ }
})

timer.start()
// timer.stop() / timer.resume()
```

### 8. 定位与地理编码

```ts
import { LocationManager } from 'common'

await LocationManager.getInstance().checkAndRequest()

const address = await LocationManager.getInstance().getAddressByLatLon(39.904989, 116.405285)
const geo = await LocationManager.getInstance().getAddressesFromName('上海中心')
```

### 9. 用户能力（登录/登出）

```ts
import { UserManager } from 'common'

try {
  await UserManager.getInstance().login('13800138000', '1234')  // 失败 reject(AppError)
  const userInfo = await UserManager.getInstance().getUserInfo() // 未登录返回 undefined
  await UserManager.getInstance().logout()
} catch (e) {
  // 登录 / 登出失败处理（含 token 持久化失败）
}
```

### 10. 断点响应式布局

```ts
import { Breakpoint, GlobalState } from 'common'
import { AppStorageV2 } from '@kit.ArkUI'

@ComponentV2
struct MyComponent {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!

  build() {
    Column()
      .width(Breakpoint.ofWidth(
        this.globalState.widthBreakpoint,
        '100%',  // XS
        '48%',   // SM
        '32%',   // MD
        '24%',   // LG
        '24%'    // XL
      ))
  }
}
```

### 11. 媒体播放

```ts
import { MediaManager, PlayMode } from 'common'

const mediaManager = await MediaManager.create(getContext(this), {
  mediaList: ['https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'],
  playMode: PlayMode.SINGLE,
  onChange: (state) => { /* index / time / duration / isPlay 回调 */ }
})

await mediaManager.setAndPrepare(0) // 加载并准备指定索引（失败会 reject）
await mediaManager.play()
await mediaManager.pause()
mediaManager.clear()                // 组件销毁时释放
```

### 12. WebView 组件

```ts
import { WebComponent } from 'common'

// JS / DOM 存储默认开启，定位默认关闭，按需放开
WebComponent({
  src: 'https://developer.harmonyos.com/',
  geolocationAccess: true
})
```

---

## 预览图

<table>
  <tr>
    <td><img src="img/img.png" width="200" /></td>
    <td><img src="img/img_1.png" width="200" /></td>
    <td><img src="img/img_2.png" width="200" /></td>
  </tr>
</table>

