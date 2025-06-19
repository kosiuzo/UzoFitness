//
//  HistoryView.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/18/25.
//


//
//  HistoryView.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/18/25.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    var body: some View {
        VStack {
            Text("History")
                .font(.largeTitle)
                .padding(.bottom)
            Text("Your past workouts and stats will show up here.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}