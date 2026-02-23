//
//  TelosView.swift
//  zentempo
//

import SwiftUI

struct TelosView: View {
    @ObservedObject var telosManager: TelosManager
    @State private var selectedAgent: String?
    @State private var runInput: String = ""
    @State private var expandedAgents: Set<String> = []

    var body: some View {
        VStack(spacing: 12) {
            if telosManager.isLoading {
                Spacer()
                ProgressView("Loading agents...")
                Spacer()
            } else if let error = telosManager.errorMessage {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                Spacer()
            } else if telosManager.agents.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No agents installed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                agentList
            }

            Divider()

            quickRunSection

            resultSection
        }
        .padding()
        .frame(width: 280)
    }

    // MARK: - Agent List

    private var agentList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Agents")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Button(action: { telosManager.refresh() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Refresh agents")
                }
                .padding(.bottom, 4)

                ForEach(telosManager.agents) { agent in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedAgents.contains(agent.name) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedAgents.insert(agent.name)
                                } else {
                                    expandedAgents.remove(agent.name)
                                }
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(agent.skills) { skill in
                                skillRow(skill: skill, agentName: agent.name)
                            }
                        }
                        .padding(.leading, 4)
                    } label: {
                        HStack {
                            Text(agent.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(agent.skillCount) \(agent.skillCount == 1 ? "skill" : "skills")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
        }
        .frame(maxHeight: 220)
    }

    private func skillRow(skill: TelosSkill, agentName: String) -> some View {
        Button(action: {
            selectedAgent = agentName
            runInput = skill.name
        }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(skill.name)
                    .font(.caption)
                    .fontWeight(.medium)
                if !skill.description.isEmpty {
                    Text(skill.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Run

    private var quickRunSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Quick Run")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
                if let agent = selectedAgent {
                    Text(agent)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.1))
                        )
                    Button(action: { selectedAgent = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                TextField("Enter command...", text: $runInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .onSubmit { executeRun() }
                    .disabled(telosManager.isRunning)

                if telosManager.isRunning {
                    Button("Cancel") {
                        telosManager.cancelRun()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                } else {
                    Button("Run") {
                        executeRun()
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .disabled(runInput.isEmpty)
                }
            }
        }
    }

    // MARK: - Result

    @ViewBuilder
    private var resultSection: some View {
        if telosManager.isRunning {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Running...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else if let result = telosManager.lastResult {
            if result.success {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Done")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    if let file = result.outputFile {
                        Button(action: {
                            NSWorkspace.shared.open(URL(fileURLWithPath: file))
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.caption2)
                                Text(URL(fileURLWithPath: file).lastPathComponent)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.link)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("Error")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    Text(result.output.prefix(200))
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(3)
                }
            }
        }
    }

    private func executeRun() {
        guard !runInput.isEmpty else { return }
        telosManager.run(agent: selectedAgent, input: runInput)
    }
}
