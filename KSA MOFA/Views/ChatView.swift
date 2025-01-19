import SwiftUI
import PhotosUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var showImageSource = false
    
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
                    Button(action: {
                        showImageSource = true
                    }) {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    
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
        .confirmationDialog("Choose Image Source", isPresented: $showImageSource) {
            Button("Camera") {
                showCamera = true
            }
            Button("Photo Library") {
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                viewModel.sendImage(image)
                selectedImage = nil
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading) {
                switch message.content {
                case .text(let text):
                    if message.isUser {
                        Text(text)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    } else {
                        Text(LocalizedStringKey(text))
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(15)
                    }
                    
                case .image(let image):
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)
                        .cornerRadius(15)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
