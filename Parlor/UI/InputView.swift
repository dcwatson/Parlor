//
//  InputView.swift
//  Parlor
//
//  Created by Daniel Watson on 2/24/26.
//

import SwiftUI

struct InputView: View {
    let placeholder: String
    @Binding var text: String
    let focused: FocusState<Bool>.Binding

    let onSend: (String) -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: 6) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused(focused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(BackgroundStyle().secondary.opacity(0.5))
                )
                .foregroundStyle(.primary)
                .submitLabel(.send)
                .onSubmit {
                    onSend(text)
                }
                .overlay(alignment: .trailing) {
                    HStack {
                        Button {
                        } label: {
                            Label("Emoji", systemImage: "face.smiling")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)

                        Button {
                        } label: {
                            Label("Add", systemImage: "plus")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .foregroundStyle(.secondary)
                }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(BackgroundStyle().tertiary.opacity(0.2))
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(10)
    }
}

#Preview {
    @Previewable @State var message = ""
    @Previewable @FocusState var focused: Bool
    InputView(placeholder: "Send Message", text: $message, focused: $focused) { _ in }
        .padding()
}
