import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit'
import { AppStorageV2 } from '@kit.ArkUI'
import { GlobalState } from '../functions'

/**
 * 权限管理类
 */
export class PermissionManager {
  /**
   * 获取权限，失败弹窗跳转设置页
   * @param permissions 权限
   * @param failStr 跳转提示信息
   * @returns 成功失败
   * @throws
   */
  public static async requestPermissions(permissions: Permissions[], failStr: string): Promise<boolean> {
    const not: Permissions[] = PermissionManager.check(permissions)
    if (not.length == 0) {
      return true
    }
    let res = await PermissionManager.request(not)
    if (res) {
      return true
    }
    PermissionManager.showDialog(failStr)
    return false
  }


  /**
   * 检查是否有权限
   * @param permissions 申请权限
   * @returns 没有的权限
   */
  private static check(permissions: Permissions[]): Permissions[] {
    const manager = abilityAccessCtrl.createAtManager()
    //获取应用信息
    const appInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    const tokenId = appInfo.appInfo.accessTokenId
    //校验每个权限,并返回校验的类型
    const noPermissionList: Permissions[] = []
    permissions.forEach((per) => {
      try {
        const res = manager.checkAccessTokenSync(tokenId, per)
        if (res !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          noPermissionList.push(per)
        }
      } catch (error) {
        noPermissionList.push(per)
      }
    })
    //处理授权结果
    return noPermissionList
  }

  /**
   * 动态申请权限
   * @throws
   */
  private static async request(permissions: Permissions[]): Promise<boolean> {
    const manager = abilityAccessCtrl.createAtManager()
    const result = await manager.requestPermissionsFromUser(getContext(), permissions)
    const success = result.authResults.every(item => item === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
    return success
  }

  /**
   * 显示权限申请对话框
   * @throws
   */
  private static async showDialog(failStr: string): Promise<void> {
    const state = AppStorageV2.connect(GlobalState)!;
    // 使用鸿蒙的对话框组件
    const result = await state.windowStage?.getMainWindowSync()
      .getUIContext()
      .getPromptAction()
      .showDialog({
        title: '权限申请',
        message: failStr,
        buttons: [
          {
            text: '取消',
            color: '#FF6B6B'
          },
          {
            text: '前往设置',
            color: '#4CAF50'
          }
        ]
      });
    if (result?.index === 1) {
      const appInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      state.uiAbilityContext?.startAbility({
        bundleName: "com.huawei.hmos.settings",
        abilityName: "com.huawei.hmos.settings.MainAbility",
        uri: "application_info_entry", //参数名
        parameters: {
          pushParams: appInfo.name
        }
      })
    }
  }
}
