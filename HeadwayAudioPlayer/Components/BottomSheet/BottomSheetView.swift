//
//  BottomSheetView.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import SwiftUI

struct BottomSheetView: View {

    @State private var bottomSheetIsVisible = false
    @State private var dragOffset = CGFloat.zero

    @Binding private var isPresented: Bool
    private let playbackSpeedSelected: (Float) -> Void
    private let playbackSpeed: Float

    init(
        playbackSpeed: Float,
        isPresented: Binding<Bool>,
        playbackSpeedSelected: @escaping (Float) -> Void
    ) {
        self._isPresented = isPresented
        self.playbackSpeedSelected = playbackSpeedSelected
        self.playbackSpeed = playbackSpeed
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if bottomSheetIsVisible {
                backgroundView
                    .zIndex(1)

                contentView
                    .zIndex(2)

            }
        }
        .ignoresSafeArea()
        .onAppear {
            animatedAppear()
        }
    }

    private var contentView: some View {
        PlaybackSpeedView(
            playbackSpeed: playbackSpeed, 
            playbackSpeedSelected: playbackSpeedSelected,
            continueTapped: { animatedDisappear() }
        )
        .transition(.move(edge: .bottom))
        .offset(y: dragOffset)
        .gesture(DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                if value.translation.height > 50 {
                    animatedDisappear()
                } else {
                    withAnimation {
                        dragOffset = 0
                    }
                }
            }
        )
        .onDisappear {
            isPresented = false
        }
    }
    private var backgroundView: some View {
        Color(.black)
            .opacity(0.15)
            .onTapGesture {
                animatedDisappear()
            }
            .transition(.opacity)
            .ignoresSafeArea()
    }

    private func animatedAppear() {
        withAnimation(.spring(
            response: 0.4,
            dampingFraction: 0.8,
            blendDuration: 2
        )) {
            bottomSheetIsVisible = true
        }
    }

    private func animatedDisappear() {
        withAnimation {
            bottomSheetIsVisible = false
        }
    }

}

#Preview {
    BottomSheetView(
        playbackSpeed: 1,
        isPresented: .constant(true),
        playbackSpeedSelected: { _ in }
    )
}
