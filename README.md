# OHealthLite — 复刻 OPPO 健康（iOS），直连刷机版小米 Watch 2 Pro LTE

## 项目简介

参考官方 OPPO 健康 iOS App（OHealth 6.11.0）的功能与 UI，用 SwiftUI 复刻一个能通过 **蓝牙 BLE 直连**手表的独立 App。

适配目标：**小米 Watch 2 Pro LTE 国际版刷 OPPO 官方固件**（fingerprint `OPPO/monaco_go/monaco_go:11/.../17.MW2.1.0.1`，OWW261）。

## 构建

### 方式一：GitHub Actions 云构建（无需 Mac）

仓库已配置 `.github/workflows/build-ipa.yml`：推送到 GitHub 后自动在 macOS runner 上编译并产出 **未签名 ipa**（Actions → Artifacts 下载 `OHealthLite-ipa`）。

```bash
# 在 GitHub 创建空仓库后：
cd OHealthLite
git remote add origin https://github.com/<你的用户名>/ohealthlite.git
git push -u origin main
```

未签名 ipa 装机：用 [Sideloadly](https://sideloadly.io) / AltStore / Signum + 免费 Apple ID 重签后安装。

### 方式二：本地 Mac 构建

1. 在 Mac 上安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`），或手动在 Xcode 中新建项目后拖入 `OHealthLite/` 源码目录。
2. 使用 XcodeGen：

```bash
cd OHealthLite
xcodegen generate
open OHealthLite.xcodeproj
```

3. 选中你的 iPhone 真机运行（BLE 需要 NSBluetoothAlwaysUsageDescription，已配置）。

## 协议分析结论（逆向自手表 + 官方 App）

### 手表侧 GATT 服务（dumpsys bluetooth_manager 实测）

| 服务 | 特征 | 说明 |
|---|---|---|
| `0000afaf-...` | `00000001` / `00001001` / `00001004`（均带 CCCD） | 系统级服务，com.heytap.accessory 静态注册 |
| `0000aa15-...` | `aa16`（read/notify）· `aa17`（write）· `aa18`（desc） | **Android 手机数据通道** |
| `bb15`（动态） | `bb16` / `bb17` / `bb18` | **iOS 设备通道**（BleConnectionParam.init(type==1)） |

### 关键来源

- 手表端 `com.heytap.accessory`（HeyAccessory.apk，system/priv-app）反编译：
  - `connectivity/constant/UUIDConstant` — 全部服务/特征 UUID
  - `connectivity/params/BleConnectionParam.init(type)` — Android 用 aa15 组，iOS 用 bb15 组
  - `transport/ProtocolFrameUtils` — 帧协议（协议头 + 分片 + ACK/NAK 控制帧 + 信用流控）
  - `transport/assemble/AFFragmenter` / `Reassembler` — 分片重组
  - `discovery/` — 扫描发现（a49eaa15 / a49ebb15 两个发现服务）
  - `pair/`（180 类）+ `security/` + `AuthenticationDbBean` — 配对认证（**未完成逆向**）
- iOS 官方 OHealth 6.11.0（砸壳版 IPA）分析：
  - `OXBluetooth.framework`（CoreBluetooth 封装）、`DeviceProtocol.framework`（数据协议）、`OLinkAuthenticate.framework`（认证）
  - 字符串已混淆，UUID 以运行时构造，UI 资源完整可参考

### 连接流程（本 App 实现）

1. 扫描：按服务 UUID（a49eaa15 / afaf / aa15 / bb15）或名称（OPPO/Watch）过滤
2. 连接后 `discoverServices`，枚举全部服务与特征（设备页展示）
3. 优先订阅 `bb16`（iOS notify 通道），其次 `aa16`；写通道绑定 `bb17`/`aa17`
4. 数据协议（帧编码/认证握手）预留接口 `WatchBLEManager.send()`，待后续版本接入

### 已知限制（刷机设备特有）

- 手表熄屏时可能停止 BLE 广播，扫描前保持亮屏
- 该固件（17.MW2.1.0.1）的官方配对认证与数据同步对刷机设备不友好，故本 App 先做**直连**，不实现官方 OLink 认证
- ECG 测量 UI 已复刻，但数据采集依赖手表 ECG 通道（该固件下 ECG 传感器通道存在配置问题，波形恒定饱和值 48437.50、lead 恒 0 —— 详见逆向报告）

## 目录结构

```
OHealthLite/
├── project.yml                 # XcodeGen 配置
└── OHealthLite/
    ├── Info.plist
    ├── App/OHealthLiteApp.swift        # 入口 + Tab 结构（健康/心电/设备/日志）
    ├── BLE/
    │   ├── WatchProtocol.swift         # 协议常量（逆向结论）
    │   └── WatchBLEManager.swift       # 扫描/连接/GATT 枚举/notify
    └── Views/
        ├── HomeView.swift              # 首页健康卡片（复刻官方布局）
        ├── DeviceView.swift            # 设备连接 + GATT 详情
        └── ECGView.swift               # 心电测量 UI（复刻官方圆环+倒计时）
```

## 研究用途声明

本项目仅用于个人研究与学习，不作为医疗诊断依据。
