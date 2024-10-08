//
//  PlayerButtonStyle.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import SwiftUI

struct PlayerButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .foregroundStyle(
                    Color.gray
                        .opacity(configuration.isPressed ? 0.3 : 0)
                )

            configuration.label
                .opacity(isEnabled ? 1 : 0.5)
                .animation(nil, value: configuration.isPressed)
        }
        .frame(width: 56, height: 56)
        .scaleEffect(configuration.isPressed ? 0.9 : 1)
        .animation(.easeOut(duration: 0.3), value: configuration.isPressed)
    }

}
