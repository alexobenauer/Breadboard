//
//  CampgroundWidget.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/21/23.
//

import SwiftUI

struct CampgroundWidget: Widget {
    let campground: CampgroundItem
    
    var title: String { "Campground" }
    var icon: String { "tent.fill" }
    var color: Color { .brown }
    
    let id = UUID()
    
    @EnvironmentObject var store: WorkspaceStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(campground.name ?? "-")
                .font(.title)
                .padding(.bottom)
            
            if let category = campground.category?.rawValue {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                    Text(category)
                }
            }
            
            if let url = campground.url {
                HStack {
                    Image(systemName: "link")
                    Link(url.absoluteString, destination: url)
                }
            }
            
            if let phone = campground.phone, let url = URL(string: "tel:"+phone) {
                HStack {
                    Image(systemName: "phone")
                    Link(phone, destination: url)
                }
            }
            else if let phone = campground.phone {
                HStack {
                    Image(systemName: "phone")
                    Text(phone)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

#if DEBUG

import MapKit

struct CampgroundWidget_Previews: PreviewProvider {
    static var previews: some View {
        CampgroundWidget(campground: CampgroundItem(
            id: UUID(),
            name: "Chief Hosa Campground",
            phone: "123 456 7890",
            category: .campground,
            url: URL(string: "https://www.denvergov.org/content/denvergov/en/denver-parks-and-recreation/parks/mountain-parks/chief-hosa-campground.html"),
            placemark: MKPlacemark(coordinate: CLLocationCoordinate2D())
        ))
    }
}

#endif
