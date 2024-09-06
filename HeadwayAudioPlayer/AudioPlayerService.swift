//
//  AudioPlayerService.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import Foundation
import AVFoundation
import ComposableArchitecture

@DependencyClient
struct AudioPlayerService {
    var play: (_ url: URL) -> AsyncStream<PlayerState> = { _ in .never }
    var pause: () -> Void
    var resume: () -> Void
    var setRate: (_ rate: Float) -> Void
    var seek: (_ time: Float64) async -> Void
}

extension DependencyValues {

    var audioPlayerService: AudioPlayerService {
        get { self[AudioPlayerServiceKey.self] }
        set { self[AudioPlayerServiceKey.self] = newValue }
    }

    private enum AudioPlayerServiceKey: DependencyKey {
        static let liveValue: AudioPlayerService = .live()
        static let testValue = AudioPlayerService()
    }

}

extension AudioPlayerService {

    static func live() -> AudioPlayerService {
        let liveHelper = LiveHelper()
        return AudioPlayerService(
            play: liveHelper.play,
            pause: liveHelper.pause,
            resume: liveHelper.resume,
            setRate: liveHelper.setRate,
            seek: liveHelper.seek
        )
    }

}

extension AudioPlayerService {

    final class LiveHelper: NSObject {
        private var player = AVPlayer()
        private var playerItem: AVPlayerItem?
        private var progressObserver: Any?
        private var continuation: AsyncStream<PlayerState>.Continuation?

        func play(url: URL) -> AsyncStream<PlayerState> {
            if let continuation {
                continuation.yield(.idle)
                continuation.finish()
            }

            setupSession()
            let (stream, newContinuation) = AsyncStream<PlayerState>.makeStream()
            continuation = newContinuation
            playerItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: playerItem)
            player.seek(to: .zero)

            newContinuation.yield(.loading)

            let task = Task {
                do {
                    /// Wait for loading
                    try await player.readyToPlay()
                    await player.play()
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            for await value in self.player.periodicTimeUpdates {
                                self.player.timeControlStatus
                                newContinuation.yield(.playing(value))
                            }
                        }
                        group.addTask {
                            for await value in self.player.statusUpdates {
                                print("!! value: \(value)")
                                print("!! value: \(value)")
                            }
                        }
                        group.addTask {
                            let notificationCenter = NotificationCenter.default
                            let didPlayToEnd = AVPlayerItem.didPlayToEndTimeNotification
                            _ = await notificationCenter.notifications(named: didPlayToEnd).makeAsyncIterator().next()
                        }
                        group.addTask {
                            let notificationCenter = NotificationCenter.default
                            let didPlayToEnd = AVPlayerItem.failedToPlayToEndTimeNotification
                            _ = await notificationCenter.notifications(named: didPlayToEnd).makeAsyncIterator().next()
                        }
                        await group.first(where: { true })
                    }
                    newContinuation.yield(.idle)
                    newContinuation.finish()
                } catch {
                    newContinuation.yield(.failed(error))
                    newContinuation.finish()
                }
            }
            newContinuation.onTermination = { [weak self] _ in
                task.cancel()
                self?.player.pause()
                self?.player.replaceCurrentItem(with: nil)
                self?.player.seek(to: .zero)
                self?.continuation = nil
            }
            return stream
        }

        func resume() {
            player.play()
//            addProgressObserver()
        }

        func pause() {
//            removeProgressObserver()
            player.pause()
            continuation?.yield(.paused)
        }

        func setRate(rate: Float) {
            player.rate = rate
        }

        func seek(to time: Float64) async {
            let cmTime = CMTimeMakeWithSeconds(time, preferredTimescale: 600)
            await player.seek(to: cmTime)
        }

        private func setupSession() {
            let options: AVAudioSession.CategoryOptions = [
                .allowAirPlay,
                .allowBluetooth,
                .allowBluetoothA2DP,
                .duckOthers,
                .interruptSpokenAudioAndMixWithOthers
            ]
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, options: options)
            } catch {
                print("Set category error \(error.localizedDescription)")
            }
            do {
                try session.setActive(true, options: [.notifyOthersOnDeactivation])
            } catch {
                print("Set active error \(error.localizedDescription)")
            }
        }
    }
}

enum PlayerStatus {
    case playing
    case paused
}

extension AVPlayer {
    nonisolated var periodicTimeUpdates: AsyncStream<PlayerProgress> {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let (stream, continuation) = AsyncStream<PlayerProgress>.makeStream()
        let progressObserver = addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self, let duration = currentItem?.duration else {
                return
            }

            let totalSeconds = CMTimeGetSeconds(duration)
            let currentSeconds = CMTimeGetSeconds(time)
            let progress = currentSeconds / totalSeconds
            continuation.yield(
                PlayerProgress(
                    progress: progress,
                    totalSeconds: totalSeconds,
                    currentSeconds: currentSeconds
                )
            )
        }
        continuation.onTermination = { [weak self] _ in
            self?.removeTimeObserver(progressObserver)
            print("!!! periodicTimeUpdates canceleld")
        }
        return stream
    }

    nonisolated var statusUpdates: AsyncStream<PlayerStatus> {
        let (stream, continuation) = AsyncStream<PlayerStatus>.makeStream()
        let observation = observe(\.timeControlStatus, options: [.new, .old]) { playerItem, change in
            switch playerItem.timeControlStatus {
            case .paused:
                continuation.yield(.paused)
                print("Media Paused")
            case .playing:
                continuation.yield(.playing)
                print("Media Playing")
            case .waitingToPlayAtSpecifiedRate:
                print("Media Waiting to play at specific rate!")
                continuation.yield(.playing)
            @unknown default:
                fatalError()
            }
        }
        continuation.onTermination = { _ in
            observation.invalidate()
        }
        return stream
    }
}

private extension AVPlayer {

    enum FeetureAVPlayerError: Error {
        case failedToStartAudio
    }

    func readyToPlay() async throws {
        try await withCheckedThrowingContinuation { continuation in
            let observer = currentItem?.observe(\.status) { [weak self] _, _ in
                self?.checkPlayerAndItemReady(continuation: continuation)
            }
            continuation.resume(returning: ())
            observer?.invalidate()
        }
    }

    private func checkPlayerAndItemReady(continuation: CheckedContinuation<Void, Error>) {
        if currentItem?.status == .readyToPlay {
            continuation.resume()
        } else {
            continuation.resume(throwing: FeetureAVPlayerError.failedToStartAudio)
        }
    }

}


enum PlayerState {
    case idle
    case loading
    case playing(PlayerProgress)
    case paused
    case failed(Error)

    var isPlaying: Bool {
        switch self {
        case .playing:
            true
        
        case .idle,
             .loading,
             .paused,
             .failed:
            false
        }
    }

    var progress: PlayerProgress {
        switch self {
        case let .playing(progress):
            progress

        case .idle,
             .loading,
             .paused,
             .failed:
            PlayerProgress(
                progress: .zero,
                totalSeconds: .zero,
                currentSeconds: .zero
            )
        }
    }
}

enum PlayerState2 {
    case loading
    case playing(PlayerProgress)
    case paused(PlayerProgress)
    case failed
}

struct PlayerProgress {
    let progress: CGFloat
    let totalSeconds: Float64
    let currentSeconds: Float64
}
