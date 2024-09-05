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
    var seek: (_ time: CMTime) -> Void
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

                    /// Start playing
                    //                newContinuation.yield(.playing(0))
                    await player.play()

                    /// Observe progress
                    addProgressObserver()

                    /// Wait for till finished
                    let notificationCenter = NotificationCenter.default
                    let didPlayToEnd = AVPlayerItem.didPlayToEndTimeNotification
                    _ = await notificationCenter.notifications(named: didPlayToEnd).first(where: { _ in true })
                    //                try? await Task.sleep(300)
                    newContinuation.yield(.idle)
                    newContinuation.finish()
                } catch {
                    newContinuation.yield(.failed(error))
                    newContinuation.finish()
                }
            }

            newContinuation.onTermination = { [weak self] _ in
                task.cancel()
                self?.removeProgressObserver()
                self?.continuation = nil
            }
            return stream
        }

        func resume() {
            player.play()
            addProgressObserver()
        }

        func pause() {
            removeProgressObserver()
            player.pause()
            continuation?.yield(.paused)
        }

        func setRate(rate: Float) {
            player.rate = rate
        }

        func seek(to time: CMTime) {
            player.seek(to: time)
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
                reportIssue("Set category error \(error.localizedDescription)")
            }
            do {
                try session.setActive(true, options: [.notifyOthersOnDeactivation])
            } catch {
                reportIssue("Set active error \(error.localizedDescription)")
            }
        }

        private func addProgressObserver() {
            let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            progressObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard
                    let self,
                    let duration = self.playerItem?.duration
                else {
                    return
                }

                let totalSeconds = CMTimeGetSeconds(duration)
                let currentSeconds = CMTimeGetSeconds(time)
                let progress = currentSeconds / totalSeconds
                self.continuation?.yield(.playing(PlayerProgress(
                    progress: progress,
                    totalSeconds: totalSeconds,
                    currentSeconds: currentSeconds
                )))
            }
        }

        private func removeProgressObserver() {
            if let token = progressObserver {
                player.removeTimeObserver(token)
                progressObserver = nil
            }
        }

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
