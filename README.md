# TheKeyOAuth2
iOS OAuth2 Library for TheKey

## Setup
#### Add GlobalTechnology CocoaPods source respository to Podfile 

`source 'https://github.com/GlobalTechnology/cocoapods-specs.git'`

#### Add TheKeyOAuth2 pod to project

`pod 'TheKeyOAuth2', '~>0.6.5'`

#### Configure `TheKeyOAuth2Client` with server URL and client ID in app delegate, `viewDidLoad` or some other setup place prior to presenting login button.

````objc
[[TheKeyOAuth2Client sharedOAuth2Client] setServerURL:@"<https://...>"
                                             clientId:@"<client_id>"];
````

#### Implement `TheKeyOAuth2ClientLoginDelegate` in View Controller that presents the login button.

````objc
/*guid is the user's unique identifier in the identity system. no value means authN was not successful*/
- (void)loginViewController:(TheKeyOAuth2LoginViewController *)loginViewController loginSuccess:(NSString *)guid {
 /* optionally store the guid. complete the login process */
}

/* error implementation goes here */
````

#### Create an instance of `TheKeyOAuth2LoginViewController` with the presenting view controller as the delegate.

````objc
TheKeyOAuth2LoginViewController *loginController = [[TheKeyOAuth2Client sharedOAuth2Client] loginViewControllerWithLoginDelegate:self];
[self.navigationController pushViewController:loginController animated:YES];
````

#### Request a service ticket from the Identity Provider for the login URL of the target API

````objc
if ([[TheKeyOAuth2Client sharedOAuth2Client] isAuthenticated]) {
  [[TheKeyOAuth2Client sharedOAuth2Client] ticketForServiceURL:[@"<https://api.mysystem.com/login/..."
                                                      complete:^(NSString *ticket) {
                                                    /* Call target API login URL with service ticket and cache bearer token in client API. 
                                                    This steps varies depending on target service and client networking implementations. */
  }];
}
