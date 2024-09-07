//
//  AudioPlayerService+Live.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 07.09.2024.
//

import AVFoundation
import IssueReporting
import ConcurrencyExtras

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
        private let player = AVPlayer()
        private let currentRate: LockIsolated<Float> = LockIsolated(1)
        private var continuation: AsyncStream<PlayerState>.Continuation?

        func play(url: URL) -> AsyncStream<PlayerState> {
            if let continuation {
                continuation.yield(.idle)
                continuation.finish()
            }

            setupSession()
            let (stream, newContinuation) = AsyncStream<PlayerState>.makeStream()
            continuation = newContinuation
            let playerItem = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: playerItem)
            player.seek(to: .zero)

            newContinuation.yield(.loading)

            let task = Task {
                await player.play()
                await MainActor.run {
                    player.rate = currentRate.value
                }
                let result = await withTaskGroup(of: Bool.self) { group in
                    group.addTask {
                        for await value in self.player.periodicTimeUpdates {
                            guard let state = self.buildState(
                                duration: value.duration,
                                time: value.time,
                                controlStatus: self.player.controlStatus
                            ) else {
                                continue
                            }

                            newContinuation.yield(state)
                        }
                        return true
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
                                continue
                            }

                            newContinuation.yield(state)
                        }
                        return true
                    }
                    group.addTask {
                        _ = await NotificationCenter.default
                            .notifications(named: AVPlayerItem.didPlayToEndTimeNotification)
                            .makeAsyncIterator()
                            .next()
                        return true
                    }
                    group.addTask {
                        _ = await NotificationCenter.default
                            .notifications(named: AVPlayerItem.failedToPlayToEndTimeNotification)
                            .makeAsyncIterator()
                            .next()
                        return false
                    }

                    defer { group.cancelAll() }
                    return await group.next() ?? false
                }
                newContinuation.yield(result ? .finished : .idle)
                newContinuation.finish()
            }
            newContinuation.onTermination = { [weak self] _ in
                task.cancel()
                self?.player.replaceCurrentItem(with: nil)
                self?.player.seek(to: .zero)
                self?.continuation = nil
            }
            return stream
        }

        func resume() {
            player.play()
            player.rate = currentRate.value
        }

        func pause() {
            player.pause()
        }

        func setRate(rate: Float) {
            currentRate.setValue(rate)
            player.rate = rate
        }

        func seek(to time: Double) async {
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
                reportIssue(error)
            }
            do {
                try session.setActive(true, options: [.notifyOthersOnDeactivation])
            } catch {
                reportIssue(error)
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

private extension AVPlayer {

    nonisolated var periodicTimeUpdates: AsyncStream<AudioPlayerService.LiveHelper.CurrentItemProgress> {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let (stream, continuation) = AsyncStream<AudioPlayerService.LiveHelper.CurrentItemProgress>.makeStream()
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
        }
        return stream
    }

    nonisolated var statusUpdates: AsyncStream<AudioPlayerService.LiveHelper.ControlStatus> {
        let (stream, continuation) = AsyncStream<AudioPlayerService.LiveHelper.ControlStatus>.makeStream()
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

    var controlStatus: AudioPlayerService.LiveHelper.ControlStatus {
        switch timeControlStatus {
        case .paused:
            return .paused

        case .playing:
            return .playing

        case .waitingToPlayAtSpecifiedRate:
            return .playing

        @unknown default:
            fatalError()
        }
    }

    var currentItemProgress: AudioPlayerService.LiveHelper.CurrentItemProgress? {
        guard let currentItem else {
            return nil
        }

        return AudioPlayerService.LiveHelper.CurrentItemProgress(
            duration: currentItem.duration,
            time: currentItem.currentTime()
        )
    }

}

extension AudioPlayerService.LiveHelper {

    enum ControlStatus {
        case playing
        case paused
    }

    struct CurrentItemProgress {
        let duration: CMTime
        let time: CMTime
    }

}
