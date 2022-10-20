//
//  APIManager.swift
//  Siren
//
//  Created by Arthur Sabintsev on 11/24/18.
//  Copyright © 2018 Sabintsev iOS Projects. All rights reserved.
//

import Foundation

public class APIManager {
    /// The default `APIManager`.
    ///
    /// The version check is performed against the  US App Store.
    public static let `default` = APIManagerAppStoreUS()
    public static let manifestUrl = APIManagerManifestUrl()
    
    /// Creates and performs a URLRequest against the iTunes Lookup API.
    ///
    /// - returns APIModel: The decoded JSON as an instance of APIModel.
    func performVersionCheckRequest() async throws -> APIModel {
        throw KnownError.appStoreAppIDFailure
    }
}
