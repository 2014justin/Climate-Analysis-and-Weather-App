import Foundation

struct SunTimes {
    let sunrise: Date
    let sunset: Date
}

enum WeatherAlmanac {
    static func dayOfYear(for date: Date = Date()) -> Int {
        let calendar = Calendar.current
        
        return calendar.ordinality(
            of: .day,
            in: .year,
            for: date
        ) ?? 1
    }
    /// This section you put in the fits for T max, T min, S(t) and s(t) for each selectable climate station. They are organized
    /// exactly in that order. So far the code goes like:
    /// North Las Vegas -> Ely
    ///
    /// All fits are trunctuated fourier series usually up to at least the fourth order harmonic.
    ///
    ///--------- NORTH LAS VEGAS, NV--------
    /// Define the climatological best fit of T max(t). This is a truncated Fourier series
    /// This one is for North Las Vegas
    static func normalHighFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 80.2578
            - 22.3325 * cos(w * day)
            - 5.8368 * sin(w * day)
            - 1.0686 * cos(2.0 * w * day)
            + 2.3288 * sin(2.0 * w * day)
            - 0.7260 * cos(3.0 * w * day)
            + 0.6903 * sin(3.0 * w * day)
            + 0.4119 * cos(4.0 * w * day)
            + 0.1014 * sin(4.0 * w * day)
            + 0.0233 * cos(5.0 * w * day)
            + 0.0410 * sin(5.0 * w * day)
    }
    /// Define the climatological best fit of T min(t) for NorthLasVegas. Fourier series
    static func normallowFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 56.4961
            - 18.8469 * cos(w * day)
            - 5.6570 * sin(w * day)
            - 0.4693 * cos(2.0 * w * day)
            + 2.5046 * sin(2.0 * w * day)
            - 0.6043 * cos(3.0 * w * day)
            + 0.3400 * sin(3.0 * w * day)
            - 0.0912 * cos(4.0 * w * day)
            + 0.1178 * sin(4.0 * w * day)
            + 0.2091 * cos(5.0 * w * day)
            + 0.2343 * sin(5.0 * w * day)
    }
    /// Solar insolation fit S(t) for North Las Vegas kWh/m^2/day
    static func solarInsolation(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 8.20645954
            - 3.54670322 * cos(w * day)
            + 0.69864850 * sin(w * day)
            - 0.20394809 * cos(2.0 * w * day)
            + 0.06474188 * sin(2.0 * w * day)
            + 0.02111741 * cos(3.0 * w * day)
            - 0.01326158 * sin(3.0 * w * day)
            + 0.00276769 * cos(4.0 * w * day)
            - 0.00233470 * sin(4.0 * w * day)
    }
    /// This is for North Las Vegas normal solar insolation s(t)
    static func normalizedSolarInsolation(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 0.52918732
            - 0.49395897 * cos(w * day)
            + 0.09730267 * sin(w * day)
            - 0.02840440 * cos(2.0 * w * day)
            + 0.00901678 * sin(2.0 * w * day)
            + 0.00294108 * cos(3.0 * w * day)
            - 0.00184698 * sin(3.0 * w * day)
            + 0.00038546 * cos(4.0 * w * day)
            - 0.00032516 * sin(4.0 * w * day)
    }
    
    
    /// ----------- FAIRBANKS AK -------------
    /// Fairbanks Alaska T max(t) fourier fit.
    static func fairbanksNormalHighFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let x = Double(t)

        return 38.8199
            - 37.4031 * cos(w * x)
            - 2.5472 * sin(w * x)
            - 1.6246 * cos(2.0 * w * x)
            + 0.5402 * sin(2.0 * w * x)
            + 0.8634 * cos(3.0 * w * x)
            + 0.3478 * sin(3.0 * w * x)
    }
    /// Fairbanks Alaska T min(t) fourier fit
    static func fairbanksNormalLowFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let x = Double(t)

        return 19.5689
            - 34.3778 * cos(w * x)
            - 7.6762 * sin(w * x)
            - 0.1941 * cos(2.0 * w * x)
            - 1.1813 * sin(2.0 * w * x)
            + 0.8105 * cos(3.0 * w * x)
            + 0.6643 * sin(3.0 * w * x)
    }
    /// Fairbanks Alaska S(t) solar insolatoin kWh/m^2/day
    static func fairbanksSolarEnergy(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)

        let solarEnergy = 2.567
            - 2.802 * cos(w * day)
            + 0.706 * sin(w * day)
            + 0.179 * cos(2.0 * w * day)
            - 0.231 * sin(2.0 * w * day)
            + 0.030 * cos(3.0 * w * day)
            - 0.028 * sin(3.0 * w * day)

        return max(0.0, solarEnergy)
    }
    /// Normalized Solar Insolation for Fairbanks Alaska s(t)
    static func fairbanksNormalizedSolarEnergy(dayOfYear t: Int) -> Double {
        let maximumSolarEnergy = 5.69034

        return fairbanksSolarEnergy(dayOfYear: t) / maximumSolarEnergy
    }
    
    /// --------ELY NV--------
    /// Ely, NV T max(t) Fourier fit. Afternoon highs
    static func elyNormalHighFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 63.18718971
            - 22.74554608 * cos(w * day)
            - 8.34772629 * sin(w * day)
            - 0.25182127 * cos(2.0 * w * day)
            + 3.23397219 * sin(2.0 * w * day)
            - 0.98226296 * cos(3.0 * w * day)
            - 0.31732103 * sin(3.0 * w * day)
    }
    /// Ely, NV T min(t) Fourier fit. Morning Lows. Expect asymmetry between T max and T min in terms of their inflection points
    static func elyNormalLowFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 31.65452857
            - 16.48367211 * cos(w * day)
            - 4.95835081 * sin(w * day)
            - 0.30083607 * cos(2.0 * w * day)
            + 2.77576809 * sin(2.0 * w * day)
            - 0.62599041 * cos(3.0 * w * day)
            - 0.83561436 * sin(3.0 * w * day)
            - 0.15929541 * cos(4.0 * w * day)
            + 0.25551139 * sin(4.0 * w * day)
    }
    /// Ely, NV Solar Insolation Curve S(t) with units of kWh/m^2/day
    static func elySolarEnergy(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 7.91238251
            - 3.82915622 * cos(w * day)
            + 0.74837118 * sin(w * day)
            - 0.15854103 * cos(2.0 * w * day)
            + 0.04667907 * sin(2.0 * w * day)
            + 0.02362530 * cos(3.0 * w * day)
            - 0.01458992 * sin(3.0 * w * day)
    }
    /// Ely, NV normalized Solar insolation curve s(t) ; unitless
    static func elyNormalizedSolarEnergy(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 0.52062648
            - 0.494220299 * cos(w * day)
            + 0.09658591 * sin(w * day)
            - 0.02041205 * cos(2.0 * w * day)
            + 0.00600574 * sin(2.0 * w * day)
            + 0.00304995 * cos(3.0 * w * day)
            - 0.00188331 * sin(3.0 * w * day)
    }
    
    /// --------STANLEY, ID--------
    /// Start with Stanley, ID T max(t)
    static func stanleyNormalHighFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 53.13698630
            - 23.78335045 * cos(w * day)
            - 8.60148391 * sin(w * day)
            - 1.60678722 * cos(2.0 * w * day)
            + 4.49183861 * sin(2.0 * w * day)
            - 0.59036357 * cos(3.0 * w * day)
            + 0.15816628 * sin(3.0 * w * day)
            - 0.52764528 * cos(4.0 * w * day)
            + 0.71800238 * sin(4.0 * w * day)
            + 0.67521048 * cos(5.0 * w * day)
            - 0.34959011 * sin(5.0 * w * day)
            + 0.42287563 * cos(6.0 * w * day)
            + 0.77138060 * sin(6.0 * w * day)
    }
    /// Then do Stanely, ID T min(t)
    static func stanleyNormalLowFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 21.87397260
            - 16.34563931 * cos(w * day)
            - 5.05403390 * sin(w * day)
            - 1.02233009 * cos(2.0 * w * day)
            + 0.25898060 * sin(2.0 * w * day)
            - 0.54796563 * cos(3.0 * w * day)
            - 0.04969351 * sin(3.0 * w * day)
            - 0.25768520 * cos(4.0 * w * day)
            + 0.49999602 * sin(4.0 * w * day)
            + 0.71902785 * cos(5.0 * w * day)
            - 0.19329467 * sin(5.0 * w * day)
            - 0.21500095 * cos(6.0 * w * day)
            + 0.26378056 * sin(6.0 * w * day)
    }
    /// Stanley, ID Solar Insolation S(t) with units of kWh/m^2/day
    static func stanleySolarEnergy(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 7.41011680
            - 4.25521209 * cos(w * day)
            + 0.82296609 * sin(w * day)
            - 0.07348156 * cos(2.0 * w * day)
            + 0.01317233 * sin(2.0 * w * day)
            + 0.02767536 * cos(3.0 * w * day)
            - 0.01669456 * sin(3.0 * w * day)
            + 0.00400916 * cos(4.0 * w * day)
            - 0.00341112 * sin(4.0 * w * day)
    }
    /// Stanley, ID normalized solar insolation s(t), unitless
    static func stanleyNormalizedSolarEnergy(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 0.50788178
            - 0.49457767 * cos(w * day)
            + 0.09565226 * sin(w * day)
            - 0.00854066 * cos(2.0 * w * day)
            + 0.00153100 * sin(2.0 * w * day)
            + 0.00321668 * cos(3.0 * w * day)
            - 0.00194038 * sin(3.0 * w * day)
            + 0.00046597 * cos(4.0 * w * day)
            - 0.00039646 * sin(4.0 * w * day)
    }
    ///
    /// Salt Lake City, UT
    ///
    /// Normal Highs Salt Lake City, UT
    static func slcNormalHighFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 65.06027397
            - 25.61793211 * cos(w * day)
            - 8.00021417 * sin(w * day)
            - 1.18178905 * cos(2.0 * w * day)
            + 3.79989386 * sin(2.0 * w * day)
            - 1.36602745 * cos(3.0 * w * day)
            - 0.85782634 * sin(3.0 * w * day)
            - 0.05669835 * cos(4.0 * w * day)
            + 0.11196176 * sin(4.0 * w * day)
            + 0.41331181 * cos(5.0 * w * day)
            + 0.06919224 * sin(5.0 * w * day)
            + 0.10921886 * cos(6.0 * w * day)
            + 0.66494871 * sin(6.0 * w * day)
    }
    /// normal Lows Salt Lake City UT
    static func slcNormalLowFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 44.58904110
            - 20.17014681 * cos(w * day)
            - 6.31079927 * sin(w * day)
            - 0.17937081 * cos(2.0 * w * day)
            + 3.36312607 * sin(2.0 * w * day)
            - 0.57925796 * cos(3.0 * w * day)
            - 1.16843969 * sin(3.0 * w * day)
            - 0.20247080 * cos(4.0 * w * day)
            + 0.12172127 * sin(4.0 * w * day)
            + 0.38509711 * cos(5.0 * w * day)
            - 0.26985967 * sin(5.0 * w * day)
            + 0.07096592 * cos(6.0 * w * day)
            + 0.43532064 * sin(6.0 * w * day)
    }
    
    ///Salt Lake City Solar Energy
    static func slcSolarEnergy(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 7.76473219
            - 3.96111848 * cos(w * day)
            + 0.77153091 * sin(w * day)
            - 0.13458042 * cos(2.0 * w * day)
            + 0.03720231 * sin(2.0 * w * day)
            + 0.02484110 * cos(3.0 * w * day)
            - 0.01522714 * sin(3.0 * w * day)
            + 0.00337838 * cos(4.0 * w * day)
            - 0.00286236 * sin(4.0 * w * day)
    }
    ///Normalized solar Salt Lake City UT
    static func slcNormalizedSolarEnergy(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 0.5167440
            - 0.49433295 * cos(w * day)
            + 0.09628421 * sin(w * day)
            - 0.01679514 * cos(2.0 * w * day)
            + 0.00464271 * sin(2.0 * w * day)
            + 0.00310008 * cos(3.0 * w * day)
            - 0.00190029 * sin(3.0 * w * day)
            + 0.00042161 * cos(4.0 * w * day)
            - 0.00035721 * sin(4.0 * w * day)
    }
    ///
    ///DENVER COLORADO FITS INCOMING
    ///
    ///Denver CO Normal High T max
    static func denverNormalHighFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 65.24000000
            - 21.90727712 * cos(1.0 * w * day) - 7.38030806 * sin(1.0 * w * day)
            - 0.09136400 * cos(2.0 * w * day) + 2.87842740 * sin(2.0 * w * day)
            - 0.60911350 * cos(3.0 * w * day) - 0.23113947 * sin(3.0 * w * day)
            + 0.94181796 * cos(4.0 * w * day) - 0.27063385 * sin(4.0 * w * day)
            + 0.27761701 * cos(5.0 * w * day) + 0.85870142 * sin(5.0 * w * day)
            - 0.00501465 * cos(6.0 * w * day) + 0.85973294 * sin(6.0 * w * day)
            + 0.00075709 * cos(7.0 * w * day) + 0.00113500 * sin(7.0 * w * day)
            - 0.00235810 * cos(8.0 * w * day) + 0.00098301 * sin(8.0 * w * day)
            - 0.00436428 * cos(9.0 * w * day) - 0.00024125 * sin(9.0 * w * day)
            + 0.00010695 * cos(10.0 * w * day) + 0.00069851 * sin(10.0 * w * day)
            + 0.00137132 * cos(11.0 * w * day) - 0.00097576 * sin(11.0 * w * day)
            + 0.00347598 * cos(12.0 * w * day) - 0.00010230 * sin(12.0 * w * day)
    }
    ///Denver CO Normal Low T min
    static func denverNormalLowFahrenheit(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 37.29452055
            - 20.00655126 * cos(1.0 * w * day) - 6.83445302 * sin(1.0 * w * day)
            + 0.25802492 * cos(2.0 * w * day) + 2.63495526 * sin(2.0 * w * day)
            - 0.10270909 * cos(3.0 * w * day) - 0.30550640 * sin(3.0 * w * day)
            + 0.34758810 * cos(4.0 * w * day) + 0.12994895 * sin(4.0 * w * day)
            + 0.32315942 * cos(5.0 * w * day) + 0.34569434 * sin(5.0 * w * day)
            - 0.06752185 * cos(6.0 * w * day) + 0.76997070 * sin(6.0 * w * day)
            + 0.00368299 * cos(7.0 * w * day) - 0.00338030 * sin(7.0 * w * day)
            - 0.00007001 * cos(8.0 * w * day) + 0.00286874 * sin(8.0 * w * day)
            - 0.00078279 * cos(9.0 * w * day) + 0.00011590 * sin(9.0 * w * day)
            - 0.00081767 * cos(10.0 * w * day) - 0.00055198 * sin(10.0 * w * day)
            + 0.00070162 * cos(11.0 * w * day) + 0.00190531 * sin(11.0 * w * day)
            + 0.00305947 * cos(12.0 * w * day) + 0.00220382 * sin(12.0 * w * day)
    }
    ///Denver CO Solar Insolation S(t) in kWh/m^2/day
    static func denverSolarEnergy(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 7.86723437
            - 3.87015560 * cos(1.0 * w * day) + 0.75557171 * sin(1.0 * w * day)
            - 0.15130049 * cos(2.0 * w * day) + 0.04381174 * sin(2.0 * w * day)
            + 0.02399976 * cos(3.0 * w * day) - 0.01478665 * sin(3.0 * w * day)
            + 0.00322188 * cos(4.0 * w * day) - 0.00272672 * sin(4.0 * w * day)
    }
    ///Denver CO normalized solar s(t)
    static func denverNormalizedSolarEnergy(dayOfYear t: Int) -> Double {
        let w = 2.0 * Double.pi / 365.0
        let day = Double(t)
        
        return 0.51945736
            - 0.49425445 * cos(1.0 * w * day) + 0.09649345 * sin(1.0 * w * day)
            - 0.01932246 * cos(2.0 * w * day) + 0.00559516 * sin(2.0 * w * day)
            + 0.00306499 * cos(3.0 * w * day) - 0.00188839 * sin(3.0 * w * day)
            + 0.00041146 * cos(4.0 * w * day) - 0.00034823 * sin(4.0 * w * day)
    }
    
    /// Generalized normal high fahrenheit
    static func normalHighFahrenheit(
        dayOfYear t: Int,
        profile: ClimatologyProfile
    ) -> Double {
        switch profile {
        case .northLasVegas:
            return normalHighFahrenheit(dayOfYear: t)
        case .fairbanks:
            return fairbanksNormalHighFahrenheit(dayOfYear: t)
        case .ely:
            return elyNormalHighFahrenheit(dayOfYear: t)
        case .stanley:
            return stanleyNormalHighFahrenheit(dayOfYear: t)
        case .saltlakecity:
            return slcNormalHighFahrenheit(dayOfYear: t)
        case .denver:
            return denverNormalHighFahrenheit(dayOfYear: t)
        }
    }
    
  
    
    
    /// Generalized Low Temperature for any location
    static func normalLowFahrenheit(
        dayOfYear t: Int,
        profile: ClimatologyProfile
    ) -> Double {
        switch profile {
        case .northLasVegas:
            return normallowFahrenheit(dayOfYear: t)
        case .fairbanks:
            return fairbanksNormalLowFahrenheit(dayOfYear: t)
        case .ely:
            return elyNormalLowFahrenheit(dayOfYear: t)
        case .stanley:
            return stanleyNormalLowFahrenheit(dayOfYear: t)
        case .saltlakecity:
            return slcNormalLowFahrenheit(dayOfYear: t)
        case .denver:
            return denverNormalLowFahrenheit(dayOfYear: t)
        }
    }
    
    
    
    /// Solar Energy function S(t) for any climate location
    static func solarEnergy(
        dayOfYear t: Int,
        profile: ClimatologyProfile
    ) -> Double {
        switch profile {
        case .northLasVegas:
            return solarInsolation(dayOfYear: t)
        case .fairbanks:
            return fairbanksSolarEnergy(dayOfYear: t)
        case .ely:
            return elySolarEnergy(dayOfYear: t)
        case .stanley:
            return stanleySolarEnergy(dayOfYear: t)
        case .saltlakecity:
            return slcSolarEnergy(dayOfYear: t)
        case .denver:
            return denverSolarEnergy(dayOfYear: t)
        }
    }
    /// normalized insolation for any climate location
    static func normalizedSolarEnergy(
        dayOfYear t: Int,
        profile: ClimatologyProfile
    ) -> Double {
        switch profile {
        case .northLasVegas:
            return normalizedSolarInsolation(dayOfYear: t)
        case .fairbanks:
            return fairbanksNormalizedSolarEnergy(dayOfYear: t)
        case .ely:
            return elyNormalizedSolarEnergy(dayOfYear: t)
        case .stanley:
            return stanleyNormalizedSolarEnergy(dayOfYear: t)
        case .saltlakecity:
            return slcNormalizedSolarEnergy(dayOfYear: t)
        case .denver:
            return denverNormalizedSolarEnergy(dayOfYear: t)
        }
    }
    static func sunTimes(
        for date: Date = Date(),
        latitude: Double,
        longitude: Double
    ) -> SunTimes? {
        let calendar = Calendar.current
        let dayNumber = Double(dayOfYear(for: date))
        
        let degreesToRadians = Double.pi / 180.0
        let radiansToDegrees = 180.0 / Double.pi
        
        let latitudeRadians = latitude * degreesToRadians
        
        let fractionalYear = 2.0 * Double.pi / 365.0 * (dayNumber - 1.0)
        
        let equationOfTime = 229.18 * (
            0.000075
            + 0.001868 * cos(fractionalYear)
            - 0.032077 * sin(fractionalYear)
            - 0.014615 * cos(2.0 * fractionalYear)
            - 0.040849 * sin(2.0 * fractionalYear)
        )
        
        let solarDeclination =
            0.006918
            - 0.399912 * cos(fractionalYear)
            + 0.070257 * sin(fractionalYear)
            - 0.006758 * cos(2.0 * fractionalYear)
            + 0.000907 * sin(2.0 * fractionalYear)
            - 0.002697 * cos(3.0 * fractionalYear)
            + 0.001480 * sin(3.0 * fractionalYear)
        
        let zenithRadians = 90.833 * degreesToRadians
        
        let hourAngleInput = (
            cos(zenithRadians) / (cos(latitudeRadians) * cos(solarDeclination))
        ) - tan(latitudeRadians) * tan(solarDeclination)
        
        guard hourAngleInput >= -1.0,
              hourAngleInput <= 1.0 else {
            return nil
        }
        
        let hourAngleDegrees = acos(hourAngleInput) * radiansToDegrees
        
        let timeZoneOffsetHours = Double(
            TimeZone.current.secondsFromGMT(for: date)
        ) / 3600.0
        
        let solarNoonMinutes = 720.0
            - 4.0 * longitude
            - equationOfTime
            + timeZoneOffsetHours * 60.0
        
        let sunriseMinutes = solarNoonMinutes - 4.0 * hourAngleDegrees
        let sunsetMinutes = solarNoonMinutes + 4.0 * hourAngleDegrees
        
        let startOfDay = calendar.startOfDay(for: date)
        
        let sunrise = startOfDay.addingTimeInterval(
            sunriseMinutes * 60.0
        )
        
        let sunset = startOfDay.addingTimeInterval(
            sunsetMinutes * 60.0
        )
        
        return SunTimes(
            sunrise: sunrise,
            sunset: sunset
        )
    }
}
