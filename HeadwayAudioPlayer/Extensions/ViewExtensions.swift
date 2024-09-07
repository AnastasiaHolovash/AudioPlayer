//
//  ViewExtensions.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 07.09.2024.
//

import SwiftUI

extension View {

    @ViewBuilder
    func modify<Content: View>(
        @ViewBuilder content: (Self) -> Content
    ) -> some View {
        content(self)
    }

}
