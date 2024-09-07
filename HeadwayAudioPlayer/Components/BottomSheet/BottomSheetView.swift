//
//  BottomSheetView.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 05.09.2024.
//

import SwiftUI
import IssueReporting

extension View {

    func bottomSheet<Value, ContentView: View>(
        _ item: Binding<Value?>,
        contentView: @escaping (Value) -> ContentView
    ) -> some View {
        self
            .overlay {
                if let value = item.wrappedValue {
                    BottomSheetView(
                        isPresented: Binding(item),
                        contentView: contentView(value)
                    )
                } else {
                    EmptyView()
                }
            }
    }

}

struct BottomSheetDismiss {

    var dismiss: () -> Void

    func callAsFunction() {
        dismiss()
    }

}

extension EnvironmentValues {

    var bottomSheetDismiss: BottomSheetDismiss {
        get { self[BottomSheetDismissKey.self] }
        set { self[BottomSheetDismissKey.self] = newValue }
    }

    private struct BottomSheetDismissKey: EnvironmentKey {
        static let defaultValue = BottomSheetDismiss { reportIssue("Can't dismiss bottom sheet") }
    }

}

private struct BottomSheetView<ContentView: View>: View {

    @State private var bottomSheetIsVisible = false
    @State private var dragOffset = CGFloat.zero
    @Binding private var isPresented: Bool
    private var contentView: ContentView

    init(
        isPresented: Binding<Bool>,
        contentView: ContentView
    ) {
        self._isPresented = isPresented
        self.contentView = contentView
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if bottomSheetIsVisible {
                backgroundView
                    .zIndex(1)

                mainView
                    .zIndex(2)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animatedAppear()
        }
    }

    private var mainView: some View {
        contentView
            .environment(\.bottomSheetDismiss, BottomSheetDismiss(dismiss: animatedDisappear))
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
