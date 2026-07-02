import Foundation

public enum IntelligenceResult: Sendable {
    case summary(String)
    case suggestedReplies([String])
    case packageTracking(PackageInfo)
    case flightInfo(FlightInfo)
    case calendarEvent(CalendarEventInfo)
    case bill(BillInfo)

    public struct PackageInfo: Sendable {
        public let carrier: String
        public let trackingNumber: String
        public let status: Status
        public let estimatedDelivery: Date?

        public enum Status: Sendable {
            case inTransit, outForDelivery, delivered
            public var label: String {
                switch self {
                case .inTransit: return "In transit"
                case .outForDelivery: return "Out for delivery"
                case .delivered: return "Delivered"
                }
            }
        }

        public init(carrier: String, trackingNumber: String, status: Status, estimatedDelivery: Date? = nil) {
            self.carrier = carrier
            self.trackingNumber = trackingNumber
            self.status = status
            self.estimatedDelivery = estimatedDelivery
        }
    }

    public struct FlightInfo: Sendable {
        public let flightNumber: String
        public let from: String
        public let to: String
        public let departureDate: Date
        public let gate: String?

        public init(flightNumber: String, from: String, to: String, departureDate: Date, gate: String? = nil) {
            self.flightNumber = flightNumber
            self.from = from
            self.to = to
            self.departureDate = departureDate
            self.gate = gate
        }
    }

    public struct CalendarEventInfo: Sendable {
        public let title: String
        public let startDate: Date
        public let endDate: Date?
        public let location: String?
        public let organiser: String?
        public let organiserEmail: String?
        public let guests: [String]
        public let meetingLink: String?
        public let isCancelled: Bool

        public init(
            title: String,
            startDate: Date,
            endDate: Date? = nil,
            location: String? = nil,
            organiser: String? = nil,
            organiserEmail: String? = nil,
            guests: [String] = [],
            meetingLink: String? = nil,
            isCancelled: Bool = false
        ) {
            self.title = title
            self.startDate = startDate
            self.endDate = endDate
            self.location = location
            self.organiser = organiser
            self.organiserEmail = organiserEmail
            self.guests = guests
            self.meetingLink = meetingLink
            self.isCancelled = isCancelled
        }
    }

    public struct BillInfo: Sendable {
        public let merchant: String
        public let amount: Double
        public let currency: String
        public let dueDate: Date?
        public let previousAmount: Double?

        public var hasPriceChange: Bool { previousAmount != nil && previousAmount != amount }

        public init(merchant: String, amount: Double, currency: String, dueDate: Date? = nil, previousAmount: Double? = nil) {
            self.merchant = merchant
            self.amount = amount
            self.currency = currency
            self.dueDate = dueDate
            self.previousAmount = previousAmount
        }
    }
}
