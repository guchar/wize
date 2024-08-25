import SwiftUI
import GoogleGenerativeAI

struct SimpleLoadingBar: View {
    @Binding var progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 10)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: min(CGFloat(self.progress) * geometry.size.width, geometry.size.width), height: 10)
            }
            .cornerRadius(5)
        }
    }
}

enum ContentCategory: String, CaseIterable {
    case technology, science, history, literature, art, music, mathematics, business, nature, sports, other

    static func matchCategory(for content: String) -> ContentCategory {
        let lowercasedContent = content.lowercased()
        
        for category in ContentCategory.allCases {
            if lowercasedContent.contains(category.rawValue) {
                return category
            }
        }
        
        var bestMatch = ContentCategory.other
        var highestScore = 0.0
        
        for category in ContentCategory.allCases {
            let categoryScore = content.compareScore(with: category.rawValue)
            if categoryScore > highestScore {
                highestScore = categoryScore
                bestMatch = category
            }
        }
        
        return bestMatch
    }
}

extension String {
    func compareScore(with other: String) -> Double {
        let words = self.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let otherWords = other.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        let commonWords = Set(words).intersection(Set(otherWords))
        return Double(commonWords.count) / Double(max(words.count, otherWords.count))
    }
}

struct ContentView: View {
    @State private var topic: String = ""
    @State private var units: [Unit] = []
    @State private var currentUnitIndex: Int = 0
    @State private var currentCardIndex: Int = 0
    @State private var isLoading = false
    @State private var loadingProgress: Double = 0.0
    @State private var errorMessage: String?
    @State private var debugText: String = ""
    @State private var loadingMessage: String = "Initializing your learning journey..."
    
    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyCjTPZDl4OWfSFVuuNK4QCqjepfr4NnBmQ")
    
    let loadingMessages = [
        "Creating knowledge...",
        "Designing your future...",
        "Becoming your best self...",
        "Unlocking potential...",
        "Crafting brilliance...",
        "Igniting curiosity...",
        "Forging wisdom...",
        "Sculpting intellect...",
        "Brewing insights...",
        "Planting seeds of knowledge..."
    ]
    
    var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    Text("Microlearning")
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
                        VStack {
                            Text(loadingMessage)
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(.bottom, 5)
                            
                            ProgressView(value: loadingProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(height: 4)
                                .padding(.horizontal)
                        }
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else if !units.isEmpty {
                        UnitView(units: units, currentUnitIndex: $currentUnitIndex, currentCardIndex: $currentCardIndex)
                    }
                    
                    if !debugText.isEmpty {
                        Text(debugText)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .navigationBarHidden(true)
            }
        }
    
    func updateLoadingMessage() {
        loadingMessage = loadingMessages.randomElement() ?? "Loading..."
    }
    
    func generateLesson() {
        isLoading = true
        loadingProgress = 0.0
        errorMessage = nil
        debugText = ""
        units.removeAll()
        currentUnitIndex = 0
        currentCardIndex = 0
        updateLoadingMessage()
        
        let maxRetries = 3
        var currentRetry = 0
        
        func attemptGeneration() async {
            let prompt = """
            Create a structured microlearning curriculum for the topic: \(topic).
            Provide exactly 5 main units, each covering a unique aspect of the topic.
            For each unit, provide exactly 3 key points or concepts.
            Format your response as follows:

            UNIT: [Unit 1 Title]
            TITLE: [Title for point 1]
            CONTENT: [Explanation for point 1, keep it under 50 words]
            TITLE: [Title for point 2]
            CONTENT: [Explanation for point 2, keep it under 50 words]
            TITLE: [Title for point 3]
            CONTENT: [Explanation for point 3, keep it under 50 words]
            ---
            UNIT: [Unit 2 Title]
            ... (repeat the structure for all 5 units)

            Ensure each unit has a clear, distinct focus within the overall topic.
            Do not use any markdown formatting. Use plain text only.
            It is crucial that you provide exactly 5 units, no more and no less.
            """
            
            do {
                let stream = try await model.generateContentStream(prompt)
                var fullText = ""
                
                for try await chunk in stream {
                    if let text = chunk.text {
                        fullText += text
                        print("Received chunk: \(text)")  // Debugging line
                        await processStreamChunk(fullText)
                        loadingProgress = min(1.0, Double(currentRetry) / Double(maxRetries) + loadingProgress / Double(maxRetries))
                        updateLoadingMessage()
                    }
                }
                
                DispatchQueue.main.async {
                    if self.units.count != 5 {
                        self.debugText = "Generated \(self.units.count) units instead of 5"
                        if currentRetry < maxRetries {
                            currentRetry += 1
                            self.debugText += ". Retrying (\(currentRetry)/\(maxRetries))"
                            Task { await attemptGeneration() }
                        } else {
                            self.errorMessage = "Error: Unable to generate the correct number of units after \(maxRetries) attempts."
                            self.isLoading = false
                        }
                    } else {
                        self.debugText = "Successfully processed 5 units"
                        self.isLoading = false
                    }
                }
            } catch let error as GoogleGenerativeAI.GenerateContentError {
                DispatchQueue.main.async {
                    self.errorMessage = "GenerateContentError: \(error.localizedDescription)"
                    self.debugText = "Error details: \(error)"
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.debugText = "An unexpected error occurred. Please try again."
                    self.isLoading = false
                }
            }
        }
        
        Task {
            await attemptGeneration()
        }
    }
    
    func processStreamChunk(_ chunk: String) async {
        let newUnits = chunk.components(separatedBy: "---")
        var processedUnits: [Unit] = []
        
        for unitContent in newUnits {
            let lines = unitContent.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .newlines)
            var unitTitle = ""
            var cards: [Card] = []
            var currentTitle = ""
            var currentContent = ""
            
            for line in lines {
                if line.starts(with: "UNIT:") {
                    unitTitle = line.replacingOccurrences(of: "UNIT:", with: "").trimmingCharacters(in: .whitespaces)
                } else if line.starts(with: "TITLE:") {
                    if !currentTitle.isEmpty && !currentContent.isEmpty {
                        let category = ContentCategory.matchCategory(for: currentContent)
                        cards.append(Card(title: currentTitle, content: currentContent, category: category))
                        currentContent = ""
                    }
                    currentTitle = line.replacingOccurrences(of: "TITLE:", with: "").trimmingCharacters(in: .whitespaces)
                } else if line.starts(with: "CONTENT:") {
                    currentContent = line.replacingOccurrences(of: "CONTENT:", with: "").trimmingCharacters(in: .whitespaces)
                } else {
                    currentContent += " " + line.trimmingCharacters(in: .whitespaces)
                }
            }
            
            if !currentTitle.isEmpty && !currentContent.isEmpty {
                let category = ContentCategory.matchCategory(for: currentContent)
                cards.append(Card(title: currentTitle, content: currentContent, category: category))
            }
            
            if !unitTitle.isEmpty && !cards.isEmpty {
                processedUnits.append(Unit(title: unitTitle, cards: cards))
            }
        }
        
        DispatchQueue.main.async {
            self.units = processedUnits
            self.updateLoadingMessage()
        }
    }
}

struct UnitView: View {
    let units: [Unit]
    @Binding var currentUnitIndex: Int
    @Binding var currentCardIndex: Int
    
    var body: some View {
        VStack {
            Text("Unit \(currentUnitIndex + 1): \(units[currentUnitIndex].title)")
                .font(.title2)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            
            CardView(cards: units[currentUnitIndex].cards, currentIndex: $currentCardIndex)

            
            HStack {
                Button(action: previousCard) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                ForEach(0..<units[currentUnitIndex].cards.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentCardIndex ? Color.blue : Color.gray)
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                
                Button(action: nextCard) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            HStack {
                Button(action: previousUnit) {
                    Text("Previous Unit")
                        .foregroundColor(.blue)
                }
                .disabled(currentUnitIndex == 0)
                
                Spacer()
                
                Text("\(currentUnitIndex + 1) / \(units.count)")
                    .font(.caption)
                
                Spacer()
                
                Button(action: nextUnit) {
                    Text("Next Unit")
                        .foregroundColor(.blue)
                }
                .disabled(currentUnitIndex == units.count - 1)
            }
            .padding()
        }
    }
    
    func previousUnit() {
        if currentUnitIndex > 0 {
            withAnimation {
                currentUnitIndex -= 1
                currentCardIndex = 0
            }
        }
    }
    
    func nextUnit() {
        if currentUnitIndex < units.count - 1 {
            withAnimation {
                currentUnitIndex += 1
                currentCardIndex = 0
            }
        }
    }
    
    func previousCard() {
        if currentCardIndex > 0 {
            withAnimation {
                currentCardIndex -= 1
            }
        } else if currentUnitIndex > 0 {
            withAnimation {
                currentUnitIndex -= 1
                currentCardIndex = units[currentUnitIndex].cards.count - 1
            }
        }
    }
    
    func nextCard() {
        if currentCardIndex < units[currentUnitIndex].cards.count - 1 {
            withAnimation {
                currentCardIndex += 1
            }
        } else if currentUnitIndex < units.count - 1 {
            withAnimation {
                currentUnitIndex += 1
                currentCardIndex = 0
            }
        }
    }
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
        .padding(.vertical, 10)  // Adjusted vertical padding to match unit heading
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)  // Added horizontal padding to match unit heading
    }
}

struct Card: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let category: ContentCategory
}

struct Unit: Identifiable {
    let id = UUID()
    let title: String
    let cards: [Card]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
