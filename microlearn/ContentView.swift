import SwiftUI
import GoogleGenerativeAI

struct GradientLoadingBar: View {
    @Binding var progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 10)
                
                LinearGradient(gradient: Gradient(colors: [Color.red, Color.purple]),
                               startPoint: .leading,
                               endPoint: .trailing)
                    .frame(width: min(CGFloat(self.progress) * geometry.size.width, geometry.size.width), height: 10)
                    .animation(.linear, value: progress)
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
    @State private var showSearchBar = true
    
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
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.red, Color.purple]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    Text("WIZE")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                    
                    if showSearchBar {
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 24))
                                    .padding(.leading, 16)
                                
                                TextField("What do you want to learn?", text: $topic)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .accentColor(.yellow)
                                    .padding(.vertical, 12)
                                
                                if !topic.isEmpty {
                                    Button(action: { topic = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding(.trailing, 16)
                                }
                            }
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            
                            Button(action: generateLesson) {
                                Text("Ignite Learning")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 40)
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                                       startPoint: .leading,
                                                       endPoint: .trailing)
                                    )
                                    .cornerRadius(25)
                                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
                            }
                            .disabled(isLoading || topic.isEmpty)
                        }
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if isLoading {
                        VStack {
                            Text(loadingMessage)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                            
                            GradientLoadingBar(progress: $loadingProgress)
                                .frame(height: 4)
                                .padding(.horizontal)
                        }
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else if !units.isEmpty {
                        UnitView(units: units, currentUnitIndex: $currentUnitIndex, currentCardIndex: $currentCardIndex)
                        
                        Button(action: resetToMainPage) {
                            Text("Learn Something New")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 30)
                                .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.purple]),
                                                           startPoint: .leading,
                                                           endPoint: .trailing))
                                .cornerRadius(20)
                        }
                        .padding(.top, 20)
                    }
                    
                    if !debugText.isEmpty {
                        Text(debugText)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .navigationBarHidden(true)
            }
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
        withAnimation {
            showSearchBar = false
        }
        
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
                var totalChunks = 0
                
                for try await chunk in stream {
                    if let text = chunk.text {
                        fullText += text
                        totalChunks += 1
                        print("Received chunk: \(text)")  // Debugging line
                        await processStreamChunk(fullText)
                        
                        // Update loading progress based on the number of chunks received
                        let estimatedTotalChunks = 50.0 // Adjust this value based on average response length
                        loadingProgress = min(0.9, Double(totalChunks) / estimatedTotalChunks)
                        
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
                            withAnimation {
                                self.showSearchBar = true
                            }
                        }
                    } else {
                        self.debugText = "Successfully processed 5 units"
                        self.loadingProgress = 1.0 // Set to 100% when complete
                        self.isLoading = false
                    }
                }
            } catch let error as GoogleGenerativeAI.GenerateContentError {
                DispatchQueue.main.async {
                    self.errorMessage = "GenerateContentError: \(error.localizedDescription)"
                    self.debugText = "Error details: \(error)"
                    self.isLoading = false
                    withAnimation {
                        self.showSearchBar = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.debugText = "An unexpected error occurred. Please try again."
                    self.isLoading = false
                    withAnimation {
                        self.showSearchBar = true
                    }
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
    
    func resetToMainPage() {
        withAnimation {
            showSearchBar = true
            units.removeAll()
            topic = ""
            errorMessage = nil
            debugText = ""
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
                .background(LinearGradient(gradient: Gradient(colors: [Color.red.opacity(0.1), Color.purple.opacity(0.1)]),
                                           startPoint: .leading,
                                           endPoint: .trailing))
                .cornerRadius(10)
                .padding(.horizontal)
            
            CardView(cards: units[currentUnitIndex].cards, currentIndex: $currentCardIndex)

            HStack {
                Button(action: previousCard) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                ForEach(0..<units[currentUnitIndex].cards.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentCardIndex ? Color.white : Color.gray)
                                        .frame(width: 8, height: 8)
                                }
                                
                                Spacer()
                                
                                Button(action: nextCard) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            
                            HStack {
                                Button(action: previousUnit) {
                                    Text("Previous Unit")
                                        .foregroundColor(.white)
                                }
                                .disabled(currentUnitIndex == 0)
                                
                                Spacer()
                                
                                Text("\(currentUnitIndex + 1) / \(units.count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: nextUnit) {
                                    Text("Next Unit")
                                        .foregroundColor(.white)
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
                                .foregroundColor(.purple)
                                .padding(.bottom, 5)
                            
                            ScrollView {
                                Text(card.content)
                                    .font(.body)
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
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
