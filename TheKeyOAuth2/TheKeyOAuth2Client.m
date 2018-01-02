//
//  TheKeyOAuth2Client.m
//  TheKeyGTM
//
//  Created by Brian Zoetewey on 11/14/13.
//  Copyright (c) 2013 Ekko Project. All rights reserved.
//

#import "TheKeyOAuth2Client.h"
#import "TheKeyOAuth2LoginViewController.h"

#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"

/* TheKey OAuth2 Settings */
static NSString *const TheKeyOAuth2ServiceProvider = @"TheKey";
static NSString *const TheKeyOAuth2RedirectURI     = @"oauth/client/public";
static NSString *const TheKeyOAuth2Scope           = @"fullticket extended";
NSString *const TheKeyOAuth2KeychainName    = @"TheKeyOAuth2Authentication";

/* TheKey OAuth2 Endpoints */
NSString *const TheKeyOAuth2TokenEndpoint      = @"api/oauth/token";
static NSString *const TheKeyOAuth2TicketEndpoint     = @"api/oauth/ticket";
static NSString *const TheKeyOAuth2AttributesEndpoint = @"api/oauth/attributes";
static NSString *const TheKeyOAuth2AuthorizeEndpoint  = @"login";

/* TheKey Notifications */
NSString *const TheKeyOAuth2ClientDidChangeGuidNotification = @"TheKeyOAuth2ClientDidChangeGuidNotification";
NSString *const TheKeyOAuth2ClientGuidKey = @"guid";

/* TheKey GUID Identifiers */
static NSString *const kTheKeyOAuth2GUIDKey = @"thekey_guid";
NSString *const TheKeyOAuth2GuestGUID = @"GUEST";

@interface TheKeyOAuth2Client () {
    BOOL _isLoginViewPresented;
    BOOL _isConfigured;
}

@property (nonatomic, strong, readwrite) NSURL *serverURL;
@property (nonatomic, strong, readwrite) NSString *clientId;
@property (nonatomic, weak) id<TheKeyOAuth2ClientLoginDelegate> loginDelegate;
@property (nonatomic, strong) TheKeyOAuth2Authentication *authentication;

@end

@implementation TheKeyOAuth2Client

@synthesize serverURL = _serverURL;
@synthesize clientId  = _clientId;
@synthesize authentication = _authentication;

+(TheKeyOAuth2Client *)sharedOAuth2Client {
    __strong static TheKeyOAuth2Client *_client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _client = [[TheKeyOAuth2Client alloc] init];
    });
    return _client;
}

-(id)init {
    self = [super init];
    if (self) {
        _isConfigured = NO;
    }
    return self;
}

-(void)setServerURL:(NSURL *)serverURL clientId:(NSString *)clientId {
    _serverURL = [serverURL copy];
    _clientId = [clientId copy];
    _authentication = [self newAuthenticationUsingKeychain:YES];
    _isConfigured = YES;
}

-(BOOL)isAuthenticated {
    return [self.authentication canAuthorize];
}

-(BOOL)isConfigured {
    return _isConfigured;
}
    
-(NSString *)guid {
    return self.authentication.guid ?: TheKeyOAuth2GuestGUID;
}

-(void)logout {
    [TheKeyOAuth2LoginViewController removeAuthFromKeychainForName:TheKeyOAuth2KeychainName];
    self.authentication = [self newAuthenticationUsingKeychain:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:TheKeyOAuth2ClientDidChangeGuidNotification object:self userInfo:@{TheKeyOAuth2ClientGuidKey: [self guid]}];
    });
}

-(TheKeyOAuth2LoginViewController *)loginViewControllerWithLoginDelegate:(id<TheKeyOAuth2ClientLoginDelegate>)delegate {
    return [self loginViewController:[TheKeyOAuth2LoginViewController class] loginDelegate:delegate];
}

-(TheKeyOAuth2LoginViewController *)loginViewController:(Class)loginViewControllerClass loginDelegate:(id<TheKeyOAuth2ClientLoginDelegate>)delegate {
    if (![loginViewControllerClass isSubclassOfClass:[TheKeyOAuth2LoginViewController class]]) {
        return nil;
    }
    
    self.loginDelegate = delegate;
    _isLoginViewPresented = NO;
    return (TheKeyOAuth2LoginViewController *)[[loginViewControllerClass alloc]
                                               initWithAuthentication:self.authentication
                                               authorizationURL:[self.serverURL URLByAppendingPathComponent:TheKeyOAuth2AuthorizeEndpoint]
                                               keychainItemName:TheKeyOAuth2KeychainName
                                               delegate:self
                                               finishedSelector:@selector(viewController:finishedWithAuth:error:)];
}

-(void)presentLoginViewController:(Class)loginViewControllerClass fromViewController:(UIViewController *)viewController loginDelegate:(id<TheKeyOAuth2ClientLoginDelegate>)delegate {
    TheKeyOAuth2LoginViewController *loginViewController = [self loginViewController:loginViewControllerClass loginDelegate:delegate];
    if (loginViewController) {
        [loginViewController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
        [viewController presentViewController:loginViewController animated:YES completion:^{
            _isLoginViewPresented = YES;
        }];
    }
}

-(void)presentLoginViewControllerFromViewController:(UIViewController *)viewController loginDelegate:(id<TheKeyOAuth2ClientLoginDelegate>)delegate {
    [self presentLoginViewController:[TheKeyOAuth2LoginViewController class] fromViewController:viewController loginDelegate:delegate];
}

-(void)ticketForServiceURL:(NSURL *)service complete:(void (^)(NSString *ticket))complete {
    [self ticketForServiceURL:service complete:complete tryRefreshingAccessToken:true];
}

-(void)ticketForServiceURL:(NSURL *)service complete:(void (^)(NSString *ticket))complete tryRefreshingAccessToken:(BOOL)refresh {
    NSString * queryString = [TheKeyOAuth2Authentication encodedQueryParametersForDictionary:@{@"service":[service absoluteString]}];
    NSURL *ticketURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [[self.serverURL URLByAppendingPathComponent:TheKeyOAuth2TicketEndpoint] absoluteString], queryString]];
    NSMutableURLRequest *ticketRequest = [NSMutableURLRequest requestWithURL:ticketURL];
    [self.authentication authorizeRequest:ticketRequest completionHandler:^(NSError *error) {
        if (error == nil) {
            [NSURLConnection sendAsynchronousRequest:ticketRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                NSInteger code = [(NSHTTPURLResponse *)response statusCode];

                if (data && code == 200) {
                    NSError *error = nil;
                    NSDictionary *json = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                    NSString *ticket = [json valueForKey:@"ticket"];
                    if (complete != nil) {
                        complete(ticket);
                    }
                }
                else if (code == 401) {
                    // try forcing an access_token refresh (1 time only)
                    if (refresh && [self.authentication primeForRefresh]) {
                        [self ticketForServiceURL:service complete:complete tryRefreshingAccessToken:false];
                    }
                    // otherwise reset the authentication
                    else {
                        [self.authentication reset];
                        if (complete != nil) {
                            complete(nil);
                        }
                    }
                }
                else if(complete) {
                    complete(nil);
                }
            }];
        }
        else if(complete) {
            complete(nil);
        }
    }];
}

-(TheKeyOAuth2Authentication *)newAuthenticationUsingKeychain:(BOOL)useKeychain {
    TheKeyOAuth2Authentication *auth = [TheKeyOAuth2Authentication authenticationWithServiceProvider:TheKeyOAuth2ServiceProvider
                                                                                            tokenURL:[self.serverURL URLByAppendingPathComponent:TheKeyOAuth2TokenEndpoint]
                                                                                         redirectURI:[self redirectURL]
                                                                                            clientID:self.clientId
                                                                                        clientSecret:@""];
    [auth setScope:TheKeyOAuth2Scope];
    if (auth && useKeychain) {
        [TheKeyOAuth2LoginViewController authorizeFromKeychainForName:TheKeyOAuth2KeychainName authentication:auth error:nil];
    }
    return auth;
}

-(void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)authentication error:(NSError *)error {
    if (error != nil) {
        if (error.code != GTMOAuth2ErrorWindowClosed && _isLoginViewPresented) {
            [viewController.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
        }
        if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(loginViewController:loginError:)]) {
            [self.loginDelegate loginViewController:(TheKeyOAuth2LoginViewController *)viewController loginError:error];
        }
    }
    else {
        self.authentication = (TheKeyOAuth2Authentication *)authentication;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:TheKeyOAuth2ClientDidChangeGuidNotification object:self userInfo:@{TheKeyOAuth2ClientGuidKey: [self guid]}];
        });
        if (_isLoginViewPresented) {
            [viewController.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
        }
        if (self.loginDelegate && [self.loginDelegate respondsToSelector:@selector(loginViewController:loginSuccess:)]) {
            [self.loginDelegate loginViewController:(TheKeyOAuth2LoginViewController *)viewController loginSuccess:self.authentication.guid];
        }
    }
    self.loginDelegate = nil;
}

- (NSString *)redirectURL {
    NSString *optionalSlash = [[[self serverURL] absoluteString] hasSuffix:@"/"] ? @"" : @"/";
    return [NSString stringWithFormat:@"%@%@%@", [[self serverURL] absoluteString], optionalSlash, TheKeyOAuth2RedirectURI];
}


-(void)setAuthenticationValuesFromJSON:(NSDictionary *)json {
    self.authentication.accessToken = json[@"access_token"];
    self.authentication.scope = json[@"scope"];
    self.authentication.userID = json[@"thekey_username"];
    self.authentication.refreshToken = json[@"refresh_token"];
}

-(void)saveAuthenticationToKeychain {
    [GTMOAuth2ViewControllerTouch saveParamsToKeychainForName:TheKeyOAuth2KeychainName authentication:self.authentication];
}

@end

@implementation TheKeyOAuth2Authentication

-(NSString *)guid {
    return [self.parameters objectForKey:kTheKeyOAuth2GUIDKey];
}

-(void)setGuid:(NSString *)guid {
    [self.parameters setValue:guid forKey:kTheKeyOAuth2GUIDKey];
}

-(NSString *)persistenceResponseString {
    NSMutableString *string = [[super persistenceResponseString] mutableCopy];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:self.guid forKey:kTheKeyOAuth2GUIDKey];
    NSString *guidString = [[self class] encodedQueryParametersForDictionary:dict];
    if (guidString) {
        [string appendFormat:@"&%@", guidString];
    }
    return string;
}

-(BOOL)primeForRefresh {
    BOOL result = [super primeForRefresh];
    if (result) {
        self.guid = nil;
    }
    return result;
}

-(void)reset {
    [super reset];
    self.guid = nil;
}

@end
