//
//  OpenWeatherController.swift
//  Bachelor2
//
//  Created by Simon Sestak on 17/04/2021.
//

import Foundation
import CoreLocation
import MapKit

class WeatherService: NSObject {
    static let shared = WeatherService()
    private let locationManager = CLLocationManager()
    private let API_KEY = "c08a957aba600ac497dfb095e4c1cd30"
    private var completitionHandler: ((Weather) -> Void)?
    
    override init () {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func loadWeatherData(_ completitionHandler: @escaping ((Weather) -> Void)) {
        self.completitionHandler = completitionHandler
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    func makeDataRequest(for coordinates: CLLocationCoordinate2D) {
        guard let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(coordinates.latitude)&lon=\(coordinates.longitude)&appid=\(API_KEY)&units=metric".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let err = error {
                printError(from: "makeDataRequest", message: err.localizedDescription)
                return
            }
            guard let data = data else { return }
            if let response = try? JSONDecoder().decode(APIResponse.self, from: data) {
                self.completitionHandler?(Weather(response: response))
            }
        }.resume()
    }
}

extension WeatherService: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        makeDataRequest(for: location.coordinate)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        printError(from: "locationManager", message: error.localizedDescription)
        print(error)
    }
}

struct APIResponse: Codable {
    let name: String
    let main: MainAPI
    let weather: [WeatherAPI]
}

struct MainAPI: Codable {
    let temp: Double
    let humidity: Double
}

struct WeatherAPI: Codable {
    let description: String
    let iconName: String
    
    enum CodingKeys: String, CodingKey {
        case description
        case iconName = "main"
    }
}


public struct Weather {
    let city: String
    let temperature: Double
    let humidity: Double
    let desc: String
    let iconName: String
    
    init(response: APIResponse){
        city = response.name
        temperature = response.main.temp
        humidity = response.main.humidity
        desc = response.weather.first?.description ?? ""
        iconName = response.weather.first?.iconName ?? ""
    }
}
