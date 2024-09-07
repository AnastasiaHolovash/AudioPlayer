//
//  AudioPlayerFeature.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import ComposableArchitecture
import Foundation

enum AppConstants {
    static let seekForwardSeconds: Float64 = 10
    static let seekBackwardSeconds: Float64 = 5
}

@Reducer
struct AudioPlayerFeature {

    @ObservableState
    struct State {
        let summary = Summary.zeroToOne
        var currentKeyPointID: Int
        var playerState: PlayerState = .idle
        var playbackSpeed: Float = 1
        var currentSeconds: Float64 = .zero
        var isEditing: Bool = false
    }

    enum Action: BindableAction {
        case playTapped
        case pauseTapped
        case seekForwardTapped
        case seekBackwardTapped
        case nextKeyPointTapped
        case previousKeyPointTapped
        case speedSelected(speed: Float)
        case seekEnded

        case setPlayerState(PlayerState)
        case setIsEditing(Bool)
        case binding(BindingAction<State>)
    }

    @Dependency(\.audioPlayerService) var audioPlayerService

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce<State, Action> { state, action in
            switch action {
            case .playTapped:
                print("--- state.playerState.isPaused: \(state.playerState.isPaused)")
                if state.playerState.isPaused {
                    audioPlayerService.resume()
                    return .none
                } else {
                    return startPlaying(state: &state)
                }

            case .pauseTapped:
                return .run { _ in
                    audioPlayerService.pause()
                }

            case .seekForwardTapped:
                let currentSecondsAfterChange = state.currentSeconds + AppConstants.seekForwardSeconds
                let secondsToSeekTo = currentSecondsAfterChange >= state.playerState.progress.totalSeconds
                    ? state.playerState.progress.totalSeconds
                    : currentSecondsAfterChange
                return .run { _ in
                    await audioPlayerService.seek(time: secondsToSeekTo)
                }

            case .seekBackwardTapped:
                let currentSecondsAfterChange = state.currentSeconds - AppConstants.seekBackwardSeconds
                let secondsToSeekTo = currentSecondsAfterChange <= .zero
                    ? .zero
                    : currentSecondsAfterChange
                return .run { _ in
                    await audioPlayerService.seek(time: secondsToSeekTo)
                }
            
            case .nextKeyPointTapped:
                guard let newKeyPointID = state.summary.keyPointID(nextTo: state.currentKeyPointID) else {
                    return .none
                }

                state.currentKeyPointID = newKeyPointID

                if state.playerState.isPlaying {
                    return startPlaying(state: &state)
                } else {
                    state.playerState = .idle
                    state.currentSeconds = .zero
                    return .cancel(id: CancelID.audioPlayer)
                }

            case .previousKeyPointTapped:
                guard let newKeyPointID = state.summary.keyPointID(previousTo: state.currentKeyPointID) else {
                    return .none
                }

                state.currentKeyPointID = newKeyPointID

                if state.playerState.isPlaying {
                    return startPlaying(state: &state)
                } else {
                    state.playerState = .idle
                    state.currentSeconds = .zero
                    return .cancel(id: CancelID.audioPlayer)
                }

            case let .speedSelected(speed):
                state.playbackSpeed = speed
                return .run { _ in
                    audioPlayerService.setRate(rate: speed)
                }

            case let .setPlayerState(playerState):
                state.playerState = playerState
                if !state.isEditing {
                    state.currentSeconds = playerState.progress.currentSeconds
                }
                return .none

            case let .setIsEditing(isEditing):
                if !isEditing {
                    return .run { [currentSeconds = state.currentSeconds] send in
                        await audioPlayerService.seek(time: currentSeconds)
                        await send(.seekEnded)
                    }
                } else {
                    state.isEditing = isEditing
                    return .none
                }

            case .seekEnded:
                state.isEditing = false
                return .none

            case .binding(\.currentSeconds):
                print("--- state.currentSeconds: \(state.currentSeconds)")
                return .none

            case .binding:
                return .none
            }
        }
    }

    private func startPlaying(state: inout State) -> Effect<Action> {
        guard let audioURL = state.summary.keyPoints[id: state.currentKeyPointID]?.audioURL else {
            reportIssue("Invalid audio UR")
            return .none
        }

        return .run { send in
            for await playerState in audioPlayerService.play(url: audioURL) {
                await send(.setPlayerState(playerState))
            }
        }
        .cancellable(id: CancelID.audioPlayer, cancelInFlight: true)
    }

    enum CancelID {
        case audioPlayer
    }
}
