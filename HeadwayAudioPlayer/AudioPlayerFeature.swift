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
        var currentKeyPoint: Summary.KeyPoint
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
        case seekToTapped(time: Float)
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
                guard let audioURL = state.currentKeyPoint.audioURL else {
                    reportIssue("Invalid audio UR")
                    return .none
                }

                return .run { send in
                    for await playerState in audioPlayerService.play(url: audioURL) {
                        print("!!! changed \(playerState)")
                        await send(.setPlayerState(playerState))
                    }
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

            case .seekToTapped(time: let time):
                return .none
            
            case .nextKeyPointTapped:
                guard state.currentKeyPoint.orderNumber < state.summary.keyPoints.count - 1 else {
                    return .none
                }

                state.currentKeyPoint = state.summary.keyPoints[state.currentKeyPoint.orderNumber + 1]
                return .none
            
            case .previousKeyPointTapped:
                guard state.currentKeyPoint.orderNumber > 0 else {
                    return .none
                }

                state.currentKeyPoint = state.summary.keyPoints[state.currentKeyPoint.orderNumber - 1]
                return .none

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

}
