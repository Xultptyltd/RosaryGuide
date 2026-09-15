import Foundation

enum LiturgicalCalendar {
    static var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 1
        return calendar
    }

    static func date(year: Int, month: Int, day: Int, calendar: Calendar = gregorian) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func addingDays(_ days: Int, to date: Date, calendar: Calendar = gregorian) -> Date? {
        calendar.date(byAdding: .day, value: days, to: date)
    }

    /// Gregorian Computus (Anonymous algorithm).
    static func easter(year: Int, calendar: Calendar = gregorian) -> Date? {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return date(year: year, month: month, day: day, calendar: calendar)
    }

    /// First Sunday of Advent: Sunday between 27 November and 3 December.
    static func firstSundayOfAdvent(year: Int, calendar: Calendar = gregorian) -> Date? {
        guard let november27 = date(year: year, month: 11, day: 27, calendar: calendar) else { return nil }
        let weekday = calendar.component(.weekday, from: november27)
        let daysUntilSunday = (8 - weekday) % 7
        return addingDays(daysUntilSunday, to: november27, calendar: calendar)
    }

    /// Baptism of the Lord: Sunday after 6 January, or Monday 7 January if 6 January is Sunday.
    static func baptismOfTheLord(year: Int, calendar: Calendar = gregorian) -> Date? {
        guard let january6 = date(year: year, month: 1, day: 6, calendar: calendar) else { return nil }
        if calendar.component(.weekday, from: january6) == 1 {
            return addingDays(1, to: january6, calendar: calendar)
        }
        let weekday = calendar.component(.weekday, from: january6)
        let daysUntilSunday = (8 - weekday) % 7
        return addingDays(daysUntilSunday, to: january6, calendar: calendar)
    }

    static func ashWednesday(year: Int, calendar: Calendar = gregorian) -> Date? {
        easter(year: year, calendar: calendar).flatMap { addingDays(-46, to: $0, calendar: calendar) }
    }

    static func pentecost(year: Int, calendar: Calendar = gregorian) -> Date? {
        easter(year: year, calendar: calendar).flatMap { addingDays(49, to: $0, calendar: calendar) }
    }

    static func holyThursday(year: Int, calendar: Calendar = gregorian) -> Date? {
        easter(year: year, calendar: calendar).flatMap { addingDays(-3, to: $0, calendar: calendar) }
    }

    static func season(on date: Date, calendar: Calendar = gregorian) -> LiturgicalSeason {
        let year = calendar.component(.year, from: date)
        let day = calendar.startOfDay(for: date)

        guard
            let advent = firstSundayOfAdvent(year: year, calendar: calendar).map({ calendar.startOfDay(for: $0) }),
            let christmas = self.date(year: year, month: 12, day: 25, calendar: calendar).map({ calendar.startOfDay(for: $0) }),
            let baptism = baptismOfTheLord(year: year, calendar: calendar).map({ calendar.startOfDay(for: $0) }),
            let ash = ashWednesday(year: year, calendar: calendar).map({ calendar.startOfDay(for: $0) }),
            let easterSunday = easter(year: year, calendar: calendar).map({ calendar.startOfDay(for: $0) }),
            let holyThu = holyThursday(year: year, calendar: calendar).map({ calendar.startOfDay(for: $0) }),
            let pentecostSunday = pentecost(year: year, calendar: calendar).map({ calendar.startOfDay(for: $0) })
        else {
            return .ordinary
        }

        if day >= advent {
            return day < christmas ? .advent : .christmas
        }

        if day <= baptism {
            return .christmas
        }

        if day >= holyThu && day < easterSunday {
            return .triduum
        }

        if day >= ash && day < easterSunday {
            return .lent
        }

        if day >= easterSunday && day <= pentecostSunday {
            return .easter
        }

        return .ordinary
    }

    static func weekdayName(for date: Date, calendar: Calendar = gregorian) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    /// US-style: solemnity observed on the Sunday on or after `date` (if not already Sunday).
    static func sundayOnOrAfter(_ date: Date, calendar: Calendar = gregorian) -> Date {
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday
        if weekday == 1 { return calendar.startOfDay(for: date) }
        return addingDays(8 - weekday, to: date, calendar: calendar) ?? calendar.startOfDay(for: date)
    }

    /// Monday after Divine Mercy Sunday (octave of Easter) — typical Annunciation transfer landing.
    static func mondayAfterDivineMercy(year: Int, calendar: Calendar = gregorian) -> Date? {
        easter(year: year, calendar: calendar).flatMap { addingDays(8, to: $0, calendar: calendar) }
    }

    static func isInHolyWeekOrEasterOctave(_ date: Date, year: Int, calendar: Calendar = gregorian) -> Bool {
        guard let easter = easter(year: year, calendar: calendar),
              let palm = addingDays(-7, to: easter, calendar: calendar),
              let octaveEnd = addingDays(7, to: easter, calendar: calendar) else { return false }
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: palm) && day <= calendar.startOfDay(for: octaveEnd)
    }

}
