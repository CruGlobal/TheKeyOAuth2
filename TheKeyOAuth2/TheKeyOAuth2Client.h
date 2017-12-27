//
//  TheKeyOAuth2Client.h
//  TheKeyGTM
//
//  Created by Brian Zoetewey on 11/14/13.
//  Copyright (c) 2013 Ekko Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TheKeyOAuth2LoginViewController.h"

@protocol TheKeyOAuth2ClientLoginDelegate;

/* TheKey Notifications */
FOUNDATION_EXPORT NSString *const TheKeyOAuth2ClientDidChangeGuidNotification;
FOUNDATION_EXPORT NSString *const TheKeyOAuth2ClientGuidKey;

/* TheKey Guest GUID */
FOUNDATION_EXPORT NSString *const TheKeyOAuth2GuestGUID;

/* TheKey Keychain Name */
extern NSString *const TheKeyOAuth2KeychainName;

/* TheKey Token Endpoint Name */
extern NSString *const TheKeyOAuth2TokenEndpoint;

/* Customized extension of the GTMOAuth2Authentication interface which adds a property for GUID */
@interface TheKeyOAuth2Authentication : GTMOAuth2Authentication

@property (nonatomic, strong) NSString *guid;

@end

@interface TheKeyOAuth2Client : NSObject

+(TheKeyOAuth2Client *)sharedOAuth2Client;

@property (nonatomic, strong, readonly) NSURL *serverURL;
@property (nonatomic, strong, readonly) NSString *clientId;
@property (nonatomic, strong) TheKeyOAuth2Authentication *authentication;

-(id)init;
-(void)setServerURL:(NSURL *)serverURL clientId:(NSString *)clientId;

-(NSString *)guid;

-(BOOL)isConfigured;
-(BOOL)isAuthenticated;

-(void)logout;

-(TheKeyOAuth2LoginViewController *)loginViewControllerWithLoginDelegate:(id<TheKeyOAuth2ClientLoginDelegate>)delegate;
-(TheKeyOAuth2LoginViewController *)loginViewController:(Class)loginViewControllerClass loginDelegate:(id<TheKeyOAuth2ClientLoginDelegate>)delegate;

-(void)presentLoginViewControllerFromViewController:(UIViewController *)viewController loginDelegate:(id<TheKeyOAuth2ClientLoginDelegate>)delegate;
-(void)presentLoginViewController:(Class)loginViewControllerClass fromViewController:(UIViewController *)viewController loginDelegate:(id<TheKeyOAuth2ClientLoginDelegate>)delegate;

-(void)ticketForServiceURL:(NSURL *)service complete:(void (^)(NSString *ticket))complete;

@end

@protocol TheKeyOAuth2ClientLoginDelegate <NSObject>
@optional
-(void)loginViewController:(TheKeyOAuth2LoginViewController *)loginViewController loginSuccess:(NSString *)guid;
-(void)loginViewController:(TheKeyOAuth2LoginViewController *)loginViewController loginError:(NSError *)error;
@end
