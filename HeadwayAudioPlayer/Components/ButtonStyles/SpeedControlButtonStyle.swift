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
                .foregroundColor(Color.gray.opacity(0.2))

            configuration.label
                .foregroundColor(.black)
        }
    }

}
