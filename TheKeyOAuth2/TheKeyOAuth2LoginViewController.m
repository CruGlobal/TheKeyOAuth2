//
//  TheKeyOAuth2LoginViewController.m
//  TheKeyOAuth2
//
//  Created by Brian Zoetewey on 11/19/13.
//  Copyright (c) 2013 TheKey. All rights reserved.
//

#import "TheKeyOAuth2LoginViewController.h"

@interface TheKeyOAuth2LoginViewController ()

@property (strong, nonatomic) UIBarButtonItem *forwardBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *backBarButtonItem;
@end

@implementation TheKeyOAuth2LoginViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateNavButtonEnabledState)
                                                 name:kGTMOAuth2WebViewStoppedLoading
                                               object:nil];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kGTMOAuth2WebViewStoppedLoading
                                                  object:nil];
}

-(IBAction)dismissLoginViewController:(id)sender {
    if ([self isBeingPresented]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)updateNavButtonEnabledState {
    self.forwardBarButtonItem.enabled = [self.webView canGoForward];
    self.backBarButtonItem.enabled = [self.webView canGoBack];
}

- (void)setUpNavigation {
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.000 green:0.475 blue:0.757 alpha:1.00];
    [self.navigationController.navigationBar setTranslucent:NO];
    
    [self configureNavButtons];
}

- (void)configureNavButtons {
    self.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[self leftChevronImage]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self.webView
                                                             action:@selector(goBack)];
    
    self.forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[self rightChevronImage]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self.webView
                                                                action:@selector(goForward)];
    
    self.backBarButtonItem.enabled = [self.webView canGoBack];
    self.forwardBarButtonItem.enabled = [self.webView canGoForward];
    
    self.navigationItem.rightBarButtonItems = @[self.forwardBarButtonItem, self.backBarButtonItem];
}

-(UIImage *)leftChevronImage {
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"TheKey" withExtension:@".bundle"]];
    
    return [UIImage imageNamed:@"back" inBundle:bundle compatibleWithTraitCollection:nil];
}

-(UIImage *)rightChevronImage {
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"TheKey" withExtension:@".bundle"]];
    
    return [UIImage imageNamed:@"forward" inBundle:bundle compatibleWithTraitCollection:nil];
}

// subclasses may override this to specify a custom nib bundle
// This allows the POD to be used as a framework so that it can be used properly in SWIFT code.
+ (NSBundle *)authNibBundle {
    return [NSBundle bundleForClass:[GTMOAuth2ViewControllerTouch class]];
}
@end
