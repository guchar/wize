import SwiftUI
import GoogleGenerativeAI
import Foundation

struct ScatteredParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var opacity: Double
    var direction: CGVector
}

struct ScatteredQuantumLoader: View {
    let particleCount = 25
    let animationDuration: Double = 0.8
    let size: CGFloat = 200

    @State private var particles: [ScatteredParticle] = []
    @State private var isGathering = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .opacity(particle.opacity)
                        .position(particle.position)
                }
            }
            .frame(width: size, height: size)
            .onAppear {
                initializeParticles()
                animateParticles()
            }
        }
    }

    private func randomPosition(in size: CGSize) -> CGPoint {
        CGPoint(
            x: CGFloat.random(in: 0...size.width),
            y: CGFloat.random(in: 0...size.height)
        )
    }

    private func randomDirection() -> CGVector {
        let angle = CGFloat.random(in: 0...2 * .pi)
        return CGVector(dx: cos(angle), dy: sin(angle))
    }

    private func initializeParticles() {
        particles = (0..<particleCount).map { _ in
            ScatteredParticle(
                position: randomPosition(in: CGSize(width: size, height: size)),
                opacity: Double.random(in: 0.3...1.0),
                direction: randomDirection()
            )
        }
    }

    private func animateParticles() {
        withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
            isGathering.toggle()
            for i in 0..<particles.count {
                if isGathering {
                    particles[i].position = CGPoint(x: size / 2, y: size / 2)
                } else {
                    let newDirection = randomDirection()
                    let newPosition = CGPoint(
                        x: particles[i].position.x + newDirection.dx * 50,
                        y: particles[i].position.y + newDirection.dy * 50
                    )
                    particles[i].position = CGPoint(
                        x: max(0, min(newPosition.x, size)),
                        y: max(0, min(newPosition.y, size))
                    )
                    particles[i].direction = newDirection
                }
                particles[i].opacity = Double.random(in: 0.3...1.0)
            }
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

struct TableOfContentsView: View {
    let units: [Unit]
    @Binding var currentUnitIndex: Int
    @Binding var showTableOfContents: Bool
    let onUnitSelected: (Int) -> Void
    
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var pressedIndex: Int? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Table of Contents")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { showTableOfContents = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()
            .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]),
                                       startPoint: .leading,
                                       endPoint: .trailing))
            
            GeometryReader { geometry in
                ZStack(alignment: .trailing) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(Array(units.enumerated()), id: \.element.id) { index, unit in
                                UnitButton(unit: unit, index: index, isSelected: currentUnitIndex == index, isPressed: pressedIndex == index) {
                                    onUnitSelected(index)
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                pressedIndex = index
                                            }
                                        }
                                        .onEnded { _ in
                                            withAnimation(.easeInOut(duration: 0.1)) {
                                                pressedIndex = nil
                                            }
                                            onUnitSelected(index)
                                        }
                                )
                            }
                        }
                        .padding()
                        .background(GeometryReader { contentGeometry in
                            Color.clear.preference(key: ContentHeightPreferenceKey.self, value: contentGeometry.size.height)
                        })
                    }
                    .onChange(of: contentHeight) { _ in
                        withAnimation {
                            scrollOffset = min(max(0, scrollOffset), contentHeight - geometry.size.height)
                        }
                    }
                    .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                        contentHeight = height
                    }
                    
                    // Custom Scroll Bar
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 4)
                        .padding(.trailing, 2)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 4, height: scrollBarHeight(in: geometry))
                        .offset(y: scrollBarOffset(in: geometry))
                        .padding(.trailing, 2)
                }
            }
            
            HStack {
                Button(action: { onUnitSelected(0) }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Last Unit")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: { onUnitSelected(units.count - 1) }) {
                    HStack {
                        Text("First Unit")
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    private func scrollBarHeight(in geometry: GeometryProxy) -> CGFloat {
        let visibleRatio = geometry.size.height / contentHeight
        return max(geometry.size.height * visibleRatio, 30)
    }
    
    private func scrollBarOffset(in geometry: GeometryProxy) -> CGFloat {
        let scrollRatio = scrollOffset / (contentHeight - geometry.size.height)
        return scrollRatio * (geometry.size.height - scrollBarHeight(in: geometry))
    }
}

struct UnitButton: View {
    let unit: Unit
    let index: Int
    let isSelected: Bool
    let isPressed: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("Unit \(index + 1)")
                    .fontWeight(.medium)
                Spacer()
                Text(unit.title)
                    .lineLimit(1)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Group {
                    if isSelected {
                        Color.blue.opacity(0.1)
                    } else if isPressed {
                        Color.gray.opacity(0.3)
                    } else {
                        Color.gray.opacity(0.1)
                    }
                }
            )
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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

struct SearchBubble: View {
    let search: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onTrash: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                Text(search)
                    .lineLimit(1)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onTrash) {
                Image(systemName: isSelected ? "trash.fill" : "trash")
                    .foregroundColor(isSelected ? .red : .white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.red.opacity(0.3) : Color.white.opacity(0.2))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
        )
    }
}

struct SearchHistoryView: View {
    @Binding var recentSearches: [String]
    @Binding var savedContent: [String: [Unit]]
    @Binding var searchesToDelete: Set<String>
    let onSelect: (String) -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("Search History")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .padding()

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(recentSearches, id: \.self) { search in
                        SearchBubble(
                            search: search,
                            isSelected: searchesToDelete.contains(search),
                            onSelect: { onSelect(search) },
                            onTrash: {
                                if searchesToDelete.contains(search) {
                                    searchesToDelete.remove(search)
                                } else {
                                    searchesToDelete.insert(search)
                                }
                            }
                        )
                    }
                }
                .padding()
            }

            HStack {
                Button(action: {
                    if searchesToDelete.count == recentSearches.count {
                        searchesToDelete.removeAll()
                    } else {
                        searchesToDelete = Set(recentSearches)
                    }
                }) {
                    Text(searchesToDelete.count == recentSearches.count ? "Deselect All" : "Select All")
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue)
                        .cornerRadius(8)
                }

                Spacer()

                if !searchesToDelete.isEmpty {
                    Button(action: onDelete) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Selected")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .padding()
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

struct CardView: View {
    let cards: [Card]
    @Binding var currentIndex: Int
    let onLastCardSwiped: () -> Void

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
                                                } else if value.translation.width < -50 && currentIndex == cards.count - 1 {
                                                    onLastCardSwiped()
                                                }
                                            }
                                    )
                                }
                            }
                        }
                    }

                    struct UnitView: View {
                        let units: [Unit]
                        @Binding var currentUnitIndex: Int
                        @Binding var currentCardIndex: Int
                        @Binding var showTableOfContents: Bool

                        var body: some View {
                            VStack {
                                Button(action: { showTableOfContents = true }) {
                                    Text("Table of Contents")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 20)
                                        .background(Color.blue.opacity(0.6))
                                        .cornerRadius(20)
                                }
                                .padding(.top, 20)

                                Text("Unit \(currentUnitIndex + 1): \(units[currentUnitIndex].title)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)]),
                                                               startPoint: .leading,
                                                               endPoint: .trailing))
                                    .cornerRadius(0)
                                    .padding(.horizontal)

                                CardView(cards: units[currentUnitIndex].cards, currentIndex: $currentCardIndex) {
                                    if currentUnitIndex < units.count - 1 {
                                        withAnimation {
                                            currentUnitIndex += 1
                                            currentCardIndex = 0
                                        }
                                    }
                                }

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

                                if !showTableOfContents {
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

                    struct FireLogoView: View {
                        let streak: Int
                        let size: CGFloat
                        
                        var body: some View {
                            ZStack {
                                Image(systemName: "flame.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.orange)
                                    .frame(width: size, height: size)
                                
                                Text("\(streak)")
                                    .font(.system(size: size * 0.4, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    struct ContentView: View {
                        @State private var topic: String = ""
                        @State private var units: [Unit] = []
                        @State private var currentUnitIndex: Int = 0
                        @State private var currentCardIndex: Int = 0
                        @State private var isLoading = false
                        @State private var errorMessage: String?
                        @State private var debugText: String = ""
                        @State private var loadingMessage: String = "Initializing your learning journey..."
                        @State private var showSearchBar = true
                        @State private var recentSearches: [String] = []
                        @State private var savedContent: [String: [Unit]] = [:]
                        @State private var showSearchHistory = false
                        @State private var searchesToDelete: Set<String> = []
                        @State private var showInappropriateContentWarning = false
                        @State private var showTableOfContents = false
                        @State private var showLoadingOverlay = false
                        @State private var streak: Int = 0
                        @State private var lastVisitDate: Date?

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

                        let randomSkills = [
                            "How to tie a tie",
                            "How to whistle",
                            "How to blow a bubble with gum",
                            "How to juggle",
                            "How to fold a paper airplane",
                            "How to do a magic trick",
                            "How to make origami",
                            "How to solve a Rubik's cube",
                            "How to do a cartwheel",
                            "How to moonwalk",
                            "How to make a perfect omelet",
                            "How to skip stones",
                            "How to do a French braid",
                            "How to beatbox",
                            "How to coin roll"
                        ]

                        @State private var loadingMessageTimer: Timer?

                        var body: some View {
                            NavigationView {
                                ZStack {
                                    Group {
                                        if showInappropriateContentWarning {
                                            LinearGradient(gradient: Gradient(colors: [Color.black, Color.red]),
                                                           startPoint: .top,
                                                           endPoint: .bottom)
                                        } else if units.isEmpty {
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

                                    VStack(spacing: 20) {
                                        if showInappropriateContentWarning {
                                            VStack(spacing: 20) {
                                                Text("WIZE doesn't want you learning that")
                                                    .font(.title)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                    .multilineTextAlignment(.center)
                                                    .padding()

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
                                            }
                                        } else if showSearchHistory {
                                            SearchHistoryView(
                                                recentSearches: $recentSearches,
                                                savedContent: $savedContent,
                                                searchesToDelete: $searchesToDelete,
                                                onSelect: selectSearch,
                                                onDelete: deleteSelectedSearches,
                                                onDismiss: { showSearchHistory = false }
                                            )
                                        } else {
                                            Button(action: learnRandomSkill) {
                                                HStack {
                                                    Image(systemName: "dice")
                                                        .font(.system(size: 20))
                                                    Text("Learn a Random Skill")
                                                        .fontWeight(.semibold)
                                                }
                                                .foregroundColor(.white)
                                                .padding(.vertical, 12)
                                                .padding(.horizontal, 20)
                                                .background(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                                                           startPoint: .leading,
                                                                           endPoint: .trailing))
                                                .cornerRadius(20)
                                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                                            }
                                            .padding(.top, 40)
                                            
                                            HStack(spacing: 10) {
                                                FireLogoView(streak: streak, size: units.isEmpty ? 80 : 40)
                                                    .animation(.easeInOut)
                                                
                                                Image("logoicon")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: units.isEmpty ? 65 : 40)
                                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                                            }
                                            .padding(.vertical, 10)

                                            if !units.isEmpty {
                                                Text("Currently Learning: \(topic)")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                    .padding(.vertical, 10)
                                                    .frame(maxWidth: .infinity)
                                                    .background(Color.black.opacity(0.3))
                                                    .cornerRadius(10)
                                                    .padding(.horizontal)

                                                if showTableOfContents {
                                                    TableOfContentsView(
                                                        units: units,
                                                        currentUnitIndex: $currentUnitIndex,
                                                        showTableOfContents: $showTableOfContents
                                                    ) { selectedIndex in
                                                        currentUnitIndex = selectedIndex
                                                        showTableOfContents = false
                                                    }
                                                } else {
                                                    UnitView(
                                                        units: units,
                                                        currentUnitIndex: $currentUnitIndex,
                                                        currentCardIndex: $currentCardIndex,
                                                        showTableOfContents: $showTableOfContents
                                                    ).frame(height: 450)  // Increased height for bigger index card
                                                

                                                    HStack(spacing: 20) {
                                                        Button(action: resetToMainPage) {
                                                            HStack {
                                                                Image(systemName: "plus.circle")
                                                                Text("New Topic")
                                                                    .fontWeight(.semibold)
                                                            }
                                                            .foregroundColor(.white)
                                                            .padding(.vertical, 12)
                                                            .padding(.horizontal, 20)
                                                            .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.purple]),
                                                                                       startPoint: .leading,
                                                                                       endPoint: .trailing))
                                                            .cornerRadius(20)
                                                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                                                        }


                                                        Button(action: {
                                                            Task {
                                                                await generateMoreUnits()
                                                            }
                                                        }) {
                                                            HStack {
                                                                Image(systemName: "arrow.down.circle")
                                                                Text("Dive Deeper")
                                                                    .fontWeight(.semibold)
                                                            }
                                                            .foregroundColor(.white)
                                                            .padding(.vertical, 12)
                                                            .padding(.horizontal, 20)
                                                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]),
                                                                                       startPoint: .leading,
                                                                                       endPoint: .trailing))
                                                            .cornerRadius(20)
                                                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                                                        }
                                                    }
                                                    .padding(.top, 20)
                                                }
                                            }

                                            if showSearchBar {
                                                Spacer()
                                                
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
                                                    Button(action: {
                                                                                        Task {
                                                                                            await generateLesson()
                                                                                        }
                                                                                    }) {
                                                                                        HStack {
                                                                                            Image(systemName: "flame")
                                                                                            Text("Ignite Learning")
                                                                                                .fontWeight(.bold)
                                                                                        }
                                                                                        .foregroundColor(.white)
                                                                                        .padding(.vertical, 16)
                                                                                        .padding(.horizontal, 40)
                                                                                        .background(LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                                                                                                   startPoint: .leading,
                                                                                                                   endPoint: .trailing))
                                                                                        .cornerRadius(25)
                                                                                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                                                                                    }
                                                                                    .disabled(isLoading || topic.isEmpty)
                                                                                }
                                                                                .padding(.horizontal, 20)
                                                                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                                                                
                                                                                Spacer()
                                                                                
                                                                                Button(action: { showSearchHistory = true }) {
                                                                                    HStack {
                                                                                        Image(systemName: "clock.arrow.circlepath")
                                                                                        Text("View Search History")
                                                                                            .fontWeight(.semibold)
                                                                                    }
                                                                                    .foregroundColor(.white)
                                                                                    .padding(.vertical, 12)
                                                                                    .padding(.horizontal, 20)
                                                                                    .background(Color.blue.opacity(0.6))
                                                                                    .cornerRadius(20)
                                                                                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                                                                                }
                                                                                .padding(.bottom, 20)
                                                                                
                                                                            }

                                                                            if !debugText.isEmpty {
                                                                                Text(debugText)
                                                                                    .font(.caption)
                                                                                    .foregroundColor(.white)
                                                                            }

                                                                            Spacer()
                                                                        }
                                                                    }
                                                                    .navigationBarHidden(true)

                                                                    if showLoadingOverlay {
                                                                        LoadingOverlay(loadingMessage: $loadingMessage)
                                                                    }
                                                                }
                                                            }
                                                            .onAppear {
                                                                loadSavedContent()
                                                                loadRecentSearches()
                                                                loadStreak()
                                                                updateStreak()
                                                            }
                                                        }

                                                        func learnRandomSkill() {
                                                            topic = randomSkills.randomElement() ?? "How to tie a tie"
                                                            Task {
                                                                await generateLesson()
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
                                                        }

                                                        func selectSearch(_ search: String) {
                                                            topic = search
                                                            if let savedUnits = savedContent[search] {
                                                                units = savedUnits
                                                                withAnimation {
                                                                    showSearchBar = false
                                                                    showSearchHistory = false
                                                                }
                                                            } else {
                                                                Task {
                                                                    await generateLesson()
                                                                }
                                                            }
                                                        }

                                                        func updateLoadingMessage() {
                                                            loadingMessage = loadingMessages.randomElement() ?? "Loading..."
                                                        }

                                                        func startLoadingMessageTimer() {
                                                            loadingMessageTimer?.invalidate()
                                                            loadingMessageTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                                                                withAnimation {
                                                                    updateLoadingMessage()
                                                                }
                                                            }
                                                        }

                                                        func stopLoadingMessageTimer() {
                                                            loadingMessageTimer?.invalidate()
                                                            loadingMessageTimer = nil
                                                        }

                                                        func generateLesson() async {
                                                            if let savedUnits = savedContent[topic] {
                                                                DispatchQueue.main.async {
                                                                    self.units = savedUnits
                                                                    self.isLoading = false
                                                                    withAnimation {
                                                                        self.showSearchBar = false
                                                                        self.showTableOfContents = true
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
                                                            errorMessage = nil
                                                            debugText = ""
                                                            units.removeAll()
                                                            currentUnitIndex = 0
                                                            currentCardIndex = 0
                                                            updateLoadingMessage()
                                                            startLoadingMessageTimer()
                                                            withAnimation {
                                                                showSearchBar = false
                                                                showSearchHistory = false
                                                                showLoadingOverlay = true
                                                            }

                                                            let prompt = """
                                                            Create a structured, formal microlearning curriculum for the topic: \(topic).
                                                            Provide exactly 5 main units, each covering a unique aspect of the topic.
                                                            For each unit, provide exactly 3 key points or concepts.
                                                            Use formal language and ensure proper capitalization of all names, places, historical terms, and proper nouns.
                                                            Format your response as follows:

                                                            UNIT: [Unit 1 Title (properly capitalized)]
                                                            TITLE: [Title for point 1 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 1, 20-50 words, with proper capitalization of all proper nouns]
                                                            TITLE: [Title for point 2 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 2, 20-50 words, with proper capitalization of all proper nouns]
                                                            TITLE: [Title for point 3 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 3, 20-50 words, with proper capitalization of all proper nouns]
                                                            ---
                                                            UNIT: [Unit 2 Title (properly capitalized)]
                                                            TITLE: [Title for point 1 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 1, 20-50 words, with proper capitalization of all proper nouns]
                                                            TITLE: [Title for point 2 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 2, 20-50 words, with proper capitalization of all proper nouns]
                                                            TITLE: [Title for point 3 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 3, 20-50 words, with proper capitalization of all proper nouns]
                                                            ---
                                                            UNIT: [Unit 3 Title (properly capitalized)]
                                                            TITLE: [Title for point 1 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 1, 20-50 words, with proper capitalization of all proper nouns]
                                                            TITLE: [Title for point 2 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 2, 20-50 words, with proper capitalization of all proper nouns]
                                                            TITLE: [Title for point 3 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 3, 20-50 words, with proper capitalization of all proper nouns]
                                                            ---
                                                            UNIT: [Unit 4 Title (properly capitalized)]
                                                            TITLE: [Title for point 1 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 1, 20-50 words, with proper capitalization of all proper nouns]
                                                            TITLE: [Title for point 2 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 2, 20-50 words, with proper capitalization of all proper nouns]
                                                            TITLE: [Title for point 3 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 3, 20-50 words, with proper capitalization of all proper nouns]
                                                            ---
                                                            UNIT: [Unit 5 Title (properly capitalized)]
                                                            TITLE: [Title for point 1 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 1, 20-50 words, with proper capitalization of all proper nouns]
                                                            TITLE: [Title for point 2 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 2, 20-50 words, with proper capitalization of all proper nouns]
                                                            TITLE: [Title for point 3 (properly capitalized)]
                                                            CONTENT: [Formal explanation for point 3, 20-50 words, with proper capitalization of all proper nouns]

                                                            Ensure each unit has a clear, distinct focus within the overall topic.
                                                            Use formal language and proper capitalization throughout, especially for names, places, and historical terms.
                                                            It is crucial that you provide exactly 5 units, no more and no less.
                                                            Do not use any markdown formatting. Use plain text only.
                                                            """

                                                            do {
                                                                let response = try await model.generateContent(prompt)
                                                                if let text = response.text {
                                                                    await processGeneratedContent(text)
                                                                }

                                                                DispatchQueue.main.async {
                                                                    self.isLoading = false
                                                                    self.saveCurrentContent()
                                                                    self.stopLoadingMessageTimer()
                                                                    withAnimation {
                                                                        self.showLoadingOverlay = false
                                                                        self.showTableOfContents = false  // Don't show table of contents after generating content
                                                                    }
                                                                }
                                                            } catch {
                                                                DispatchQueue.main.async {
                                                                    self.errorMessage = "Error: \(error.localizedDescription)"
                                                                    self.isLoading = false
                                                                    self.stopLoadingMessageTimer()
                                                                    withAnimation {
                                                                        self.showLoadingOverlay = false
                                                                        self.showInappropriateContentWarning = true
                                                                    }
                                                                }
                                                            }
                                                        }

                        func processGeneratedContent(_ content: String) async {
                            let unitSections = content.components(separatedBy: "---").filter { !$0.isEmpty }
                            var newUnits: [Unit] = []

                            for section in unitSections {
                                let lines = section.split(separator: "\n", omittingEmptySubsequences: true)
                                if lines.count >= 7 {
                                    var unitTitle = String(lines[0].dropFirst(6))
                                    unitTitle = unitTitle.trimmingCharacters(in: .punctuationCharacters)
                                    
                                    var cards: [Card] = []

                                    for i in stride(from: 1, to: lines.count, by: 2) {
                                        if i + 1 < lines.count {
                                            let title = String(lines[i].dropFirst(7)).trimmingCharacters(in: .whitespaces)
                                            var content = String(lines[i + 1].dropFirst(9)).trimmingCharacters(in: .whitespaces)
                                            
                                            // Ensure content is a complete sentence with proper capitalization
                                            if !content.isEmpty {
                                                content = content.lowercased()
                                                content = content.prefix(1).uppercased() + content.dropFirst()
                                                if !content.hasSuffix(".") && !content.hasSuffix("!") && !content.hasSuffix("?") {
                                                    content += "."
                                                }
                                            }
                                            
                                            let category = ContentCategory.matchCategory(for: content)
                                            cards.append(Card(title: title, content: content, category: category))
                                        }
                                    }

                                    // Ensure we have exactly 3 cards per unit
                                    while cards.count < 3 {
                                        cards.append(Card(title: "Additional Information", content: "Content for this card is currently unavailable.", category: .other))
                                    }
                                    cards = Array(cards.prefix(3))

                                    newUnits.append(Unit(title: unitTitle, cards: cards))
                                }
                            }

                            DispatchQueue.main.async {
                                self.units = newUnits
                            }
                        }

                                                        func resetToMainPage() {
                                                            withAnimation {
                                                                showSearchBar = true
                                                                units.removeAll()
                                                                topic = ""
                                                                errorMessage = nil
                                                                debugText = ""
                                                                showInappropriateContentWarning = false
                                                                showTableOfContents = false
                                                            }
                                                        }

                                                        func loadRecentSearches() {
                                                            if let savedSearches = UserDefaults.standard.stringArray(forKey: "RecentSearches") {
                                                                recentSearches = savedSearches
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
                                                            let currentUnitCount = units.count
                                                            let prompt = """
                                                            Continue the microlearning curriculum for the topic: \(topic).
                                                            We already have \(currentUnitCount) units. Please provide 3 more units, each covering a unique aspect of the topic that hasn't been covered yet.
                                                            For each unit, provide exactly 3 key points or concepts.
                                                            Format your response as follows:

                                                            UNIT: [Unit \(currentUnitCount + 1) Title]
                                                            TITLE: [Title for point 1]
                                                            CONTENT: [Explanation for point 1, keep it under 50 words]
                                                            TITLE: [Title for point 2]
                                                            CONTENT: [Explanation for point 2, keep it under 50 words]
                                                            TITLE: [Title for point 3]
                                                            CONTENT: [Explanation for point 3, keep it under 50 words]
                                                            ---
                                                            UNIT: [Unit \(currentUnitCount + 2) Title]
                                                            ... (repeat the structure for all 3 new units)

                                                            Ensure each unit has a clear, distinct focus within the overall topic.
                                                            Do not use any markdown formatting. Use plain text only.
                                                            It is crucial that you provide exactly 3 new units, no more and no less.
                                                            """

                                                            do {
                                                                let response = try await model.generateContent(prompt)
                                                                if let text = response.text {
                                                                    await processAdditionalUnits(text)
                                                                }
                                                            } catch {
                                                                DispatchQueue.main.async {
                                                                    self.errorMessage = "Error generating more units: \(error.localizedDescription)"
                                                                }
                                                            }
                                                        }

                                                        func processAdditionalUnits(_ content: String) async {
                                                            let unitSections = content.components(separatedBy: "---").filter { !$0.isEmpty }
                                                            var newUnits: [Unit] = []

                                                            for section in unitSections {
                                                                let lines = section.split(separator: "\n")
                                                                if lines.count >= 7 {
                                                                    let unitTitle = String(lines[0].dropFirst(6))
                                                                    var cards: [Card] = []

                                                                    for i in stride(from: 1, to: lines.count, by: 3) {
                                                                        if i + 2 < lines.count {
                                                                            let title = String(lines[i].dropFirst(7))
                                                                            let content = String(lines[i + 1].dropFirst(9))
                                                                            let category = ContentCategory.matchCategory(for: content)
                                                                            cards.append(Card(title: title, content: content, category: category))
                                                                        }
                                                                    }

                                                                    newUnits.append(Unit(title: unitTitle, cards: cards))
                                                                }
                                                            }

                                                            DispatchQueue.main.async {
                                                                self.units.append(contentsOf: newUnits)
                                                                self.saveCurrentContent()
                                                            }
                                                        }

                                                        func loadStreak() {
                                                            if let savedStreak = UserDefaults.standard.object(forKey: "Streak") as? Int {
                                                                streak = savedStreak
                                                            }
                                                            if let savedDate = UserDefaults.standard.object(forKey: "LastVisitDate") as? Date {
                                                                lastVisitDate = savedDate
                                                            }
                                                        }

                                                        func saveStreak() {
                                                            UserDefaults.standard.set(streak, forKey: "Streak")
                                                            UserDefaults.standard.set(lastVisitDate, forKey: "LastVisitDate")
                                                        }

                                                        func updateStreak() {
                                                            let currentDate = Date()
                                                            let calendar = Calendar.current

                                                            if let lastVisit = lastVisitDate {
                                                                if calendar.isDate(currentDate, inSameDayAs: lastVisit) {
                                                                    // Do nothing if it's the same day
                                                                } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate),
                                                                          calendar.isDate(lastVisit, inSameDayAs: yesterday) {
                                                                    // Increment streak if the last visit was yesterday
                                                                    streak += 1
                                                                } else {
                                                                    // Reset streak if there's a gap
                                                                    streak = 1
                                                                }
                                                            } else {
                                                                // First visit
                                                                streak = 1
                                                            }

                                                            lastVisitDate = currentDate
                                                            saveStreak()
                                                        }
                                                    }

                                                    struct LoadingOverlay: View {
                                                        @Binding var loadingMessage: String
                                                        
                                                        var body: some View {
                                                            ZStack {
                                                                Color.black.opacity(0.7)
                                                                    .edgesIgnoringSafeArea(.all)
                                                                
                                                                VStack {
                                                                    Text(loadingMessage)
                                                                        .font(.headline)
                                                                        .foregroundColor(.white)
                                                                        .padding(.bottom, 20)
                                                                    ScatteredQuantumLoader()
                                                                        .frame(width: 200, height: 200)
                                                                }
                                                            }
                                                        }
                                                    }

                                                    @main
                                                    struct YourAppNameApp: App {
                                                        var body: some Scene {
                                                            WindowGroup {
                                                                ContentView()
                                                            }
                                                        }
                                                    }

                                                    struct ContentView_Previews: PreviewProvider {
                                                        static var previews: some View {
                                                            ContentView()
                                                        }
                                                    }
