// v2
// @Env(SystemProperties.BREAK_POINT) breakpoint: uiObserver.WindowSizeLayoutBreakpointInfo; // 正确用法

// Text('Test')
//  .fontSize(  BreakpointType.of(this.currentWidthBreakpoint,'14fp', '16fp', '18fp') )
/**
 * 屏幕断点工具
 */
export class Breakpoint {
  static ofWidth(point: WidthBreakpoint, xs: Length, sm?: Length, md?: Length, lg?: Length, xl?: Length): Length {
    switch (point) {
      case 0:
        return xs;
      case 1:
        return sm ?? xs;
      case 2:
        return md ?? xs;
      case 3:
        return lg ?? xs;
      case 4:
        return xl ?? xs;
      default:
        return xs
    }
  }

  static ofHeight(point: HeightBreakpoint, sm: Length, md?: Length, lg?: Length): Length {
    switch (point) {
      case 0:
        return sm;
      case 1:
        return md ?? sm;
      case 2:
        return lg ?? sm;
      default:
        return sm
    }
  }
}
