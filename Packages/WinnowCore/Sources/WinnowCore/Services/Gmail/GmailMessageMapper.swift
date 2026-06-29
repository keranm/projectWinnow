import Foundation

enum GmailMessageMapper {
    static func mapThread(_ gmailThread: GmailThread, accountID: String) -> MailThread {
        let messages = (gmailThread.messages ?? []).map {
            mapMessage($0, threadID: gmailThread.id, accountID: accountID)
        }
        let lastMessage = messages.last
        let allLabelIDs = gmailThread.messages?.last?.labelIds ?? []
        let labels = Set(allLabelIDs)

        let date = lastMessage?.date ?? Date()
        let subject = lastMessage.map { messageSubject($0) } ?? "(No Subject)"

        return MailThread(
            id: gmailThread.id,
            accountID: accountID,
            subject: subject,
            snippet: gmailThread.messages?.last?.snippet ?? "",
            messages: messages,
            labels: labels,
            isRead: !labels.contains("UNREAD"),
            lastMessageDate: date
        )
    }

    static func mapMessage(_ m: GmailMessage, threadID: String, accountID: String) -> MailMessage {
        let from = parseParticipant(m.header("From") ?? "")
        let to   = parseParticipants(m.header("To") ?? "")
        let sub  = m.header("Subject") ?? "(No Subject)"
        let date = m.internalDate.flatMap(Double.init).map { Date(timeIntervalSince1970: $0 / 1000) } ?? Date()

        let body: MessageBody? = m.plainTextBody.map { .plain($0) }

        return MailMessage(
            id: m.id,
            threadID: threadID,
            accountID: accountID,
            from: from,
            to: to,
            subject: sub,
            snippet: m.snippet ?? "",
            body: body,
            date: date,
            labels: Set(m.labelIds ?? []),
            isRead: !(m.labelIds?.contains("UNREAD") ?? false)
        )
    }

    // MARK: - Helpers

    private static func messageSubject(_ m: MailMessage) -> String { m.subject }

    private static func parseParticipant(_ raw: String) -> Participant {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let lt = s.firstIndex(of: "<"), let gt = s.lastIndex(of: ">") {
            let name  = String(s[s.startIndex..<lt])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let email = String(s[s.index(after: lt)..<gt])
            return Participant(name: name.isEmpty ? nil : name, email: email)
        }
        return Participant(email: s)
    }

    private static func parseParticipants(_ raw: String) -> [Participant] {
        raw.components(separatedBy: ",")
            .map { parseParticipant($0) }
            .filter { !$0.email.isEmpty }
    }
}
