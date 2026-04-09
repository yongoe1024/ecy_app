import { GlobalState, RouteManager, RouteTable } from 'common';
import { AppStorageV2 } from '@kit.ArkUI';

@Entry
@ComponentV2
struct Index {

  aboutToAppear(): void {
  }

  build() {
    Navigation(RouteManager.getInstance().getStack(), { name: RouteTable.ENTRY_MAIN }) {
    }
    .mode(NavigationMode.Stack)
  }
}
