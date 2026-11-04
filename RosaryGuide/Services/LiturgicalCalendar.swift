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

    /// Civil year of `date` on the Gregorian calendar. `Calendar.current` may be Buddhist,
    /// Japanese, or another era, and feeding that year into Computus or a fixed feast
    /// lands the observance centuries away from the day the user is looking at.
    static func year(of date: Date) -> Int {
        gregorian.component(.year, from: date)
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

    /// US Epiphany observance: Sunday on or after 2 January (transferred from 6 January).
    static func epiphany(year: Int, calendar: Calendar = gregorian) -> Date? {
        guard let jan2 = date(year: year, month: 1, day: 2, calendar: calendar) else { return nil }
        return sundayOnOrAfter(jan2, calendar: calendar)
    }

    /// Baptism of the Lord — US particular calendar, derived from the same Epiphany date the app uses.
    /// Normally the Sunday after Epiphany. When Epiphany falls on 7 or 8 January (US transferred table),
    /// Baptism is the following Monday so it never precedes Epiphany and Christmas Time ends coherently.
    static func baptismOfTheLord(year: Int, calendar: Calendar = gregorian) -> Date? {
        guard let epiphanyDate = epiphany(year: year, calendar: calendar) else { return nil }
        let day = calendar.component(.day, from: epiphanyDate)
        if day == 7 || day == 8 {
            return addingDays(1, to: epiphanyDate, calendar: calendar)
        }
        return addingDays(7, to: epiphanyDate, calendar: calendar)
    }

    /// Sacred Heart: Friday after the second Sunday after Pentecost (Easter + 68).
    static func sacredHeart(year: Int, calendar: Calendar = gregorian) -> Date? {
        easter(year: year, calendar: calendar).flatMap { addingDays(68, to: $0, calendar: calendar) }
    }

    /// Holy Family: Sunday within the Octave of Christmas (26–31 December), or 30 December
    /// when Christmas is a Sunday and the octave has no Sunday.
    static func holyFamily(year: Int, calendar: Calendar = gregorian) -> Date? {
        guard let dec26 = date(year: year, month: 12, day: 26, calendar: calendar) else { return nil }
        let sunday = sundayOnOrAfter(dec26, calendar: calendar)
        if calendar.component(.month, from: sunday) == 12,
           calendar.component(.day, from: sunday) <= 31 {
            return sunday
        }
        return date(year: year, month: 12, day: 30, calendar: calendar)
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

    /// US-style: solemnity observed on the Sunday on or after `date` (if not already Sunday).
    static func sundayOnOrAfter(_ date: Date, calendar: Calendar = gregorian) -> Date {
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday
        if weekday == 1 { return calendar.startOfDay(for: date) }
        return addingDays(8 - weekday, to: date, calendar: calendar) ?? calendar.startOfDay(for: date)
    }

    /// Monday after Divine Mercy Sunday (octave of Easter) — Annunciation transfer when
    /// 25 March falls in Holy Week or the Easter Octave.
    static func mondayAfterDivineMercy(year: Int, calendar: Calendar = gregorian) -> Date? {
        easter(year: year, calendar: calendar).flatMap { addingDays(8, to: $0, calendar: calendar) }
    }

    /// 25 March, or the next day when that is a Sunday of Lent. Holy Week and the Easter
    /// Octave outrank the solemnity, so it then waits until the Monday after Divine Mercy Sunday.
    static func annunciation(year: Int, calendar: Calendar = gregorian) -> Date? {
        guard let mar25 = date(year: year, month: 3, day: 25, calendar: calendar) else { return nil }
        if isInHolyWeekOrEasterOctave(mar25, year: year, calendar: calendar) {
            return mondayAfterDivineMercy(year: year, calendar: calendar)
        }
        if calendar.component(.weekday, from: mar25) == 1 {
            return addingDays(1, to: mar25, calendar: calendar)
        }
        return mar25
    }

    /// 19 March. A Sunday of Lent keeps it the next day. Holy Week keeps it on the Saturday
    /// before Palm Sunday (the Monday would still be inside Holy Week).
    static func saintJoseph(year: Int, calendar: Calendar = gregorian) -> Date? {
        guard let mar19 = date(year: year, month: 3, day: 19, calendar: calendar) else { return nil }
        if isInHolyWeekOrEasterOctave(mar19, year: year, calendar: calendar),
           let easter = easter(year: year, calendar: calendar),
           let palm = addingDays(-7, to: easter, calendar: calendar) {
            return addingDays(-1, to: palm, calendar: calendar)
        }
        if calendar.component(.weekday, from: mar19) == 1 {
            return addingDays(1, to: mar19, calendar: calendar)
        }
        return mar19
    }

    /// 8 December. An Advent Sunday outranks the solemnity, so it is kept the next day.
    static func immaculateConception(year: Int, calendar: Calendar = gregorian) -> Date? {
        guard let dec8 = date(year: year, month: 12, day: 8, calendar: calendar) else { return nil }
        if calendar.component(.weekday, from: dec8) == 1 {
            return addingDays(1, to: dec8, calendar: calendar)
        }
        return dec8
    }

    static func isInHolyWeekOrEasterOctave(_ date: Date, year: Int, calendar: Calendar = gregorian) -> Bool {
        guard let easter = easter(year: year, calendar: calendar),
              let palm = addingDays(-7, to: easter, calendar: calendar),
              let octaveEnd = addingDays(7, to: easter, calendar: calendar) else { return false }
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: palm) && day <= calendar.startOfDay(for: octaveEnd)
    }

}
