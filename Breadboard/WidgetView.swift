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
    
    var size: CGSize {
        store.widgetFrame[widget.id]?.size ?? CGSize(width: 550, height: 350)
    }
    
    var position: CGPoint {
        store.widgetFrame[widget.id]?.origin ?? CGPoint(x: 350, y: 350)
    }
    
    var offset: CGSize {
        store.widgetOffset[widget.id] ?? CGSize.zero
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TopBar(title: widget.title, icon: widget.icon, color: widget.color)
                
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
            .offset(x: offset.width, y: offset.height)
            
            VStack {
                Color.white.opacity(0)
                    .contentShape(Rectangle())
                    .frame(height: 48)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                store.widgetOffset[widget.id] = gesture.translation
                                
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
                        TapGesture()
                            .onEnded {
                                if let index = store.widgets.firstIndex(where: { $0.id == widget.id }) {
                                    let element = store.widgets.remove(at: index)
                                    store.widgets.append(element)
                                }
                            }
                    )
        
                
                Spacer()
            }
        }
        .position(x: position.x, y: position.y)
        .frame(width: size.width, height: size.height)
    }
}

fileprivate struct TopBar: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .bold()
            Spacer()
            Image(systemName: icon)
        }
        .padding()
        .foregroundColor(color)
        .background(color.opacity(0.1))
    }
}

struct WidgetView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetView(widget: MapWidget())
    }
}
