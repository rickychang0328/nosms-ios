import Foundation
import Combine
import OneTimePassword

class TokenListViewModel: ObservableObject {
    
    enum SectionType {
        case pinned
        case other
    }
    
    // UI input bindings
    @Published var searchText: String = ""
    @Published var selectedGroup: GroupObject? = nil // nil means "All"
    @Published var selectedTokensToDelete = Set<Data>()
    
    // Outputs to View
    @Published var pinnedTokens: [TokenItemViewModel] = []
    @Published var otherTokens: [TokenItemViewModel] = []
    @Published var groups: [GroupObject] = []
    
    private let tokenService: TokenService
    private var cancellables = Set<AnyCancellable>()
    private var cellViewModelCache: [Data: TokenItemViewModel] = [:]
    
    init(tokenService: TokenService = .shared) {
        self.tokenService = tokenService
        
        // Expose groups directly
        tokenService.$groupList
            .assign(to: \.groups, on: self)
            .store(in: &cancellables)
            
        // Main subscription combining: tokens, pins, search, and group filters
        Publishers.CombineLatest4(
            tokenService.$persistentTokens,
            tokenService.$pinList,
            $searchText
                .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
                .removeDuplicates(),
            $selectedGroup
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] tokens, pins, query, group in
            self?.processTokens(tokens: tokens, pins: pins, query: query, group: group)
        }
        .store(in: &cancellables)
    }
    
    private func getOrCreateViewModel(for persistentToken: PersistentToken) -> TokenItemViewModel {
        if let cached = cellViewModelCache[persistentToken.identifier] {
            return cached
        }
        let newVM = TokenItemViewModel(
            persistentToken: persistentToken,
            timerPublisher: tokenService.timerPublisher,
            tokenService: tokenService
        )
        cellViewModelCache[persistentToken.identifier] = newVM
        return newVM
    }
    
    private func processTokens(tokens: [PersistentToken], pins: [Data], query: String, group: GroupObject?) {
        // 1. Group filtering
        var filtered = tokens
        if let group = group {
            filtered = tokens.filter { group.tokens.contains($0.identifier) }
        }
        
        // 2. Search query filtering
        if !query.isEmpty {
            filtered = filtered.filter { token in
                token.token.name.localizedCaseInsensitiveContains(query) ||
                token.token.issuer.localizedCaseInsensitiveContains(query)
            }
        }
        
        // 3. Partitioning into Pinned and Other
        let pinnedList = filtered.filter { pins.contains($0.identifier) }
        let otherList = filtered.filter { !pins.contains($0.identifier) }
        
        // 4. Map to view models (using cache)
        self.pinnedTokens = pinnedList.map { getOrCreateViewModel(for: $0) }
        self.otherTokens = otherList.map { getOrCreateViewModel(for: $0) }
        
        // Clean cache for deleted tokens to free memory
        let activeIDs = Set(tokens.map { $0.identifier })
        cellViewModelCache = cellViewModelCache.filter { activeIDs.contains($0.key) }
    }
    
    // MARK: - Actions
    
    func deleteToken(_ item: TokenItemViewModel) {
        do {
            try tokenService.deleteToken(item.persistentToken)
        } catch {
            print("Failed to delete token: \(error)")
        }
    }
    
    func deleteSelectedTokens() {
        let tokensToDelete = persistentTokensForSelectedIDs()
        for token in tokensToDelete {
            try? tokenService.deleteToken(token)
        }
        selectedTokensToDelete.removeAll()
    }
    
    func togglePin(for item: TokenItemViewModel) {
        item.togglePin()
    }
    
    func moveToken(from source: IndexSet, to destination: Int, inSection section: SectionType) {
        // Reordering is only allowed in the "Other" section (matching original logic)
        // or relative indices.
        switch section {
        case .pinned:
            // Pin list order is managed by KeychainTokenStore.shared.pinList
            // Original code didn't support reordering pinned tokens directly, but we can do it if desired.
            break
        case .other:
            guard let firstIndex = source.first else { return }
            
            // Map the indices in the filtered "otherTokens" list back to the master list
            let sourceItem = otherTokens[firstIndex]
            let destinationItem = otherTokens[destination < otherTokens.count ? destination : otherTokens.count - 1]
            
            if let masterSourceIndex = tokenService.persistentTokens.firstIndex(where: { $0.identifier == sourceItem.id }),
               let masterDestIndex = tokenService.persistentTokens.firstIndex(where: { $0.identifier == destinationItem.id }) {
                tokenService.moveToken(from: masterSourceIndex, to: masterDestIndex)
            }
        }
    }
    
    func addToken(urlString: String) async -> Result<Void, Error> {
        return await withCheckedContinuation { continuation in
            tokenService.addTokenWith(urlString: urlString) { result in
                switch result {
                case .success:
                    continuation.resume(returning: .success(()))
                case .failure(let error):
                    let nsError = error as NSError
                    if nsError.domain == "TokenService" && nsError.code == 409,
                       let retryAction = nsError.userInfo["retryAction"] as? () -> Void {
                        retryAction()
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
        }
    }
    
    // Toggle deletion selection status
    func toggleSelection(for id: Data) {
        if selectedTokensToDelete.contains(id) {
            selectedTokensToDelete.remove(id)
        } else {
            selectedTokensToDelete.insert(id)
        }
    }
    
    var isDeleteButtonEnabled: Bool {
        return !selectedTokensToDelete.isEmpty
    }
    
    private func persistentTokensForSelectedIDs() -> [PersistentToken] {
        return tokenService.persistentTokens.filter { selectedTokensToDelete.contains($0.identifier) }
    }
}
