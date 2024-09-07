//
//  DoubleExtensions.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 07.09.2024.
//

import Foundation

extension Double {

    var formattedTime: String {
        let minutes = Int(self) / 60
        let remainingSeconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

}
