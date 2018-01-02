//
//  TheKeyOAuth2Client+PasswordGrant.swift
//  TheKeyOAuth2
//
//  Created by Ryan Carlson on 12/27/17.
//  Copyright © 2017 TheKey. All rights reserved.
//

import Foundation
import GTMOAuth2

public enum TheKeyPasswordGrantResult {
    case success, badPassword, jsonParsingError, serverError, clientNotConfiguredError, responseCastingError, unknownError
}

public extension TheKeyOAuth2Client {
    public func passwordGrantLogin(for username: String, password: String, completion: @escaping (TheKeyPasswordGrantResult, Error?) -> Void) {
        if !isConfigured() {
            completion(.clientNotConfiguredError, nil)
            return
        }
        
        guard let request = buildAccessTokenRequest(for: username, password: password) else {
            completion(.clientNotConfiguredError, nil)
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        
        session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.unknownError, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.responseCastingError, nil)
                return
            }

            if httpResponse.statusCode == 200, let usableData = data {
                self.handleSuccessfulPasswordGrant(responseData: usableData, completion: completion)
                return
            }
            
            if httpResponse.statusCode == 400, let usableData = data {
                self.handleBadResponse(responseData: usableData, completion: completion)
                return
            }
            
            if httpResponse.statusCode / 100 == 5 {
                completion(.serverError, nil)
                return
            }
            
            completion(.unknownError, nil)
        }.resume()
    }
    
    private func buildAccessTokenRequest(for username: String, password: String) -> URLRequest? {
        guard let clientId = clientId, let serverURL = serverURL else {
            return nil
        }
        
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed)
        let encodedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed)
        
        var formURLString = "username=\(encodedUsername)"
        
        formURLString = formURLString.appending("&password=\(encodedPassword)")
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
    
    private func handleSuccessfulPasswordGrant(responseData: Data, completion: @escaping (TheKeyPasswordGrantResult, Error?) -> Void) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? Dictionary<String, Any?> else {
                return
            }

            setAuthenticationValuesFromJSON(json)
            saveAuthenticationToKeychain()
            
            completion(.success, nil)
        } catch {
            completion(.jsonParsingError, error)
        }
    }
    
    private func handleBadResponse(responseData: Data, completion: @escaping (TheKeyPasswordGrantResult, Error?) -> Void) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as? Dictionary<String, Any?> else {
                return
            }
            
            if let errorMessage = json["thekey_authn_error"] as? String, errorMessage == "invalid_credentials" {
                completion(.badPassword, nil)
            }
            
            // more statuses to come over time..
            
            completion(.serverError, nil)
        } catch {
            completion(.jsonParsingError, error)
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


