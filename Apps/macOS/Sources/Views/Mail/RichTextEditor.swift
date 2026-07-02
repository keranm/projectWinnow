import SwiftUI
import AppKit
import WinnowUI

// MARK: - FormattedTextEditor
//
// The app's mail text editor: an NSTextView (the same machinery Apple Mail uses) wrapped
// for SwiftUI, with a floating formatting bar that appears over selected text. Native
// behaviour comes free from AppKit — Return inserts newlines, undo/redo, copy/paste,
// spellcheck, smart quotes, drag-select. ⌘B/⌘I/⌘U toggle traits and ⌘K links the
// selection while the editor is focused (⌘K falls through to thread navigation otherwise).

struct FormattedTextEditor: View {
    @Binding var text: NSAttributedString
    var placeholder: String = ""
    @Binding var isFocused: Bool
    /// Auto-grow the editor with its content inside these bounds; nil fills available space.
    var growLimits: ClosedRange<CGFloat>? = nil
    var fontSize: CGFloat = 13.5

    @State private var controller = RichTextController()
    @State private var selectionRect: CGRect?
    @State private var linkFieldShown = false
    @State private var linkURL = ""

    var body: some View {
        RichTextEditor(
            text: $text,
            placeholder: placeholder,
            isFocused: $isFocused,
            selectionRect: $selectionRect,
            growLimits: growLimits,
            fontSize: fontSize,
            controller: controller
        )
        .overlay {
            GeometryReader { geo in
                // linkFieldShown keeps the bar alive while the URL field has focus
                if let rect = selectionRect, isFocused || linkFieldShown {
                    formattingBar
                        .fixedSize()
                        .position(
                            x: min(max(rect.midX, 96), max(geo.size.width - 96, 96)),
                            y: rect.minY < 40 ? rect.maxY + 24 : rect.minY - 22
                        )
                }
            }
        }
        .onAppear {
            controller.onLinkRequest = { linkFieldShown = true }
        }
        .onChange(of: selectionRect == nil) { _, cleared in
            if cleared { linkFieldShown = false; linkURL = "" }
        }
    }

    // MARK: Formatting bar

    private var formattingBar: some View {
        HStack(spacing: 2) {
            if linkFieldShown {
                TextField("Paste or type a link…", text: $linkURL)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .frame(width: 170)
                    .padding(.horizontal, 6)
                    .onSubmit {
                        controller.applyLink(linkURL)
                        linkFieldShown = false
                        linkURL = ""
                    }
                barButton("checkmark", help: "Apply link") {
                    controller.applyLink(linkURL)
                    linkFieldShown = false
                    linkURL = ""
                }
            } else {
                barButton("bold", help: "Bold (⌘B)") { controller.toggleBold() }
                barButton("italic", help: "Italic (⌘I)") { controller.toggleItalic() }
                barButton("underline", help: "Underline (⌘U)") { controller.toggleUnderline() }
                Rectangle()
                    .fill(Color.black.opacity(0.10))
                    .frame(width: 1, height: 14)
                    .padding(.horizontal, 3)
                barButton("link", help: "Add link (⌘K)") { linkFieldShown = true }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.winnowSurface)
                .shadow(color: Color(red: 0.04, green: 0.05, blue: 0.12).opacity(0.26), radius: 18, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func barButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Color.winnowText)
                .frame(width: 26, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

// MARK: - Controller
//
// Bridges the SwiftUI formatting bar to the live NSTextView.

@MainActor
final class RichTextController {
    weak var textView: NSTextView?
    var onLinkRequest: (() -> Void)?

    func toggleBold()   { toggleTrait(.boldFontMask) }
    func toggleItalic() { toggleTrait(.italicFontMask) }

    func toggleUnderline() {
        textView?.underline(nil)
    }

    func applyLink(_ raw: String) {
        guard let tv = textView else { return }
        let range = tv.selectedRange()
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty, range.length > 0 else { return }
        if !s.contains("://") { s = "https://\(s)" }
        guard let url = URL(string: s), tv.shouldChangeText(in: range, replacementString: nil) else { return }
        tv.textStorage?.addAttribute(.link, value: url, range: range)
        tv.didChangeText()
        tv.window?.makeFirstResponder(tv)
        tv.setSelectedRange(NSRange(location: range.location + range.length, length: 0))
    }

    private func toggleTrait(_ trait: NSFontTraitMask) {
        guard let tv = textView else { return }
        let fm = NSFontManager.shared
        let range = tv.selectedRange()
        let fallback = (tv.typingAttributes[.font] as? NSFont) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)

        if range.length == 0 {
            // No selection — flip the trait for text typed next.
            var attrs = tv.typingAttributes
            let font = (attrs[.font] as? NSFont) ?? fallback
            let has = fm.traits(of: font).contains(trait)
            attrs[.font] = has ? fm.convert(font, toNotHaveTrait: trait) : fm.convert(font, toHaveTrait: trait)
            tv.typingAttributes = attrs
            return
        }

        guard let storage = tv.textStorage, tv.shouldChangeText(in: range, replacementString: nil) else { return }
        // Uniform toggle: only remove the trait when the whole selection already has it.
        var allHave = true
        storage.enumerateAttribute(.font, in: range) { value, _, _ in
            let f = (value as? NSFont) ?? fallback
            if !fm.traits(of: f).contains(trait) { allHave = false }
        }
        storage.beginEditing()
        storage.enumerateAttribute(.font, in: range) { value, r, _ in
            let f = (value as? NSFont) ?? fallback
            let converted = allHave ? fm.convert(f, toNotHaveTrait: trait) : fm.convert(f, toHaveTrait: trait)
            storage.addAttribute(.font, value: converted, range: r)
        }
        storage.endEditing()
        tv.didChangeText()
    }
}

// MARK: - NSViewRepresentable

private struct RichTextEditor: NSViewRepresentable {
    @Binding var text: NSAttributedString
    var placeholder: String
    @Binding var isFocused: Bool
    @Binding var selectionRect: CGRect?
    var growLimits: ClosedRange<CGFloat>?
    var fontSize: CGFloat
    let controller: RichTextController

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = FormattingTextView()
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: fontSize)
        textView.textColor = NSColor(Color.winnowText)
        textView.insertionPointColor = NSColor(Color.winnowAccent)
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: NSColor(Color.winnowText),
        ]
        textView.isAutomaticLinkDetectionEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.textContainerInset = NSSize(width: 0, height: 2)
        textView.placeholder = placeholder
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        let scroll = GrowingScrollView()
        scroll.documentView = textView
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.verticalScrollElasticity = growLimits == nil ? .automatic : .none
        if let limits = growLimits {
            scroll.growLimits = limits
        }

        controller.textView = textView
        textView.onLinkRequest = { [weak controller] in controller?.onLinkRequest?() }
        textView.attributedText = text
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? FormattingTextView else { return }

        if !textView.attributedString().isEqual(to: text) {
            textView.attributedText = text
            textView.setSelectedRange(NSRange(location: text.length, length: 0))
            scroll.invalidateIntrinsicContentSize()
        }

        if isFocused, textView.window != nil, textView.window?.firstResponder !== textView {
            textView.window?.makeFirstResponder(textView)
        }
    }

    // MARK: Coordinator

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: RichTextEditor
        init(_ parent: RichTextEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.attributedString().copy() as! NSAttributedString
            tv.enclosingScrollView?.invalidateIntrinsicContentSize()
        }

        func textDidBeginEditing(_ notification: Notification) {
            if !parent.isFocused { parent.isFocused = true }
        }

        func textDidEndEditing(_ notification: Notification) {
            // Keep selectionRect: NSTextView preserves its selection while unfocused,
            // and the link field needs the bar to survive the focus handoff.
            if parent.isFocused { parent.isFocused = false }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView,
                  let scroll = tv.enclosingScrollView
            else { return }
            let range = tv.selectedRange()
            guard range.length > 0,
                  let lm = tv.layoutManager, let tc = tv.textContainer
            else {
                parent.selectionRect = nil
                return
            }
            let glyphs = lm.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            var rect = lm.boundingRect(forGlyphRange: glyphs, in: tc)
            rect.origin.x += tv.textContainerOrigin.x
            rect.origin.y += tv.textContainerOrigin.y
            parent.selectionRect = tv.convert(rect, to: scroll)
        }
    }
}

// MARK: - NSTextView subclass

private final class FormattingTextView: NSTextView {
    var placeholder: String = ""
    var onLinkRequest: (() -> Void)?

    var attributedText: NSAttributedString {
        get { attributedString() }
        set { textStorage?.setAttributedString(newValue) }
    }

    // ⌘B/⌘I/⌘U/⌘K while the editor is focused. Everything else (⌘C/⌘V/⌘Z, ⌘↵ send)
    // falls through to the menu bar / responder chain.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
              let key = event.charactersIgnoringModifiers?.lowercased()
        else { return super.performKeyEquivalent(with: event) }

        let controller = RichTextController()
        controller.textView = self
        switch key {
        case "b": controller.toggleBold(); return true
        case "i": controller.toggleItalic(); return true
        case "u": underline(nil); return true
        case "k":
            guard selectedRange().length > 0 else { return super.performKeyEquivalent(with: event) }
            onLinkRequest?()
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if string.isEmpty, !placeholder.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize),
                .foregroundColor: NSColor.placeholderTextColor,
            ]
            let origin = NSPoint(x: textContainerOrigin.x + 4, y: textContainerOrigin.y)
            NSAttributedString(string: placeholder, attributes: attrs).draw(at: origin)
        }
    }
}

// MARK: - Auto-growing scroll view

private final class GrowingScrollView: NSScrollView {
    var growLimits: ClosedRange<CGFloat>?

    override var intrinsicContentSize: NSSize {
        guard let limits = growLimits,
              let tv = documentView as? NSTextView,
              let lm = tv.layoutManager, let tc = tv.textContainer
        else { return super.intrinsicContentSize }
        lm.ensureLayout(for: tc)
        let height = lm.usedRect(for: tc).height + tv.textContainerInset.height * 2
        return NSSize(
            width: NSView.noIntrinsicMetric,
            height: min(max(height, limits.lowerBound), limits.upperBound)
        )
    }
}

// MARK: - Editor text helpers

extension NSAttributedString {
    /// Text carrying the editor's standard attributes — use when seeding programmatic
    /// content (signatures, drafts, quick replies) so it matches typed text.
    static func editorText(_ string: String, fontSize: CGFloat = 13.5) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: NSColor(Color.winnowText),
        ])
    }

    var isBlank: Bool {
        string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func appendingEditorText(_ s: String, fontSize: CGFloat = 13.5) -> NSAttributedString {
        let m = NSMutableAttributedString(attributedString: self)
        m.append(.editorText(s, fontSize: fontSize))
        return m
    }
}

// MARK: - Outgoing body rendering

enum MailBodyRenderer {
    /// HTML for the outgoing message, or nil when the text carries no formatting worth
    /// shipping (plain text then goes out alone, exactly as before).
    static func htmlBody(from attr: NSAttributedString) -> String? {
        guard hasFormatting(attr) else { return nil }
        let range = NSRange(location: 0, length: attr.length)
        guard let data = try? attr.data(from: range, documentAttributes: [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func hasFormatting(_ attr: NSAttributedString) -> Bool {
        var found = false
        let fm = NSFontManager.shared
        attr.enumerateAttributes(in: NSRange(location: 0, length: attr.length)) { attrs, _, stop in
            if attrs[.link] != nil || attrs[.underlineStyle] != nil || attrs[.strikethroughStyle] != nil {
                found = true; stop.pointee = true; return
            }
            if let font = attrs[.font] as? NSFont,
               !fm.traits(of: font).intersection([.boldFontMask, .italicFontMask]).isEmpty {
                found = true; stop.pointee = true
            }
        }
        return found
    }
}
