// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import UIKit
import SwiftGodot
import RevenueCat
import RevenueCatUI

#initSwiftExtension(cdecl: "swift_entry_point", types: [GodotSubscription.self])

@Godot
class GodotSubscription: RefCounted {
    #signal("productsOutput", arguments: ["event": String.self, "data": String.self])
    #signal("purchaseOutput", arguments: ["event": String.self])
    #signal("entitlementOutput", arguments: ["event": String.self])
    #signal("presentPaywallOutput", arguments: ["event": String.self])

    
    @Callable
    func initialize(input: String) {
        Purchases.configure(withAPIKey: input)
    }
    
    @Callable
    func isEntitlementActive(input: String) {
        let signal = SignalWith1Argument<String>("entitlementOutput")
        self.emit(signal: signal, "entitlement_loading")
        
        var isEntitlementActive: Bool = false
        Purchases.shared.getCustomerInfo { customerInfo, error in
            if let error = error {
                self.emit(signal: signal, "entitlement_error")
                return
            }
            
            isEntitlementActive = customerInfo?.entitlements[input]?.isActive ?? false
            
            if (isEntitlementActive) {
                self.emit(signal: signal, "entitlement_active")
            } else {
                self.emit(signal: signal, "entitlement_inactive")
            }
        }
    }
    
    @Callable
    func listProducts() {
        let signal = SignalWith2Arguments<String, String>("productsOutput")
        var productList: [[String: String]] = []
        self.emit(signal: signal, "products_loading", "")
        
        Purchases.shared.getOfferings { offerings, error in
            if let error = error {
                self.emit(signal: signal, "products_failed", "")
                return
            }
            
            if let offerings = offerings {
                guard let currentOfferings = offerings.current else {
                    self.emit(signal: signal, "products_failed", "")
                    return
                }
                
                for package in currentOfferings.availablePackages {
                    let product = package.storeProduct
                    let priceInCents = String(NSDecimalNumber(decimal: product.price * Decimal(100)).intValue)
                    
                    let productInfo: [String: String] = [
                        "identifier": product.productIdentifier,
                        "price": priceInCents,
                        "localizedPrice": product.localizedPriceString,
                        "title": product.localizedTitle,
                        "description": product.localizedDescription
                    ]
                    productList.append(productInfo)
                    
                }
                
                let productListJson = try? JSONSerialization.data(withJSONObject: productList, options: [])
                let productListString = String(data: productListJson!, encoding: .utf8)
                self.emit(signal: signal, "products_success", productListString!)
            } else {
                self.emit(signal: signal, "products_failed", "")
                return
            }
        }
    }
    
    @Callable
    func purchase(input: String) {
        let signal = SignalWith1Argument<String>("purchaseOutput")
        
        self.emit(signal: signal, "purchase_loading")
        
        Purchases.shared.getOfferings { offerings, error in
            if let error = error {
                // Emit an error message via the signal
                self.emit(signal: signal, "purchase_failed")
                return
            }
            
            if let offerings = offerings {
                guard let currentOfferings = offerings.current else {
                    self.emit(signal: signal, "purchase_failed")
                    return
                }
                
                if let package = currentOfferings.availablePackages.first(where: { $0.storeProduct.productIdentifier == input }) {
                    Purchases.shared.purchase(package: package) { transaction, purchaserInfo, error, userCancelled in
                        if let error = error {
                            self.emit(signal: signal, "purchase_failed")
                            return
                        }
                        if userCancelled {
                            self.emit(signal: signal, "purchase_canceled")
                            return
                        }
                        self.emit(signal: signal, "purchase_success")
                        return
                    }
                    
                    
                } else {
                    self.emit(signal: signal, "purchase_failed")
                    return
                }
            } else {
                self.emit(signal: signal, "purchase_failed")
                return
            }
        }
    }
    
    @Callable
    func presentPaywall() {
        let signal = SignalWith1Argument<String>("presentPaywallOutput")
        
        self.emit(signal: signal, "paywall_loading")
        
        // Fetch offerings and present the paywall
        Purchases.shared.getOfferings { offerings, error in
            if let error = error {
                self.emit(signal: signal, "paywall_failed")
                return
            }
            
            guard let offerings = offerings,
                  let currentOffering = offerings.current else {
                self.emit(signal: signal, "paywall_failed")
                return
            }
            
            // Present PaywallViewController using RevenueCatUI
            DispatchQueue.main.async {
                if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                    let paywallViewController = PaywallViewController(offering: currentOffering)
                    
                    // Optionally configure the presentation style
                    paywallViewController.modalPresentationStyle = .formSheet
                    
                    // Present the paywall
                    rootViewController.present(paywallViewController, animated: true) {
                        self.emit(signal: signal, "paywall_presented")
                    }
                } else {
                    self.emit(signal: signal, "paywall_failed")
                }
            }
        }
    }
}
