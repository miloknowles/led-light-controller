import Foundation

class WeatherGetter {
    
    private let openWeatherMapBaseURL = "http://api.openweathermap.org/data/2.5/weather"
    private let openWeatherMapAPIKey = "a0f00efccaf12f3c1d705b575323962a"
    
    func getWeather(city: String) {
        
        // This is a pretty simple networking task, so the shared session will do.
        /*let session = URLSession.shared
        
        let weatherRequestURL = NSURL(string: "\(openWeatherMapBaseURL)?APPID=\(openWeatherMapAPIKey)&q=\(city)")!
        
        // The data task retrieves the data.
        let dataTask = session.dataTask(with: weatherRequestURL as URL) {(data: Data?, response: URLResponse?, error: Error?) in
            
            if let error = error {
                // Case 1: Error
                // We got some kind of error while trying to get data from the server.
                print("Error:\n\(error)")
            }
            else {
                print("Raw data:\n\(data!)\n")
                //let dataString = String(data: data!, encoding: String.Encoding.utf8)
                //let dataString = "{\"coord\":{\"lon\":-80.31,\"lat\":43.36},\"weather\":[{\"id\":620,\"main\":\"Snow\",\"description\":\"light shower snow\",\"icon\":\"13d\"}],\"base\":\"stations\",\"main\":{\"temp\":264.24,\"pressure\":1020,\"humidity\":72,\"temp_min\":263.15,\"temp_max\":265.15},\"visibility\":4023,\"wind\":{\"speed\":10.8,\"deg\":320,\"gust\":17},\"clouds\":{\"all\":75},\"dt\":1489182480,\"sys\":{\"type\":1,\"id\":3730,\"message\":0.0117,\"country\":\"CA\",\"sunrise\":1489146003,\"sunset\":1489188175},\"id\":5913695,\"name\":\"Cambridge\",\"cod\":200}"
                print("Human-readable data:\n\(dataString)")
            }
        }*/
        
        let dataString = "{\"coord\":{\"lon\":-80.31,\"lat\":43.36},\"weather\":[{\"id\":620,\"main\":\"Snow\",\"description\":\"light shower snow\",\"icon\":\"13d\"}],\"base\":\"stations\",\"main\":{\"temp\":264.24,\"pressure\":1020,\"humidity\":72,\"temp_min\":263.15,\"temp_max\":265.15},\"visibility\":4023,\"wind\":{\"speed\":10.8,\"deg\":320,\"gust\":17},\"clouds\":{\"all\":75},\"dt\":1489182480,\"sys\":{\"type\":1,\"id\":3730,\"message\":0.0117,\"country\":\"CA\",\"sunrise\":1489146003,\"sunset\":1489188175},\"id\":5913695,\"name\":\"Cambridge\",\"cod\":200}"
        print("Human-readable data:\n\(dataString)")
        
        /*var error : NSError?
        let JSONDictionary: Dictionary = JSONSerialization.jsonObject(with: JSONData, options: nil, error: &error) as NSDictionary
        
        // Loop
        for (key, value) in JSONDictionary {
            let keyName = key as String
            let keyValue: String = value as String
            
            
        }*/
        
        //print(testArray["coord"] ?? 0)
        
        // The data task is set up...launch it!
        //dataTask.resume()
    }
    
}
