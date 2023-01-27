//
//  WeatherWidgetView.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/13/23.
//

import SwiftUI
import CoreLocation
import WeatherKit

struct WeatherWidget: Widget {
    var title: String { "Weather" }
    var icon: String { "sun.max.fill" }
    var color: Color { .orange }
    
    let id = UUID()
    
    @EnvironmentObject var store: WorkspaceStore
    @State private var locationTitle: String = "-"
    @StateObject private var weatherManager = WeatherManager()
    
    @State private var selectedView = WidgetView.daily
    
    private let geocoder = CLGeocoder()
    
    private func update() async {
        guard let location = store.getContextualLocation(forWidgetId: id) else {
            return
        }
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
                
            if let placemark = placemarks.first {
                if let city = placemark.locality {
                    print(city)
                    self.locationTitle = city
                } else {
                    print("City not found")
                    self.locationTitle = "-"
                }
            }
        } catch {
            print("Reverse geocoder failed with error" + error.localizedDescription)
            self.locationTitle = "-"
        }
        
        if store.doFetching {
            weatherManager.fetchWeather(forLocation: location)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text(locationTitle)
                        .font(.title).bold()
                        
                    Spacer()
                    
                    Picker(selection: $selectedView, label: Text("")) {
                        ForEach(WidgetView.allCases, id: \.self) { option in
                            Text(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 100)
                }
                .padding(.bottom)
                
                if store.doFetching {
                    Group {
                        if let weather = weatherManager.weather {
                            HStack {
                                Label(weather.currentWeather.condition.description, systemImage: weather.currentWeather.symbolName)
                                Spacer()
                                Text(weather.currentWeather.temperature.converted(to: .fahrenheit).tempStringShort)
                            }
                            .font(.title2)
                            
                            Divider()
                            
                            switch selectedView {
                            case .hourly:
                                ForEach(weather.hourlyForecast, id: \.date) { hourly in
                                    HStack {
                                        Text(hourly.date.timeStringShort)
                                            .frame(width: 80, alignment: .trailing)
                                            .padding(.trailing)
                                        Label(hourly.condition.description, systemImage: hourly.symbolName)
                                        Spacer()
                                        Text(hourly.temperature.converted(to: .fahrenheit).tempStringShort)
                                    }
                                }
                            case .daily:
                                ForEach(weather.dailyForecast, id: \.date) { daily in
                                    HStack {
                                        Text(daily.date.dateString)
                                            .frame(width: 100, alignment: .leading)
                                            .padding(.trailing)
                                        Label(daily.condition.description, systemImage: daily.symbolName)
                                        Spacer()
                                        Text(daily.lowTemperature.converted(to: .fahrenheit).tempStringShort)
                                        Text(daily.highTemperature.converted(to: .fahrenheit).tempStringShort)
                                    }
                                }
                            }
                        }
                    }
                    .opacity(weatherManager.fetching ? 0.33 : 1)
                }
                
                Spacer()
            }
            .padding()
        }
        .onChange(of: store.getContextualLocation(forWidgetId: id) ?? CLLocation()) { location in
            Task { await update() }
        }
        .onChange(of: store.doFetching) { newValue in
            if newValue {
                Task { await update() }
            }
        }
        .onAppear {
            Task { await update() }
        }
    }
}

fileprivate extension WeatherWidget {
    enum WidgetView: String, CaseIterable {
        case hourly = "Hourly"
        case daily = "Daily"
    }
}

fileprivate class WeatherManager: ObservableObject {
    @Published var fetching: Bool = false
    @Published var weather: Weather? = nil
    
    private var updateThrottle: DispatchWorkItem? = nil
    
    func fetchWeather(forLocation location: CLLocation) {
        self.fetching = true
        
        self.updateThrottle?.cancel()
        
        let task = DispatchWorkItem {
            Task {
                do {
                    let weather = try await WeatherService.shared.weather(for: location)
                    print(weather)
                    
                    DispatchQueue.main.async {
                        self.weather = weather
                        self.fetching = false
                    }
                } catch {
                    print(error)
                    
                    DispatchQueue.main.async {
                        self.fetching = false
                    }
                }
            }
        }
        
        self.updateThrottle = task
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: task)
    }
}

fileprivate let dateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "EEE, MMM d"
    return f
}()

fileprivate let timeFormatter = {
    let f = DateFormatter()
    f.timeStyle = .short
    return f
}()

fileprivate extension Date {
    var dateString: String {
        dateFormatter.string(from: self)
    }
    
    var timeStringShort: String {
        timeFormatter.string(from: self)
    }
}

fileprivate extension Measurement<UnitTemperature> {
    var tempStringShort: String {
        "\(Int(round(value))) \(unit.symbol)"
    }
}

struct WeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        WeatherWidget()//.body(store: WorkspaceStore())
    }
}
