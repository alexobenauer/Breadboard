//
//  WorkspaceView.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/13/23.
//

import SwiftUI

struct WorkspaceView: View {
    @StateObject private var store = WorkspaceStore()
    
    var body: some View {
        ZStack {
            Image("dot")
                .resizable(resizingMode: .tile)
                .opacity(0.25)
            
            ForEach(store.widgets, id: \.id) { widget in
                WidgetView(widget: widget)
            }
            
            VStack {
                Spacer()
                HStack {
                    Button {
                        store.openWidget(MapWidget())
                    } label: {
                        Label("Map", systemImage: "map.fill")
                    }
                    .tint(Color.green)
                    
                    Button {
                        store.openWidget(WeatherWidget())
                    } label: {
                        Label("Weather", systemImage: "sun.max.fill")
                    }
                    .tint(Color.orange)
                    
                    Spacer()
                    
                    Text("Configure:")
                        .font(Font.system(size: 12).monospaced())
                        .opacity(0.5)
                        .padding(.trailing, 10)
                    
                    Toggle(isOn: $store.doFetching) {
                        Text("Allow fetching")
                            .font(Font.system(size: 12).monospaced())
                    }
                    .padding(.trailing, 10)
                    
                    Toggle(isOn: $store.spatiallyAware) {
                        Label("Spatially-aware", systemImage: "wave.3.forward")
                            .font(Font.system(size: 12).monospaced())
                    }
                    
                    Slider(value: $store.senseAround, in: -50...1000) {
                        
                    }
                    .disabled(!store.spatiallyAware)
                    .frame(maxWidth: 100)
                    
                    Text(store.senseAround == 1000 ? "∞" : "\(Int(store.senseAround))")
                        .font(Font.system(size: 12).monospaced())
                        .opacity(0.5)
                        .frame(width: 30, alignment: .leading)
                    
                    Toggle(isOn: $store.groupContexts) {
                        Label("Group contexts", systemImage: "rectangle.3.group")
                            .font(Font.system(size: 12).monospaced())
                    }
                    .disabled(!store.spatiallyAware)
                }
                .padding()
            }
        }
        .background(.blue.opacity(0.05))
        .frame(minWidth: 1024, minHeight: 768)
        .environmentObject(store)
    }
}

struct WorkspaceView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceView()
    }
}
