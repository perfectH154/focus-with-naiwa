# Focus with naiwa · 奶蛙专注

一个使用 SwiftUI 编写的 iOS 专注计时器。界面会跟随系统浅色/深色外观切换；

## 功能

- 自选 1–180 分钟的专注时长。
- 专注与休息循环：每轮专注后短休息，每完成四轮后进入长休息。
- 完成专注可获得一颗奶蛋，并在月历时间轴中查看专注和休息记录。
- App 进入后台时结束并重置当前一轮专注。

## 下载与安装

在 GitHub 仓库页面选择 **Code → Download ZIP** 下载源代码，解压后用 Xcode 打开 `FocusCompanion.xcodeproj`。连接 iPhone，在 Xcode 的 **Signing & Capabilities** 中选择你自己的 Team；如有 Bundle Identifier 冲突，也在这里改成自己的标识符。选择手机作为运行目标并点击 Run。

项目的最低部署版本是 iOS 17。首次运行需要在 Mac 上安装 Xcode，并用数据线或无线调试连接 iPhone。

### 关于直接在 iPhone 上安装

GitHub 提供的是可下载的源代码，不是点开网页就能安装的 iOS 应用。iOS 应用需要 Apple 签名：个人开发者可用 Xcode 把 App 安装到自己的设备；要让其他用户便捷安装，通常需要通过 TestFlight 邀请测试，或提交 App Store。当前仓库尚未提供面向公众的签名安装包。

## 开发

1. 打开 `FocusCompanion.xcodeproj`。
2. 选择 `FocusCompanion` scheme 和 iPhone 模拟器或已连接的 iPhone。
3. 在 **Signing & Capabilities** 选择自己的 Team，再运行。

## 视频资源

视频位于 `FocusCompanion/Resources/`：

- `FocusCompanionLight.mov`：浅色外观。
- `FocusCompanionDark.mov`：深色外观。

替换视频时保留文件名即可。Xcode target 已把两段视频加入 **Copy Bundle Resources**，不需要再把整个 Resources 文件夹作为 folder reference 加入工程。
