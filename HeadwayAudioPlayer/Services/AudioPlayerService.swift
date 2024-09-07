//
//  AudioPlayerService.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import Foundation
import Dependencies
import DependenciesMacros

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
