//
//  ContentView.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/13/23.
//

import SwiftUI
import MapKit

/// Generic data chunks:
/// - Location
/// - Date
/// - Contact
///

struct ContentView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.334_900,
                                       longitude: -122.009_020),
        latitudinalMeters: 750,
        longitudinalMeters: 750
    )
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            
            DraggableView()
            
            Map(coordinateRegion: $region)
        }
        .padding()
    }
}

struct DraggableView: View {
    @State private var position = CGPoint.zero
    @State private var offset = CGSize.zero
    
    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 100, height: 100)
            .position(x: position.x, y: position.y)
            .offset(x: offset.width, y: offset.height)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                    }
                    .onEnded { gesture in
                        offset = .zero
                        position = CGPoint(x: gesture.translation.width + position.x, y: gesture.translation.height + position.y)
                    }
            )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
