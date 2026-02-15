import Foundation
import CoreLocation
import MapKit

class RealPOIService {
    static let shared = RealPOIService()
    
    private init() {}
    
    func searchNearbyRealPOI(location: CLLocation, radius: CLLocationDistance = 1000) async throws -> [POI] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "超市 医院 药店 餐厅 加油站"
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: radius, longitudinalMeters: radius)
        request.resultTypes = [.pointOfInterest]
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        var pois: [POI] = []
        
        for item in response.mapItems {
            guard let name = item.name, let coordinate = item.placemark.location?.coordinate else { continue }
            
            let poi = POI(
                id: UUID().uuidString,
                name: name,
                coordinate: coordinate,
                type: getPOIType(from: item.pointOfInterestCategory?.rawValue ?? "")
            )
            pois.append(poi)
        }
        
        let filteredPOIs = filterPOIsByDensity(pois)
        return filteredPOIs
    }
    
    func filterPOIsByDensity(_ pois: [POI]) -> [POI] {
        let densityLevel = PlayerLocationManager.shared.densityLevel
        let maxPOICount = densityLevel.poiCount
        
        if pois.count <= maxPOICount {
            return pois
        } else {
            return Array(pois.prefix(maxPOICount))
        }
    }
    
    private func getPOIType(from category: String) -> POIType {
        switch category {
        case "supermarket": return .supermarket
        case "hospital": return .hospital
        case "pharmacy": return .pharmacy
        case "restaurant": return .restaurant
        case "gas_station": return .gasStation
        default: return .other
        }
    }
}

enum POIType {
    case supermarket
    case hospital
    case pharmacy
    case restaurant
    case gasStation
    case other
    
    var iconName: String {
        switch self {
        case .supermarket: return "cart"
        case .hospital: return "cross"
        case .pharmacy: return "pill"
        case .restaurant: return "fork.knife"
        case .gasStation: return "fuelpump"
        case .other: return "mappin"
        }
    }
}

struct POI: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let type: POIType
}
