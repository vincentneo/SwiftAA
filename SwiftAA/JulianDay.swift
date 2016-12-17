//
//  JulianDay.swift
//  SwiftAA
//
//  Created by Cédric Foellmi on 26/06/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import Foundation

public struct JulianDay: NumericType {
    public var value: Double
    public init(_ value: Double) {
        self.value = value
    }
}

extension JulianDay: ExpressibleByIntegerLiteral {
    public init(integerLiteral: IntegerLiteralType) {
        self.init(Double(integerLiteral))
    }
}

extension JulianDay: ExpressibleByFloatLiteral {
    public init(floatLiteral: FloatLiteralType) {
        self.init(Double(floatLiteral))
    }
}

public extension JulianDay {
    /**
     Transform a julian day into a Date.
     
     - returns: The corresponding Date instance.
     */
    public func date() -> Date {
        let X: Double = self.value+0.5
        let Z: Double = floor(X)
        let F: Double = X - Z
        let Y: Double = floor((Z-1867216.25)/36524.25)
        let A: Double = Z+1+Y-floor(Y/4)
        let B: Double = A+1524
        let C: Double = floor((B-122.1)/365.25)
        let D: Double = floor(365.25*C)
        let G: Double = floor((B-D)/30.6001)
        let month: Double = (G<13.5) ? (G-1) : (G-13)
        let year: Double = (month<2.5) ? (C-4715) : (C-4716)
        var UT: Double = B-D-floor(30.6001*G)+F
        let day: Double = floor(UT)
        UT -= floor(UT)
        UT *= 24.0
        let hour: Double = floor(UT)
        UT -= floor(UT)
        UT *= 60.0
        let minute: Double = floor(UT)
        UT -= floor(UT)
        UT *= 60.0
        let second: Double = UT
        
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month)
        components.day = Int(day)
        components.hour = Int(hour)
        components.minute = Int(minute)
        components.second = Int(floor(second))
        components.nanosecond = Int((second-floor(second))*1e6)
        
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)!
    }
    
    public var modified: JulianDay {
        get { return JulianDay(self.value - ModifiedJulianDayZero) }
    }
    
    /**
     Computes the mean sidereal time for the Greenwich meridian.
     That is, the Greenwich hour angle of the mean vernal point (the intersection of the ecliptic
     of the date with the mean equator of the date).
     
     - returns: The sidereal time in hours.
     */
    public func meanGreenwichSiderealTime() -> Hour {
        return Hour(KPCAASidereal_MeanGreenwichSiderealTime(self.value))
    }

    /**
     Computes the mean sidereal time for a given longitude on Earth.
     
     - parameter longitude: Positively Westward (see AA p. 93 for explanations).
     Basically: this is the contrary of IAU decision. But this orientation is consistent
     with longitude orientation in all other planets!
     
     - returns: The sidereal time in hours.
     */
    public func meanLocalSiderealTime(forGeographicLongitude longitude: Double) -> Hour {
        return Hour(self.meanGreenwichSiderealTime().value - RadiansToHours(DegreesToRadians(longitude)))
    }

    /**
     Computes the apparent sidereal time.
     That is, the Greenwich hour angle of the true vernal equinox, obtained by adding a correction
     that depends on the nutation in longitude, and the true obliquity of the ecliptic.
     
     - returns: The sidereal time in hours.
     */
    public func apparentGreenwichSiderealTime() -> Hour {
        return Hour(KPCAASidereal_ApparentGreenwichSiderealTime(self.value))
    }
    
    // MARK: - Dynamical Times
    
    public func deltaT() -> JulianDay {
        return JulianDay(KPCAADynamicalTime_DeltaT(self.value))
    }
    
    public func cumulativeLeapSeconds() -> JulianDay {
        return JulianDay(KPCAADynamicalTime_CumulativeLeapSeconds(self.value))
    }

    public func TTtoUTC() -> JulianDay {
        return JulianDay(KPCAADynamicalTime_TT2UTC(self.value))
    }

    public func UTCtoTT() -> JulianDay {
        return JulianDay(KPCAADynamicalTime_UTC2TT(self.value))
    }

    public func TTtoTAI() -> JulianDay {
        return JulianDay(KPCAADynamicalTime_TT2TAI(self.value))
    }

    public func TAItoTT() -> JulianDay {
        return JulianDay(KPCAADynamicalTime_TAI2TT(self.value))
    }

    public func TTtoUT1() -> JulianDay {
        return JulianDay(KPCAADynamicalTime_TT2UT1(self.value))
    }

    public func UT1toTT() -> JulianDay {
        return JulianDay(KPCAADynamicalTime_UT12TT(self.value))
    }

    public func UT1minusUTC() -> JulianDay {
        return JulianDay(KPCAADynamicalTime_UT1MinusUTC(self.value))
    }
}

public extension Date {
    /**
     Computes the Julian Day from the date.
     
     - returns: The value of the Julian Day, as a fractional (double) number.
     */
    public func julianDay() -> JulianDay {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: self)
        
        let year = Double(components.year!)
        let month = Double(components.month!)
        let day = Double(components.day!)
        let hour = Double(components.hour!)
        let minute = Double(components.minute!)
        let second = Double(components.second!)
        let nanosecond = Double(components.nanosecond!)
        
        var jd = 367.0*year - floor( 7.0*( year+floor((month + 9.0) / 12.0)) / 4.0 )
        jd -= floor( 3.0*(floor((year+(month - 9.0)/7.0)/100.0) + 1.0)/4.0)
        jd += floor(275.0*month/9.0) + day + 1721028.5
        jd += (hour + minute/60.0 + (second+nanosecond/1e6)/3600.0)/24.0
        
        return JulianDay(jd)
    }
    
    public var year: Int {
        get { return Calendar(identifier: .gregorian).component(.year, from: self) }
    }
    
    public var month: Int {
        get { return Calendar(identifier: .gregorian).component(.month, from: self) }
    }

    public var day: Int {
        get { return Calendar(identifier: .gregorian).component(.day, from: self) }
    }

    public var hour: Int {
        get { return Calendar(identifier: .gregorian).component(.hour, from: self) }
    }

    public var minute: Int {
        get { return Calendar(identifier: .gregorian).component(.minute, from: self) }
    }

    public var second: Int {
        get { return Calendar(identifier: .gregorian).component(.second, from: self) }
    }

    public var nanosecond: Int {
        get { return Calendar(identifier: .gregorian).component(.nanosecond, from: self) }
    }
    
    public var isLeap : Bool {
        get { return ((self.year % 100) == 0) ? (self.year % 400) == 0 : (self.year % 4) == 0 }
    }
    
    public func januaryFirstDate() -> Date {
        var components = DateComponents()
        components.year = self.year
        components.month = 1
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        return Calendar(identifier: .gregorian).date(from: components)!
    }
    
    public var fractionalYear: Double {
        get {
            let daysCount = (self.isLeap) ? 366.0 : 365.0
            return Double(self.year) + ((self.julianDay().value - self.januaryFirstDate().julianDay().value) / daysCount)
        }
    }
}
