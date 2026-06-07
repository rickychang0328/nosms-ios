import SwiftUI

struct TokenListView: View {
    @StateObject var viewModel = TokenListViewModel()
    
    @State private var toastMessage: String = ""
    @State private var isShowingToast: Bool = false
    @State private var isEditing: Bool = false
    @State private var isShowingAddMenu: Bool = false
    
    // Navigation routes
    @State private var navigateToManualInput: Bool = false
    @State private var navigateToScanner: Bool = false
    @State private var isShowingPhotoPicker: Bool = false
    @State private var navigateToGroups: Bool = false
    @State private var navigateToSettings: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.tokenListTableViewBackgroundColor)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("搜索", text: $viewModel.searchText)
                                .font(.system(size: 15))
                            if !viewModel.searchText.isEmpty {
                                Button(action: { viewModel.searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(UIColor.tokenListSearchTextFieldBackgroundColor))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    // Group Tabs (Only show if groups exist and not editing)
                    if !viewModel.groups.isEmpty && !isEditing {
                        CustomSegmentControl(
                            titles: ["全部"] + viewModel.groups.map { $0.title },
                            selectedIndex: Binding(
                                get: {
                                    if let selected = viewModel.selectedGroup,
                                       let index = viewModel.groups.firstIndex(where: { $0.uuid == selected.uuid }) {
                                        return index + 1
                                    }
                                    return 0
                                },
                                set: { index in
                                    if index == 0 {
                                        viewModel.selectedGroup = nil
                                    } else {
                                        viewModel.selectedGroup = viewModel.groups[index - 1]
                                    }
                                }
                            )
                        )
                        .frame(height: 41)
                        .padding(.vertical, 4)
                    }
                    
                    // Main Content (List or Empty State)
                    if viewModel.pinnedTokens.isEmpty && viewModel.otherTokens.isEmpty {
                        emptyStateView
                    } else {
                        tokenListContent
                    }
                }
                
                // Add Account Popover Menu overlay
                if isShowingAddMenu {
                    addMenuOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("MustAuth")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        navigateToSettings = true
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            withAnimation {
                                isEditing.toggle()
                                if !isEditing {
                                    viewModel.selectedTokensToDelete.removeAll()
                                }
                            }
                        }) {
                            Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            withAnimation {
                                isShowingAddMenu.toggle()
                            }
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            // Silent Navigation Targets
            .background(
                Group {
                    NavigationLink(destination: JoinManuallyTOTPView(), isActive: $navigateToManualInput) { EmptyView() }
                    NavigationLink(destination: TokenScannerView(), isActive: $navigateToScanner) { EmptyView() }
                    NavigationLink(destination: Text("分組管理頁面暫存"), isActive: $navigateToGroups) { EmptyView() }
                    NavigationLink(destination: Text("安全設置頁面暫存"), isActive: $navigateToSettings) { EmptyView() }
                }
            )
        }
        .toast(isPresented: $isShowingToast, message: toastMessage)
    }
    
    private var tokenListContent: some View {
        VStack(spacing: 0) {
            List {
                // Section 1: Pinned tokens
                if !viewModel.pinnedTokens.isEmpty {
                    Section(header: Text("已置頂").font(.system(size: 12))) {
                        ForEach(viewModel.pinnedTokens) { item in
                            HStack {
                                if isEditing {
                                    Image(systemName: viewModel.selectedTokensToDelete.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(viewModel.selectedTokensToDelete.contains(item.id) ? .red : .gray)
                                        .onTapGesture {
                                            viewModel.toggleSelection(for: item.id)
                                        }
                                }
                                TokenRowView(viewModel: item, onCopied: { msg in
                                    self.toastMessage = msg
                                    self.isShowingToast = true
                                }, onDelete: {
                                    viewModel.deleteToken(item)
                                })
                            }
                        }
                    }
                }
                
                // Section 2: Other tokens
                if !viewModel.otherTokens.isEmpty {
                    Section(header: Text("驗證碼").font(.system(size: 12))) {
                        ForEach(viewModel.otherTokens) { item in
                            HStack {
                                if isEditing {
                                    Image(systemName: viewModel.selectedTokensToDelete.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(viewModel.selectedTokensToDelete.contains(item.id) ? .red : .gray)
                                        .onTapGesture {
                                            viewModel.toggleSelection(for: item.id)
                                        }
                                }
                                TokenRowView(viewModel: item, onCopied: { msg in
                                    self.toastMessage = msg
                                    self.isShowingToast = true
                                }, onDelete: {
                                    viewModel.deleteToken(item)
                                })
                            }
                        }
                        .onMove { indices, newOffset in
                            viewModel.moveToken(from: indices, to: newOffset, inSection: .other)
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
            
            // Delete Bar (appears in multi-select edit mode)
            if isEditing && viewModel.isDeleteButtonEnabled {
                Button(action: {
                    viewModel.deleteSelectedTokens()
                    isEditing = false
                }) {
                    Text("刪除選中的帳號")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.red)
                        .cornerRadius(8)
                        .padding()
                }
                .transition(.move(edge: .bottom))
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("NoSMS_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
            
            Text("啟用兩步驗證後，無論何時您登入帳號，\n都需要輸入自己的密碼和此應用產生的驗證碼")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: {
                isShowingAddMenu = true
            }) {
                Text("開始設置")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color(UIColor.homePageButtonBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(UIColor.homePageButtonBroderColor), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 54)
        }
        .background(Color(UIColor.homePageBackgroundColor))
    }
    
    private var addMenuOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isShowingAddMenu = false
                }
            
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    Text("選擇新增方式")
                        .font(.system(size: 16, weight: .bold))
                        .padding(.top, 16)
                    
                    Divider()
                    
                    Button("掃描二維碼") {
                        isShowingAddMenu = false
                        navigateToScanner = true
                    }
                    .font(.system(size: 15))
                    .padding(.vertical, 8)
                    
                    Button("從相冊導入") {
                        isShowingAddMenu = false
                        isShowingPhotoPicker = true
                    }
                    .font(.system(size: 15))
                    .padding(.vertical, 8)
                    
                    Button("手動輸入") {
                        isShowingAddMenu = false
                        navigateToManualInput = true
                    }
                    .font(.system(size: 15))
                    .padding(.vertical, 8)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .background(Color(UIColor.tokenListTableViewBackgroundColor))
                .cornerRadius(16)
            }
        }
    }
}

struct TokenListView_Previews: PreviewProvider {
    static var previews: some View {
        TokenListView()
    }
}
