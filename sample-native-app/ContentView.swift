import Combine
import SwiftUI

enum Palette {
    static let ink = Color(red: 0.055, green: 0.16, blue: 0.22)
    static let cream = Color(red: 1, green: 0.96, blue: 0.85)
    static let coral = Color(red: 1, green: 0.36, blue: 0.29)
    static let gold = Color(red: 1, green: 0.81, blue: 0.31)
    static let mint = Color(red: 0.48, green: 0.9, blue: 0.77)
}

enum RunState: Equatable {
    case ready, running, paused, finished
}

enum PickupKind {
    case coin, barrier, sign, train
}

struct TrackItem: Identifiable {
    let id = UUID()
    let lane: Int
    let kind: PickupKind
    var progress: Double = 0
    var handled = false
}

struct RunnerGame {
    var state: RunState = .ready
    var lane = 1
    var score = 0
    var coins = 0
    var best = UserDefaults.standard.integer(forKey: "metroDashBest")
    var distance = 0.0
    var jumpTime = 0.0
    var slideTime = 0.0
    var items: [TrackItem] = []
    var trackMotion = 0.0
    private var spawnTime = 0.0
    private var wave = 0

    mutating func start() {
        lane = 1
        score = 0
        coins = 0
        distance = 0
        jumpTime = 0
        slideTime = 0
        trackMotion = 0
        spawnTime = 0
        wave = 0
        items = []
        state = .running
    }

    mutating func move(_ direction: Int) {
        guard state == .running else { return }
        lane = min(2, max(0, lane + direction))
    }

    mutating func jump() {
        guard state == .running, slideTime == 0 else { return }
        jumpTime = 0.82
    }

    mutating func slide() {
        guard state == .running, jumpTime == 0 else { return }
        slideTime = 0.82
    }

    mutating func advance(_ delta: Double) {
        guard state == .running else { return }
        let step = min(delta, 0.05)
        distance += step
        trackMotion += step * (0.52 + min(distance / 120, 0.22))
        jumpTime = max(0, jumpTime - step)
        slideTime = max(0, slideTime - step)
        score = Int(distance * 12) + coins * 25

        spawnTime += step
        if spawnTime >= max(0.72, 1.12 - distance / 180) {
            spawnTime = 0
            spawnWave()
        }

        for index in items.indices {
            items[index].progress += step * (0.39 + min(distance / 180, 0.14))
            guard !items[index].handled,
                  (0.89...0.99).contains(items[index].progress),
                  items[index].lane == lane else { continue }
            items[index].handled = true
            switch items[index].kind {
            case .coin:
                coins += 1
                score += 25
            case .barrier:
                if jumpTime == 0 { finish() }
            case .sign:
                if slideTime == 0 { finish() }
            case .train:
                finish()
            }
        }
        items.removeAll { $0.progress > 1.12 }
    }

    private mutating func spawnWave() {
        let blockedLane = (wave * 2 + wave / 3) % 3
        let kinds: [PickupKind] = [.barrier, .train, .sign]
        items.append(TrackItem(lane: blockedLane, kind: kinds[wave % kinds.count]))
        let coinLane = (blockedLane + 1 + wave % 2) % 3
        items.append(TrackItem(lane: coinLane, kind: .coin))
        wave += 1
    }

    private mutating func finish() {
        state = .finished
        if score > best {
            best = score
            UserDefaults.standard.set(best, forKey: "metroDashBest")
        }
    }
}

struct ContentView: View {
    @State private var game = RunnerGame()
    @State private var lastFrame = Date()
    private let clock = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Canvas { context, size in
                TrackArtwork.draw(in: context, size: size, game: game)
            }
            .ignoresSafeArea()

            if game.state == .running {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .gesture(controlGesture)
                    .onTapGesture { game.jump() }
                    .accessibilityLabel("Game area. Swipe left or right to change lanes, up to jump, down to slide")
            }

            VStack(spacing: 0) {
                header
                Spacer(minLength: 0)
                switch game.state {
                case .ready: readyPanel
                case .running: runningHint
                case .paused: pausePanel
                case .finished: finishedPanel
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 14)
            .padding(.bottom, 22)
        }
        .preferredColorScheme(.dark)
        .onReceive(clock) { now in
            let delta = now.timeIntervalSince(lastFrame)
            lastFrame = now
            game.advance(delta)
        }
    }

    private var controlGesture: some Gesture {
        DragGesture(minimumDistance: 22)
            .onEnded { drag in
                let horizontal = drag.translation.width
                let vertical = drag.translation.height
                if abs(horizontal) > abs(vertical) {
                    game.move(horizontal > 0 ? 1 : -1)
                } else if vertical < 0 {
                    game.jump()
                } else {
                    game.slide()
                }
            }
    }

    private var header: some View {
        HStack(alignment: .top) {
            HStack(spacing: 7) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Palette.gold)
                Text("METRO DASH")
                    .tracking(1.2)
            }
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(Palette.cream)
            .padding(.horizontal, 13)
            .frame(height: 38)
            .background(Palette.ink.opacity(0.75), in: Capsule())

            Spacer()

            if game.state == .running || game.state == .paused {
                HStack(spacing: 5) {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(Palette.gold)
                    Text("\(game.coins)")
                        .monospacedDigit()
                }
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .frame(height: 38)
                .background(Palette.ink.opacity(0.75), in: Capsule())

                Button {
                    game.state = game.state == .running ? .paused : .running
                    lastFrame = Date()
                } label: {
                    Image(systemName: game.state == .running ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 38, height: 38)
                        .background(Palette.ink.opacity(0.75), in: Circle())
                }
                .accessibilityIdentifier("pauseButton")
                .accessibilityLabel(game.state == .running ? "Pause" : "Resume")
            }
        }
    }

    private var readyPanel: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 4) {
                Text("THE CITY IS YOURS")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(Palette.gold)
                Text("RUN WILD.")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .tracking(-2)
                    .foregroundStyle(Palette.cream)
                    .shadow(color: Palette.ink, radius: 3, y: 4)
                Text("DODGE TRAINS. GRAB GOLD. KEEP MOVING.")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(Palette.cream.opacity(0.8))
            }
            .padding(.bottom, 24)

            primaryButton("LET'S RUN", icon: "arrow.right", identifier: "startButton") {
                game.start()
                lastFrame = Date()
            }

            HStack(spacing: 18) {
                instruction("arrow.left.arrow.right", "MOVE")
                instruction("arrow.up", "JUMP")
                instruction("arrow.down", "SLIDE")
            }
            .padding(.top, 23)
            .padding(.bottom, 9)
        }
    }

    private var runningHint: some View {
        VStack(spacing: 8) {
            Text(String(format: "%05d", game.score))
                .font(.system(size: 39, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Palette.cream)
                .shadow(color: Palette.ink, radius: 6, y: 3)
                .accessibilityIdentifier("scoreLabel")
            Text("SWIPE TO DODGE  •  TAP TO JUMP")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(1.3)
                .foregroundStyle(Palette.cream.opacity(0.8))
        }
        .padding(.bottom, 3)
    }

    private var pausePanel: some View {
        modalPanel(eyebrow: "TAKE A BREATHER", title: "PAUSED", subtitle: "THE TRACKS WILL WAIT FOR YOU.") {
            primaryButton("KEEP RUNNING", icon: "play.fill", identifier: "resumeButton") {
                game.state = .running
                lastFrame = Date()
            }
        }
    }

    private var finishedPanel: some View {
        modalPanel(eyebrow: "END OF THE LINE", title: "NICE RUN!", subtitle: "EVERY RUN GETS YOU FURTHER.") {
            HStack(spacing: 0) {
                resultValue("SCORE", value: "\(game.score)")
                Rectangle().fill(Palette.cream.opacity(0.2)).frame(width: 1, height: 45)
                resultValue("BEST", value: "\(game.best)")
                Rectangle().fill(Palette.cream.opacity(0.2)).frame(width: 1, height: 45)
                resultValue("COINS", value: "\(game.coins)")
            }
            .padding(.vertical, 22)
            primaryButton("RUN AGAIN", icon: "arrow.clockwise", identifier: "retryButton") {
                game.start()
                lastFrame = Date()
            }
        }
    }

    private func resultValue(_ title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(title).font(.system(size: 10, weight: .black, design: .rounded)).tracking(1.5).foregroundStyle(Palette.mint)
            Text(value).font(.system(size: 23, weight: .black, design: .rounded)).monospacedDigit().foregroundStyle(Palette.cream)
        }
        .frame(maxWidth: .infinity)
    }

    private func modalPanel<Content: View>(eyebrow: String, title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 9) {
                Text(eyebrow).font(.system(size: 11, weight: .black, design: .rounded)).tracking(3).foregroundStyle(Palette.gold)
                Text(title).font(.system(size: 43, weight: .black, design: .rounded)).foregroundStyle(Palette.cream)
                Text(subtitle).font(.system(size: 10, weight: .heavy, design: .rounded)).tracking(1).foregroundStyle(Palette.cream.opacity(0.7))
                content()
                    .padding(.top, 13)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Palette.ink.opacity(0.96), in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(Palette.mint.opacity(0.25), lineWidth: 1))
            Spacer()
        }
    }

    private func instruction(_ symbol: String, _ label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol).font(.system(size: 12, weight: .bold))
            Text(label).font(.system(size: 10, weight: .black, design: .rounded)).tracking(1)
        }
        .foregroundStyle(Palette.cream)
    }

    private func primaryButton(_ label: String, icon: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(label).tracking(1.5)
                Spacer()
                Image(systemName: icon)
            }
            .font(.system(size: 16, weight: .black, design: .rounded))
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 22)
            .frame(height: 58)
            .background(Palette.gold, in: RoundedRectangle(cornerRadius: 17))
            .shadow(color: Palette.ink.opacity(0.5), radius: 0, y: 6)
        }
        .accessibilityIdentifier(identifier)
    }
}

#Preview {
    ContentView()
}
