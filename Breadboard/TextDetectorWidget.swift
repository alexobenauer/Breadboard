//
//  TextDetectorWidget.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/28/23.
//

import SwiftUI
import NaturalLanguage
import CoreLocation

// https://developer.apple.com/documentation/foundation/nslinguistictagger/identifying_people_places_and_organizations

struct TextDetectorWidget: Widget {
    var title: String { "Text Detector" }
    var icon: String { "highlighter" }
    var color: Color { .yellow }
    
    let id = UUID()
    
    @EnvironmentObject var store: WorkspaceStore
    
    @State private var text: String = ""
    @StateObject private var manager = Manager()
    
    var body: some View {
        ScrollView {
            VStack {
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 300)
                    .padding()
                    .onChange(of: text) { newValue in
                        manager.fetchResults(text: newValue, store: store, id: id)
                    }
                    // TODO: Should be based on values not count
                    .onChange(of: manager.results.count) { _ in
                        store.declareOutputs(manager.results, fromWidgetId: id)
                    }
                
//                if manager.results.count > 0 {
//                    Divider()
//                }
//
//                ForEach(manager.results, id: \.hash) { result in
//                    switch result.resultType {
//                    case .date:
//                        let date = result.date
//                        let timeZone = result.timeZone
//                        let duration = result.duration
//                        Text("\(date), \(timeZone), \(duration)")
//                    case .address:
//                        if let components = result.components {
//                            let name = components[.name]
//                            let jobTitle = components[.jobTitle]
//                            let organization = components[.organization]
//                            let street = components[.street]
//                            let locality = components[.city]
//                            let region = components[.state]
//                            let postalCode = components[.zip]
//                            let country = components[.country]
//                            let phoneNumber = components[.phone]
//                            Text("\(name), \(jobTitle), \(organization), \(street), \(locality), \(region), \(postalCode), \(country), \(phoneNumber)")
//                        }
//                    case .link:
//                        let url = result.url
//                        Text("\(url)")
//                    case .phoneNumber:
//                        let phoneNumber = result.phoneNumber
//                        Text("\(phoneNumber)")
//                    case .transitInformation:
//                        if let components = result.components {
//                            let airline = components[.airline]
//                            let flight = components[.flight]
//                            Text("\(airline), \(flight)")
//                        }
//                    default:
//                        Text("Unrecognized result of type \(result.resultType)")
//                    }
//                }
            }
        }
        .background(.yellow.opacity(0.01))
    }
}

fileprivate class Manager: ObservableObject {
    @Published var fetching: Bool = false
    @Published var results: [any WorkspaceItem] = []
    
    private var updateThrottle: DispatchWorkItem? = nil
    
    func _fetchResults(text: String, store: WorkspaceStore, id: UUID) {
        // let text = "I'd like to visit Miami or Denver the weekend of February 4."
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.personalName, .placeName, .organizationName]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            // Get the most likely tag, and print it if it's a named entity.
            if let tag = tag, tags.contains(tag) {
                print("\(text[tokenRange]): \(tag.rawValue)")
            }
            
            // Get multiple possible tags with their associated confidence scores.
            let (hypotheses, _) = tagger.tagHypotheses(at: tokenRange.lowerBound, unit: .word, scheme: .nameType, maximumCount: 1)
            print(hypotheses)
            
            return true
        }
    }
    
    func fetchResults(text: String, store: WorkspaceStore, id: UUID) {
        self.fetching = true
        
        self.updateThrottle?.cancel()
        
        let task = DispatchWorkItem {
            let types: NSTextCheckingResult.CheckingType = [
                .orthography,
                .spelling,
                .grammar,
                .date,
                .address,
                .link,
                .quote,
                .dash,
                .replacement,
                .correction,
                .regularExpression,
                .phoneNumber,
                .transitInformation
            ]
            
            let detector = try! NSDataDetector(types: NSTextCheckingAllTypes) // types.rawValue
            
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            
            for match in detector.matches(in: text, range: range) {
                switch match.resultType {
                case .date:
                    let date = match.date
                    let timeZone = match.timeZone
                    let duration = match.duration
                    print(date, timeZone, duration)
                    
                    if let date {
                        store.donatePrimitiveValue(.date(date), fromId: id)
                    }
                    
                    if let date {
                        let dateItem = DateItem(date: date, timezone: timeZone, duration: duration)
                        store.donateItems(items: [dateItem], fromId: id)
                        self.results.append(dateItem)
                    }
                case .address:
                    if let components = match.components {
                        let name = components[.name]
                        let jobTitle = components[.jobTitle]
                        let organization = components[.organization]
                        let street = components[.street]
                        let locality = components[.city]
                        let region = components[.state]
                        let postalCode = components[.zip]
                        let country = components[.country]
                        let phoneNumber = components[.phone]
                        print(name, jobTitle, organization, street, locality, region, postalCode, country, phoneNumber)
                        
                        print((text as NSString).substring(with: match.range))
                        
                        AddressItem.make(text: (text as NSString).substring(with: match.range)) { [weak self] item in
                            store.donateItems(items: [item], fromId: id)
                            self?.results.append(item)
                        }
                    }
                case .link:
                    let url = match.url
                    print(url)
                case .phoneNumber:
                    let phoneNumber = match.phoneNumber
                    print(phoneNumber)
                case .transitInformation:
                    if let components = match.components {
                        let airline = components[.airline]
                        let flight = components[.flight]
                        print(airline, flight)
                    }
                default:
                    return
                }
            }
        }
        
        self.updateThrottle = task
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: task)
    }
}

struct DateItem: WorkspaceItem {
    var id = UUID()

    var type: String { "date" }
    var primitiveValue: WorkspaceStore.PrimitiveValue? { .date(date) }
    // var associations: [WorkspaceStore.PrimitiveValue] { get }
    // var items: [any WorkspaceItem] { get }

    let date: Date
    let timezone: TimeZone?
    let duration: TimeInterval?

//    func generateWidget() -> any Widget {
//        // Calendar View...
//    }
}

struct AddressItem: WorkspaceItem {
    var id = UUID()

    var type: String { "address" }
    // var primitiveValue: WorkspaceStore.PrimitiveValue? { .date(date) }
    var associations: [WorkspaceStore.PrimitiveValue] // { [.location(<#T##CLLocation#>)] }
    // var items: [any WorkspaceItem] { get }

    let text: String
//    let street: String
//    let zip: String
    
    static let geoCoder = CLGeocoder()
    
    static func make(text: String, finished: @escaping (Self) -> Void) {
        geoCoder.geocodeAddressString(text) { (placemarks, error) in
            if let placemarks = placemarks, let location = placemarks.first?.location {
                finished(AddressItem(associations: [.location(location)], text: text))
            }
        }
    }

//    func generateWidget() -> any Widget {
//        // Map View...
//    }
}

//struct TextDetectorWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        TextDetectorWidget()
//    }
//}
