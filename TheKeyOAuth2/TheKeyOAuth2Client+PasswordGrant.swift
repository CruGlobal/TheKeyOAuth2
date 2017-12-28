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
    public func passwordGrantLogin(for username: String, password: String, completion: @escaping (TheKeyOAuth2Authentication?, Error?) -> Void) {
        if !isConfigured() {
            completion(nil, nil)
            return
        }
        
        guard let request = buildAccessTokenRequest(for: username, password: password) else {
            completion(nil, nil)
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        
        session.dataTask(with: request) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, nil)
                return
            }

            if httpResponse.statusCode == 200, let usableData = data {
                self.handleSuccessfulPasswordGrant(responseData: usableData, completion: completion)
            }
            
            if httpResponse.statusCode == 400, let usableData = data {
                self.handleBadResponse(responseData: usableData, completion: completion)
            }
        }.resume()
    }
    
    private func buildAccessTokenRequest(for username: String, password: String) -> URLRequest? {
        guard let clientId = clientId, let serverURL = serverURL else {
            return nil
        }
        
        var formURLString = "username=\(username)"
        
        formURLString = formURLString.appending("&password=\(password)")
        formURLString = formURLString.appending("&client_id=\(clientId)")
        formURLString = formURLString.appending("&scope=fullticket extended")
        formURLString = formURLString.appending("&grant_type=password")
        
        let tokenURL = serverURL.appendingPathComponent(TheKeyOAuth2TokenEndpoint)
        
        var request = URLRequest(url: tokenURL)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = formURLString.data(using: .utf8, allowLossyConversion: false)
        
        return request
    }
    
    private func buildAuthenticationFromJSON(_ json: [String: Any?]) -> TheKeyOAuth2Authentication {
        let auth = TheKeyOAuth2Authentication()
        auth.clientID = self.clientId
        
        if let accessToken = json["access_token"] as? String {
            auth.accessToken = accessToken
        }
        
        if let scope = json["scope"] as? String {
            auth.scope = scope
        }
        
        if let thekeyUsername = json["thekey_username"] as? String {
            auth.userID = thekeyUsername
        }
        
        if let refreshToken = json["refresh_token"] as? String {
            auth.refreshToken = refreshToken
        }
        
        if let thekeyGuid = json["thekey_guid"] as? String {
            auth.setValue(thekeyGuid, forKey: "guid")
        }
        
        return auth
    }
    
    private func handleSuccessfulPasswordGrant(responseData: Data, completion: @escaping (TheKeyOAuth2Authentication?, Error?) -> Void) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? Dictionary<String, Any?> else {
                return
            }
            
            let auth = buildAuthenticationFromJSON(json)
            
            GTMOAuth2ViewControllerTouch.saveParamsToKeychain(forName: TheKeyOAuth2KeychainName, authentication: auth)
            completion(auth, nil)
        } catch {
            completion(nil, error)
        }
    }
    
    private func handleBadResponse(responseData: Data, completion: @escaping (TheKeyOAuth2Authentication?, Error?) -> Void) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? Dictionary<String, Any?> else {
                return
            }
            
            completion(nil, nil)
        } catch {
            completion(nil, error)
        }
    }
}

extension TheKeyOAuth2Client: URLSessionDelegate {
    public func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(
            .useCredential,
            URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}


