import SwiftUI
import GoogleGenerativeAI
import Foundation

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

enum ContentCategory: String, CaseIterable, Codable {
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
    @State private var recentSearches: [String] = []
    @State private var savedContent: [String: [Unit]] = [:]
    @State private var hoveredSearch: String? = nil
    @State private var showAllSearches: Bool = false
    @State private var isDeleteMode: Bool = false
    @State private var searchesToDelete: Set<String> = []

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
                Group {
                    if units.isEmpty {
                        LinearGradient(gradient: Gradient(colors: [Color.red, Color.purple]),
                                       startPoint: .top,
                                       endPoint: .bottom)
                    } else {
                        LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]),
                                       startPoint: .top,
                                       endPoint: .bottom)
                    }
                }
                .edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()

                    Image("logoicon")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)

                    if showSearchBar {
                        VStack(spacing: 20) {
                            // Search bar
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

                            Button(action: {
                                Task {
                                    await generateLesson()
                                }
                            }) {
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

                            // Recently Searched section
                            if !recentSearches.isEmpty {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Recently Searched")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        if recentSearches.count > 3 {
                                            Button(action: { showAllSearches.toggle() }) {
                                                Text(showAllSearches ? "Show Less" : "Show More")
                                                    .foregroundColor(.white)
                                                    .font(.caption)
                                            }
                                        }
                                        Button(action: { isDeleteMode.toggle() }) {
                                            Image(systemName: isDeleteMode ? "checkmark.circle.fill" : "trash")
                                                .foregroundColor(.white)
                                        }
                                    }
                                    let displayedSearches = showAllSearches ?
                                    recentSearches : Array(recentSearches.prefix(3))
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: .infinity), spacing: 10)], spacing: 10) {
                                        ForEach(displayedSearches, id: \.self) { search in
                                            RecentSearchItem(search: search,
                                                             hoveredSearch: $hoveredSearch,
                                                             isDeleteMode: $isDeleteMode,
                                                             searchesToDelete: $searchesToDelete,
                                                             onSelect: selectSearch)
                                        }
                                    }
                                    if isDeleteMode && !searchesToDelete.isEmpty {
                                        Button(action: deleteSelectedSearches) {
                                            Text("Delete Selected")
                                                .foregroundColor(.white)
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .background(Color.red)
                                                .cornerRadius(8)
                                        }
                                    }
                                }.padding(.horizontal)
                            }
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

                        HStack(spacing: 20) {
                            Button(action: resetToMainPage) {
                                Text("Learn Something New")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.purple]),
                                                               startPoint: .leading,
                                                               endPoint: .trailing))
                                    .cornerRadius(20)
                            }

                            Button(action: {
                                Task {
                                    await generateMoreUnits()
                                }
                            }) {
                                Text("Dive Deeper")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]),
                                                               startPoint: .leading,
                                                               endPoint: .trailing))
                                    .cornerRadius(20)
                            }
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
        .onAppear {
            loadSavedContent()
            loadRecentSearches()
        }
    }

    func deleteSelectedSearches() {
        for search in searchesToDelete {
            if let index = recentSearches.firstIndex(of: search) {
                recentSearches.remove(at: index)
                savedContent.removeValue(forKey: search)
            }
        }
        saveRecentSearches()
        saveContentToUserDefaults()
        searchesToDelete.removeAll()
        isDeleteMode = false
    }

    func selectSearch(_ search: String) {
        if isDeleteMode {
            if searchesToDelete.contains(search) {
                searchesToDelete.remove(search)
            } else {
                searchesToDelete.insert(search)
            }
        } else {
            topic = search
            if let savedUnits = savedContent[search] {
                units = savedUnits
                withAnimation {
                    showSearchBar = false
                }
            } else {
                Task {
                    await generateLesson()
                }
            }
        }
    }

    func updateLoadingMessage() {
        loadingMessage = loadingMessages.randomElement() ?? "Loading..."
    }

    func generateLesson() async {
        if let savedUnits = savedContent[topic] {
            DispatchQueue.main.async {
                self.units = savedUnits
                self.isLoading = false
                withAnimation {
                    self.showSearchBar = false
                }
            }
            return
        }

        if !recentSearches.contains(topic) {
            recentSearches.insert(topic, at: 0)
            if recentSearches.count > 10 {  // Limit to 10 recent searches
                recentSearches = Array(recentSearches.prefix(10))
            }
            saveRecentSearches()
        }

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
            let response = try await model.generateContent(prompt)
            if let text = response.text {
                await processGeneratedContent(text)
            }

            DispatchQueue.main.async {
                self.loadingProgress = 1.0
                self.isLoading = false
                self.saveCurrentContent()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func processGeneratedContent(_ content: String) async {
        let newUnits = content.components(separatedBy: "---").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        var processedUnits: [Unit] = []

        for (index, unitContent) in newUnits.enumerated() {
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
                        cards.append(Card(title:currentTitle, content: currentContent, category: category))
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

            if !unitTitle.isEmpty && cards.count == 3 {
                processedUnits.append(Unit(title: unitTitle, cards: cards))
            }

            // Update loading progress
            DispatchQueue.main.async {
                self.loadingProgress = Double(index + 1) / Double(newUnits.count)
                self.updateLoadingMessage()
            }
        }

        DispatchQueue.main.async {
            if processedUnits.count == 5 {
                self.units = processedUnits
            } else {
                self.errorMessage = "Error: Generated content did not match the expected format."
            }
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

    func loadRecentSearches() {
        if let savedSearches = UserDefaults.standard.stringArray(forKey: "RecentSearches") {
            recentSearches = savedSearches
        }

        if let savedContentData = UserDefaults.standard.data(forKey: "SavedContent"),
           let decodedContent = try? JSONDecoder().decode([String: [Unit]].self, from: savedContentData) {
            savedContent = decodedContent
        }
    }

    func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "RecentSearches")
    }

    func saveCurrentContent() {
        savedContent[topic] = units
        saveContentToUserDefaults()
    }

    func saveContentToUserDefaults() {
        if let encodedContent = try? JSONEncoder().encode(savedContent) {
            UserDefaults.standard.set(encodedContent, forKey: "SavedContent")
        }
    }

    func loadSavedContent() {
        if let savedContentData = UserDefaults.standard.data(forKey: "SavedContent"),
           let decodedContent = try? JSONDecoder().decode([String: [Unit]].self, from: savedContentData) {
            savedContent = decodedContent
        }
    }

    func generateMoreUnits() async {
        isLoading = true
        loadingProgress = 0.0
        errorMessage = nil
        updateLoadingMessage()

        let prompt = """
        Create exactly 3 more units for the microlearning curriculum on the topic: \(topic).
        Each new unit should cover a unique aspect of the topic not covered in the previous units.
        For each unit, provide exactly 3 key points or concepts.
        Format your response strictly as follows, with no deviations:

        UNIT: [New Unit Title]
        TITLE: [Title for point 1]
        CONTENT: [Explanation for point 1, keep it under 50 words]
        TITLE: [Title for point 2]
        CONTENT: [Explanation for point 2, keep it under 50 words]
        TITLE: [Title for point 3]
        CONTENT: [Explanation for point 3, keep it under 50 words]
        ---
        UNIT: [New Unit Title]
        TITLE: [Title for point 1]
        CONTENT: [Explanation for point 1, keep it under 50 words]
        TITLE: [Title for point 2]
        CONTENT: [Explanation for point 2, keep it under 50 words]
        TITLE: [Title for point 3]
        CONTENT: [Explanation for point 3, keep it under 50 words]
        ---
        UNIT: [New Unit Title]
        TITLE: [Title for point 1]
        CONTENT: [Explanation for point 1, keep it under 50 words]
        TITLE: [Title for point 2]
        CONTENT: [Explanation for point 2, keep it under 50 words]
        TITLE: [Title for point 3]
        CONTENT: [Explanation for point 3, keep it under 50 words]

        Ensure each new unit has a clear, distinct focus within the overall topic.
        Do not use any markdown formatting. Use plain text only.
        It is crucial that you provide exactly 3 units, no more and no less, following the exact format above.
        """

        do {
            let response = try await model.generateContent(prompt)
            if let text = response.text {
                await processAdditionalUnits(text)
            }

            DispatchQueue.main.async {
                self.loadingProgress = 1.0
                self.isLoading = false
                self.saveCurrentContent()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func processAdditionalUnits(_ content: String) async {
        let newUnits = content.components(separatedBy: "---").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        var processedUnits: [Unit] = []

        for (index, unitContent) in newUnits.enumerated() {
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

            if !unitTitle.isEmpty && cards.count == 3 {
                processedUnits.append(Unit(title: unitTitle, cards: cards))
            }

            // Update loading progress
            DispatchQueue.main.async {
                self.loadingProgress = Double(index + 1) / Double(newUnits.count)
                self.updateLoadingMessage()
            }
        }

        DispatchQueue.main.async {
            if processedUnits.count == 3 {
                self.units.append(contentsOf: processedUnits)
            } else {
                self.errorMessage = "Error: Generated content did not match the expected format."
            }
        }
    }
}

struct RecentSearchItem: View {
    let search: String
    @Binding var hoveredSearch: String?
    @Binding var isDeleteMode: Bool
    @Binding var searchesToDelete: Set<String>
    let onSelect: (String) -> Void

    var body: some View {
        ZStack {
            Button(action: { onSelect(search) }) {
                Text(search)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .overlay(
                isDeleteMode ?
                    AnyView(
                        Image(systemName: searchesToDelete.contains(search) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(.white)
                            .padding(4)
                    ) :
                    AnyView(EmptyView())
            )
        }
        .onHover { isHovered in
            hoveredSearch = isHovered ? search : nil
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
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)]),
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
                        .foregroundColor(currentUnitIndex == units.count - 1 ? .gray : .white)
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
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct Card: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let category: ContentCategory

    init(id: UUID = UUID(), title: String, content: String, category: ContentCategory) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
    }
}

struct Unit: Identifiable, Codable {
    let id: UUID
    let title: String
    let cards: [Card]

    init(id: UUID = UUID(), title: String, cards: [Card]) {
        self.id = id
        self.title = title
        self.cards = cards
    }
}
