//
//  ViewController.m
//  WebKitDemo
//
//  Created by LS on 12/30/15.
//  Copyright © 2015 LS. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController () <UITextFieldDelegate, WKNavigationDelegate,WKScriptMessageHandler>

@property (weak, nonatomic) IBOutlet UIView *barBackGroundView;
@property (nonatomic, strong) WKWebView *webView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet UITextField *inputURLField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stopReloadButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backwardButton;

@end

static NSString * const kMessageHandler = @"didFetchAuthors";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.forwardButton.enabled = NO;
    self.backwardButton.enabled = NO;
    
//    self.inputURLField.text = @"http://www.raywenderlich.com/u/funkyboy";  // default page
    self.inputURLField.delegate = self;
    self.barBackGroundView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 30.0);
    [self.view addSubview:self.webView];
    [self.view insertSubview:self.webView belowSubview:self.progressView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-44.0]];
    
    
    // load the default page
    [self loadReuqest];
    
    // observer the webview loading and estimatedprogress property
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    self.barBackGroundView.frame = CGRectMake(0.0, 0.0, size.width, 30.0);
}

#pragma mark - Private Method

- (void)loadReuqest
{
    self.progressView.hidden = NO;
    NSURL *url = [NSURL URLWithString:self.inputURLField.text];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if([keyPath isEqualToString:@"loading"])
    {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = self.webView.loading;
        if(self.webView.loading == false)
        {
            self.inputURLField.text = [self.webView.URL absoluteString];
        }
    }
    else if([keyPath isEqualToString:@"estimatedProgress"])
    {
        self.progressView.hidden = self.webView.estimatedProgress == 1;
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
    }
    
    self.forwardButton.enabled = self.webView.canGoForward;
    self.backwardButton.enabled = self.webView.canGoBack;
    [self.stopReloadButton setTitle:self.webView.loading?@"停止":@"刷新"];
}

#pragma mark - UITextField

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(handleCancel:)];
    self.navigationItem.rightBarButtonItem = cancelItem;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self handleCancel:nil];
    [self loadReuqest];
    
    return NO;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    // callback message from js
    NSLog(@"%@",message);
    if([message.name isEqualToString:kMessageHandler])
    {
        NSLog(@"%@",message.body);
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    NSLog(@"begin");
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self.progressView setProgress:0.0 animated:NO];
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"%@",webView.URL);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"%@",error.localizedDescription);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if(navigationAction.navigationType == WKNavigationTypeLinkActivated && ![navigationAction.request.URL.host.lowercaseString hasPrefix:@"www.raywenderlich.com"])
    {
        [[UIApplication sharedApplication] openURL:self.webView.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - Handling Event

- (IBAction)handleForward:(id)sender
{
    [self.webView goForward];
}

- (IBAction)handleBack:(id)sender
{
    [self.webView goBack];
}

- (IBAction)handleRefresh:(id)sender
{
    if(self.webView.loading)
    {
        [self.webView stopLoading];
    }
    else
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:self.webView.URL];
        [self.webView loadRequest:request];
    }
}

- (void)handleCancel:(UIBarButtonItem *)sender
{
    [self.inputURLField resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
    self.barBackGroundView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 30.0);
}

#pragma mark - Other

- (WKWebView *)webViewBaiscUse
{
    self.inputURLField.text = @"https://www.baidu.com";
    return [[WKWebView alloc] initWithFrame:CGRectZero];
}

- (WKWebView *)webViewWithUserScript
{
    self.inputURLField.text = @"http://www.raywenderlich.com/u/funkyboy";
    
    WKWebViewConfiguration *conf = [[WKWebViewConfiguration alloc] init];
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"hideBio" ofType:@"js"];
    NSString *hideBioJS = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
    
    // inject user script
    WKUserScript *hideBioUserScript = [[WKUserScript alloc] initWithSource:hideBioJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [conf.userContentController addUserScript:hideBioUserScript];
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:conf];
    
    return webView;
}

- (WKWebView *)webViewWithScriptMessage
{
    self.inputURLField.text = @"http://www.raywenderlich.com/about";
    
    WKWebViewConfiguration *conf = [[WKWebViewConfiguration alloc] init];
    NSString *scriptURL = [[NSBundle mainBundle] pathForResource:@"fetchAuthors" ofType:@"js"];
    NSString *jsScript = [NSString stringWithContentsOfFile:scriptURL encoding:NSUTF8StringEncoding error:nil];
    
    // inject user script
    WKUserScript *fetchAuthorsScript = [[WKUserScript alloc] initWithSource:jsScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [conf.userContentController addUserScript:fetchAuthorsScript];
   
    // inject script message
    [conf.userContentController addScriptMessageHandler:self name:kMessageHandler];
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:conf];
    
    return webView;
}

#pragma mark - Getter

- (WKWebView *)webView
{
    if(!_webView)
    {
        _webView = [self webViewBaiscUse];
//        _webView = [self webViewWithUserScript];
//        _webView = [self webViewWithScriptMessage];
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
        _webView.navigationDelegate = self;
    }
    
    return _webView;
}

- (void)dealloc
{
    [self.webView removeObserver:self forKeyPath:@"loading"];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

@end
