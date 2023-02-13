//
//  WidgetView.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/13/23.
//

import SwiftUI

struct WidgetView: View {
    let widget: any Widget

    @EnvironmentObject var store: WorkspaceStore
    
    @State private var isHovering: Bool = false
    @State private var showChipBar: Bool = false
    
    var size: CGSize {
        store.widgetFrame[widget.id]?.size ?? CGSize(width: 550, height: 350)
    }
    
    var position: CGPoint {
        store.widgetFrame[widget.id]?.origin ?? CGPoint(x: 350, y: 350)
    }
    
    /*var sizeOffset: CGSize {
        store.widgetOffset[widget.id]?.size ?? .zero
    }*/
    
    var posOffset: CGPoint {
        store.widgetOffset[widget.id]?.origin ?? .zero
    }
    
    var body: some View {
        ZStack {
            ZStack {
                VStack(spacing: 0) {
                    TopBar(title: widget.title, icon: widget.icon, color: widget.color, showTapAdd: !showChipBar) {
                        showChipBar = true
                    }
                    
                    if showChipBar {
                        Divider()
                            .background(.white.opacity(0.05))
                            .padding(.horizontal)
                            .padding(.vertical, -1)
                        ChipBar(color: widget.color)
                    }
                    
                    VStack {
                        AnyView(widget)
                    }
                    .frame(maxHeight: .infinity)
                }
                .background(.background)
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.10), radius: 2, y: 1)
                .shadow(color: .black.opacity(0.10), radius: 6, y: 3)
                .shadow(color: .black.opacity(0.15), radius: 24, y: 12)
                
                HStack {
                    Spacer()
                    
                    VStack {
                        Spacer()
                        
                        ResizeIcon()
                    }
                }
                .opacity(0.1)
                
                HStack {
                    VStack {
                        
                    }
                    
                    Spacer()
                    
                    VStack {
//                        ForEach(store.outputs[widget.id] ?? [], id: \.id) { d in
//                            switch d {
//                            case let d as? AddressItem:
//                                Text("A")
//                            default:
//                                Text("!")
//                            }
//                        }
                    }
                }
                .padding(.horizontal, -50)
            }
            .offset(x: posOffset.x, y: posOffset.y)
            
            VStack {
                Color.white.opacity(0)
                    .contentShape(Rectangle())
                    .frame(height: 48)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                store.widgetOffset[widget.id] = CGRect(x: gesture.translation.width, y: gesture.translation.height, width: 0, height: 0)
                                
                                if store.widgets.last?.id == widget.id {
                                    return
                                }

                                if let index = store.widgets.firstIndex(where: { $0.id == widget.id }) {
                                    let element = store.widgets.remove(at: index)
                                    store.widgets.append(element)
                                }
                            }
                            .onEnded { gesture in
                                store.widgetOffset[widget.id] = .zero
                                store.widgetFrame[widget.id] = CGRect(x: gesture.translation.width + position.x, y: gesture.translation.height + position.y, width: size.width, height: size.height)
                            }
                    )
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            if let index = store.widgets.firstIndex(where: { $0.id == widget.id }) {
                                let element = store.widgets.remove(at: index)
                                store.widgets.append(element)
                            }
                        }
                    )
                    .simultaneousGesture(
                        TapGesture(count: 3).onEnded {
                            store.closeWidget(id: widget.id)
                        }
                    )
        
                
                Spacer()
            }
            
            HStack {
                Spacer()
                
                VStack {
                    Spacer()
                    
                    ResizeIcon()
                        .background(.primary)
                        .opacity(0.0001)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    store.widgetOffset[widget.id] = CGRect(x: gesture.translation.width, y: gesture.translation.height, width: gesture.translation.width, height: gesture.translation.height)
                                }
                                .onEnded { gesture in
                                    store.widgetOffset[widget.id] = .zero
                                    store.widgetFrame[widget.id] = CGRect(x: position.x + gesture.translation.width, y: position.y + gesture.translation.height, width: size.width + gesture.translation.width, height: size.height + gesture.translation.height)
                                }
                        )
                }
            }
        }
        .onHover { isHovering in
            self.isHovering = isHovering
        }
//        .position(x: position.x, y: position.y)
//        .frame(width: size.width + sizeOffset.width, height: size.height + sizeOffset.height)
    }
}

fileprivate struct TopBar: View {
    let title: String
    let icon: String
    let color: Color
    let showTapAdd: Bool
    let onTapAdd: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .bold()
            
            if showTapAdd {
                Image(systemName: "plus")
                    .opacity(0.5)
                    .onTapGesture {
                        onTapAdd()
                    }
            }
            
            Spacer()
            Image(systemName: icon)
        }
        .padding()
        .foregroundColor(color)
        .background(color.opacity(0.1))
    }
}

fileprivate struct ChipBar: View {
    let color: Color
    @State private var text: String = ""
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                Chip(title: "Campground Finder", subtitle: "8", icon: "tent.2.fill", color: .blue, toggle: { }, peek: { }, remove: { })
                
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .frame(minWidth: 320)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
        }
    }
}

fileprivate struct Chip: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    
    let toggle: () -> Void
    let peek: () -> Void
    let remove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            
            Text(title)
                .bold()
            
            if let subtitle {
                Text(subtitle)
            }
        }
        .font(.system(size: 11))
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(100)
        .gesture(
            TapGesture().onEnded {
                toggle()
            }
        )
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                peek()
            }
        )
        .simultaneousGesture(
            TapGesture(count: 3).onEnded {
                remove()
            }
        )
    }
}

fileprivate struct ResizeIcon: View {
    //@State private var isHovering: Bool = false
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(.primary)
                    .frame(width: 2, height: 6)
            }
            
            VStack {
                Spacer()
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(.primary)
                    .frame(width: 6, height: 2)
            }
        }
        .frame(width: 6, height: 6)
//        .opacity(isHovering ? 1 : 0.5)
//        .onHover { isHovering in
//            withAnimation {
//                self.isHovering = isHovering
//            }
//        }
    }
}

struct WidgetView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetView(widget: MapWidget())
    }
}
