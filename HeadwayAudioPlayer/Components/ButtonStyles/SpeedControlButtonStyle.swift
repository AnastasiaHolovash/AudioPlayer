//
//  SpeedControlButtonStyle.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import SwiftUI

struct SpeedControlButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(Color.playerLightGray)

            configuration.label
                .foregroundStyle(.black)
        }
    }

}
