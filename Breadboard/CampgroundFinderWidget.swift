//
//  CampgroundFinderWidget.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/21/23.
//

import SwiftUI
import MapKit

// This next demo starts to deal with sets and donating whole items

// How do we want to deal with sets?
// - One way is to have widgets which display them
//      which can use system or provide custom actions
//      for things like filter and search
//      Then you can add those actions onto the widget
//      Or the filters could be a separate widget?

struct CampgroundFinderWidget: Widget {
    var title: String { "Campground Finder" }
    var icon: String { "tent.2.fill" }
    var color: Color { .red }
    
    let id = UUID()
    
    @EnvironmentObject var store: WorkspaceStore
    
    @State private var query: String = ""
    // @State private var results: [CampgroundItem] = []
    @State private var cgType: CGType = .campground
    @StateObject private var manager = Manager()
    
    enum CGType: String, CaseIterable {
        case campground = "Campground"
        case rvPark = "RV Park"
    }
    
    private func update() {
        guard let region = store.getContextualRegion(forWidgetId: id) else {
            return
        }
        
        manager.fetchResults(forRegion: region, search: cgType.rawValue)
    }
    
//    func search() {
//        if query == "grand teton" {
//            setResults()
//        }
//        else {
//            unsetResults()
//        }
//    }
//
//    func setResults() {
//        self.results = [
//            CampgroundItem(id: UUID(), name: "Jenny Lake Campground"),
//            CampgroundItem(id: UUID(), name: "Signal Mountain Campground"),
//            CampgroundItem(id: UUID(), name: "Colter Bay RV Park"),
//            CampgroundItem(id: UUID(), name: "Gros Ventre Campground"),
//            CampgroundItem(id: UUID(), name: "Lizard Creek Campground"),
//        ]
//    }
//
//    func unsetResults() {
//        self.results = []
//    }
    
    var body: some View {
        VStack(spacing: 0) {
            /*TextField("Search", text: $query)
                .textFieldStyle(.plain)
                .font(.title2)
                .padding()
                .onChange(of: query) { _ in
                    // search()
                }*/
            
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            
                            ForEach(CGType.allCases.reversed(), id: \.rawValue) { cgType in
                                Button {
                                    self.cgType = cgType
                                } label: {
                                    Text(cgType.rawValue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(self.cgType == cgType ? .red : .primary.opacity(0.05))
                                        .cornerRadius(50)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        
                        ForEach(manager.results) { campground in
                            HStack {
                                HStack {
                                    Text(campground.name ?? "-")
                                    Spacer()
                                    
                                    /*if let url = campground.url {
                                        Link(destination: url) {
                                            Text(url.absoluteString)
                                        }
                                    }*/
                                }
                                .padding()
                                .background(store.focusHover == campground.id ? .orange : .primary.opacity(0.05))
                                .cornerRadius(12)
                                
                                Button {
                                    store.openWidget(CampgroundWidget(campground: campground))
                                } label: {
                                    Image(systemName: "arrow.up.right")
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            .onHover { isHovering in
                                store.setFocusHover(id: campground.id, isHovering: isHovering)
                            }
                        }
                        
                        Rectangle()
                            .fill(.clear)
                            .frame(height: 4)
                    }
                }
                .onChange(of: store.focusHover) { newValue in
                    if let id = newValue {
                        withAnimation {
                            scrollProxy.scrollTo(id)
                        }
                    }
                }
            }
            .opacity(manager.fetching ? 0.33 : 1)
        }
        .onAppear {
            update()
        }
        .onChange(of: store.getContextualRegion(forWidgetId: id) ?? MKCoordinateRegion()) { _ in
            update()
        }
        .onChange(of: cgType, perform: { _ in
            update()
        })
        .onChange(of: manager.results) { newValue in
            store.donateItems(items: newValue, fromId: id)
        }
    }
}

struct CampgroundItem: WorkspaceItem {
    var type: String { "campground" }
    var associations: [WorkspaceStore.PrimitiveValue] {
        if let location = placemark.location {
            return [.location(location)]
        } else {
            return []
        }
    }
    
    func generateWidget() -> any Widget {
        CampgroundWidget(campground: self)
    }
    
    let id: UUID
    let name: String?
    let phone: String?
    let category: MKPointOfInterestCategory?
    let url: URL?
    let placemark: MKPlacemark
}

fileprivate class Manager: ObservableObject {
    @Published var fetching: Bool = false
    @Published var results: [CampgroundItem] = []
    @Published var boundingRegion: MKCoordinateRegion? = nil

    private var updateThrottle: DispatchWorkItem? = nil

    func fetchResults(forRegion region: MKCoordinateRegion, search: String) {
        self.fetching = true

        self.updateThrottle?.cancel()

        let task = DispatchWorkItem {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = search
            request.region = region
            
            let search = MKLocalSearch(request: request)
            
            search.start(completionHandler: { response, error in
                self.fetching = false
                
                guard let response else {
                    print("Error occurred in search: \(error?.localizedDescription ?? "")")
                    return
                }
                
                self.boundingRegion = response.boundingRegion
                self.results = response.mapItems.map({ item in
                    CampgroundItem(
                        id: UUID(),
                        name: item.name,
                        phone: item.phoneNumber,
                        category: item.pointOfInterestCategory,
                        url: item.url,
                        placemark: item.placemark
                    )
                })
            })
        }

        self.updateThrottle = task

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: task)
    }
}

extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        lhs.center == rhs.center && lhs.span == rhs.span
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension MKCoordinateSpan: Equatable {
    public static func == (lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
        lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
    }
}

struct CampgroundFinderWidget_Previews: PreviewProvider {
    static var previews: some View {
        CampgroundFinderWidget()
    }
}
