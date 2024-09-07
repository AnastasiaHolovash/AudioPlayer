//
//  PlayerState.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import Foundation

enum PlayerState {
    case idle
    case loading
    case playing(PlayerProgress)
    case paused(PlayerProgress)
    case failed(Error)
}

extension PlayerState {

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

    var isPaused: Bool {
        switch self {
        case .paused:
            true

        case .idle,
             .loading,
             .playing,
             .failed:
            false
        }
    }

    var isLoading: Bool {
        switch self {
        case .loading:
            true

        case .idle,
             .playing,
             .paused,
             .failed:
            false
        }
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
        switch self {
        case .playing,
             .paused:
            true

        case .idle,
             .loading,
             .failed:
            false
        }
    }
    
}
