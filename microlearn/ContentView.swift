import SwiftUI
import GoogleGenerativeAI

struct RainbowLoadingBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .cornerRadius(5)
                
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: CGFloat(self.progress) * geometry.size.width)
                    .cornerRadius(5)
            }
        }
    }
}

struct RainbowProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        RainbowLoadingBar(progress: configuration.fractionCompleted ?? 0)
            .frame(height: 10)
            .padding()
    }
}

struct ContentView: View {
    @State private var topic: String = ""
    @State private var cards: [Card] = []
    @State private var currentCardIndex: Int = 0
    @State private var isLoading = false
    @State private var loadingProgress: Double = 0.0
    @State private var errorMessage: String?
    
    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyCjTPZDl4OWfSFVuuNK4QCqjepfr4NnBmQ")
    
    var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Gemini Microlearning")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        TextField("Enter a topic...", text: $topic)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: generateLesson) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView(value: loadingProgress)
                            .progressViewStyle(RainbowProgressViewStyle())
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else if !cards.isEmpty {
                        CardView(cards: cards, currentIndex: $currentCardIndex)
                    }
                    
                    Spacer()
                }
                .navigationBarHidden(true)
            }
        }
        
        func generateLesson() {
            isLoading = true
            loadingProgress = 0.0
            errorMessage = nil
            cards.removeAll()
            currentCardIndex = 0
            
            let prompt = """
            Create a microlearning lesson for the topic: \(topic).
            Provide 3 key points or concepts, each with a brief title and a detailed explanation.
            Format your response as follows:
            TITLE: [Title for point 1]
            CONTENT: [Explanation for point 1, keep it under 100 words]
            ---
            TITLE: [Title for point 2]
            CONTENT: [Explanation for point 2, keep it under 100 words]
            ---
            TITLE: [Title for point 3]
            CONTENT: [Explanation for point 3, keep it under 100 words]

            Do not use any markdown formatting. Use plain text only.
            """
            
            Task {
                do {
                    let stream = try await model.generateContentStream(prompt)
                    var fullText = ""
                    
                    for try await chunk in stream {
                        if let text = chunk.text {
                            fullText += text
                            processStreamChunk(fullText)
                            loadingProgress = min(1.0, loadingProgress + 0.05)
                        }
                    }
                    
                    isLoading = false
                } catch {
                    errorMessage = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
        
        func processStreamChunk(_ chunk: String) {
            let newCards = chunk.components(separatedBy: "---")
            cards = newCards.compactMap { cardContent in
                let lines = cardContent.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
                var title = ""
                var content = ""
                var isContent = false
                
                for line in lines {
                    if line.starts(with: "TITLE:") {
                        title = line.replacingOccurrences(of: "TITLE:", with: "").trimmingCharacters(in: .whitespaces)
                    } else if line.starts(with: "CONTENT:") {
                        isContent = true
                        content = line.replacingOccurrences(of: "CONTENT:", with: "").trimmingCharacters(in: .whitespaces)
                    } else if isContent {
                        content += " " + line.trimmingCharacters(in: .whitespaces)
                    }
                }
                
                guard !title.isEmpty && !content.isEmpty else { return nil }
                return Card(title: title, content: content)
            }
        }
}

struct Card: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}

struct CardView: View {
    let cards: [Card]
    @Binding var currentIndex: Int
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    ForEach(cards.indices, id: \.self) { index in
                        CardContent(card: cards[index])
                            .opacity(index == currentIndex ? 1 : 0)
                            .scaleEffect(index == currentIndex ? 1 : 0.5)
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < -50 && currentIndex < cards.count - 1 {
                                withAnimation {
                                    currentIndex += 1
                                }
                            } else if value.translation.width > 50 && currentIndex > 0 {
                                withAnimation {
                                    currentIndex -= 1
                                }
                            }
                        }
                )
                
                HStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index <= currentIndex ? Color.blue : Color.gray)
                            .frame(width: 10, height: 10)
                    }
                }
                .padding()
            }
        }
    }
}

struct CardContent: View {
    let card: Card
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.title)
                .font(.headline)
                .padding(.bottom, 5)
            
            ScrollView {
                Text(card.content)
                    .font(.body)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
