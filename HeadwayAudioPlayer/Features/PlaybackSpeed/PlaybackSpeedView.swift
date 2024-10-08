//
//  PlaybackSpeedView.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import SwiftUI

struct PlaybackSpeedView: View {

    @Environment(\.bottomSheetDismiss) var bottomSheetDismiss
    @Binding private var playbackSpeed: Float

    init(playbackSpeed: Binding<Float>) {
        self._playbackSpeed = playbackSpeed
    }

    var body: some View {
        VStack(spacing: 16) {
            titleView

            plusMinusControl

            sliderView

            speedButtons

            continueButton
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    private var titleView: some View {
        Text("Playback speed")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var plusMinusControl: some View {
        HStack(spacing: 20) {
            Button {
                playbackSpeed -= 0.1
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 18))
            }
            .opacity(playbackSpeed > 0.5 ? 1 : 0)
            .buttonStyle(SpeedControlButtonStyle())
            .frame(width: 48, height: 48)

            Text(String(format: "%.1fx", playbackSpeed))
                .font(.title)
                .fontWeight(.bold)
                .kerning(1)
                .foregroundStyle(.playerBlue)
                .frame(width: 65)
                .modify { view in
                    if #available(iOS 16.0, *) {
                        view
                            .contentTransition(.numericText())
                    } else {
                        view
                    }
                }

            Button {
                playbackSpeed += 0.1
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18))
            }
            .opacity(playbackSpeed < 2 ? 1 : 0)
            .buttonStyle(SpeedControlButtonStyle())
            .frame(width: 48, height: 48)
        }
        .animation(.default, value: playbackSpeed)
        .padding(.vertical, 20)
    }

    private var sliderView: some View {
        VStack(spacing: .zero) {
            Slider(value: $playbackSpeed, in: 0.5...2, step: 0.1)
                .accentColor(.playerBlue)
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

    private var speedButtons: some View {
        HStack(spacing: 8) {
            SpeedButton(label: "0.8x", speed: 0.8, playbackSpeed: $playbackSpeed)
            SpeedButton(label: "Normal", speed: 1.0, playbackSpeed: $playbackSpeed)
            SpeedButton(label: "1.2x", speed: 1.2, playbackSpeed: $playbackSpeed)
            SpeedButton(label: "1.5x", speed: 1.5, playbackSpeed: $playbackSpeed)
        }
    }

    private var continueButton: some View {
        Button {
            bottomSheetDismiss()
        } label: {
            Text("Continue")
                .foregroundColor(.white)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.playerBlue)
                .cornerRadius(10)
        }
    }

}
