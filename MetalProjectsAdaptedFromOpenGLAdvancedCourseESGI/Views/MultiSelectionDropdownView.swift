//
//  MultiSelectionDropdownView.swift
//  MetalProjectsAdaptedFromOpenGLAdvancedCourseESGI
//
//  Created by Michaël ATTAL on 06/03/2025.
//

import SwiftUI

struct MultiSelectionDropdownView<OptionType>: View where OptionType: Hashable & CustomStringConvertible {
    var labelText: String?
    let options: Set<OptionType>
    let sortOptions = true
    let displayBulkSelection = false
    @Binding var selectedOptions: Set<OptionType>
    @State private var isExpanded = false

    private var optionsSorted: [OptionType] {
        if sortOptions {
            return options.sorted { $0.description.localizedCaseInsensitiveCompare($1.description) == .orderedAscending }
        }
        return Array(options)
    }

    var body: some View {
        Menu {
            ForEach(optionsSorted, id: \.self) { option in
                Button(action: {
                    withAnimation {
                        toggleSelection(option)
                    }
                }) {
                    HStack {
                        if selectedOptions.contains(option) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                        Text(option.description)
                    }
                }
            }

            if displayBulkSelection {
                Divider()

                HStack {
                    Button("Tout sélectionner") {
                        selectedOptions = Set(options)
                    }
                    Button("Tout désélectionner") {
                        selectedOptions.removeAll()
                    }
                }
                .padding()
            }
        } label: {
            HStack {
                if let labelText = self.labelText {
                    Text(labelText)
                        .fontWeight(.medium)
                    Spacer()
                }
                Text("\(selectedOptions.count) sélectionnée(s)").fontWeight(.medium)
                Image(systemName: "chevron.up.chevron.down")
            }
        }
    }

    private func toggleSelection(_ option: OptionType) {
        if selectedOptions.contains(option) {
            selectedOptions.remove(option)
        } else {
            selectedOptions.insert(option)
        }
    }
}
