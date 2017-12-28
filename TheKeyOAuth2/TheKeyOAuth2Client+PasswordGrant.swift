//
//  TheKeyOAuth2Client+PasswordGrant.swift
//  TheKeyOAuth2
//
//  Created by Ryan Carlson on 12/27/17.
//  Copyright © 2017 TheKey. All rights reserved.
//

import Foundation
import GTMOAuth2


public extension TheKeyOAuth2Client {
    public func passwordGrantLogin(for username: String, password: String, completion:  @escaping (TheKeyOAuth2Authentication?, Error?) -> Void) {
        if !isConfigured() {
            return
        }
        
        let request = buildAccessTokenRequest(for: username, password: password)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in            
            if let usableData = data {
                do {
                    guard let json = try JSONSerialization.jsonObject(with: usableData, options: .allowFragments) as? Dictionary<String, Any?> else {
                        return
                    }
                    
                    let auth = TheKeyOAuth2Authentication()
                    auth.accessToken = json["access_token"] as? String
                    auth.scope = json["scope"] as? String
                    auth.userID = json["thekey_username"] as? String
                    auth.clientID = self.clientId
                    auth.refreshToken = json["refresh_token"] as? String
                    auth.guid = json["thekey_guid"] as? String
                    
                    GTMOAuth2ViewControllerTouch.saveParamsToKeychain(forName: TheKeyOAuth2KeychainName, authentication: auth)
                    completion(auth, nil)
                } catch {
                    completion(nil, error)
                    print(error)
                }
            }
            }.resume()
    }
    
    private func buildAccessTokenRequest(for username: String, password: String) -> URLRequest {
        var formURLString = "username=\(username)"
        
        formURLString = formURLString.appending("&password=\(password)")
        formURLString = formURLString.appending("&client_id=\(clientId!)")
        formURLString = formURLString.appending("&scope=fullticket extended")
        formURLString = formURLString.appending("&grant_type=password")
        
        var request = URLRequest(url: serverURL!)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = formURLString.data(using: .utf8, allowLossyConversion: false)
        
        return request
    }
}
