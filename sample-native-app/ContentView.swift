import SwiftUI

struct ContentView: View {
    @StateObject private var game = RunnerGame()

    private let ink = Color(red: 0.06, green: 0.06, blue: 0.15)
    private let cream = Color(red: 1, green: 0.96, blue: 0.85)
    private let coral = Color(red: 1, green: 0.36, blue: 0.35)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MetalGameView(game: game)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 24).onEnded { value in
                        guard game.phase == .running else { return }
                        if abs(value.translation.width) > abs(value.translation.height) {
                            game.move(value.translation.width > 0 ? 1 : -1)
                        } else if value.translation.height < 0 {
                            game.jump()
                        } else {
                            game.slide()
                        }
                    })
                    .allowsHitTesting(game.phase == .running)
                    .accessibilityIdentifier("gameSurface")

                VStack(spacing: 0) {
                    header
                    Spacer()
                    if game.phase == .running { controls } else { menu }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 16) + 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ink)
            .foregroundStyle(cream)
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("N / R")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .tracking(-2)
                    .foregroundStyle(coral)
                Text("NIGHT RUNNERS CLUB")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .tracking(2)
            }
            Spacer()
            if game.phase == .running || game.phase == .paused {
                HStack(spacing: 6) {
                    stat(value: "\(game.score)", symbol: "bolt.fill", tint: cream)
                    stat(value: "\(game.coins)", symbol: "circle.fill", tint: Color(red: 1, green: 0.76, blue: 0.31))
                    Button { game.pauseOrResume() } label: {
                        Image(systemName: game.phase == .paused ? "play.fill" : "pause.fill")
                            .frame(width: 40, height: 40)
                            .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel(game.phase == .paused ? "Resume" : "Pause")
                    .accessibilityIdentifier(game.phase == .paused ? "resumeButton" : "pauseButton")
                }
            } else {
                Text("EST. 20XX  /  AFTER DARK")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .padding(.top, 9)
            }
        }
    }

    private func stat(value: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).foregroundStyle(tint)
            Text(value).contentTransition(.numericText())
        }
        .font(.system(size: 14, weight: .black, design: .rounded))
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 10)
        .frame(height: 40)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 12))
    }

    private var menu: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(coral).frame(width: 7, height: 7)
                Text(game.phase == .over ? "RUN COMPLETE" : game.phase == .paused ? "TAKE A BREATH" : "THE CITY IS YOURS")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .tracking(2)
            }
            .foregroundStyle(coral)
            .padding(.bottom, 13)

            Text(game.phase == .over ? "NICE\nRUN." : game.phase == .paused ? "PAUSED\nIN TIME." : "OWN THE\nNIGHT.")
                .font(.system(size: 51, weight: .black, design: .rounded))
                .tracking(-3)
                .lineSpacing(-9)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 14)

            Text(game.phase == .over ? "You made it \(game.score) meters. The tracks are calling again." : "Three tracks. One way forward. Dodge the rush and collect the glow.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(cream.opacity(0.72))
                .lineSpacing(4)
                .padding(.bottom, 24)

            if game.phase == .over {
                HStack(spacing: 28) {
                    result(label: "DISTANCE", value: "\(game.score) M")
                    result(label: "COINS", value: "\(game.coins)")
                    result(label: "BEST", value: "\(game.best) M")
                }
                .padding(.bottom, 22)
            } else if game.phase == .paused {
                result(label: "DISTANCE SO FAR", value: "\(game.score) M")
                    .padding(.bottom, 22)
            }

            Button {
                if game.phase == .paused { game.pauseOrResume() } else { game.start() }
            } label: {
                HStack {
                    Text(game.phase == .over ? "RUN IT BACK" : game.phase == .paused ? "KEEP RUNNING" : "START RUNNING")
                        .tracking(1.4)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(ink)
                .padding(.horizontal, 21)
                .frame(height: 58)
                .background(coral, in: RoundedRectangle(cornerRadius: 17))
            }
            .accessibilityIdentifier(game.phase == .over ? "restartButton" : game.phase == .paused ? "continueButton" : "startButton")

            HStack(spacing: 8) {
                Image(systemName: "hand.draw")
                Text("SWIPE TO MOVE  ·  UP TO JUMP  ·  DOWN TO SLIDE")
            }
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(cream.opacity(0.56))
            .padding(.top, 20)
        }
        .padding(25)
        .frame(maxWidth: 440, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(ink.opacity(0.94))
                .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(cream.opacity(0.15)))
        }
    }

    private func result(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundStyle(cream.opacity(0.54))
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Text("LANE \(game.lane + 1) / 3")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .tracking(3)
                .accessibilityIdentifier("laneIndicator")
            HStack(spacing: 12) {
                control("arrow.left", label: "Left", id: "leftButton") { game.move(-1) }
                control("arrow.up", label: "Jump", id: "jumpButton") { game.jump() }
                control("arrow.down", label: "Slide", id: "slideButton") { game.slide() }
                control("arrow.right", label: "Right", id: "rightButton") { game.move(1) }
            }
        }
        .frame(maxWidth: 440)
    }

    private func control(_ symbol: String, label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(ink.opacity(0.75), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(cream.opacity(0.3)))
        }
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }
}
