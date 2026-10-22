/**
 * 路由表
 * 命名规则 {模块名}_{功能名}
 */
export class RouteTable {
  /** 应用内部深链 scheme */
  public static readonly SCHEME: string = "ecy://";
  /** common  **/
  // web
  public static readonly COMMON_WEB: string = "ecy://common/web";
  // 环境切换（调试用，非 PRD 环境的悬浮球入口）
  public static readonly COMMON_ENV: string = "ecy://common/env";
  /** mine  **/
  // 登录
  public static readonly MINE_LOGIN: string = "ecy://mine/login";
  /** entry  **/
  // 主页
  public static readonly ENTRY_MAIN: string = "ecy://entry/main";
}