//
//  PlaceFinder.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/21/23.
//

import SwiftUI

struct PlaceFinder: Widget {
    var title: String { "Place Finder" }
    var icon: String { "mappin.and.ellipse" }
    var color: Color { .green }
    
    let id = UUID()
    
    @EnvironmentObject var store: WorkspaceStore
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct PlaceFinder_Previews: PreviewProvider {
    static var previews: some View {
        PlaceFinder()
    }
}
