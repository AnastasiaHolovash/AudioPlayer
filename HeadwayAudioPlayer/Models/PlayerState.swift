//
//  PlayerState.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import Foundation
import CasePaths

@CasePathable
enum PlayerState {
    case idle
    case loading
    case playing(PlayerProgress)
    case paused(PlayerProgress)
    case failed
}

extension PlayerState {

    var isPlaying: Bool {
        self.is(\.playing)
    }

    var isPaused: Bool {
        self.is(\.paused)
    }

    var isLoading: Bool {
        self.is(\.loading)
    }

    var progress: PlayerProgress {
        switch self {
        case let .playing(progress),
             let .paused(progress):
            progress

        case .idle,
             .loading,
             .failed:
            PlayerProgress(
                totalSeconds: 1,
                currentSeconds: .zero
            )
        }
    }

    var hasProgress: Bool {
        isPlaying || isPaused
    }
    
}
