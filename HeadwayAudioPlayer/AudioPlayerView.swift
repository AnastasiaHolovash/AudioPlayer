//
//  AudioPlayerView.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 04.09.2024.
//

import SwiftUI
import ComposableArchitecture

struct AudioPlayerView: View {
    
    @State private var isPresented: Bool = false
    @Perception.Bindable var store: StoreOf<AudioPlayerFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: Constants.largePadding) {
                headerView
                
                playerView
                
                Spacer(minLength: .zero)
                
                textAudioToggleView
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .overlay {
                if isPresented {
                    BottomSheetView(
                        playbackSpeed: store.playbackSpeed,
                        isPresented: $isPresented
                    ) { speed in
                        store.send(.speedSelected(speed: speed))
                    }
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: Constants.largePadding) {
            AsyncImage(url: store.summary.imageURL) { image in
                image
                    .resizable()
            } placeholder: {
                Color.gray
            }
            .aspectRatio(2/3, contentMode: .fit)
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
            }

            VStack(spacing: 16) {
                Text("Key point \(store.currentKeyPoint.orderNumber + 1) of \(store.summary.keyPoints.count)".uppercased())
                    .font(.subheadline)
                    .kerning(1)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)

                Text(store.currentKeyPoint.title)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var playerView: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 8) {
                HStack {
                    Text(store.playerState.progress.currentSeconds.formattedTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: 40)

                    Slider(
                        value: $store.currentSeconds,
                        in: 0...store.playerState.progress.totalSeconds
                    ) { isEditing in
                        store.send(.setIsEditing(isEditing))
                    }
                    .animation(.easeIn, value: store.currentSeconds)

                    Text(store.playerState.progress.totalSeconds.formattedTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: 40)
                }

                Button {
                    isPresented = true
                } label: {
                    Text(String(format: "%.1fx speed", store.playbackSpeed))
                        .font(.subheadline)
                        .foregroundStyle(Color.black)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 15)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
            .padding(.bottom, Constants.largePadding)

            playbackControlsView
        }
    }

    private var playbackControlsView: some View {
        HStack(spacing: .zero) {
            Button {
                store.send(.previousKeyPointTapped)
            } label: {
                Image(systemName: "backward.end")
                    .font(.system(size: 26, weight: .medium))
            }
            .disabled(store.currentKeyPoint.orderNumber == .zero)

            Button {
                store.send(.seekBackwardTapped)
            } label: {
                Image(systemName: "gobackward.5")
                    .font(.system(size: 26, weight: .medium))
            }

            Button {
                store.send(store.playerState.isPlaying ? .pauseTapped : .playTapped)
            } label: {
                if store.playerState.isLoading {
                    ProgressView()
                } else {
                    Image(systemName: store.playerState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 34, weight: .medium))
                }
            }

            Button {
                store.send(.seekForwardTapped)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 26, weight: .medium))
            }

            Button {
                store.send(.nextKeyPointTapped)
            } label:  {
                Image(systemName: "forward.end")
                    .font(.system(size: 26, weight: .medium))
            }
            .disabled(store.currentKeyPoint.orderNumber + 1 == store.currentKeyPoint.totalKeyPointsNumber)
        }
        .buttonStyle(PlayerButtonStyle())
        .foregroundColor(.primary)
        .allowsTightening(!store.playerState.isLoading)
    }

    private var textAudioToggleView: some View {
        HStack(spacing: 8) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 16, weight: .bold))
                .padding(8)

            Image(systemName: "headphones")
                .font(.system(size: 16, weight: .bold))
                .padding(12)
                .background(Color.blue)
                .clipShape(Circle())
                .foregroundColor(.white)
        }
        .padding(4)
        .background(
            Capsule()
                .stroke(.gray.opacity(0.2), lineWidth: 1)
                .background(Capsule().fill(.white))
        )
    }

}

private extension AudioPlayerView {

    enum Constants {
        static let largePadding: CGFloat = 32
        static let padding: CGFloat = 16
    }

}

#Preview {

    AudioPlayerView(store: Store(
        initialState: AudioPlayerFeature.State(currentKeyPoint: Summary.zeroToOne.keyPoints.first!),
        reducer: {
            AudioPlayerFeature()
        }
    ))

}

extension Float64 {

    var formattedTime: String {
        let minutes = Int(self) / 60
        let remainingSeconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

}
