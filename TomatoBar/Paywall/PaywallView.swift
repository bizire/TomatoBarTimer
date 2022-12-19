
import SwiftUI
import RevenueCat

/*
 An example paywall that uses the current offering.
 */
struct PaywallView: View {
    
    @ObservedObject var userModel = UserViewModel.shared
    //@Binding var isPresented: Bool
    
    /// - State for displaying an overlay view
    @State
    private(set) var isPurchasing: Bool = false
    
    @State private var error: NSError?
    @State private var displayError: Bool = false
    
    func someStuff() {
        print("Some Stufd")
        print("Some Mood")
        print("Gary Stufd")
    }

    var body: some View {
            VStack {
                Image("logo")
                
                Text("• Unlock All Features \n• Remove Ad Banners\n• Launch At Login\n• Eneable Hot Keys")
                    .font(.title)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .bold()

                let packages = UserViewModel.shared.offerings?.current?.availablePackages ?? []
                let package = packages[0]
                PackageCellView(package: package) { (package) in
                    /// - Set 'isPurchasing' state to `true`
                    isPurchasing = true
                    /// - Purchase a package
                    do {
                        let result = try await Purchases.shared.purchase(package: package)

                        /// - Set 'isPurchasing' state to `false`
                        self.isPurchasing = false

                        if !result.userCancelled {
                            //self.isPresented = false
                        }
                    } catch {
                        self.isPurchasing = false
                        self.error = error as NSError
                        self.displayError = true
                    }
                }
            }
        .colorScheme(.dark)
//        .alert(
//            isPresented: self.$displayError,
//            error: self.error,
//            actions: { _ in
//                Button(role: .cancel,
//                       action: { self.displayError = false },
//                       label: { Text("OK") })
//            },
//            message: { Text($0.recoverySuggestion ?? "Please try again") }
//        )
    }
}

/* The cell view for each package */
struct PackageCellView: View {

    let package: Package
    let onSelection: (Package) async -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                Task {
                    await self.onSelection(self.package)
                }
            } label: {
                self.buttonLabel
            }
            .buttonStyle(.plain)
            .background(Color.blue)
            .cornerRadius(20)
            .focusable(false)
            .padding()
            Spacer()
        }
    }

    private var buttonLabel: some View {
        HStack {
            VStack {
                HStack {
                    Text("UPGRADE for "+package.localizedPriceString)
                        .font(.title3)
                        .bold()
                        .padding(.all, 15)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white, lineWidth: 2))
                }
            }
            
        }
        .contentShape(Rectangle()) // Make the whole cell tappable
    }
}

extension NSError: LocalizedError {

    public var errorDescription: String? {
        return self.localizedDescription
    }

}
