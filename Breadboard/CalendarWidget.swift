//
//  CalendarWidget.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 2/6/23.
//

import SwiftUI
import EventKit

struct CalendarWidget: Widget {
    var title: String { "Calendar" }
    var icon: String { "calendar" }
    var color: Color { .red }
    
    let id = UUID()
    
    @EnvironmentObject var store: WorkspaceStore
    
    @StateObject private var manager = EKManager()
    
    @State private var date: Date = Date()
    @State private var days: Int = 0
    
    func timeString(date: Date) -> String? {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
        
        if dateComponents.hour == 0, dateComponents.minute == 0, dateComponents.second == 0 {
            return nil
        }

        return timeFormatter.string(from: date)
    }
    
    func getItems() {
        let items = store.getContextualItems(forWidgetId: id)
        
        for item in items {
            if let item = item as? DateItem {
                self.date = item.date
                self.days = Int((item.duration ?? 0) / (24 * 60 * 60))
                
                return
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(0...days, id: \.self) { day in
                    HStack {
                        Text(dateFormatter.string(from: date.addingTimeInterval(Double(day * 24 * 60 * 60))))
                            .bold()
                            .padding(.top, 24)
                            .padding(.bottom, 12)
                        
                        Spacer()
                    }
                    
                    ForEach(manager.events.filter({ isSameDay(date1: $0.startDate, date2: date.addingTimeInterval(Double(day * 24 * 60 * 60))) }), id: \.eventIdentifier) { event in
                        HStack {
                            Circle()
                                .fill(Color(event.calendar.color))
                                .frame(width: 12, height: 12)
                            
                            if let timeString = timeString(date: event.startDate) {
                                Text(timeString)
                                    .monospaced()
                                    .opacity(0.5)
                            }
                            
                            Text(event.title)
                            
                            Spacer()
                            
                            Text(event.calendar.title)
                                .foregroundColor(Color(event.calendar.color))
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
        .onAppear {
            manager.load()

            getItems()
        }
        .onChange(of: store.items.map({ $0.0.id })) { _ in
            getItems()
        }
    }
    
    private func isSameDay(date1: Date, date2: Date) -> Bool {
        let calendar = Calendar.current
        let date1Components = calendar.dateComponents([.year, .month, .day], from: date1)
        let date2Components = calendar.dateComponents([.year, .month, .day], from: date2)
        return date1Components == date2Components
    }
}

fileprivate let dateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .medium
    return df
}()

fileprivate let timeFormatter = {
    let df = DateFormatter()
    df.timeStyle = .short
    return df
}()

fileprivate class EKManager: ObservableObject {
    @Published var events: [EKEvent] = []
    
    var store = EKEventStore()
    
    func load() {
        store.requestAccess(to: .event) { granted, error in
            // Handle the response to the request.
            
            // Get the appropriate calendar.
            let calendar = Calendar.current
            
            // Create the start date components
            var back = DateComponents()
            back.year = -1
            let oneYearAgo = calendar.date(byAdding: back, to: Date(), wrappingComponents: false)
            
            // Create the end date components.
            var fore = DateComponents()
            fore.year = 1
            let oneYearFromNow = calendar.date(byAdding: fore, to: Date(), wrappingComponents: false)
            
            // Create the predicate from the event store's instance method.
            var predicate: NSPredicate? = nil
            if let anAgo = oneYearAgo, let aNow = oneYearFromNow {
                predicate = self.store.predicateForEvents(withStart: anAgo, end: aNow, calendars: nil)
            }
            
            // Fetch all events that match the predicate.
            var events: [EKEvent]? = nil
            if let aPredicate = predicate {
                events = self.store.events(matching: aPredicate)
            }
            
            DispatchQueue.main.async {
                self.events = events ?? self.events
            }
        }
    }
}

struct CalendarWidget_Previews: PreviewProvider {
    static var previews: some View {
        CalendarWidget()
    }
}
