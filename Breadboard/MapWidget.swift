//
//  MapWidgetView.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/13/23.
//

import SwiftUI
import MapKit
import CoreLocation

// TODO: Impl some throttling mechanism offered by WorkspaceStore
var updateThrottle: DispatchWorkItem? = nil

//class InputSubscriber {
//    var title: String? = nil
//    var type: String = "any"
//    
//    func newState() { }
//}
//
//protocol NewWidget {
//    var typeTitle: String { get }
//    var icon: String { get }
//    var color: Color { get }
//    
//    associatedtype MyView: View
//    func generateNew(declareInputs: ([WVInput]) -> [WVInputSubscriber], declareOutputs: ([BreadboardValue]) -> Void) -> MyView
//}
//
//struct MapNewWidget: NewWidget {
//    var typeTitle: String { "Map" }
//    var icon: String { "map.fill" }
//    var color: Color { .green }
//    
//    func generateNew(declareInputs: ([WVInput]) -> [WVInputSubscriber], declareOutputs: ([BreadboardValue]) -> Void) -> some View {
//        MapNewWidgetView(declareInputs: declareInputs, declareOutputs: declareOutputs)
//    }
//}
//
//struct MapNewWidgetView: View {
//    init(declareInputs: ([WVInput]) -> [WVInputSubscriber], declareOutputs: ([BreadboardValue]) -> Void) {
//        
//    }
//    
//    
//    
//    @StateObject var inputsSubscriber: WorkspaceStore.InputSubscriber<MKCoordinateRegion>
//    
//    var declareOutputs: ([any Hashable]) -> Void
//    
//    var body: some View {
//        Group {
//            
//        }
//        .onAppear {
//            inputsSubscriber.enabled = false
//        }
//    }
//    
//    let values: [any NewWidget]
//}
//
//protocol BreadboardValue { }
//
//extension BreadboardValue {
//    var stringValue: String? {
//        return self as? String
//    }
//    
//    var intValue: Int? {
//        return self as? Int
//    }
//}
//
//struct WVInput {
//    let title: String
//    let valueForValue: (BreadboardValue) -> BreadboardValue?
//    let enabledByDefault: Bool
//}
//
//class WVInputSubscriber: ObservableObject {
//    @Published var value: BreadboardValue? = nil
//}
//
//extension WorkspaceStore {
//    struct Value<VV> {
//        let title: String
//        let value: VV
//    }
//    
//    struct InputDeclaration {
//        
//        let type: String
//        let title: String
//    }
//    
//    class InputSubscriber<ValueType>: ObservableObject {
//        @Published var values: [ValueType] = []
//        
//        private let unsubscribe: () -> Void
//        var enabled: Bool {
//            didSet {
//                // tell store to unsubscribe? record change in store for ui?
//            }
//        }
//        
//        init(store: WorkspaceStore, enabled: Bool = true) {
//            // subscribe to store
//            unsubscribe = {}
//            
//            self.enabled = enabled
//        }
//        
//        deinit {
//            unsubscribe()
//        }
//        
//        func update(_ store: WorkspaceStore) {
//            
//            self.values = values
//        }
//    }
//    
//    func subscribe<ValueType>(enabled: Bool = true) -> InputSubscriber<ValueType> {
//        return .init(store: self, enabled: enabled)
//    }
//}

/// Donates a focus on location by the user's panning; donates the center coordinates
struct MapWidget: Widget {
    var title: String { "Map" }
    var icon: String { "map.fill" }
    var color: Color { .green }
    
    let id = UUID()
    
    @EnvironmentObject var store: WorkspaceStore
    @StateObject private var locationManager = LocationManager()
    
    @State private var searchIsOpen = false
    @State private var query: String = ""
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900,
                                       longitude: -122.009_020),
        latitudinalMeters: 750,
        longitudinalMeters: 750
    )
    
    @State private var markers: [Marker] = []
    
    func search() {
        guard query.count > 0 else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        
        let search = MKLocalSearch(request: request)
        
        search.start(completionHandler: { response, error in
            if error != nil {
                print("Error occurred in search: \(error!.localizedDescription)")
            } else if response!.mapItems.count == 0 {
                print("No matches found")
            } else {
                print("Matches found")
                
                if let first = response?.mapItems.first {
                    region.center = first.placemark.coordinate
                    
                    searchIsOpen = false
                }
            }
        })
    }
    
    func getItems() {
        let mapRect = MKMapRectForCoordinateRegion(region: region)
        
        let items = store.getContextualItems(forWidgetId: id)
            /*.filter { item in
                for association in item.associations {
                    if case let .location(location) = association {
                        let point = MKMapPoint(CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
                        if mapRect.contains(point) {
                            return true
                        }
                    }
                }
                
                return false
            }*/
        
        self.markers = items.compactMap({ Marker(workspaceItem: $0) })
        
        // Update region? This could cause infinite loops?
        if self.markers.count > 0 {
            var minLatitude = 90.0
            var maxLatitude = -90.0
            var minLongitude = 180.0
            var maxLongitude = -180.0
            
            for annotation in markers {
                let latitude = annotation.location.coordinate.latitude
                let longitude = annotation.location.coordinate.longitude
                
                minLatitude = min(latitude, minLatitude)
                maxLatitude = max(latitude, maxLatitude)
                minLongitude = min(longitude, minLongitude)
                maxLongitude = max(longitude, maxLongitude)
            }
            
            let center = CLLocationCoordinate2D(latitude: (minLatitude + maxLatitude) / 2,
                                                longitude: (minLongitude + maxLongitude) / 2)
            let span = MKCoordinateSpan(latitudeDelta: (maxLatitude - minLatitude) * 1.5,
                                        longitudeDelta: (maxLongitude - minLongitude) * 1.5)
            let region = MKCoordinateRegion(center: center, span: span)
            
            self.region = region
        }
    }
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: markers) { marker in
                //MapMarker(coordinate: , tint: store.focusHover == $0.id ? .green : .gray)
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: marker.location.coordinate.latitude, longitude: marker.location.coordinate.longitude)) {
                    Circle()
                        .fill(store.focusHover == marker.id ? Color.orange : Color.green)
                        .frame(width: store.focusHover == marker.id ? 20 : 10, height: store.focusHover == marker.id ? 20 : 10)
                        .shadow(color: .black.opacity(0.25), radius: 2)
                        .onHover { isHovering in
                            store.setFocusHover(id: marker.id, isHovering: isHovering)
                        }
                        .onTapGesture {
                            
                        }
                }
            }
            .onChange(of: region.center.latitude + region.center.longitude) { _ in
                updateThrottle?.cancel()
                
                let task = DispatchWorkItem {
                    store.donatePrimitiveValue(.location(CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)), fromId: id)
                    store.donatePrimitiveValue(.region(region), fromId: id)
                    
                    // store.declareOutputs([region], fromWidgetId: id)
                }
                
                updateThrottle = task
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: task)
            }
            .onAppear {
                if let location = store.getContextualLocation(forWidgetId: id) {
                    self.region.center.latitude = location.coordinate.latitude
                    self.region.center.longitude = location.coordinate.longitude
                }
                else if let location = locationManager.location {
                    self.region.center.latitude = location.coordinate.latitude
                    self.region.center.longitude = location.coordinate.longitude
                }
            }
            .onChange(of: locationManager.location) { location in
                if let location, store.getContextualLocation(forWidgetId: id) == nil {
                    self.region.center.latitude = location.coordinate.latitude
                    self.region.center.longitude = location.coordinate.longitude
                }
            }
            .onChange(of: store.items.map({ $0.0.id })) { _ in
                getItems()
            }
            
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    if searchIsOpen {
                        TextField("Search", text: $query)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                search()
                            }
                            .padding()
                            .background(.background)
                            .cornerRadius(12)
                            .padding()
                    }
                    else {
                        Spacer()
                    }
                    
                    
                    Button {
                        withAnimation {
                            searchIsOpen.toggle()
                        }
                    } label: {
                        Image(systemName: searchIsOpen ? "xmark" : "magnifyingglass")
                            .foregroundColor(.green)
                            .frame(width: 36, height: 36)
                            .background(.background.opacity(0.8))
                            .cornerRadius(24)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
            }
        }
    }
}

fileprivate struct Marker: Identifiable {
    init?(workspaceItem: any WorkspaceItem) {
        for prim in workspaceItem.associations {
            if case let .location(location) = prim {
                self.id = workspaceItem.id
                self.location = location
                self.title = (workspaceItem as? CampgroundItem)?.name ?? (workspaceItem as? AddressItem)?.text ?? "-"
                return
            }
        }
        
//        if let item = workspaceItem as? AddressItem {
//            let geoCoder = CLGeocoder()
//            geoCoder.geocodeAddressString(item.text) { (placemarks, error) in
//                if let placemarks = placemarks, let location = placemarks.first?.location {
//                    self.id = workspaceItem.id
//                    self.location = location
//                    self.title = item.text
//                    return
//                }
//            }
//        }
        
        return nil
    }
    
    let id: UUID
    let location: CLLocation
    let title: String
}

fileprivate class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    let manager = CLLocationManager()
    @Published var location: CLLocation? = nil
    
    override init() {
        super.init()
        
        #if DEBUG
        location = CLLocation(latitude: 39.7392, longitude: -104.9903)
        #else
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
        #endif
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("Found user's location: \(location)")
            self.location = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}

fileprivate func MKMapRectForCoordinateRegion(region: MKCoordinateRegion) -> MKMapRect {
    let topLeft = CLLocationCoordinate2D(latitude: region.center.latitude + (region.span.latitudeDelta/2), longitude: region.center.longitude - (region.span.longitudeDelta/2))
    let bottomRight = CLLocationCoordinate2D(latitude: region.center.latitude - (region.span.latitudeDelta/2), longitude: region.center.longitude + (region.span.longitudeDelta/2))
    
    let a = MKMapPoint(topLeft)
    let b = MKMapPoint(bottomRight)
    
    return MKMapRect(origin: MKMapPoint(x:min(a.x,b.x), y:min(a.y,b.y)), size: MKMapSize(width: abs(a.x-b.x), height: abs(a.y-b.y)))
}

//extension CLLocation: WorkspaceItem {
////    var id: UUID {
////        self.hash
////    }
//    
//    var type: String {
//        "cllocation"
//    }
//}

struct LocationItem: WorkspaceItem {
    var center: CLLocation? = nil
    var region: MKCoordinateRegion? = nil
    
    var id = UUID()
    
    var type: String { "location" }
    // var primitiveValue: WorkspaceStore.PrimitiveValue? { .date(date) }
    // var associations: [WorkspaceStore.PrimitiveValue] { get }
    // var items: [any WorkspaceItem] { get }
    
    func generateWidget() -> any Widget {
        // Map View...
        MapWidget()
    }
}

extension MKCoordinateRegion: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(center)
        hasher.combine(span)
    }
}

extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

extension MKCoordinateSpan: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitudeDelta)
        hasher.combine(longitudeDelta)
    }
}

struct MapWidget_Previews: PreviewProvider {
    static var previews: some View {
        MapWidget()
            .environmentObject(WorkspaceStore())
    }
}
