//
//  PlaybackSpeedView.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import SwiftUI

struct PlaybackSpeedView: View {

    @State private var playbackSpeed: Float
    private let playbackSpeedSelected: (Float) -> Void
    private let continueTapped: () -> Void

    init(
        playbackSpeed: Float,
        playbackSpeedSelected: @escaping (Float) -> Void,
        continueTapped: @escaping () -> Void
    ) {
        self.playbackSpeed = playbackSpeed
        self.playbackSpeedSelected = playbackSpeedSelected
        self.continueTapped = continueTapped
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Playback speed")
                    .font(.headline)

                Spacer(minLength: .zero)
            }

            HStack(spacing: 20) {
                Button {
                    if playbackSpeed > 0.5 { playbackSpeed -= 0.1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 18))
                }
                .buttonStyle(SpeedControlButtonStyle())
                .frame(width: 48, height: 48)

                Text(String(format: "%.1fx", playbackSpeed))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)

                Button {
                    if playbackSpeed < 2.0 { playbackSpeed += 0.1 }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18))
                }
                .buttonStyle(SpeedControlButtonStyle())
                .frame(width: 48, height: 48)
            }
            .padding(.vertical, 20)

            sliderView

            HStack(spacing: 8) {
                SpeedButton(label: "0.8x", speed: 0.8, playbackSpeed: $playbackSpeed)
                SpeedButton(label: "Normal", speed: 1.0, playbackSpeed: $playbackSpeed)
                SpeedButton(label: "1.2x", speed: 1.2, playbackSpeed: $playbackSpeed)
                SpeedButton(label: "1.5x", speed: 1.5, playbackSpeed: $playbackSpeed)
            }

            Button {
                continueTapped()
            } label: {
                Text("Continue")
                    .foregroundColor(.white)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 48) // TODO: Change
        .background(Color.white)
        .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]) )
        .onChange(of: playbackSpeed) { newValue in
            playbackSpeedSelected(newValue)
        }
    }

    private var sliderView: some View {
        VStack(spacing: .zero) {
            Slider(value: $playbackSpeed, in: 0.5...2, step: 0.1)
                .accentColor(.blue)
                .padding(.horizontal, 8)

            HStack {
                Text("0.5x")
                Spacer()
                Text("2x")
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
        }
    }

}
