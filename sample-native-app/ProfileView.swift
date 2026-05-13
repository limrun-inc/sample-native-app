//
//  ProfileView.swift
//  sample-native-app
//

import SwiftUI

struct ProfileView: View {
    let profile: UserProfile

    private static let joinedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    statsRow
                    bioSection
                    detailsSection
                    interestsSection
                    actionButtons
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Mock action
                    } label: {
                        Image(systemName: "gearshape")
                            .accessibilityLabel("Settings")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: profile.avatarSystemName)
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .foregroundStyle(.tint)
                .background(
                    Circle()
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    Circle()
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .accessibilityIdentifier("profileAvatar")

            VStack(spacing: 4) {
                Text(profile.name)
                    .font(.title2.bold())
                    .accessibilityIdentifier("profileName")
                Text(profile.username)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("profileUsername")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private var statsRow: some View {
        HStack {
            statItem(value: profile.stats.posts.formatted(), label: "Posts")
                .accessibilityIdentifier("statPosts")
            Divider().frame(height: 32)
            statItem(value: profile.stats.followers.formatted(), label: "Followers")
                .accessibilityIdentifier("statFollowers")
            Divider().frame(height: 32)
            statItem(value: profile.stats.following.formatted(), label: "Following")
                .accessibilityIdentifier("statFollowing")
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var bioSection: some View {
        SectionCard(title: "About") {
            Text(profile.bio)
                .font(.body)
                .foregroundStyle(.primary)
                .accessibilityIdentifier("profileBio")
        }
    }

    private var detailsSection: some View {
        SectionCard(title: "Details") {
            VStack(spacing: 12) {
                detailRow(icon: "mappin.and.ellipse", text: profile.location)
                    .accessibilityIdentifier("detailLocation")
                detailRow(icon: "link", text: profile.website)
                    .accessibilityIdentifier("detailWebsite")
                detailRow(icon: "envelope", text: profile.email)
                    .accessibilityIdentifier("detailEmail")
                detailRow(
                    icon: "calendar",
                    text: "Joined \(Self.joinedDateFormatter.string(from: profile.joinedDate))"
                )
                .accessibilityIdentifier("detailJoined")
            }
        }
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }

    private var interestsSection: some View {
        SectionCard(title: "Interests") {
            FlowLayout(spacing: 8) {
                ForEach(profile.interests, id: \.self) { interest in
                    Text(interest)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.accentColor.opacity(0.15))
                        )
                        .foregroundStyle(.tint)
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                // Mock action
            } label: {
                Text("Follow")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("followButton")

            Button {
                // Mock action
            } label: {
                Text("Message")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("messageButton")
        }
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }
}

/// A simple wrapping flow layout used to present interest chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                rowWidth = size.width + spacing
                rowHeight = size.height
            } else {
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth == .infinity ? rowWidth : maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    ProfileView(profile: .mock)
}
