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
    UIImage *backImage = [self isLeftToRightLanguage] ? [self leftChevronImage] : [self rightChevronImage];
    
    self.backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backImage
                                                              style:UIBarButtonItemStylePlain
                                                             target:self.webView
                                                             action:@selector(goBack)];
    
    UIImage *forwardImage = [self isLeftToRightLanguage] ? [self rightChevronImage] : [self leftChevronImage];
    
    self.forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:forwardImage
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self.webView
                                                                action:@selector(goForward)];
    
    self.backBarButtonItem.enabled = [self.webView canGoBack];
    self.forwardBarButtonItem.enabled = [self.webView canGoForward];
    
    self.navigationItem.rightBarButtonItems = @[self.forwardBarButtonItem, self.backBarButtonItem];
}

/* defaults to true if locale or language code cannot be determined */
-(bool)isLeftToRightLanguage {
    NSLocale *locale = [NSLocale currentLocale];
    if (!locale) {
        return true;
    }
    
    NSString *languageCode;
    
    if (@available(iOS 10, *)) {
        languageCode = [locale languageCode];
    } else {
        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        NSDictionary *languageDic = [NSLocale componentsFromLocaleIdentifier:language];
        languageCode = [languageDic objectForKey:@"kCFLocaleLanguageCodeKey"];
    }
    
    if (!languageCode) {
        return true;
    }
    
    if (![languageCode respondsToSelector:@selector(isEqualToString:)]) {
        return true;
    }
    
    return ![languageCode isEqualToString:@"ar"];
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
