//
//  BreadboardApp.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/13/23.
//

import SwiftUI

@main
struct BreadboardApp: App {
    @State private var boards: [UUID] = []
    
    var body: some Scene {
        WindowGroup {
//            NavigationSplitView {
//                ForEach(boards, id: \.self) { id in
//                    NavigationLink {
//                        WorkspaceView()
//                    } label: {
//                        Text(id.uuidString)
//                    }
//                }
//            } detail: {
//                WorkspaceView()
//            }

            WorkspaceView()
        }
    }
}
