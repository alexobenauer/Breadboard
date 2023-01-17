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

/// Donates a focus on location by the user's panning; donates the center coordinates
struct MapWidget: Widget {
    var title: String { "Map" }
    var icon: String { "map.fill" }
    var color: Color { .green }
    
    let id = UUID()
    
    @EnvironmentObject var store: WorkspaceStore
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900,
                                       longitude: -122.009_020),
        latitudinalMeters: 750,
        longitudinalMeters: 750
    )
    
    var body: some View {
        Map(coordinateRegion: $region)
            .onChange(of: region.center.latitude + region.center.longitude) { _ in
                updateThrottle?.cancel()
                
                let task = DispatchWorkItem {
                    store.donatePrimitiveValue(.location(CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)), fromId: id)
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
    }
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

struct MapWidget_Previews: PreviewProvider {
    static var previews: some View {
        MapWidget()//.body(store: WorkspaceStore())
    }
}
