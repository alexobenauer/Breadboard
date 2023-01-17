//
//  WorkspaceStore.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/13/23.
//

import Foundation
import CoreLocation

class WorkspaceStore: ObservableObject {
    @Published var widgets: [any Widget] = []
    @Published var primitives: [(PrimitiveValue, UUID)] = []
    @Published var items: [any WorkspaceItem] = []
    
    @Published var widgetFrame: [UUID: CGRect] = [:]
    @Published var widgetOffset: [UUID: CGSize] = [:]
    
    @Published var doFetching: Bool = true
    @Published var spatiallyAware: Bool = false
    @Published var senseAround: Double = 1000
    @Published var groupContexts: Bool = false
    
    // Three options: get latest value from anywhere,
    //  get latest value from nearest emitter of value type,
    //  get latest value within grouping
    
    enum PrimitiveValue {
        case date(Date)
        case location(CLLocation)
    }
    
    func openWidget(_ widget: any Widget) {
        self.widgets.append(widget)
    }
    
    func donatePrimitiveValue(_ value: PrimitiveValue, fromId: UUID) {
        print("Primitive donated: \(String(describing: value))")
        self.primitives.insert((value, fromId), at: 0)
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
        // TODO: Perf can become *terrible* here
        // This is partially written to let quick experimentation happen
        //  Once we hone in on one direction for the concept, we can explore
        //  better ways of computing the results we're looking for
//        else if senseAround > 999 {
//            // Find widget with location nearest this
//            let myPosition = position(forWidgetId: widgetId)
//
//            let widgets = widgets.sorted { a, b in
//                let aPos = position(forWidgetId: a.id)
//                let bPos = position(forWidgetId: b.id)
//
//                return (abs(myPosition.x - aPos.x) + abs(myPosition.y - aPos.y)) < (abs(myPosition.x - bPos.x) + abs(myPosition.y - bPos.y))
//            }
//
//            for widget in widgets {
//                let primitives = primitives.filter({ $0.1 == widget.id })
//
//                for primitive in primitives {
//                    if case let .location(location) = primitive.0 {
//                        return location
//                    }
//                }
//            }
//        }
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
        let wOff = widgetOffset[widgetId] ?? .zero
        let wPos = CGPoint(x: wLoc.x + wOff.width, y: wLoc.y + wOff.height)
        
        return wPos
    }
    
    private func rect(forWidgetId widgetId: UUID) -> CGRect {
        var frame = widgetFrame[widgetId] ?? .zero
        let offset = widgetOffset[widgetId] ?? .zero
        
        frame.origin.x += offset.width
        frame.origin.y += offset.height
        
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

protocol WorkspaceItem {
    var type: String { get }
    var associations: [WorkspaceStore.PrimitiveValue] { get }
}
