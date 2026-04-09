// v2
// @Env(SystemProperties.BREAK_POINT) breakpoint: uiObserver.WindowSizeLayoutBreakpointInfo; // 正确用法

// Text('Test')
//  .fontSize(  BreakpointType.of(this.currentWidthBreakpoint,'14fp', '16fp', '18fp') )
/**
 * 屏幕断点工具
 */
export class Breakpoint {
  static ofWidth<T>(point: WidthBreakpoint, xs?: T, sm?: T, md?: T, lg?: T, xl?: T): T | undefined {
    switch (point) {
      case 0:
        return xs;
      case 1:
        return sm;
      case 2:
        return md;
      case 3:
        return lg;
      case 4:
        return xl;
      default:
        return xs
    }
  }

  static ofHeight<T>(point: HeightBreakpoint, sm?: T, md?: T, lg?: T): T | undefined {
    switch (point) {
      case 0:
        return sm;
      case 1:
        return md;
      case 2:
        return lg;
      default:
        return sm
    }
  }
}
