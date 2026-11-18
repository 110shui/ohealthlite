import Foundation
import CoreBluetooth

/// 手表 BLE 协议常量
/// 来源：手表端 com.heytap.accessory (HeyAccessory.apk) 反编译
///   - connectivity/constant/UUIDConstant
///   - connectivity/params/BleConnectionParam.init(type)
///   - dumpsys bluetooth_manager GATT Server Map 实测
enum WatchProtocol {
    // MARK: - GATT 服务（手表作为 GATT Server 暴露）

    /// 主数据服务（Android 通道）
    static let servicePrimary = "0000aa15-0000-1000-8000-00805f9b34fb"
    /// 读 / notify 特征（主服务）
    static let charReadPrimary = "0000aa16-0000-1000-8000-00805f9b34fb"
    /// 写特征（主服务）
    static let charWritePrimary = "0000aa17-0000-1000-8000-00805f9b34fb"
    /// 读特征描述符（主服务）
    static let charDescPrimary = "0000aa18-0000-1000-8000-00805f9b34fb"

    /// 副数据服务（iOS 通道 —— BleConnectionParam.init(type==1) 使用）
    /// 注意：手表固件按连接设备类型动态注册，iOS 连接时预期出现
    static let serviceSecondary = "0000bb15-0000-1000-8000-00805f9b34fb"
    static let charReadSecondary = "0000bb16-0000-1000-8000-00805f9b34fb"
    static let charWriteSecondary = "0000bb17-0000-1000-8000-00805f9b34fb"
    static let charDescSecondary = "0000bb18-0000-1000-8000-00805f9b34fb"

    /// 手表系统级服务（com.heytap.accessory 静态注册，实测 dumpsys 可见）
    /// 特征: 00000001 / 00001001 / 00001004（均带 CCCD）
    static let serviceAFAF = "0000afaf-0000-1000-8000-00805f9b34fb"

    /// accessory SDK 发现服务 / 经典蓝牙 RFCOMM 服务（BtRfConnection）
    static let serviceDiscovery = "a49eaa15-cb06-495c-9f4f-bb80a90cdf00"
    static let serviceDiscoveryAlt = "a49ebb15-cb06-495c-9f4f-bb80a90cdf00"

    /// 扫描用服务集合（任一匹配即认为可能是手表）
    static var scanServices: [CBUUID] {
        [CBUUID(string: serviceDiscovery),
         CBUUID(string: serviceAFAF),
         CBUUID(string: servicePrimary),
         CBUUID(string: serviceSecondary)]
    }

    // MARK: - 已知广播特征（PC 端实测：无名称广播，厂商 ID 0x0006）
    /// 厂商数据前缀（0109...）
    static let mfgCompanyID: UInt16 = 0x0006
}

/// 一条 GATT 特征的快照（用于设备详情展示）
struct GATTCharacteristicSnapshot: Identifiable {
    let id: String
    let uuid: CBUUID
    let properties: [String]
    let value: Data?
}

struct GATTServiceSnapshot: Identifiable {
    let id: String
    let uuid: CBUUID
    let characteristics: [GATTCharacteristicSnapshot]
}
