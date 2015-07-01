    //
//  FNAPI.swift
//  Finicky
//
//  Created by John Sterling on 12/06/15.
//  Copyright (c) 2015 John sterling. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol FinickyAPIExports : JSExport {
    static func setDefaultBrowser(browser: String?) -> Void
    static func log(message: String?) -> Void
    static func onUrl(handler: JSValue) -> Void
}

@objc class FinickyAPI : NSObject, FinickyAPIExports {
    
    private static var urlHandlers = Array<JSValue>()
    
    class func setDefaultBrowser(browser: String?) -> Void {
        AppDelegate.defaultBrowser = browser
    }
    
    static func log(message: String?) -> Void {
        if message != nil {
            NSLog(message!)
        }
    }
    
    class func onUrl(handler: JSValue) -> Void {
        urlHandlers.append(handler)
    }
    
    class func reset() -> Void {
        urlHandlers.removeAll(keepCapacity: true)
    }
    
    /**
        Get strategy from registered handlers
    
        @param originalUrl The original url that triggered finicky to start
    
        @param sourceBundleIdentifier Bundle identifier of the application that triggered the url to open
    
        @return A dictionary keyed with "url" and "bundleIdentifier" with 
            the new url and bundle identifier to spawn
    */

    class func callUrlHandlers(originalUrl: String, sourceBundleIdentifier: String, flags : Dictionary<String, Bool>) -> Dictionary<String, String> {
        var strategy : Dictionary<String, String> = [
            "url": originalUrl,
            "bundleIdentifier": ""
        ]
        
        var options : Dictionary<String, AnyObject> = [
            "sourceBundleIdentifier": sourceBundleIdentifier,
            "flags": flags
        ]
        
        for handler in urlHandlers {
            let url = strategy["url"]!
            let val = handler.callWithArguments([url, options])

            if !val.isUndefined() {
                let handlerStrategy = val.toDictionary()
                if handlerStrategy != nil {
                    if handlerStrategy["url"] != nil {
                        strategy["url"] = (handlerStrategy["url"] as! String)
                    }
            
                    if handlerStrategy["bundleIdentifier"] != nil {
                        strategy["bundleIdentifier"] = (handlerStrategy["bundleIdentifier"] as! String)
                    }
                    
                    if handlerStrategy["last"] != nil {
                        break
                    }
                }
            }
        }        
        return strategy
    }
    
}