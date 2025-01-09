import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image("mofa_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                    .padding(.top, 40)
                
                VStack(spacing: 16) {
                    Text("Ministry of Foreign Affairs")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Kingdom of Saudi Arabia")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    infoSection(
                        title: "About MOFA",
                        content: "The Ministry of Foreign Affairs (MOFA) is responsible for handling the Kingdom's foreign relations and diplomatic missions worldwide."
                    )
                    
                    infoSection(
                        title: "Our Services",
                        content: """
                        • Visa Services
                        • Consular Services
                        • Diplomatic Relations
                        • International Cooperation
                        • Citizen Services Abroad
                        """
                    )
                    
                    infoSection(
                        title: "Contact Us",
                        content: """
                        Website: www.mofa.gov.sa
                        Email: info@mofa.gov.sa
                        """
                    )
                    
                    infoSection(
                        title: "App Version",
                        content: "1.0.0"
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func infoSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
