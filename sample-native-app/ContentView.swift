//
//  ContentView.swift
//  sample-native-app
//
//  Created by Muvaffak on 1/16/26.
//

import SwiftUI

private enum AppTab: String, CaseIterable, Identifiable {
    case home
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            "Home"
        case .profile:
            "Profile"
        }
    }

    var symbolName: String {
        switch self {
        case .home:
            "house.fill"
        case .profile:
            "person.crop.circle.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.14), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:
                    HomePage()
                case .profile:
                    ProfilePage()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.25), value: selectedTab)

            LiquidGlassNavigationBar(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
    }
}

private struct HomePage: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Home")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text("Welcome back. Your dashboard is ready.")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Group {
                    HomeCard(
                        title: "Today",
                        subtitle: "3 upcoming events",
                        symbolName: "calendar.badge.clock"
                    )
                    HomeCard(
                        title: "Focus",
                        subtitle: "Continue your current plan",
                        symbolName: "bolt.heart.fill"
                    )
                    HomeCard(
                        title: "Goals",
                        subtitle: "2 milestones this week",
                        symbolName: "target"
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 130)
        }
    }
}

private struct ProfilePage: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Profile")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Taylor Jordan")
                            .font(.title3.bold())
                        Text("iOS Product Designer")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                )

                VStack(alignment: .leading, spacing: 12) {
                    ProfileRow(label: "Email", value: "taylor@example.com")
                    ProfileRow(label: "Membership", value: "Pro")
                    ProfileRow(label: "Location", value: "San Francisco")
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 130)
        }
    }
}

private struct LiquidGlassNavigationBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbolName)
                            .font(.system(size: 16, weight: .semibold))
                        Text(tab.title)
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(selectedTab == tab ? Color.primary : Color.secondary)
                }
                .buttonStyle(.plain)
                .background {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.45))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.55), Color.white.opacity(0.18)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
        )
    }
}

private struct HomeCard: View {
    let title: String
    let subtitle: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
    }
}

private struct ProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    ContentView()
}
