import SwiftUI
import LocalAuthentication

struct SplashView: View {
    @State private var isAuthenticated = false
    @State private var authError: String? = nil
    @State private var showError = false
    
    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView()
            } else {
                VStack {
                    Spacer()
                    
                    Image("mofa_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .padding()
                    
                    Text("KSA MOFA")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Ministry of Foreign Affairs")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: authenticate) {
                        HStack {
                            Image(systemName: "faceid")
                                .font(.title)
                            Text("Authenticate with Face ID")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 50)
                }
                .alert("Authentication Error", isPresented: $showError, presenting: authError) { _ in
                    Button("OK", role: .cancel) { }
                } message: { error in
                    Text(error)
                }
            }
        }
        .onAppear {
            authenticate()
        }
    }
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: "Authenticate to access KSA MOFA") { success, error in
                DispatchQueue.main.async {
                    if success {
                        isAuthenticated = true
                    } else {
                        authError = error?.localizedDescription ?? "Authentication failed"
                        showError = true
                    }
                }
            }
        } else {
            authError = error?.localizedDescription ?? "Face ID not available"
            showError = true
        }
    }
}
