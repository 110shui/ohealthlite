import MediaPlayer
import UIKit

/// 短视频遥控：把手表发来的 VOLUP/VOLDOWN 转成系统音量变化。
/// 抖音开启「音量键翻页」（我→设置→通用设置）后，音量+/− 即翻页。
final class RemoteControlManager {
    static let shared = RemoteControlManager()

    private var volumeView: MPVolumeView?
    private var slider: UISlider?

    /// 应用启动后挂载一个隐藏的 MPVolumeView（必须在 window 层级内才能控制系统音量）
    func attach(to view: UIView) {
        let vv = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 10, height: 10))
        view.addSubview(vv)
        volumeView = vv
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.slider = vv.subviews.compactMap { $0 as? UISlider }.first
        }
    }

    func handle(_ cmd: String) {
        switch cmd {
        case "VOLUP", "VOLUP2":
            change(delta: 0.125)   // 一次音量格
        case "VOLDOWN":
            change(delta: -0.125)
        default:
            break
        }
    }

    private func change(delta: Float) {
        guard let slider else {
            // 重试获取 slider
            if let vv = volumeView {
                slider = vv.subviews.compactMap { $0 as? UISlider }.first
            }
            return
        }
        let target = min(1.0, max(0.0, slider.value + delta))
        slider.setValue(target, animated: false)
        // 触发系统音量变更（产生与音量键等效的系统事件）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.slider?.sendActions(for: .valueChanged)
        }
    }
}
