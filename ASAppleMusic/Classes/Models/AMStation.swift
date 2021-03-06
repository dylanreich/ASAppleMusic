//
//  Alex Silva - 2018
//  alex@alexsays.info
//

import Foundation
import Alamofire
import EVReflection

/**
 Station object representation. For more information take a look at [Apple Music API](https://developer.apple.com/documentation/applemusicapi/station)
 */
public class AMStation: EVObject {

    /// The radio station artwork
    public var artwork: AMArtwork?

    /// (Optional) The duration of the stream. Not emitted for 'live' or programmed stations
    public var durationInMillis: Int64?

    /// (Optional) The notes about the station that appear in Apple Music
    public var editorialNotes: AMEditorialNotes?

    /// (Optional) The episode number of the station. Only emitted when the station represents an episode of a show or other content
    public var episodeNumber: Int?

    /// Indicates whether the station is a live stream
    public var isLive: Bool?

    /// The localized name of the station
    public var name: String?

    /// The URL for sharing a station in Apple Music
    public var url: String?

    /// :nodoc:
    public override func propertyConverters() -> [(key: String, decodeConverter: ((Any?) -> ()), encodeConverter: (() -> Any?))] {
        return [
            ("artwork", { if let artwork = $0 as? NSDictionary { self.artwork = AMArtwork(dictionary: artwork) } }, { return self.artwork }),
            ("editorialNotes", { if let editorialNotes = $0 as? NSDictionary { self.editorialNotes = AMEditorialNotes(dictionary: editorialNotes) } }, { return self.editorialNotes })
        ]
    }
    /// :nodoc:
    public override func setValue(_ value: Any!, forUndefinedKey key: String) {
        if key == "durationInMillis" {
            if let rawValue = value as? Int64 {
                durationInMillis = rawValue
            }
        } else if key == "episodeNumber" {
            if let rawValue = value as? Int {
                episodeNumber = rawValue
            }
        }
    }

}

public extension ASAppleMusic {

    /**
     Get Station based on the id of the `storefront` and the station `id`

     - Parameters:
     - id: The id of the station (Number). Example: `"ra.925434166"`
     - storeID: The id of the store in two-letter code. Example: `"us"`
     - lang: (Optional) The language that you want to use to get data. **Default value: `en-us`**
     - completion: The completion code that will be executed asynchronously after the request is completed. It has two return parameters: *Station*, *AMError*
     - station: the `Station` object itself
     - error: if the request you will get an `AMError` object

     **Example:** *https://api.music.apple.com/v1/catalog/us/stations/ra.925434166*
     */
    func getStation(withID id: String, storefrontID storeID: String, lang: String? = nil, completion: @escaping (_ station: AMStation?, _ error: AMError?) -> Void) {
        callWithToken { token in
            guard let token = token else {
                let error = AMError()
                error.status = "401"
                error.code = .unauthorized
                error.title = "Unauthorized request"
                error.detail = "Missing token, refresh current token or request a new token"
                completion(nil, error)
                self.print("[ASAppleMusic] 🛑: Missing token")
                return
            }
            let headers = [
                "Authorization": "Bearer \(token)"
            ]
            var url = "https://api.music.apple.com/v1/catalog/\(storeID)/stations/\(id)"
            if let lang = lang {
                url = url + "?l=\(lang)"
            }
            Alamofire.SessionManager.default.request(url, headers: headers)
                .responseJSON { (response) in
                    self.print("[ASAppleMusic] Making Request 🌐: \(url)")
                    if let response = response.result.value as? [String:Any],
                        let data = response["data"] as? [[String:Any]],
                        let resource = data.first,
                        let attributes = resource["attributes"] as? NSDictionary {
                        let station = AMStation(dictionary: attributes)
                        completion(station, nil)
                        self.print("[ASAppleMusic] Request Succesful ✅: \(url)")
                    } else if let response = response.result.value as? [String:Any],
                        let errors = response["errors"] as? [[String:Any]],
                        let errorDict = errors.first as NSDictionary? {
                        let error = AMError(dictionary: errorDict)

                        self.print("[ASAppleMusic] 🛑: \(error.title ?? "") - \(error.status ?? "")")

                        completion(nil, error)
                    } else {
                        self.print("[ASAppleMusic] 🛑: Unauthorized request")

                        let error = AMError()
                        error.status = "401"
                        error.code = .unauthorized
                        error.title = "Unauthorized request"
                        error.detail = "Missing token, refresh current token or request a new token"
                        completion(nil, error)
                    }
            }
        }
    }

    /**
     Get several Station objects based on the `ids` of the stations that you want to get and the Storefront ID of the store

     - Parameters:
     - ids: An id array of the stations. Example: `["ra.925344166", "ra.1228162316"]`
     - storeID: The id of the store in two-letter code. Example: `"us"`
     - lang: (Optional) The language that you want to use to get data. **Default value: `en-us`**
     - completion: The completion code that will be executed asynchronously after the request is completed. It has two return parameters: *[Station]*, *AMError*
     - stations: the `[Station]` array of objects
     - error: if the request you will get an `AMError` object

     **Example:** *https://api.music.apple.com/v1/catalog/us/stations?ids=ra.925344166,ra.1228162316*
     */
    func getMultipleStations(withIDs ids: [String], storefrontID storeID: String, lang: String? = nil, completion: @escaping (_ stations: [AMStation]?, _ error: AMError?) -> Void) {
        callWithToken { token in
            guard let token = token else {
                let error = AMError()
                error.status = "401"
                error.code = .unauthorized
                error.title = "Unauthorized request"
                error.detail = "Missing token, refresh current token or request a new token"
                completion(nil, error)
                self.print("[ASAppleMusic] 🛑: Missing token")
                return
            }
            let headers = [
                "Authorization": "Bearer \(token)"
            ]
            var url = "https://api.music.apple.com/v1/catalog/\(storeID)/stations?ids=\(ids.joined(separator: ","))&"
            if let lang = lang {
                url = url + "l=\(lang)"
            }
            Alamofire.SessionManager.default.request(url, headers: headers)
                .responseJSON { (response) in
                    self.print("[ASAppleMusic] Making Request 🌐: \(url)")
                    if let response = response.result.value as? [String:Any],
                        let resources = response["data"] as? [[String:Any]] {
                        var stations: [AMStation]?
                        if resources.count > 0 {
                            stations = []
                        }
                        resources.forEach { stationData in
                            if let attributes = stationData["attributes"] as? NSDictionary {
                                let station = AMStation(dictionary: attributes)
                                stations?.append(station)
                            }
                        }
                        completion(stations, nil)
                        self.print("[ASAppleMusic] Request Succesful ✅: \(url)")
                    } else if let response = response.result.value as? [String:Any],
                        let errors = response["errors"] as? [[String:Any]],
                        let errorDict = errors.first as NSDictionary? {
                        let error = AMError(dictionary: errorDict)

                        self.print("[ASAppleMusic] 🛑: \(error.title ?? "") - \(error.status ?? "")")

                        completion(nil, error)
                    } else {
                        self.print("[ASAppleMusic] 🛑: Unauthorized request")

                        let error = AMError()
                        error.status = "401"
                        error.code = .unauthorized
                        error.title = "Unauthorized request"
                        error.detail = "Missing token, refresh current token or request a new token"
                        completion(nil, error)
                    }
            }
        }
    }

}

