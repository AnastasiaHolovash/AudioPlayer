//
//  BottomSheetView.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import SwiftUI

struct BottomSheetView: View {

    @State private var bottomSheetIsVisible = false
    @Binding var isPresented: Bool
    @State private var playbackSpeed: Double = 1.0
    @State private var dragOffset = CGFloat.zero

    var body: some View {
        ZStack(alignment: .bottom) {
            if bottomSheetIsVisible {
                backgroundView
                    .zIndex(1)

                contentView
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
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
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animatedAppear()
        }
    }

    private var contentView: some View {
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

                Text("\(String(format: "%.1fx", playbackSpeed))")
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
        if #available(iOS 17.0, *) {
            withAnimation {
                bottomSheetIsVisible = false
            } completion: {
                isPresented = false
            }
        } else {
            withAnimation(.linear(duration: AspBottomSheetViewConstants.animationDuration)) {
                bottomSheetIsVisible = false
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + AspBottomSheetViewConstants.animationDispatchTimeDuration
            ) {
                isPresented = false
            }
        }
    }

}

private enum AspBottomSheetViewConstants {
    static let animationDuration: TimeInterval = 0.2
    static let animationDispatchTimeDuration: DispatchTimeInterval = .milliseconds(Int(
        animationDuration * 1000
    ))
}

struct SpeedButton: View {
    let label: String
    let speed: Double
    @Binding var playbackSpeed: Double

    var body: some View {
        Button {
            playbackSpeed = speed
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .medium))
        }
        .buttonStyle(SpeedControlButtonStyle())
        .frame(height: 36)
    }
}

#Preview {
    BottomSheetView(isPresented: .constant(true))
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
