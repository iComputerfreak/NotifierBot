//
//  SharedUtils.swift
//  
//
//  Created by Jonas Frey on 01.04.22.
//

import Foundation

public struct SharedUtils {
    
    /// Dummy formatter that replaces the DateComponentsFormatter with a fixed configuration
    /// DateComponentsFormatter is not yet available on Linux, so we have to use this one instead
    public struct DummyFormatter {
        
        let fullUnits: Bool
        
        public init(fullUnits: Bool = false) {
            self.fullUnits = fullUnits
        }
        
        public func string(from ti: TimeInterval) -> String? {
            var components: [String] = []
            var rest = ti
            let years = rest / (365 * 24 * 60 * 60)
            rest = rest.truncatingRemainder(dividingBy: (365 * 24 * 60 * 60))
            if years >= 1 {
                components.append(durationString(Int(years), .year))
            }
            
            let days = rest / (24 * 60 * 60)
            rest = rest.truncatingRemainder(dividingBy: (24 * 60 * 60))
            if days >= 1 {
                components.append(durationString(Int(days), .day))
            }
            
            let hours = rest / (60 * 60)
            rest = rest.truncatingRemainder(dividingBy: (60 * 60))
            if hours >= 1 {
                components.append(durationString(Int(hours), .hour))
            }
            
            let minutes = rest / 60
            rest = rest.truncatingRemainder(dividingBy: 60)
            if minutes >= 1 {
                components.append(durationString(Int(minutes), .minute))
            }
            
            return components.joined(separator: " ")
        }
        
        private enum Unit: String {
            case year
            case day
            case hour
            case minute
        }
        
        private func durationString(_ amount: Int, _ unit: Unit) -> String {
            return "\(amount) \(unitString(amount, unit))"
        }
        
        private func unitString(_ amount: Int, _ unit: Unit) -> String {
            if !fullUnits {
                return .init(unit.rawValue.first!)
            }
            return unit.rawValue.appending(amount == 1 ? "" : "s")
        }
    }
    
    public static var muteDurationFormatter: DummyFormatter {
//        let f = DateComponentsFormatter()
//        f.unitsStyle = .abbreviated
//        f.allowedUnits = [.year, .day, .hour, .minute]
//        return f
        return DummyFormatter(fullUnits: false)
    }
    
}
