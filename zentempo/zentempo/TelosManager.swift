//
//  TelosManager.swift
//  zentempo
//

import Foundation

struct TelosAgent: Identifiable {
    let id = UUID()
    let name: String
    var skillCount: Int
    var skills: [TelosSkill]
}

struct TelosSkill: Identifiable {
    let id = UUID()
    let name: String
    let description: String
}

struct RunResult {
    let success: Bool
    let output: String
    let outputFile: String?
}

class TelosManager: ObservableObject {
    @Published var agents: [TelosAgent] = []
    @Published var isRunning: Bool = false
    @Published var lastResult: RunResult?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var runningProcess: Process?

    private func shell(_ command: String) -> (output: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (output, process.terminationStatus)
    }

    func refresh() {
        isLoading = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let result = self.shell("uv run --project ~/workspace/telos telos agents")

            if result.exitCode != 0 {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "telos not found — install with `uv pip install -e ~/workspace/telos`"
                }
                return
            }

            let agentNames = self.parseAgentList(result.output)
            var loadedAgents: [TelosAgent] = []

            for name in agentNames {
                let skillResult = self.shell("uv run --project ~/workspace/telos telos list-skills --agent \(name)")
                let skills = self.parseSkillList(skillResult.output)
                loadedAgents.append(TelosAgent(
                    name: name,
                    skillCount: skills.count,
                    skills: skills
                ))
            }

            DispatchQueue.main.async {
                self.agents = loadedAgents
                self.isLoading = false
            }
        }
    }

    func run(agent: String?, input: String) {
        isRunning = true
        lastResult = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let agentName = agent ?? "general"
            let escapedInput = input.replacingOccurrences(of: "\"", with: "\\\"")

            // Build output file path: ~/telos/<agent>/YYYY-MM-DD-<slug>.md
            let outputDir = NSString(string: "~/telos/\(agentName)").expandingTildeInPath
            let fm = FileManager.default
            try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateStr = dateFormatter.string(from: Date())

            let slug = input
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .prefix(4)
                .joined(separator: "-")
            let outputPath = "\(outputDir)/\(dateStr)-\(slug).md"

            // Tee output to file so telos write_file tool still works,
            // and we also capture stdout for the UI
            var command = "uv run --project ~/workspace/telos telos"
            if let agent = agent {
                command += " --agent \(agent)"
            }
            command += " \"\(escapedInput)\""
            command += " 2>&1 | tee \"\(outputPath)\""

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", command]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            DispatchQueue.main.async {
                self.runningProcess = process
            }

            try? process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let success = process.terminationStatus == 0

            // Check if telos already wrote a file in the agent dir (prefer that over our tee file)
            let telosFile = self.findNewestFile(in: outputDir, excludingPath: outputPath)
            let finalOutputFile: String?

            if let telosFile = telosFile {
                // Telos wrote its own file — remove our tee duplicate
                try? fm.removeItem(atPath: outputPath)
                finalOutputFile = telosFile
            } else if fm.fileExists(atPath: outputPath) {
                // Use our tee'd output file
                finalOutputFile = outputPath
            } else {
                finalOutputFile = nil
            }

            DispatchQueue.main.async {
                self.runningProcess = nil
                self.isRunning = false
                self.lastResult = RunResult(
                    success: success,
                    output: output.trimmingCharacters(in: .whitespacesAndNewlines),
                    outputFile: finalOutputFile
                )

                // Auto-clear result after 10 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    self.lastResult = nil
                }
            }
        }
    }

    /// Find the newest file in a directory created within the last 60 seconds, excluding a given path.
    private func findNewestFile(in directory: String, excludingPath: String) -> String? {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: directory) else { return nil }
        let cutoff = Date().addingTimeInterval(-60)

        var newest: (path: String, date: Date)?
        for name in contents {
            let fullPath = "\(directory)/\(name)"
            guard fullPath != excludingPath else { continue }
            guard let attrs = try? fm.attributesOfItem(atPath: fullPath),
                  let modified = attrs[.modificationDate] as? Date,
                  modified > cutoff else { continue }
            if newest == nil || modified > newest!.date {
                newest = (fullPath, modified)
            }
        }
        return newest?.path
    }

    func cancelRun() {
        runningProcess?.terminate()
        runningProcess = nil
        isRunning = false
    }

    // MARK: - Parsing

    /// Split a Rich-table row on `│` or `┃` pipe characters and return trimmed cell values.
    private func parseTableRow(_ line: String) -> [String]? {
        // Only process lines that contain box-drawing pipe characters
        guard line.contains("│") || line.contains("┃") else { return nil }
        // Split on any box-drawing vertical bar
        let cells = line.components(separatedBy: CharacterSet(charactersIn: "│┃"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !cells.isEmpty else { return nil }
        return cells
    }

    /// Returns true if the line is a Rich-table border (━, ─, ┏, ┗, ┡, └, etc.)
    private func isTableBorder(_ line: String) -> Bool {
        let borderChars = CharacterSet(charactersIn: "━─┏┓┗┛┡┩╇╈┠┨├┤┼╋┬┴╀╁╂╃╄╅╆╉╊═╔╗╚╝╠╣╦╩╬ ")
        return line.unicodeScalars.allSatisfy { borderChars.contains($0) }
    }

    private func parseAgentList(_ output: String) -> [String] {
        // Parse Rich-table output from `telos agents`
        // Format: │ agent-name │ mode │ skills │ working dir │
        var agents: [String] = []
        var seenHeader = false

        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !isTableBorder(trimmed) else { continue }

            guard let cells = parseTableRow(trimmed) else { continue }

            // Skip the header row (contains "Agent")
            if cells.first?.lowercased() == "agent" {
                seenHeader = true
                continue
            }
            guard seenHeader else { continue }

            if let name = cells.first {
                // Strip trailing * (marks default agent)
                let cleaned = name.replacingOccurrences(of: " *", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !cleaned.isEmpty {
                    agents.append(cleaned)
                }
            }
        }
        return agents
    }

    private func parseSkillList(_ output: String) -> [TelosSkill] {
        // Parse Rich-table output from `telos list-skills --agent X`
        // Format: │ skill-name │ description │
        var skills: [TelosSkill] = []
        var seenHeader = false

        for line in output.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !isTableBorder(trimmed) else { continue }

            guard let cells = parseTableRow(trimmed) else { continue }

            // Skip the header row (contains "Skill")
            if cells.first?.lowercased() == "skill" {
                seenHeader = true
                continue
            }
            guard seenHeader else { continue }

            let name = cells[0]
            let description = cells.count > 1 ? cells[1] : ""
            if !name.isEmpty {
                skills.append(TelosSkill(name: name, description: description))
            }
        }
        return skills
    }

    private func parseOutputFile(_ output: String) -> String? {
        // Look for file paths in the output
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("~/") || trimmed.hasPrefix("/") {
                let expanded = trimmed.hasPrefix("~/")
                    ? NSString(string: trimmed).expandingTildeInPath
                    : trimmed
                if FileManager.default.fileExists(atPath: expanded) {
                    return expanded
                }
            }
        }
        return nil
    }
}
