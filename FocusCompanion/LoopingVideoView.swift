import AVFoundation
import SwiftUI
import UIKit

struct LoopingVideoView: UIViewRepresentable {
    let url: URL
    let isPlaying: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .clear
        let player = AVQueuePlayer()
        let item = AVPlayerItem(url: url)
        let looper = AVPlayerLooper(player: player, templateItem: item)

        player.isMuted = true
        player.actionAtItemEnd = .none
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.isOpaque = false
        view.playerLayer.backgroundColor = UIColor.clear.cgColor

        context.coordinator.player = player
        context.coordinator.looper = looper
        if isPlaying {
            player.play()
        }

        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        guard let player = context.coordinator.player else { return }
        if isPlaying {
            if player.timeControlStatus != .playing {
                player.play()
            }
        } else {
            player.pause()
        }
    }

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.player = nil
        coordinator.looper = nil
    }

    final class Coordinator {
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
    }
}

final class PlayerContainerView: UIView {
    override var isOpaque: Bool {
        get { false }
        set { }
    }

    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
