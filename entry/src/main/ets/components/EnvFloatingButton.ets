import { GlobalState, RouteManager, RouteTable } from 'common';
import { AppStorageV2 } from '@kit.ArkUI';

/** 球体尺寸与屏幕边缘留白 */
const BALL_SIZE = 44
const EDGE_MARGIN = 8

/**
 * 环境切换悬浮球：可拖动的圆形按钮，点开调试页（RouteTable.COMMON_DEBUG）。
 * 仅非 PRD 环境挂载（生产包不出现调试入口，由 Index 判定）。
 * 轻点 = 打开页面；拖动 = PanGesture 更新位置（拖动抑制 click，二者不冲突）。
 */
@ComponentV2
export struct EnvFloatingButton {
  @Local globalState: GlobalState = AppStorageV2.connect(GlobalState, () => new GlobalState())!
  // 相对屏幕左上角的位置
  @Local x: number = 0
  @Local y: number = 0
  // 手势开始时的位置快照：offsetX/Y 是自手势开始的累计位移，须基于起点计算（基于已更新坐标会逐帧叠加导致不跟手）
  private dragStartX: number = 0
  private dragStartY: number = 0

  aboutToAppear(): void {
    // 初始位置：右上角、状态栏之下；windowWidth 由 Index 挂载条件保证已就绪
    // （updateWinInfo 中 topRectHeight 先于 windowWidth 写入，二者同时就绪）
    this.x = this.globalState.windowWidth - BALL_SIZE - EDGE_MARGIN
    this.y = this.globalState.topRectHeight + 120
  }

  /** 拖动增量累加后限制在屏幕内（窗口尺寸未就绪时先不做限制） */
  private clamp(x: number, y: number): void {
    const maxX = this.globalState.windowWidth - BALL_SIZE - EDGE_MARGIN
    const maxY = this.globalState.windowHeight - BALL_SIZE - EDGE_MARGIN
    this.x = maxX > 0 ? Math.min(Math.max(x, EDGE_MARGIN), maxX) : x
    this.y = maxY > 0 ? Math.min(Math.max(y, EDGE_MARGIN), maxY) : y
  }

  build() {
    Text('debug')
      .fontSize(10)
      .fontWeight(FontWeight.Bold)
      .fontColor('#FFFFFF')
      .textAlign(TextAlign.Center)
      .width(BALL_SIZE)
      .height(BALL_SIZE)
      .borderRadius(BALL_SIZE / 2)
      .backgroundColor('#80000000')
      .position({ x: this.x, y: this.y })
      .gesture(
        PanGesture()
          .onActionStart(() => {
            this.dragStartX = this.x
            this.dragStartY = this.y
          })
          .onActionUpdate((event: GestureEvent) => {
            this.clamp(this.dragStartX + event.offsetX, this.dragStartY + event.offsetY)
          })
      )
      .onClick(() => {
        // 悬浮球在调试页上仍可见，已在调试页时不再压栈（连点会叠加多个）
        if (RouteManager.getInstance().getCurrentPageName() === RouteTable.COMMON_DEBUG) {
          return
        }
        RouteManager.getInstance().push({ url: RouteTable.COMMON_DEBUG })
      })
  }
}
