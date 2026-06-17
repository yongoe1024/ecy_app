# ecy app

基于 HarmonyOS / ArkTS 的多模块脚手架。把网络、存储、登录、路由、权限、定位、媒体等常用能力封装成开箱即用的 Manager，可直接作为新项目的起点。

## 技术栈

| 类型 | 内容 |
|------|------|
| 开发语言 | ArkTS |
| 构建工具 | Hvigor |
| SDK | HarmonyOS 6.0.2 |
| HTTP | `@ohos/axios` ^2.2.6 |
| UI 组件库 | `@ibestservices/ibest-ui-v2` ^1.0.5 |

## 快速开始

1. 用 DevEco Studio 打开项目。
2. 选择 `entry` 模块运行到模拟器或真机。
3. 首页「Common Lab」以卡片形式演示了下列全部能力，是各 Manager 的活文档——对照 `features/home` 源码即可学习标准用法。

> **统一约定**：所有能力都从 `common` 模块导入（`import { XxxManager } from 'common'`）。
> 业务能力为单例，用 `XxxManager.getInstance()` 获取；`PreferenceManager` / `PermissionManager` / `TimeHelper` / `Breakpoint` 是静态工具类，直接调用静态方法。

## 能力总览

| 能力 | 入口类 | 核心方法 |
|------|--------|---------|
| 网络请求 | `NetManager` | `request` · `upload` · `download` |
| 用户与登录 | `UserManager` | `login` · `logout` · `getToken` · `getUserInfo` |
| 本地存储 | `PreferenceManager` | `getStringSync` · `putSync` · `deleteSync` |
| 环境切换 | `EnvironmentManager` | `getEnv` · `getBaseUrl` · `setEnv` |
| 路由导航 | `RouteManager` | `push` · `pop` · `popTo` |
| WebView | `WebComponent` | 组件，必填 `src` |
| 权限申请 | `PermissionManager` | `requestPermissions` |
| 定位 / 地理编码 | `LocationManager` | `checkAndRequest` · `getAddressByLatLon` |
| 媒体播放 | `MediaManager` | `create` · `setAndPrepare` · `play` · `pause` |
| 计时器 | `TimeHelper` | `build` · `start` · `stop` |
| 响应式布局 | `Breakpoint` | `ofWidth` · `ofHeight` |

---

## 核心能力与用法

### 网络请求 · NetManager

```ts
import { NetManager } from 'common'

// request：只要服务器有响应就 resolve，业务成功与否看 res.code；仅网络/超时走 catch
try {
  const res = await NetManager.getInstance().request<UserInfo>({
    method: 'get',
    url: '/user/info'
  })
  if (res.code === 200) {
    // 使用 res.data
  }
} catch (e) {
  // 网络错误 / 超时
}

// 文件上传 / 下载
await NetManager.getInstance().upload(context, { url: '/upload', filePath })
await NetManager.getInstance().download(context, { url, filePath })
```

> 已登录时，Token 会被请求拦截器自动加到 `Authorization` 头，无需手动设置。

### 用户与登录 · UserManager

```ts
import { UserManager } from 'common'

// 登录 / 登出（失败 reject）
try {
  await UserManager.getInstance().login('13800138000', '1234')
  await UserManager.getInstance().logout()
} catch (e) { /* 失败处理 */ }

// Token（同步、持久化）
UserManager.getInstance().setToken('xxx')            // 写失败会抛出
const token = UserManager.getInstance().getToken()   // 无 token 返回 ''

// 用户信息（懒加载，未登录返回 undefined）
const info = await UserManager.getInstance().getUserInfo()
await UserManager.getInstance().refreshUserInfo()     // 强制刷新

// 监听登录态变化
UserManager.getInstance().registerListener({
  onLogin: () => {},
  onLogout: () => {},
  onUserInfoChanged: (info) => {}
})
```

> 脚手架内置 **mock 登录**（返回固定 token）。接入真实后端时，把 `UserManager.login` 里被注释的请求打开即可。

### 本地存储 · PreferenceManager

```ts
import { PreferenceManager } from 'common'

try {
  PreferenceManager.putSync('key', 'value')               // 写入（失败抛出）
  PreferenceManager.deleteSync('key')
} catch (e) { /* 存储异常 */ }
```

### 环境切换 · EnvironmentManager

```ts
import { EnvironmentManager, EnvEnum } from 'common'

const env = EnvironmentManager.getInstance().getEnv()         // 当前环境
const baseUrl = EnvironmentManager.getInstance().getBaseUrl()  // 当前 baseURL
EnvironmentManager.getInstance().setEnv(EnvEnum.TEST)          // 切换并重启应用
```

> 环境地址在 `EnvironmentManager.ets` 顶部配置；生产 / 测试为占位地址，需替换为真实域名。

### 路由导航 · RouteManager

```ts
import { RouteManager, RouteTable } from 'common'

RouteManager.getInstance().push({ url: RouteTable.ENTRY_MAIN })              // 应用内页面
RouteManager.getInstance().push({ url: 'https://developer.harmonyos.com/' }) // http 自动用 WebView 打开
RouteManager.getInstance().push({ url: 'ecy://some/page', needLogin: true }) // 未登录先跳登录页
RouteManager.getInstance().pop()            // 返回
RouteManager.getInstance().popTo('PageA')   // 返回到指定页
```

> 路由方法均为「尽力而为」：失败只记录日志 / Toast，不会抛异常，调用处无需 try/catch。

### WebView · WebComponent

```ts
import { WebComponent } from 'common'

// JS / DOM 存储默认开启，定位、文件访问默认关闭，按需放开
WebComponent({ src: 'https://developer.harmonyos.com/', geolocationAccess: true })
```

> 用 `RouteManager.push({ url: 'http...' })` 打开 http 链接时，会自动进入内置 `WebViewPage`。

### 权限申请 · PermissionManager

```ts
import { PermissionManager } from 'common'

// 返回是否已授权；遇到「不再询问」会自动弹窗引导去设置页
const granted = await PermissionManager.requestPermissions(
  ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'],
  '需要定位权限以继续'
)
```

### 定位 / 地理编码 · LocationManager

```ts
import { LocationManager } from 'common'

await LocationManager.getInstance().checkAndRequest()  // 检查权限与定位开关
const addr = await LocationManager.getInstance().getAddressByLatLon(39.9049, 116.4053) // 逆地理编码
const geo = await LocationManager.getInstance().getAddressesFromName('上海中心')        // 地理编码
```

### 媒体播放 · MediaManager

```ts
import { MediaManager, PlayMode } from 'common'

const player = await MediaManager.create(getContext(this), {
  mediaList: ['https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'],
  playMode: PlayMode.SINGLE,
  onChange: (state) => { /* index / time / duration / isPlay */ }
})

await player.setAndPrepare(0)  // 加载指定索引（失败 reject）
await player.play()
await player.pause()
player.clear()                 // 组件销毁时务必释放
```

### 计时器 · TimeHelper

```ts
import { TimeHelper, TimerType } from 'common'

const timer = TimeHelper.build({
  type: TimerType.COUNT_DOWN,
  maxTimeMs: 60 * 1000,
  onTick: (ms) => {},        // 每秒回调
  onReachLimit: () => {}     // 倒计时结束
})
timer.start()                 // stop() / resume() / destroy()

TimeHelper.formatClock(90_000) // "01:30"
```

> 在 `aboutToDisappear` 调用 `timer.destroy()` 释放定时器。

### 响应式布局 · Breakpoint

```ts
import { Breakpoint, GlobalState } from 'common'
import { AppStorageV2 } from '@kit.ArkUI'

@Local globalState: GlobalState = AppStorageV2.connect(GlobalState)!

Column().width(Breakpoint.ofWidth(
  this.globalState.widthBreakpoint,
  '100%', '48%', '32%', '24%', '24%' // XS / SM / MD / LG / XL
))
```

---

## 错误处理约定

按方法所在「层」决定如何处理返回与错误——照下表写即可。脚手架自身抛出 / reject 的错误统一为 `AppError`（继承 `Error`、带 `code`）；底层 SDK 错误以 `BusinessError` 透传。两者都可读 `e.code` / `e.message`。

| 层 | 代表方法 | 失败时 | 你该怎么做 |
|----|---------|--------|-----------|
| 读查询（同步） | `getToken` · `getStringSync` · `getEnv` | 记日志，返回安全默认值（`''`/`false`/`DEV`） | 直接用返回值 |
| 写变更（同步） | `putSync` · `deleteSync` · `setToken` · `setEnv` | **抛异常** | `try / catch` |
| 网络 | `request` · `upload` · `download` | 有响应即 resolve（即使 `code !== 200`）；仅网络/超时 reject | 先查 `res.code`，再 `catch` |
| 领域异步 | `login` · `LocationManager.*` · `MediaManager.*` | `reject(AppError)` | `try/catch` 或 `.catch` |
| 状态查询（异步） | `getUserInfo` · `refreshUserInfo` | `undefined` ＝ 未登录；出错才 reject | 先判 `undefined`，再 `catch` |
| 路由（UI 命令） | `push` · `pop*` | 只记日志 / Toast，**不抛** | 直接调用 |

---

## 架构参考

### 目录结构

```text
ecy_app
├── AppScope        # 应用全局配置与资源
├── entry           # 入口模块（可执行）
├── common          # 通用 HAR（工具与业务能力）
└── features/home   # 业务 HAR（首页、我的）
```

### 启动流程

1. `EntryStage` 创建全局状态 `GlobalState`（`AppStorageV2`）。
2. `EntryAbility.onWindowStageCreate` 依据首选项 `agreePrivacy` 选首屏：未同意 → `PrivacyPage`，已同意 → `Index`。
3. 深链（`want.parameters.toUrl`）在隐私同意后、进入 `Index` 时消费；热启动经 `onNewWant` 处理。

> 当前未注册外部 `ecy://` scheme，深链仅来自**应用内部** want 传参；如需支持外部应用 / 浏览器唤起，参见 `entry/src/main/module.json5` 中 `skills` 的注释。

### 页面与路由

| 页面 | 路由 | 说明 |
|------|------|------|
| PrivacyPage | `pages/PrivacyPage` | 隐私同意页，首次启动显示 |
| Index | `pages/Index` | 导航容器（`Navigation` + `NavPathStack`） |
| Main | `ecy://entry/main` | 底部 Tab 主页面（首页 / 购物 / 我的） |
| WebViewPage | `ecy://common/web` | 通用 WebView，打开 http 链接时自动进入 |
| LoginPage | `ecy://mine/login` | 登录页，`needLogin` 未登录时自动跳转 |

---

## 安全与生产化提示

- **Token 明文存储**：当前存于 Preferences（无加密层），仅适合演示；生产请改用加密存储（HUKS / 关系型数据库加密）。
- **环境地址**：生产 / 测试为占位（`myprod.com` / `mytest.com`），DEV 为明文 http；上线前替换为真实 HTTPS 域名并配置网络安全策略。
- **登录为 mock**：`UserManager.login` 返回固定 token，需接入真实后端。
- **WebView**：默认开启 JS / DOM 存储，加载不可信外链前请收紧权限。

---

## 预览图

<table>
  <tr>
    <td><img src="img/img.png" width="200" /></td>
    <td><img src="img/img_1.png" width="200" /></td>
    <td><img src="img/img_2.png" width="200" /></td>
  </tr>
</table>
