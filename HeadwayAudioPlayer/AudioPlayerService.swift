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
                    try await player.readyToPlay()
                    await player.play()
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            for await value in self.player.periodicTimeUpdates {
                                guard let state = self.buildState(
                                    duration: value.duration,
                                    time: value.time,
                                    controlStatus: self.player.controlStatus
                                ) else {
                                    return
                                }

                                newContinuation.yield(state)
                            }
                        }
                        group.addTask {
                            for await value in self.player.statusUpdates {
                                guard let currentItemProgress = self.player.currentItemProgress,
                                      let state = self.buildState(
                                        duration: currentItemProgress.duration,
                                        time: currentItemProgress.time,
                                        controlStatus: value
                                    )
                                else {
                                    return
                                }

                                newContinuation.yield(state)
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
        }

        func pause() {
            player.pause()
        }

//        func stop

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

        private func buildState(
            duration: CMTime,
            time: CMTime,
            controlStatus: ControlStatus
        ) -> PlayerState? {
            guard duration.isNumeric, time.isNumeric else {
                return nil
            }

            let playerProgress = PlayerProgress(
                totalSeconds: CMTimeGetSeconds(duration),
                currentSeconds: CMTimeGetSeconds(time)
            )

            return switch controlStatus {
            case .playing:
                .playing(playerProgress)

            case .paused:
                .paused(playerProgress)
            }
        }
    }
}

extension AudioPlayerService {

    enum ControlStatus {
        case playing
        case paused
    }

    struct CurrentItemProgress {
        let duration: CMTime
        let time: CMTime
    }

}

extension AVPlayer {

    nonisolated var periodicTimeUpdates: AsyncStream<AudioPlayerService.CurrentItemProgress> {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let (stream, continuation) = AsyncStream<AudioPlayerService.CurrentItemProgress>.makeStream()
        let progressObserver = addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self,
                  let currentItemProgress
            else {
                return
            }

            continuation.yield(currentItemProgress)
        }
        continuation.onTermination = { [weak self] _ in
            self?.removeTimeObserver(progressObserver)
            print("!!! periodicTimeUpdates canceleld")
        }
        return stream
    }

    nonisolated var statusUpdates: AsyncStream<AudioPlayerService.ControlStatus> {
        let (stream, continuation) = AsyncStream<AudioPlayerService.ControlStatus>.makeStream()
        let observation = observe(\.timeControlStatus, options: [.new, .old]) { playerItem, change in
            continuation.yield(playerItem.controlStatus)
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

private extension AVPlayer {

    var controlStatus: AudioPlayerService.ControlStatus {
        switch timeControlStatus {
        case .paused:
            print("Media Paused")
            return .paused

        case .playing:
            print("Media Playing")
            return .playing

        case .waitingToPlayAtSpecifiedRate:
            print("Media Waiting to play at specific rate!")
            return .playing

        @unknown default:
            fatalError()
        }
    }

    var currentItemProgress: AudioPlayerService.CurrentItemProgress? {
        guard let currentItem else {
            return nil
        }

        return AudioPlayerService.CurrentItemProgress(
            duration: currentItem.duration,
            time: currentItem.currentTime()
        )
    }

}
