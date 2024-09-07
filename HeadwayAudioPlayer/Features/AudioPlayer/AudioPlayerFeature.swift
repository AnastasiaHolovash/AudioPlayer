//
//  AudioPlayerFeature.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import ComposableArchitecture
import Foundation

@Reducer
struct AudioPlayerFeature {

    @CasePathable
    enum Destination {
        case playbackSpeed
    }

    @ObservableState
    struct State {
        let summary = Summary.zeroToOne
        var currentKeyPointID: Int
        var playerState: PlayerState = .idle
        var playbackSpeed: Float = 1
        var currentSeconds: Double = .zero
        var isCurrentSecondsEditing: Bool = false
        var destination: Destination?
    }

    enum Action: ViewAction {
        enum View: BindableAction {
            case playTapped
            case pauseTapped
            case seekForwardTapped
            case seekBackwardTapped
            case nextKeyPointTapped
            case previousKeyPointTapped
            case playbackSpeedTapped
            case setCurrentSecondsIsEditing(Bool)
            case binding(BindingAction<State>)
        }

        enum Local {
            case seekEnded
            case setPlayerState(PlayerState)
        }

        case view(View)
        case local(Local)
    }

    @Dependency(\.audioPlayerService) var audioPlayerService

    var body: some ReducerOf<Self> {
        BindingReducer(action: \.view)

        Reduce<State, Action> { state, action in
            switch action {
            case let .view(viewAction):
                return reduceView(state: &state, action: viewAction)

            case let .local(localAction):
                return reduceLocal(state: &state, action: localAction)
            }
        }
    }

}

private extension AudioPlayerFeature {

    func reduceView(state: inout State, action: Action.View) -> Effect<Action> {
        switch action {
        case .playTapped:
            if state.playerState.isPaused {
                audioPlayerService.resume()
                return .none
            } else {
                return startPlaying(state: &state)
            }

        case .pauseTapped:
            audioPlayerService.pause()
            return .none

        case .seekForwardTapped:
            let currentSecondsAfterChange = state.currentSeconds + Constants.seekForwardSeconds
            let secondsToSeekTo = currentSecondsAfterChange >= state.playerState.progress.totalSeconds
            ? state.playerState.progress.totalSeconds
            : currentSecondsAfterChange
            return .run { _ in
                await audioPlayerService.seek(time: secondsToSeekTo)
            }

        case .seekBackwardTapped:
            let currentSecondsAfterChange = state.currentSeconds - Constants.seekBackwardSeconds
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
            return handleNewKeyPointID(state: &state, newKeyPointID: newKeyPointID)

        case .previousKeyPointTapped:
            guard let newKeyPointID = state.summary.keyPointID(previousTo: state.currentKeyPointID) else {
                return .none
            }
            return handleNewKeyPointID(state: &state, newKeyPointID: newKeyPointID)

        case .playbackSpeedTapped:
            state.destination = .playbackSpeed
            return .none

        case let .setCurrentSecondsIsEditing(isEditing):
            if !isEditing {
                return .run { [currentSeconds = state.currentSeconds] send in
                    await audioPlayerService.seek(time: currentSeconds)
                    await send(.local(.seekEnded))
                }
            } else {
                state.isCurrentSecondsEditing = isEditing
                return .none
            }

        case .binding(\.playbackSpeed):
            audioPlayerService.setRate(rate: state.playbackSpeed)
            return .none

        case .binding:
            return .none
        }
    }

    func reduceLocal(state: inout State, action: Action.Local) -> Effect<Action> {
        switch action {
        case let .setPlayerState(playerState):
            state.playerState = playerState
            if !state.isCurrentSecondsEditing {
                state.currentSeconds = playerState.progress.currentSeconds
            }
            return .none

        case .seekEnded:
            state.isCurrentSecondsEditing = false
            return .none
        }
    }

    func handleNewKeyPointID(state: inout State, newKeyPointID: Int) -> Effect<Action> {
        state.currentKeyPointID = newKeyPointID

        if state.playerState.isPlaying {
            return startPlaying(state: &state)
        } else {
            state.playerState = .idle
            state.currentSeconds = .zero
            return .cancel(id: CancelID.audioPlayer)
        }
    }

    func startPlaying(state: inout State) -> Effect<Action> {
        guard let audioURL = state.summary.keyPoints[id: state.currentKeyPointID]?.audioURL else {
            reportIssue("Invalid audio UR")
            return .none
        }

        return .run { send in
            for await playerState in audioPlayerService.play(url: audioURL) {
                await send(.local(.setPlayerState(playerState)))
            }
        }
        .cancellable(id: CancelID.audioPlayer, cancelInFlight: true)
    }

}

private extension AudioPlayerFeature {

    enum CancelID {
        case audioPlayer
    }

    enum Constants {
        static let seekForwardSeconds: Double = 10
        static let seekBackwardSeconds: Double = 5
    }

}
