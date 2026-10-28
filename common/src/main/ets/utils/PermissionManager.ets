import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalState } from '../functions/environment/GlobalModel';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'PermissionManager';

/** 动态申请权限的结果 */
interface PermissionRequestResult {
  granted: boolean
  // 是否存在「不再询问」的永久拒绝项（系统未弹框），用于决定是否引导去设置页
  permanentlyDenied: boolean
}

/** 动态权限申请：未授予的批量申请；「不再询问」的永久拒绝引导去设置页 */
export class PermissionManager {
  /**
   * 获取权限，永久拒绝时弹窗引导跳转设置页
   * @param permissions 权限
   * @param failStr 跳转提示信息
   * @returns 是否已授权
   * @throws context 未初始化时抛 Error；权限查询底层异常透传 BusinessError
   */
  public static async requestPermissions(permissions: Permissions[], failStr: string): Promise<boolean> {
    const not: Permissions[] = PermissionManager.check(permissions)
    if (not.length == 0) {
      return true
    }
    const res = await PermissionManager.request(not)
    if (res.granted) {
      return true
    }
    // 仅在「不再询问」的永久拒绝时引导去设置页；首次拒绝保留下次系统弹窗的机会
    if (res.permanentlyDenied) {
      PermissionManager.showDialog(failStr)
        .catch((error: BusinessError) => {
          hilog.error(DOMAIN, TAG, `引导去设置页弹出失败 ${error.code} ${error.message}`);
        })
    }
    return false
  }


  /**
   * 检查是否有权限
   * @param permissions 申请权限
   * @returns 没有的权限
   * @throws BusinessError
   */
  private static check(permissions: Permissions[]): Permissions[] {
    const manager = abilityAccessCtrl.createAtManager()
    // 获取应用信息（accessTokenId）
    const appInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    const tokenId = appInfo.appInfo.accessTokenId
    // 逐个校验权限，收集未授予项
    const noPermissionList: Permissions[] = []
    permissions.forEach((per) => {
      try {
        const res = manager.checkAccessTokenSync(tokenId, per)
        if (res !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          noPermissionList.push(per)
        }
      } catch (error) {
        // 校验异常时按未授予处理，并记录便于排查
        hilog.warn(DOMAIN, TAG, `check ${per} ：${error?.code} ${error?.message}`);
        noPermissionList.push(per)
      }
    })
    // 返回未授权列表
    return noPermissionList
  }

  /** 动态申请权限，并区分首次拒绝与「不再询问」的永久拒绝 */
  private static async request(permissions: Permissions[]): Promise<PermissionRequestResult> {
    const state = AppStorageV2.connect(GlobalState)!
    const context = state.uiAbilityContext
    if (!context) {
      throw new Error('PermissionManager: uiAbilityContext 未初始化，请在 Ability 创建后调用');
    }
    const manager = abilityAccessCtrl.createAtManager()
    const result = await manager.requestPermissionsFromUser(context, permissions)
    const authResults = result.authResults
    const dialogShownResults = result.dialogShownResults
    const granted = authResults.every(item => item === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
    // 被拒绝且系统未弹框（dialogShownResults 为 false）→「不再询问」的永久拒绝
    let permanentlyDenied = false
    for (let i = 0; i < authResults.length; i++) {
      const denied = authResults[i] !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      const dialogShown = dialogShownResults ? dialogShownResults[i] : false
      if (denied && !dialogShown) {
        permanentlyDenied = true
        break
      }
    }
    return { granted, permanentlyDenied }
  }

  /** 弹窗引导用户前往系统设置页开启权限 */
  private static async showDialog(failStr: string): Promise<void> {
    const state = AppStorageV2.connect(GlobalState)!;
    // windowStage 尚未就绪时无法弹窗，显式记录而非静默失败
    if (!state.windowStage) {
      throw new Error('PermissionManager: windowStage 未初始化，请在 Ability 创建后调用');
    }
    // 系统弹窗对话框
    const result = await state.windowStage.getMainWindowSync()
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
      return state.uiAbilityContext?.startAbility({
        bundleName: "com.huawei.hmos.settings",
        abilityName: "com.huawei.hmos.settings.MainAbility",
        uri: "application_info_entry", // 设置页的应用信息入口
        parameters: {
          pushParams: appInfo.name
        }
      })
    }
  }
}
