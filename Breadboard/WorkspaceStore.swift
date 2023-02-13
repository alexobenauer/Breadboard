//
//  WorkspaceStore.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/13/23.
//

import SwiftUI
import CoreLocation
import MapKit

class WorkspaceStore: ObservableObject {
    @Published var widgets: [any Widget] = []
    @Published var primitives: [(PrimitiveValue, UUID)] = []
    @Published var items: [(any WorkspaceItem, UUID)] = []
    
    // Next: Base primitives & items on:
    @Published var outputs: [UUID: [any WorkspaceItem]] = [:]
    
    @Published var focusHover: UUID? = nil
    @Published var focusSelect: [UUID] = []
    
    @Published var widgetFrame: [UUID: CGRect] = [:]
    @Published var widgetOffset: [UUID: CGRect] = [:]
    @Published var fullscreenWidget: UUID? = nil
    
    @Published var doFetching: Bool = true
    @Published var spatiallyAware: Bool = false
    @Published var senseAround: Double = 1000
    @Published var showRadius: Bool = false
    @Published var groupContexts: Bool = false
    @Published var peekOnHover: Bool = false
    
    private var mousePosition: CGPoint? = nil
    private var hoverThrottle: DispatchWorkItem? = nil
    @Published var peekHoveredItemAt: CGPoint? = nil
    
    // Three options: get latest value from anywhere,
    //  get latest value from nearest emitter of value type,
    //  get latest value within grouping
    
    enum PrimitiveValue: Equatable, Hashable {
        case date(Date)
        case location(CLLocation)
        case region(MKCoordinateRegion)
    }
    
    func openWidget(_ widget: any Widget, atLoc loc: CGPoint? = nil) {
        self.widgetFrame[widget.id] = CGRect(x: loc?.x ?? 0, y: loc?.y ?? 0, width: 550, height: 350)
        
        self.widgets.append(widget)
    }
    
    func closeWidget(id: UUID) {
        self.widgets = widgets.filter({ $0.id != id })
        
        self.primitives = primitives.filter({ $0.1 != id })
        self.items = items.filter({ $0.1 != id })
        self.outputs.removeValue(forKey: id)
    }
    
    func fullscreenWidget(id: UUID?) {
        self.fullscreenWidget = id
    }
    
    func donatePrimitiveValue(_ value: PrimitiveValue, fromId: UUID) {
        print("Primitive donated: \(String(describing: value))")
        self.primitives.insert((value, fromId), at: 0)
    }
    
    func donateItems(items: [any WorkspaceItem], fromId: UUID) {
        self.items = self.items
            .filter({ item in
                item.1 != fromId
            })
        + items.map({ ($0, fromId) })
    }
    
    func declareOutputs(_ outputs: [any WorkspaceItem], fromWidgetId: UUID) {
        self.outputs[fromWidgetId] = outputs
    }
    
    func setFocusHover(id: UUID?, isHovering: Bool) {
        if isHovering {
            if focusHover != id {
                withAnimation(.easeInOut(duration: 0.1)) {
                    focusHover = id
                }
            }
            
            updateHoverThrottle()
        }
        else if !isHovering {
            if focusHover == id {
                withAnimation(.easeInOut(duration: 0.1)) {
                    focusHover = nil
                }
            }
            
            updateHoverThrottle(cancel: true)
        }
    }
    
    func setMousePosition(_ position: CGPoint?) {
        guard peekOnHover else { return }
        
        self.mousePosition = position
        updateHoverThrottle()
    }
    
    private func updateHoverThrottle(cancel: Bool = false) {
        guard peekOnHover else { return }
        
        // self.peekHoveredItemAt = nil
        self.hoverThrottle?.cancel()
        
        if cancel {
            self.hoverThrottle = nil
            self.peekHoveredItemAt = nil
            return
        }
        
        if peekHoveredItemAt != nil {
            return
        }
        
        let task = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.15)) {
                self.peekHoveredItemAt = self.mousePosition
            }
        }
        
        self.hoverThrottle = task
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: task)
    }
    
    func closePeekHoveredItem() {
//        if let focusHover {
//            self.setFocusHover(id: focusHover, isHovering: false)
//        }
        self.focusHover = nil
        
        withAnimation(.easeInOut(duration: 0.15)) {
            self.peekHoveredItemAt = nil
            updateHoverThrottle(cancel: true)
        }
    }
    
    
    func getContextualRegion(forWidgetId widgetId: UUID) -> MKCoordinateRegion? {
        if !spatiallyAware {
            // Just get the latest
            for primitive in primitives {
                if case let .region(region) = primitive.0 {
                    return region
                }
            }
            
            return nil
        }
        else if groupContexts == false {
            // Now we want to see how it works if things need to be within a certain proximity
            
            let ids = getWidgetsInContext(ofWidgetId: widgetId)
            
            for id in ids {
                let primitives = primitives.filter({ $0.1 == id })
                
                for primitive in primitives {
                    if case let .region(region) = primitive.0 {
                        return region
                    }
                }
            }
        }
        else {
            // And now we want to create proximity-based groups
            
            let ids = getWidgetsInGroupedContext(ofWidgetId: widgetId)
            
            for id in ids {
                let primitives = primitives.filter({ $0.1 == id })
                
                for primitive in primitives {
                    if case let .region(region) = primitive.0 {
                        return region
                    }
                }
            }
        }
        
        return nil
    }
    
    func getContextualLocation(forWidgetId widgetId: UUID) -> CLLocation? {
        if !spatiallyAware {
            // Just get the latest
            for primitive in primitives {
                if case let .location(location) = primitive.0 {
                    return location
                }
            }

            return nil
        }
        else if groupContexts == false {
            // Now we want to see how it works if things need to be within a certain proximity

            let ids = getWidgetsInContext(ofWidgetId: widgetId)
            
            for id in ids {
                let primitives = primitives.filter({ $0.1 == id })
                
                for primitive in primitives {
                    if case let .location(location) = primitive.0 {
                        return location
                    }
                }
            }
        }
        else {
            // And now we want to create proximity-based groups
            
            let ids = getWidgetsInGroupedContext(ofWidgetId: widgetId)
            
            for id in ids {
                let primitives = primitives.filter({ $0.1 == id })
                
                for primitive in primitives {
                    if case let .location(location) = primitive.0 {
                        return location
                    }
                }
            }
        }

        return nil
    }
    
    func getContextualItems(forWidgetId widgetId: UUID) -> [any WorkspaceItem] {
        if !spatiallyAware {
            return items.map({ $0.0 })
        }
        else if groupContexts == false {
            let ids = getWidgetsInContext(ofWidgetId: widgetId)
            
            return items.filter({ ids.contains($0.1) }).map({ $0.0 })
        }
        else {
            let ids = getWidgetsInGroupedContext(ofWidgetId: widgetId)
            
            return items.filter({ ids.contains($0.1) }).map({ $0.0 })
        }
    }
    
    private func getWidgetsInContext(ofWidgetId id: UUID) -> [UUID] {
        let thisRect = rect(forWidgetId: id)
        
        let widgetDistances: [(id: UUID, distance: CGFloat)] = widgets.map { widget in
            let thatRect = rect(forWidgetId: widget.id)
            if let size = intersectionBetweenRects(rect1: thisRect, rect2: thatRect) {
                let distance = sqrt(size.width * size.width + size.height * size.height)
                return (widget.id, distance * -1)
            }
            else {
                let size = distanceBetweenRects(rect1: thisRect, rect2: thatRect)
                print(size)
                let distance = sqrt(size.width * size.width + size.height * size.height) // * ((size.width < 0 || size.height < 0) ? -1 : 1)
                return (widget.id, distance)
            }
        }
        
//        print(widgetDistances)
        
        return widgetDistances
            .filter { item in
                senseAround > 999 || item.distance <= senseAround
            }
            .sorted { a, b in
                a.distance < b.distance
            }
            .map { $0.id }
    }
    
    private func getWidgetsInGroupedContext(ofWidgetId id: UUID, found: [UUID] = []) -> [UUID] {
        let newIds = getWidgetsInContext(ofWidgetId: id)
            .filter { !found.contains($0) }
        
        var rIds: [UUID] = []
        
        for id in newIds {
            for id in getWidgetsInGroupedContext(ofWidgetId: id, found: found + newIds + rIds) {
                if !(found + newIds + rIds).contains(id) {
                    rIds.append(id)
                }
            }
        }
        
        return (found + newIds + rIds)
    }
    
//    private func getWidgetsInContext(ofWidgetId id: UUID) -> [UUID] {
//        /// Option 1: Everything in context
//        if !spatiallyAware {
//            return widgets.map { $0.id }
//        }
//
//        /// Option 2: Context defined individually by distance between widgets
//        else if !groupContexts {
//            let thisRect = rect(forWidgetId: id)
//
//            let widgetDistances: [(id: UUID, distanceSquared: CGFloat)] = widgets.map { widget in
//                let size = distanceBetweenRects(rect1: thisRect, rect2: rect(forWidgetId: widget.id))
//                let distanceSquared = size.width * size.width + size.height * size.height
//                return (widget.id, distanceSquared)
//            }
//
//            let senseAroundSquared = senseAround * senseAround
//
//            return widgetDistances
//                .filter { item in
//                    senseAround > 999 || item.distanceSquared <= senseAroundSquared
//                }
//                .sorted { a, b in
//                    a.distanceSquared < b.distanceSquared
//                }
//                .map { $0.id }
//        }
//
//        /// Option 3: Context is everything within the group
//        else {
//            getWidgetsInGroupedContext(ofWidgetId: <#T##UUID#>)
//        }
//    }
    
    private func position(forWidgetId widgetId: UUID) -> CGPoint {
        let wLoc = widgetFrame[widgetId]?.origin ?? .zero
        let wOff = widgetOffset[widgetId]?.origin ?? .zero
        let wPos = CGPoint(x: wLoc.x + wOff.x, y: wLoc.y + wOff.y)
        
        return wPos
    }
    
    private func rect(forWidgetId widgetId: UUID) -> CGRect {
        var frame = widgetFrame[widgetId] ?? .zero
        let offset = widgetOffset[widgetId] ?? .zero
        
        frame.origin.x += offset.origin.x
        frame.origin.y += offset.origin.y
        frame.size.width += offset.size.width
        frame.size.height += offset.size.height
        
        return frame
    }
    
    private func intersectionBetweenRects(rect1: CGRect, rect2: CGRect) -> CGSize? {
        let intersection = rect1.intersection(rect2)
        
        if !intersection.isNull {
            return intersection.size
        }
        
        return nil
    }
    
    private func distanceBetweenRects(rect1: CGRect, rect2: CGRect) -> CGSize {
        if rect1.intersects(rect2) {
            return CGSize(width: 0, height: 0)
        }
        
        let mostLeft = rect1.origin.x < rect2.origin.x ? rect1 : rect2
        let mostRight = rect2.origin.x < rect1.origin.x ? rect1 : rect2
        
        var xDifference = mostLeft.origin.x == mostRight.origin.x ? 0 : mostRight.origin.x - (mostLeft.origin.x + mostLeft.size.width)
        xDifference = CGFloat(max(0, xDifference))
        
        let upper = rect1.origin.y < rect2.origin.y ? rect1 : rect2
        let lower = rect2.origin.y < rect1.origin.y ? rect1 : rect2
        
        var yDifference = upper.origin.y == lower.origin.y ? 0 : lower.origin.y - (upper.origin.y + upper.size.height)
        yDifference = CGFloat(max(0, yDifference))
        
        return CGSize(width: xDifference, height: yDifference)
    }

}

protocol WorkspaceItem: Hashable, Identifiable, Equatable {
    var id: UUID { get }
    
    var type: String { get }
    var primitiveValue: WorkspaceStore.PrimitiveValue? { get }
    var associations: [WorkspaceStore.PrimitiveValue] { get }
    var items: [any WorkspaceItem] { get }
    
    func generateWidget() -> (any Widget)?
}

extension WorkspaceItem {
    var primitiveValue: WorkspaceStore.PrimitiveValue? {
        return nil
    }
    
    var associations: [WorkspaceStore.PrimitiveValue] {
        return []
    }
    
    var items: [any WorkspaceItem] {
        return []
    }
    
    func generateWidget() -> (any Widget)? {
        return nil
    }
}
    
    

//struct WorkspaceItemSet: WorkspaceItem {
//    var type: String
//    var items: [any WorkspaceItem]
//
//    var associations: [WorkspaceStore.PrimitiveValue] { return [] }
//    let id = UUID()
//}
