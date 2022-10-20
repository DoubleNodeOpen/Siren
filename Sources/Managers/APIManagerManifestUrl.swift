//
//  APIManagerManifestUrl.swift
//  Siren
//
//  Created by Arthur Sabintsev on 11/24/18.
//  Copyright © 2018 Sabintsev iOS Projects. All rights reserved.
//

import Foundation

/// APIManager for Siren
public class APIManagerManifestUrl: APIManager {
    /// Constants used in the `APIManagerManifestUrl`.
    private struct Constants {
        /// Constant for the `bundleId` parameter in the iTunes Lookup API request.
        static let bundleID = "bundleId"
        /// Constant for the `country` parameter in the iTunes Lookup API request.
        static let country = "country"
        /// Constant for the `lang` parameter in the iTunes Lookup API request.
        static let language = "lang"
        /// Constant for the `entity` parameter in the iTunes Lookup API reqeust.
        static let entity = "entity"
        /// Constant for the `entity` parameter value when performing a tvOS iTunes Lookup API reqeust.
        static let tvSoftware = "tvSoftware"
    }

    /// Return results or errors obtained from performing a version check with Siren.
    typealias CompletionHandler = (Result<APIModel, KnownError>) -> Void

    /// The Bundle ID for the your application. Defaults to "Bundle.main.bundleIdentifier".
    let bundleID: String?
    
    /// The region or country of an App Store in which the app is available.
    let country: AppStoreCountry
    
    /// The language for the localization of App Store responses.
    let language: String?

    public var manifestUrl: URL?
    
    /// Initializes `APIManager` to the region or country of an App Store in which the app is available.
    /// By default, all version check requests are performed against the US App Store and the language of the copy/text is returned in English.
    /// - Parameters:
    ///  - country: The country for the App Store in which the app is available.
    ///  - language: The locale to use for the App Store notes. The default result the API returns is equivalent to passing "en_us", so passing `nil` is equivalent to passing "en_us".
    ///  - bundleID: The bundleID for your app. Defaults to `Bundle.main.bundleIdentifier`. Passing `nil` will throw a `missingBundleID` error.
    public init(country: AppStoreCountry = .unitedStates, language: String? = nil, bundleID: String? = Bundle.main.bundleIdentifier) {
      self.country = country
      self.language = language
      self.bundleID = bundleID
    }

    /// Convenience initializer that initializes `APIMAPIManagerManifestUrlanager` to the region or country of an App Store in which the app is available.
    /// If nil, version check requests are performed against the US App Store.
    ///
    /// - Parameter countryCode: The raw country code for the App Store in which the app is available.
    public convenience init(countryCode: String?) {
      self.init(country: .init(code: countryCode))
    }

    /// Creates and performs a URLRequest against the iTunes Lookup API.
    ///
    /// - returns APIModel: The decoded JSON as an instance of APIModel.
    override func performVersionCheckRequest() async throws -> APIModel {
        guard bundleID != nil else {
            throw KnownError.missingBundleID
        }

        do {
            guard let url = self.manifestUrl else {
                throw KnownError.malformedURL
            }
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
            let (data, response) = try await URLSession.shared.data(for: request)
            return try processVersionCheckResults(withData: data, response: response)
        } catch {
            throw error
        }
    }

    /// Parses and maps the the results from the iTunes Lookup API request.
    ///
    /// - Parameters:
    ///   - data: The JSON data returned from the request.
    ///   - response: The response metadata returned from the request.
    private func processVersionCheckResults(withData data: Data?, response: URLResponse?) throws -> APIModel {
        guard let data = data else {
            throw KnownError.appStoreDataRetrievalFailure(underlyingError: nil)
        }
        do {
            let manifestModel = try PropertyListDecoder().decode(ManifestModel.self, from: data)
            guard let item = manifestModel.items.first else {
                throw KnownError.appStoreDataRetrievalEmptyResults
            }
            let metadata = item.metadata
            let releaseDate = metadata.releaseDate
            let releaseNotes = metadata.releaseNotes
            let version = metadata.bundleVersion
            let minimumOSVersion = "14.0"
            
            let result = APIModel.Results(appID: 1,
                                          currentVersionReleaseDate: releaseDate,
                                          minimumOSVersion: minimumOSVersion,
                                          releaseNotes: releaseNotes,
                                          version: version)
            let apiModel = APIModel(results: [ result ])

            guard !apiModel.results.isEmpty else {
                throw KnownError.appStoreDataRetrievalEmptyResults
            }

            return apiModel
        } catch {
            throw KnownError.appStoreJSONParsingFailure(underlyingError: error)
        }
    }
}

struct ManifestModel: Decodable {
    private enum CodingKeys: String, CodingKey {
        case items
    }

    let items: [Item]

    struct Item: Decodable {
        private enum CodingKeys: String, CodingKey {
            case assets, metadata
        }

        let assets: [Asset]
        let metadata: Metadata

        struct Asset: Decodable {
            private enum CodingKeys: String, CodingKey {
                case kind, url
            }
            
            let kind: String
            let url: String
        }
        struct Metadata: Decodable {
            private enum CodingKeys: String, CodingKey {
                case bundleId = "bundle-identifier"
                case bundleVersion = "bundle-version"
                case releaseDate = "release-date"
                case releaseNotes = "release-notes"
                case kind
                case platform = "platform-identifier"
                case title
            }

            let bundleId: String
            let bundleVersion: String
            let releaseDate: String
            let releaseNotes: String
            let kind: String
            let platform: String
            let title: String
        }
    }
}
