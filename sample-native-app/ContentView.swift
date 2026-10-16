import SwiftUI

private struct Todo: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isComplete = false
}

private enum TodoFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case completed = "Done"
}

struct ContentView: View {
    @State private var todos: [Todo] = []
    @State private var newTitle = ""
    @State private var filter: TodoFilter = .all
    @FocusState private var isInputFocused: Bool

    private let storageKey = "savedTodos"
    private let ink = Color(red: 0.12, green: 0.18, blue: 0.19)
    private let accent = Color(red: 0.14, green: 0.43, blue: 0.39)
    private let canvas = Color(red: 0.97, green: 0.97, blue: 0.94)

    private var remainingCount: Int { todos.filter { !$0.isComplete }.count }

    private var visibleTodos: [Todo] {
        switch filter {
        case .all: todos
        case .active: todos.filter { !$0.isComplete }
        case .completed: todos.filter { $0.isComplete }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                header
                composer
                tasks
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 60)
        }
        .background(canvas.ignoresSafeArea())
        .foregroundStyle(ink)
        .onAppear(perform: loadTodos)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("YOUR SPACE", systemImage: "circle.grid.2x2.fill")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(accent)
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(accent)
                    .accessibilityHidden(true)
            }

            Text("Make room for\nwhat matters.")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .tracking(-1.5)
                .fixedSize(horizontal: false, vertical: true)

            Text(remainingCount == 0 ? "You're all caught up. Enjoy the moment." :
                    "\(remainingCount) \(remainingCount == 1 ? "task" : "tasks") on your mind today.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("remainingCount")
        }
    }

    private var composer: some View {
        HStack(spacing: 12) {
            TextField("What needs doing?", text: $newTitle)
                .focused($isInputFocused)
                .submitLabel(.done)
                .onSubmit(addTodo)
                .accessibilityIdentifier("todoInput")

            Button(action: addTodo) {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityLabel("Add task")
            .accessibilityIdentifier("addTodoButton")
        }
        .padding(12)
        .padding(.leading, 8)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
    }

    private var tasks: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("My tasks")
                    .font(.title2.bold())
                Spacer()
                Text("\(todos.count) TOTAL")
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(TodoFilter.allCases, id: \.self) { option in
                    Button {
                        filter = option
                    } label: {
                        Text(option.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(filter == option ? .white : ink)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(filter == option ? ink : .white, in: Capsule())
                    }
                    .accessibilityIdentifier("filter\(option.rawValue)")
                }
            }

            if visibleTodos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: filter == .completed ? "checkmark.circle" : "leaf")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(accent)
                    Text(filter == .all ? "A fresh start" : filter == .active ? "Nothing left to do" : "No completed tasks yet")
                        .font(.headline)
                    Text(filter == .all ? "Add a task above to get started." :
                            filter == .active ? "All your tasks are complete." : "Finish a task and it’ll show up here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))
                .accessibilityIdentifier("emptyState")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(visibleTodos) { todo in
                        HStack(spacing: 14) {
                            Button {
                                toggleTodo(todo.id)
                            } label: {
                                Image(systemName: todo.isComplete ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(accent)
                            }
                            .accessibilityLabel(todo.isComplete ? "Mark \(todo.title) incomplete" : "Complete \(todo.title)")

                            Text(todo.title)
                                .font(.body.weight(.medium))
                                .strikethrough(todo.isComplete)
                                .foregroundStyle(todo.isComplete ? .secondary : ink)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                deleteTodo(todo.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, height: 36)
                            }
                            .accessibilityLabel("Delete \(todo.title)")
                        }
                        .padding(16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
        }
    }

    private func addTodo() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        todos.insert(Todo(title: title), at: 0)
        newTitle = ""
        isInputFocused = false
        saveTodos()
    }

    private func toggleTodo(_ id: UUID) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].isComplete.toggle()
        saveTodos()
    }

    private func deleteTodo(_ id: UUID) {
        todos.removeAll { $0.id == id }
        saveTodos()
    }

    private func loadTodos() {
        if ProcessInfo.processInfo.arguments.contains("-resetTodosForUITests") {
            UserDefaults.standard.removeObject(forKey: storageKey)
        }
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([Todo].self, from: data) else { return }
        todos = saved
    }

    private func saveTodos() {
        guard let data = try? JSONEncoder().encode(todos) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

#Preview {
    ContentView()
}
