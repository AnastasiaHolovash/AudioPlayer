//
//  AudioPlayerView.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 04.09.2024.
//

import SwiftUI
import ComposableArchitecture

@ViewAction(for: AudioPlayerFeature.self)
struct AudioPlayerView: View {

    @Perception.Bindable var store: StoreOf<AudioPlayerFeature>

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: .zero) {
                headerView

                playerView

                Spacer(minLength: .zero)

                textAudioToggleView
            }
            .padding()
            .background(Color.playerBackground)
            .bottomSheet($store.destination.playbackSpeed) {
                PlaybackSpeedView(playbackSpeed: $store.playbackSpeed)
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
            .frame(height: UIScreen.main.bounds.height > 700 ? 300 : 200)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
            }

            VStack(spacing: Constants.padding) {
                Text(
                    "Key point \(store.currentKeyPointOrderNumberUIValue) of \(store.summary.keyPoints.count)"
                        .uppercased()
                )
                .font(.system(size: 12))
                .kerning(1)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

                if let currentKeyPoint = store.currentKeyPoint {
                    Text(currentKeyPoint.title)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private var playerView: some View {
        VStack(spacing: .zero) {
            VStack(spacing: Constants.padding) {
                sliderView

                Button {
                    send(.playbackSpeedTapped)
                } label: {
                    Text(String(format: "%.1fx speed", store.playbackSpeed))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .padding(Constants.smallPadding)
                        .background(Color.playerLightGray)
                        .cornerRadius(4)
                }
            }
            .padding(.bottom, Constants.largePadding)

            playbackControlsView
        }
        .padding(.vertical, Constants.largePadding)
    }

    private var sliderView: some View {
        HStack {
            Text(store.playerState.progress.currentSeconds.formattedTime)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 40)

            Slider(
                value: $store.currentSeconds,
                in: 0...store.playerState.progress.totalSeconds
            ) { isEditing in
                send(.setCurrentSecondsIsEditing(isEditing))
            }
            .tint(.playerBlue)
            .animation(.easeIn, value: store.currentSeconds)
            .allowsHitTesting(store.playerState.hasProgress)

            Text(store.playerState.progress.totalSeconds.formattedTime)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 40)
        }
    }

    private var playbackControlsView: some View {
        HStack(spacing: .zero) {
            Button {
                send(.previousKeyPointTapped)
            } label: {
                Image(systemName: "backward.end")
                    .font(.system(size: 26, weight: .medium))
            }
            .disabled(store.currentKeyPointOrderNumber == store.summary.firstKeyPointOrderNumber)

            Button {
                send(.seekBackwardTapped)
            } label: {
                Image(systemName: "gobackward.5")
                    .font(.system(size: 26, weight: .medium))
            }

            Button {
                send(store.playerState.isPlaying ? .pauseTapped : .playTapped)
            } label: {
                if store.playerState.isLoading {
                    ProgressView()
                } else {
                    Image(systemName: store.playerState.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 34, weight: .medium))
                }
            }

            Button {
                send(.seekForwardTapped)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 26, weight: .medium))
            }

            Button {
                send(.nextKeyPointTapped)
            } label:  {
                Image(systemName: "forward.end")
                    .font(.system(size: 26, weight: .medium))
            }
            .disabled(store.currentKeyPointOrderNumber == store.summary.lastKeyPointOrderNumber)
        }
        .buttonStyle(PlayerButtonStyle())
        .foregroundColor(.primary)
        .allowsHitTesting(!store.playerState.isLoading)
    }

    private var textAudioToggleView: some View {
        HStack(spacing: Constants.smallPadding) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 16, weight: .bold))
                .padding(Constants.smallPadding)

            Image(systemName: "headphones")
                .font(.system(size: 16, weight: .bold))
                .padding(12)
                .background(Color.playerBlue)
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

private extension AudioPlayerFeature.State {

    var currentKeyPoint: Summary.KeyPoint? {
        summary.keyPoints[id: currentKeyPointID]
    }

    var currentKeyPointOrderNumber: Int {
        currentKeyPoint?.orderNumber ?? .zero
    }

    var currentKeyPointOrderNumberUIValue: Int {
        currentKeyPointOrderNumber + 1
    }

}


private extension AudioPlayerView {

    enum Constants {
        static let largePadding: CGFloat = 32
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
    }

}

#Preview {

    AudioPlayerView(
        store: Store(
            initialState: AudioPlayerFeature.State(
                currentKeyPointID: Summary.zeroToOne.keyPoints.first!.id
            )
        ) {
            AudioPlayerFeature()
        }
    )

}
