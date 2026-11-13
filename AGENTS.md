# Sample Native App

This is a native iOS app written in Swift but can be built and tested in any environment,
such as Linux.

During development, you MUST use the `limrun-xcode` skill to build the app and
the `limrun-ios-simulator` skill to test it in the simulator using `lim` CLI.

- The bundle ID is `com.limrun.sample-native`.
- Run the unit and UI tests with `lim xcode test . --scheme sample-native-app`.


```bash
npm install --global lim
```

## Cloud specific instructions

- Install `lim` CLI: `npm install --global lim`
- Always use `lim` CLI to replace xcodebuild and iOS simulator.
- Refer to `.agents/skills/limrun-xcode/SKILL.md` for the build workflow and
  `.agents/skills/limrun-ios-simulator/SKILL.md` for driving the simulator.

## This repository is public

Everything pushed here is visible to anyone: code, comments, commit messages, branch names,
pull request titles and descriptions, and issue text.

- Never name a customer or a prospect, or describe one closely enough to identify it.
- Never link to or quote private sources: private repositories and their pull requests, chat
  threads, tickets, dashboards, or meeting notes.
- Leave out internal detail: infrastructure, hostnames, capacity, security findings, and how
  a change is rolled out.
- Write the reason for a change for an outside reader: what it gives someone who uses this
  project, not what prompted it inside the company.
- Do not copy text from a private repository's pull request or issue into this one.
- Check before you post. A pull request description keeps its edit history, so a later edit
  does not take a mistake back.
