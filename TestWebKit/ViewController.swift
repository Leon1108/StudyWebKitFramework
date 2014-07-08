//
//  ViewController.swift
//  TestWebKit
//
//  Created by Leon on 14-6-26.
//  Copyright (c) 2014年 Leon. All rights reserved.
//

import UIKit
import WebKit

enum HistoryType {
    case Back, Forward
}

class ViewController:UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler,UIPickerViewDataSource, UIPickerViewDelegate {

    var webView : WKWebView?
    var timer : NSTimer?
    var historyType : HistoryType = .Back
    @IBOutlet var dimmingView: UIView
    @IBOutlet var loadingProgress: UIActivityIndicatorView
    @IBOutlet var label: UILabel
    @IBOutlet var goBackBtn: UIButton
    @IBOutlet var goForwardBtn: UIButton
    @IBOutlet var history: UIPickerView
    @IBOutlet var loadProgressView: UIProgressView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // init web view
        self.initWebView()
        self.view!.addSubview(self.webView)
        
        // start to load web view
        var req = NSURLRequest(URL:self.getUrl(URLType.Local))
        self.webView!.loadRequest(req)
        
        startProgressMonitor()
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
    
    func initWebView(){
        let config = createConfiguration()
        self.webView = WKWebView(frame:CGRectMake(0, 84, 320, 320),
            configuration:config)
        self.webView!.allowsBackForwardNavigationGestures = true
        self.webView!.navigationDelegate = self
        self.webView!.UIDelegate = self
    }
    
    enum URLType {
        case Local, Remote
    }
    
    func getUrl(type:URLType) -> NSURL{
        var url : NSURL
        switch(type){
            case .Remote:
                url = NSURL(string:"http://www.sina.com.cn")
            case .Local:
                url = NSBundle.mainBundle().URLForResource("web", withExtension: "html", subdirectory: nil)
            
        }
        return url;
    }

    /********* Detecting the loading progress ********/
    func startProgressMonitor(){
        timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector:Selector("progress"), userInfo:nil, repeats:true)
    }
    
    func progress(){
        NSLog("Progress: %f", self.webView!.estimatedProgress)
        var progress = self.webView!.estimatedProgress
        self.loadProgressView!.setProgress(CFloat(progress), animated:true)
        
        if (self.webView!.estimatedProgress == 1.0){
            self.timer!.invalidate()
            self.loadProgressView!.setProgress(0, animated: false)
            NSLog("Progress: Finished!")
        }
    }
    
    /********* Build WKWebViewConfiguration ********/
    func createConfiguration() -> WKWebViewConfiguration {
        var config = WKWebViewConfiguration()
        
//        config.processPool ??
        config.preferences = self.createPreferences()
        config.userContentController = self.createUserContentController()
        
        return config
    }
    
    func createPreferences() -> WKPreferences {
        var preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true;
        
        return preferences
    }
    
    func createUserContentController() -> WKUserContentController {
        var contentController = WKUserContentController()
        contentController.addScriptMessageHandler(self, name:"defaultHandler")
        contentController.addUserScript(self.createUserScript())
        return contentController
    }
    
    func createUserScript() -> WKUserScript! {
//        var source = "changeBackground(\"#0000FF\")"
        var source = "function changeBackgroundColor(newColor){self.document.body.style.background = newColor;}"
        let userScript = WKUserScript(source:source, injectionTime:WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly:true)
        return userScript
    }
    
    func callJavascriptFunction(js: String){
        let userScript = WKUserScript(source:js,
                               injectionTime:WKUserScriptInjectionTime.AtDocumentEnd,
                            forMainFrameOnly:true)
        self.webView!.configuration.userContentController.addUserScript(userScript)
    }
    
    @IBAction func onGoBack(sender: UIButton) {
        if self.webView!.canGoBack {
            self.webView!.goBack()
        }
    }

    @IBAction func onGoBackLongPress(sender: UILongPressGestureRecognizer) {
        presentHistory(HistoryType.Back)
    }
    
    @IBAction func onGoForwardLongPress(sender: UILongPressGestureRecognizer) {
        presentHistory(HistoryType.Forward)
    }
    
    @IBAction func onDismissHistory(sender: UITapGestureRecognizer) {
        closeHistory()
    }
    
    func presentHistory(type: HistoryType){
        self.historyType = type
        self.history!.reloadComponent(0)
        self.view.addSubview(self.dimmingView)
        self.view.addSubview(self.history)
    }
    
    func closeHistory(){
        self.history.removeFromSuperview()
        self.dimmingView.removeFromSuperview()
    }
    
    @IBAction func onForward(sender: UIButton) {
        if self.webView!.canGoForward {
            self.webView!.goForward()
        }
    }
    
    @IBAction func onRefresh(sender: UIButton) {
        self.webView!.reload()
    }
    
    @IBAction func onJsCalled(sender: UIButton) {
        self.callJavascriptFunction("changeBackgroundColor(\"#0055FF\");")
        self.webView!.reload()
    }
    
    func checkCanGoBackOrFroward(){
        self.goBackBtn!.enabled = self.webView!.canGoBack ? true : false;
        self.goForwardBtn!.enabled = self.webView!.canGoForward ? true : false;
    }
    
    /********* WKScriptMessageHandler Delegate ********/
    func userContentController(userContentController: WKUserContentController!, didReceiveScriptMessage message: WKScriptMessage!){
        if message.body is NSNumber {
            NSLog("PostNSNumber: %@", message.body as NSNumber)
        }
        else if message.body is NSArray {
            NSLog("PostNSArray: %@", message.body as NSArray)
        }
        else if message.body is NSDictionary {
            NSLog("PostNSDictionary: %@", message.body as NSDictionary)
        }
        else if message.body is NSDate {
            NSLog("PostNSDate: %@", message.body as NSDate)
        }
        else if message.body is NSString {
            NSLog("PostNSString: %@", message.body as NSString)
        }
        else if message.body is NSNull {
            NSLog("PostNSNull: %@", message.body as NSNull)
        }
        else {
            NSLog("What are you!!")
        }
        
    }
    
    /********* WK UI Delegate ********/
    func webView(webView: WKWebView!,
        runJavaScriptAlertPanelWithMessage msg: String!,
        initiatedByFrame frame: WKFrameInfo!,
        completionHandler: (() -> Void)!)
    {
        NSLog("runJavaScriptAlertPanelWithMessage. Message:%@; Frame:%@", msg, frame)
        
        var alertView:UIAlertView = UIAlertView(title:"Alert From Web", message:msg, delegate:nil, cancelButtonTitle:"Cancel")
        alertView.show()
        completionHandler()
    }
    
    func webView(webView: WKWebView!,
        runJavaScriptConfirmPanelWithMessage message: String!,
        initiatedByFrame frame: WKFrameInfo!,
        completionHandler: ((Bool) -> Void)!)
    {
        NSLog("runJavaScriptConfirmPanelWithMessage. Message:%@", message)
        completionHandler(true)
    }
    
    func webView(webView: WKWebView!,
        runJavaScriptTextInputPanelWithPrompt prompt: String!,
        defaultText: String!,
        initiatedByFrame frame: WKFrameInfo!,
        completionHandler: ((String!) -> Void)!){
        NSLog("runJavaScriptTextInputPanelWithPrompt. Prompt:%@; defaultText:%@", prompt, defaultText)
        completionHandler("New Value")
    }
    
    /********* Tracking Load Progress ********/
    func webView(webView: WKWebView!, didCommitNavigation navigation: WKNavigation!){
        if nil != navigation{
            NSLog("didCommitNavigation. Invoked when content starts arriving for the main frame.")
            printNavigation(navigation)
        } else {
            NSLog("didCommitNavigation. Navigation is nil.")
        }
    }
    
    func webView(webView: WKWebView!, didFailNavigation navigation: WKNavigation!,
        withError error: NSError!){
        NSLog("didFailNavigation %@", error)
        printNavigation(navigation)
    }
    
    func webView(webView: WKWebView!, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: NSError!){
        NSLog("didFailProvisionalNavigation %@", error)
        printNavigation(navigation)
    }
    
    func webView(webView: WKWebView!, didFinishNavigation navigation: WKNavigation!){
        NSLog("didFinishNavigation. Invoked when a main frame load completes. title: %@", self.webView!.title)
//        self.lable.text = self.webView!.title
        self.label!.text = self.webView!.title
        printNavigation(navigation)
        checkCanGoBackOrFroward()
        loadingProgress!.stopAnimating()
    }
    
    func webView(webView: WKWebView!,
        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!){
        NSLog("didReceiveServerRedirectForProvisionalNavigation. Invoked when a server redirect is received for the main frame. Redirect to : %@ ", self.webView!.URL)
        printNavigation(navigation)
    }
    
    func webView(webView: WKWebView!, didStartProvisionalNavigation navigation: WKNavigation!){
        NSLog("didStartProvisionalNavigation. Invoked when a main frame page load starts.")
        printNavigation(navigation)
    }

    /******** Deciding Load Policy *******/
    func webView(webView: WKWebView!,
        decidePolicyForNavigationAction navigationAction: WKNavigationAction!,
        decisionHandler: ((WKNavigationActionPolicy) -> Void)!)
    {
        NSLog("[Deciding Load Policy] navigationAction; %@", navigationAction)
        decisionHandler(WKNavigationActionPolicy.Allow)
        loadingProgress!.startAnimating()
        checkCanGoBackOrFroward()
    }
    
    func webView(webView: WKWebView!,
        decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse!,
        decisionHandler: ((WKNavigationResponsePolicy) -> Void)!)
    {
        NSLog("[Deciding Load Policy] WKNavigationResponse; %@", navigationResponse)
        decisionHandler(WKNavigationResponsePolicy.Allow)
        checkCanGoBackOrFroward()
    }
    
    func printNavigation(navigation: WKNavigation!){
        if nil != navigation {
            var req = navigation.request
            var resp = navigation.response
            var err = navigation.error
            
            NSLog("Navigation -> req: %@; resp: %@; error: %@",
                nil != req ? req : "",
                nil != resp ? resp : "(nil)",
                nil != err ? err : "(nil)"
            )
        }
    }
    
    /********* Picker View DataSource ********/
    func numberOfComponentsInPickerView(pickerView: UIPickerView!) -> Int
    {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView!, numberOfRowsInComponent component: Int) -> Int
    {
        return getCurrentBackForwardListForType().count
    }
    
    func pickerView(pickerView: UIPickerView!, titleForRow row: Int, forComponent component: Int) -> String!
    {
        return "Title Hahaha"
    }
    
    func pickerView(pickerView: UIPickerView!, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString!
    {
        var backList = getCurrentBackForwardListForType()
        var item = backList[row] as WKBackForwardListItem
        return NSAttributedString(string: item.title)
    }
    
    func pickerView(pickerView: UIPickerView!, didSelectRow row: Int, inComponent component: Int)
    {
    }
    
    func getCurrentBackForwardListForType() -> [AnyObject]{
        var backList : [AnyObject]
        switch(self.historyType){
        case .Back:
            backList = self.webView!.backForwardList.backList
        case .Forward:
            backList = self.webView!.backForwardList.forwardList
        }
        return backList
    }

}
