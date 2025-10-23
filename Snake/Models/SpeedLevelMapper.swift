import Foundation

enum SpeedLevelMapper {
    static func level(
        for engineSpeed: Double,
        minVelocity: Double,
        maxVelocity: Double,
        step: Double,
        steps: Int
    ) -> Int {
        guard step > 0 else { return 1 }
        let raw = (maxVelocity - engineSpeed) / step
        let level = Int(raw.rounded()) + 1
        return min(max(level, 1), steps)
    }

    static func engineSpeed(
        forLevel level: Int,
        minVelocity: Double,
        maxVelocity: Double,
        step: Double,
        steps: Int
    ) -> Double {
        guard step > 0 else { return maxVelocity }
        let clampedLevel = min(max(level, 1), steps)
        let speed = maxVelocity - (Double(clampedLevel - 1) * step)
        return min(max(speed, minVelocity), maxVelocity)
    }
}
