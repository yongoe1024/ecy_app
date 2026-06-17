import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalState } from '../functions';
import { AppError } from '../functions/AppError';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'PermissionManager';

/** 动态申请权限的结果 */
interface PermissionRequestResult {
  granted: boolean
  // 是否存在「不再询问」的永久拒绝项（系统未弹框），用于决定是否引导去设置页
  permanentlyDenied: boolean
}

/**
 * 权限管理类
 */
export class PermissionManager {
  /**
   * 获取权限，永久拒绝时弹窗引导跳转设置页
   * @param permissions 权限
   * @param failStr 跳转提示信息
   * @returns 成功失败
   * @throws BusinessError
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
        // 校验异常时按未授予处理，并记录便于排查
        hilog.warn(DOMAIN, TAG, `check ${per} ：${error?.code} ${error?.message}`);
        noPermissionList.push(per)
      }
    })
    //处理授权结果
    return noPermissionList
  }

  /**
   * 动态申请权限，并区分首次拒绝与「不再询问」的永久拒绝
   * @throws
   */
  private static async request(permissions: Permissions[]): Promise<PermissionRequestResult> {
    const state = AppStorageV2.connect(GlobalState)!
    const context = state.uiAbilityContext
    if (!context) {
      throw new AppError(1201, 'PermissionManager: uiAbilityContext 未初始化，请在 Ability 创建后调用');
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

  /**
   * 显示权限申请对话框
   * @throws
   */
  private static async showDialog(failStr: string): Promise<void> {
    const state = AppStorageV2.connect(GlobalState)!;
    // windowStage 尚未就绪时无法弹窗，显式记录而非静默失败
    if (!state.windowStage) {
      throw new AppError(1202, 'PermissionManager: windowStage 未初始化，请在 Ability 创建后调用');
    }
    // 使用鸿蒙的对话框组件
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
        uri: "application_info_entry", //参数名
        parameters: {
          pushParams: appInfo.name
        }
      })
    }
  }
}
