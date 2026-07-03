

import Foundation
import RevenueCat
import SwiftUI

/* Static shared model for UserView */
class UserViewModel: ObservableObject {
    static let shared = UserViewModel()
    
    /* The latest CustomerInfo from RevenueCat. Updated by PurchasesDelegate whenever the Purchases SDK updates the cache */
    @Published var customerInfo: CustomerInfo? {
        didSet {
            subscriptionActive = hasPremiumAccess
            let activeIDs = activeEntitlementIDs.joined(separator: ", ")
            print("RevenueCat active entitlements: \(activeIDs.isEmpty ? "none" : activeIDs)")
        }
    }
    
    /* The latest offerings - fetched from MagicWeatherApp.swift on app launch */
    @Published var offerings: Offerings? = nil
    
    /* Set from the didSet method of customerInfo above, based on the entitlement set in Constants.swift */
    @Published var subscriptionActive: Bool = false

    var activeEntitlementIDs: [String] {
        customerInfo?.entitlements.active.keys.sorted() ?? []
    }

    var hasPremiumAccess: Bool {
        guard let entitlements = customerInfo?.entitlements else {
            return false
        }

        if entitlements[Constants.entitlementID]?.isActive == true {
            return true
        }

        // This app has a single paid tier; accepting any active RevenueCat entitlement
        // keeps existing buyers unlocked if the dashboard identifier differs from this build.
        return !entitlements.active.isEmpty
    }

    @MainActor
    func refreshRevenueCatState() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            print("ZDNPLX Error fetching customer info: \(error)")
        }

        do {
            // Fetch offerings before rendering the paywall so an empty Product Catalog
            // degrades to a loading state instead of crashing on a missing package.
            offerings = try await Purchases.shared.offerings()
        } catch {
            print("ZDNPLX Error fetching offerings: \(error)")
        }
    }
}
