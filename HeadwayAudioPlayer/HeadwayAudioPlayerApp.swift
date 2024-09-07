//
//  HeadwayAudioPlayerApp.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 04.09.2024.
//

import SwiftUI
import ComposableArchitecture

@main
struct HeadwayAudioPlayerApp: App {

    static let store = Store(
        initialState: AudioPlayerFeature.State(currentKeyPointID: Summary.zeroToOne.keyPoints.first!.id),
        reducer: {
            AudioPlayerFeature()
        }
    )

    var body: some Scene {
        WindowGroup {
            AudioPlayerView(store: HeadwayAudioPlayerApp.store)
        }
    }

}
