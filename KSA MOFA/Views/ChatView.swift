import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Logo
            VStack {
                Image("mofa_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                    .frame(height: 60)
                    .padding(.vertical, 10)
                    .accessibilityLabel("KSA MOFA Logo")
                
                if viewModel.isProcessingDocuments {
                    ProgressView("Initializing knowledge base...")
                        .padding(.bottom)
                }
            }
            .background(Color(UIColor.systemBackground))
            .shadow(radius: 1)
            
            // Chat Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.messages.isEmpty {
                            VStack(spacing: 20) {
                                Text("Welcome to KSA MOFA Assistant")
                                    .font(.title2)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 40)
                                
                                Text("Ask me about:")
                                    .font(.headline)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("• Visa services and requirements")
                                    Text("• Diplomatic missions and consulates")
                                    Text("• International relations")
                                    Text("• Consular services")
                                    Text("• Services for foreign residents")
                                }
                                .font(.subheadline)
                            }
                            .foregroundColor(.gray)
                            .padding()
                        }
                        
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Area
            VStack(spacing: 0) {
                Divider()
                
                HStack {
                    TextField("Ask me about KSA MOFA services...", text: $viewModel.inputMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isLoading)
                    
                    Button(action: {
                        viewModel.sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .shadow(radius: 1)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("KSA MOFA Assistant")
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(15)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}
