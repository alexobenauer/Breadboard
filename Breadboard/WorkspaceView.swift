//
//  WorkspaceView.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/13/23.
//

import SwiftUI

struct WorkspaceView: View {
    @StateObject private var store = WorkspaceStore()
    
    @State private var searchIsOpen = false
    
    var hoverWidget: (any Widget)? {
        guard let id = store.focusHover else {
            return nil
        }
        
        guard let item = store.items.first(where: { $0.0.id == id })?.0 else {
            return nil
        }
        
        return item.generateWidget()
    }
    
    var body: some View {
        ZStack {
            Image("dot")
                .resizable(resizingMode: .tile)
                .opacity(0.25)
            
            ForEach(store.widgets, id: \.id) { widget in
                WidgetView(widget: widget)
                    .position(x: store.widgetFrame[widget.id]?.origin.x ?? 0, y: store.widgetFrame[widget.id]?.origin.y ?? 0)
                    .frame(width: (store.widgetFrame[widget.id]?.size.width ?? 550) + (store.widgetOffset[widget.id]?.size.width ?? 0), height: (store.widgetFrame[widget.id]?.size.height ?? 350) + (store.widgetOffset[widget.id]?.size.height ?? 0))
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
                    
                    Button {
                        store.openWidget(CampgroundFinderWidget())
                    } label: {
                        Label("Campground Finder", systemImage: "tent.2.fill")
                    }
                    .tint(Color.red)
                    
                    Spacer()
                    
                    Text("Configure:")
                        .font(Font.system(size: 12).monospaced())
                        .opacity(0.5)
                        .padding(.trailing, 10)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Toggle(isOn: $store.peekOnHover) {
                                Label("Peek on hover", systemImage: "cursorarrow.and.square.on.square.dashed")
                                    .font(Font.system(size: 12).monospaced())
                            }
                        }
                        HStack {
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
                    }
                }
                .padding()
            }
            
            if let point = store.peekHoveredItemAt, let widget = self.hoverWidget {
                WidgetView(widget: widget)
                    .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .center)))
                    .onHover { isHovering in
                        if !isHovering {
                            store.closePeekHoveredItem()
                        }
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            // TODO: Reset anything else with peek?
                            store.closePeekHoveredItem()
                            store.openWidget(widget, atLoc: CGPoint(x: point.x - 550, y: point.y - 10 - 350))
                        }
                    )
                    .opacity(0.9)
                    .position(x: point.x - 550, y: point.y - 10 - 350)
                    .frame(width: 550, height: 350)
            }
            
            if searchIsOpen {
                HStack {
                    Button {
                        searchIsOpen = false
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                            .accessibility(hint: Text("Back"))
                            .padding()
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction) // TODO: Why doesn't this work?
                    
                    TextField("Search", text: .constant(""))
                        .textFieldStyle(.plain)
                        .font(.title2)
                        .padding()
                        .cornerRadius(12)
                }
                .background(.regularMaterial)
            }
        }
        .onContinuousHover(perform: { phase in
            switch phase {
            case .active(let point):
                store.setMousePosition(point)
            case .ended:
                store.setMousePosition(nil)
            }
        })
        .background(.blue.opacity(0.05))
        .frame(minWidth: 1024, minHeight: 768)
        .toolbar {
            ToolbarItem {
                Button {
                    searchIsOpen.toggle()
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }

            }
        }
        .environmentObject(store)
    }
}

struct WorkspaceView_Previews: PreviewProvider {
    static var previews: some View {
        WorkspaceView()
    }
}
