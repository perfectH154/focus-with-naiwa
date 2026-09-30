为浅色和深色外观分别准备一段陪伴动画：浅色背景的视频命名为 `FocusCompanionLight.mov`，深色背景的视频命名为 `FocusCompanionDark.mov`。视频不需要透明通道；app 会根据系统外观自动选择对应文件并循环播放。两段视频都已加入 Xcode 的 FocusCompanion target「Copy Bundle Resources」构建阶段。不要把整个 Resources 文件夹作为 folder reference 资源加入。

也支持 `FocusCompanion.mp4`，但普通 MP4 通常没有透明通道。建议先试 8–12 秒、1:1 或 4:3、24 fps、无对白；固定机位、动作幅度小，首尾尽量同构，便于循环。
