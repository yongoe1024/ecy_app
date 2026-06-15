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
  /** mine  **/
  // 登录
  public static readonly MINE_LOGIN: string = "ecy://mine/login";
  /** entry  **/
  // 主页
  public static readonly ENTRY_MAIN: string = "ecy://entry/main";
}