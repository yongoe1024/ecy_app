/**
 * 屏幕断点工具：按宽/高断点取值，未提供的档位回落到首参。
 * 取值来源：GlobalState.widthBreakpoint / heightBreakpoint（EntryAbility 维护）。
 */
export class Breakpoint {
  static ofWidth(point: WidthBreakpoint, xs: Length, sm?: Length, md?: Length, lg?: Length, xl?: Length): Length {
    switch (point) {
      case WidthBreakpoint.WIDTH_XS:
        return xs;
      case WidthBreakpoint.WIDTH_SM:
        return sm ?? xs;
      case WidthBreakpoint.WIDTH_MD:
        return md ?? xs;
      case WidthBreakpoint.WIDTH_LG:
        return lg ?? xs;
      case WidthBreakpoint.WIDTH_XL:
        return xl ?? xs;
      default:
        return xs
    }
  }

  static ofHeight(point: HeightBreakpoint, sm: Length, md?: Length, lg?: Length): Length {
    switch (point) {
      case HeightBreakpoint.HEIGHT_SM:
        return sm;
      case HeightBreakpoint.HEIGHT_MD:
        return md ?? sm;
      case HeightBreakpoint.HEIGHT_LG:
        return lg ?? sm;
      default:
        return sm
    }
  }
}
