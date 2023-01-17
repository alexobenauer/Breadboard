//
//  Widget.swift
//  Breadboard
//
//  Created by Alexander Obenauer on 1/13/23.
//

import SwiftUI

protocol Widget: Identifiable, View {
    var title: String { get }
    var icon: String { get }
    var color: Color { get }
    
    var id: UUID { get }
    
//    associatedtype V: View
//    func body(store: WorkspaceStore) -> V
}
