//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

struct ContentView: View {
    @State private var count: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()

                Text("\(count)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .accessibilityIdentifier("countLabel")

                HStack(spacing: 24) {
                    Button {
                        withAnimation {
                            count -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.red)
                    }
                    .accessibilityIdentifier("decrementButton")

                    Button {
                        withAnimation {
                            count = 0
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityIdentifier("resetButton")

                    Button {
                        withAnimation {
                            count += 1
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.green)
                    }
                    .accessibilityIdentifier("incrementButton")
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Counter")
        }
    }
}

#Preview {
    ContentView()
}
