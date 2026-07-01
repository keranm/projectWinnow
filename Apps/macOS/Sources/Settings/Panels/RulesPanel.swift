import SwiftUI
import WinnowCore

struct RulesPanel: View {
    @Environment(WinnowSettings.self) private var settings
    @State private var selectedRuleID: UUID?
    @State private var editingRule: Rule?

    var body: some View {
        @Bindable var s = settings
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(title: "Rules")

            Text("Rules run automatically when mail arrives. Conditions are checked on your Mac — nothing leaves the device.")
                .font(.system(size: 12.5))
                .foregroundStyle(Color.winnowTextSecondary)

            rulesList

            HStack(spacing: 10) {
                Button {
                    let rule = Rule()
                    settings.upsertRule(rule)
                    editingRule = rule
                } label: {
                    Label("Add Rule", systemImage: "plus")
                        .font(.system(size: 12.5, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.winnowAccent)
                .controlSize(.small)

                Spacer()
            }
        }
        .sheet(item: $editingRule) { rule in
            RuleEditorSheet(rule: rule) { updated in
                settings.upsertRule(updated)
                editingRule = nil
            } onCancel: {
                // If the rule has no conditions yet, it was just created — remove it
                if settings.rules.first(where: { $0.id == rule.id })?.conditions.isEmpty == true {
                    settings.deleteRule(id: rule.id)
                }
                editingRule = nil
            }
            .environment(settings)
        }
    }

    // MARK: - Rules list

    @ViewBuilder
    private var rulesList: some View {
        if settings.rules.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                ForEach(settings.rules) { rule in
                    RuleRow(rule: rule,
                            onEdit:   { editingRule = rule },
                            onDelete: { settings.deleteRule(id: rule.id) },
                            onToggle: {
                                var updated = rule
                                updated.isEnabled.toggle()
                                settings.upsertRule(updated)
                            })
                    if rule.id != settings.rules.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Color.winnowTextTertiary)
            Text("No rules yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.winnowTextSecondary)
            Text("Add a rule to automatically sort incoming mail.")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.winnowTextQuaternary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.winnowHover.opacity(0.5))
        )
    }
}

// MARK: - Rule row

private struct RuleRow: View {
    let rule: Rule
    let onEdit:   () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(get: { rule.isEnabled }, set: { _ in onToggle() }))
                .toggleStyle(.checkbox)
                .labelsHidden()
                .controlSize(.small)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(rule.isEnabled ? Color.winnowText : Color.winnowTextTertiary)

                Text(ruleDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.winnowTextQuaternary)
                    .lineLimit(1)
            }

            Spacer()

            if isHovered {
                HStack(spacing: 4) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.winnowTextSecondary)
                            .padding(5)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color.winnowHover))
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.winnowAlert)
                            .padding(5)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color.winnowHover))
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(count: 2) { onEdit() }
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }

    private var ruleDescription: String {
        let conditions = rule.conditions.map { c in
            "\(c.field.displayName) contains \"\(c.value)\""
        }.joined(separator: rule.conditionMatch == .all ? " AND " : " OR ")

        let actions = rule.actions.map { $0.displayName }.joined(separator: ", ")
        return conditions.isEmpty ? "No conditions" : "\(conditions) → \(actions)"
    }
}

// MARK: - Rule editor sheet

struct RuleEditorSheet: View {
    @State var rule: Rule
    let onSave:   (Rule) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Edit Rule")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.winnowText)
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.winnowTextSecondary)
                    .font(.system(size: 13))
                Button("Save") { onSave(rule) }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.winnowAccent)
                    .disabled(!isValid)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.winnowTextSecondary)
                        TextField("Rule name", text: $rule.name)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                    }

                    // Conditions
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("When").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.winnowTextSecondary)
                            Picker("", selection: $rule.conditionMatch) {
                                ForEach(ConditionMatch.allCases, id: \.self) { m in
                                    Text(m.displayName).tag(m)
                                }
                            }
                            .labelsHidden()
                            .fixedSize()
                            Text("match:").font(.system(size: 12)).foregroundStyle(Color.winnowTextSecondary)
                            Spacer()
                        }

                        ForEach(rule.conditions.indices, id: \.self) { idx in
                            ConditionRow(condition: $rule.conditions[idx]) {
                                rule.conditions.remove(at: idx)
                            }
                        }

                        Button {
                            rule.conditions.append(RuleCondition())
                        } label: {
                            Label("Add Condition", systemImage: "plus.circle")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.winnowAccent)
                        }
                        .buttonStyle(.plain)
                    }

                    // Actions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Then").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.winnowTextSecondary)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(RuleAction.allCases, id: \.self) { action in
                                let isOn = rule.actions.contains(action)
                                Button {
                                    if isOn {
                                        rule.actions.removeAll { $0 == action }
                                    } else {
                                        rule.actions.append(action)
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: isOn ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 14))
                                            .foregroundStyle(isOn ? Color.winnowAccent : Color.winnowTextQuaternary)

                                        Image(systemName: action.systemImage)
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.winnowTextSecondary)

                                        Text(action.displayName)
                                            .font(.system(size: 13))
                                            .foregroundStyle(Color.winnowText)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 440, height: 420)
        .background(Color.winnowSurface)
    }

    private var isValid: Bool {
        !rule.name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !rule.conditions.isEmpty &&
        !rule.actions.isEmpty
    }
}

// MARK: - Condition row

private struct ConditionRow: View {
    @Binding var condition: RuleCondition
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Picker("", selection: $condition.field) {
                ForEach(RuleCondition.ConditionField.allCases, id: \.self) { f in
                    Text(f.displayName).tag(f)
                }
            }
            .labelsHidden()
            .fixedSize()

            Text("contains")
                .font(.system(size: 12))
                .foregroundStyle(Color.winnowTextSecondary)

            TextField("value", text: $condition.value)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13))

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.winnowTextQuaternary)
            }
            .buttonStyle(.plain)
        }
    }
}
