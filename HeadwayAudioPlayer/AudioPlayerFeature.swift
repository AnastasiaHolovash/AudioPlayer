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

    @ObservableState
    struct State {
        let summary = Summary.zeroToOne
        
    }

    enum Action {

    }

    @Dependency(\.audioPlayerService) var audioPlayerService

    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
                
            }
        }
    }

}
