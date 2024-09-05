//
//  ContentView.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 04.09.2024.
//

import SwiftUI

struct ContentView: View {
    @State private var progress: Double = 0.28
    @State private var isPlaying: Bool = true
    @State private var isPresented: Bool = false
    @State private var playbackSpeed: Double = 1

    var body: some View {
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
                BottomSheetView(isPresented: $isPresented, playbackSpeed: $playbackSpeed)
            }
        }
        
    }

    private var headerView: some View {
        VStack(spacing: Constants.largePadding) {
            AsyncImage(
                url: URL(string: "https://static.get-headway.com/600_3182022704394b4587ab-15e0764877ed68.jpg")
            ) { image in
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
                Text("Key point 1 of 8".uppercased())
                    .font(.subheadline)
                    .kerning(1)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)

                Text("Design is not how a thing looks, but how it works")
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var playerView: some View {
        VStack(spacing: .zero) {
            VStack(spacing: 16) {
                HStack {
                    Text("00:28")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Slider(value: $progress, in: 0...1)

                    Text("02:12")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Button(action: {
                    isPresented = true
                }) {
                    Text("\(playbackSpeed)x speed")
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

            } label: {
                Image(systemName: "backward.end")
                    .font(.system(size: 26, weight: .medium))
            }

            Button {

            } label: {
                Image(systemName: "gobackward.5")
                    .font(.system(size: 26, weight: .medium))
            }

            Button {
                isPlaying.toggle()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 34, weight: .medium))
            }

            Button {

            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 26, weight: .medium))
            }

            Button {

            } label:  {
                Image(systemName: "forward.end")
                    .font(.system(size: 26, weight: .medium))
            }
        }
        .buttonStyle(PlayerButtonStyle())
        .foregroundColor(.primary)
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

private extension ContentView {

    enum Constants {
        static let largePadding: CGFloat = 32
        static let padding: CGFloat = 16
    }

}

#Preview {
    ContentView()
}
