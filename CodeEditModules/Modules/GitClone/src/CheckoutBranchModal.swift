//
//  CheckoutBranchModal.swift
//  
//
//  Created by Aleksi Puttonen on 14.4.2022.
//

import Foundation
import SwiftUI
import GitClient
import ShellClient

public struct CheckoutBranchModal: View {
    private let shellClient: ShellClient
    @Binding private var isPresented: Bool
    @Binding private var repoPath: String
    // TODO: This has to be derived from git
    @State private var selectedBranch = "main"
    public init(isPresented: Binding<Bool>,
                repoPath: Binding<String>,
                shellClient: ShellClient) {
        self.shellClient = shellClient
        self._isPresented = isPresented
        self._repoPath = repoPath
    }
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .padding(.bottom, 50)
                VStack(alignment: .leading) {
                    Text("Checkout branch")
                        .bold()
                        .padding(.bottom, 2)
                    Text("Select a branch to checkout")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .alignmentGuide(.trailing) { context in
                        context[.trailing]
                    }
                    Menu {
                        ForEach(getBranches().filter {!$0.contains("HEAD")}, id: \.self) { branch in
                            Button {
                                    guard selectedBranch != branch else { return }
                                    selectedBranch = branch
                            } label: {
                                Text(branch)
                            }.disabled(selectedBranch == branch)
                        }
                    } label: {
                        Text(selectedBranch)
                    }
                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        Button("Checkout") {
                            checkoutBranch()
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    .alignmentGuide(.trailing) { context in
                        context[.trailing]
                    }
                    .offset(x: 145)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .frame(width: 400)
        }
    }
}

extension CheckoutBranchModal {
    func getBranches() -> [String] {
        guard let url = URL(string: repoPath) else {
            return [""]
        }
        do {
            let branches = try GitClient.default(directoryURL: url,
                                                 shellClient: shellClient).getBranches(true)
            return branches
        } catch {
            return [""]
        }
    }
    func checkoutBranch() {
        var parsedBranch = selectedBranch
        if selectedBranch.contains("origin/") || selectedBranch.contains("upstream/") {
            parsedBranch = selectedBranch.components(separatedBy: "/")[1]
        }
        do {
            if let url = URL(string: repoPath) {
                try GitClient.default(directoryURL: url,
                                      shellClient: shellClient).checkoutBranch(parsedBranch)
                isPresented = false
            }
        } catch {
            guard let error = error as? GitClient.GitClientError else { return }
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Ok")
            switch error {
            case .notGitRepository:
                alert.messageText = "Not a git repository"
            case let .outputError(message):
                alert.messageText = message
            }
            alert.runModal()
        }
    }
}
