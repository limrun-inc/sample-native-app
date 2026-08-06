//
//  ProfileView.swift
//  sample-native-app
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .imageScale(.large)
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            Text("Muvaffak")
                .font(.title2)
                .bold()
            Text("muvaf@limrun.com")
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Profile")
    }
}

#Preview {
    ProfileView()
}
