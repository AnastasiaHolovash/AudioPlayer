//
//  SpeedButton.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import SwiftUI

struct SpeedButton: View {

    let label: String
    let speed: Float
    @Binding var playbackSpeed: Float

    var body: some View {
        Button {
            playbackSpeed = speed
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .medium))
        }
        .buttonStyle(SpeedControlButtonStyle())
        .frame(height: 36)
    }

}
