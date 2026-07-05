import SwiftUI
import VitalisCore

struct NutritionLogView: View {
    @Bindable var viewModel: NutritionLogViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Section 1: Simulated Scanner Input
                            VStack(alignment: .leading, spacing: 10) {
                                Text("BARCODE SCANNER SIMULATOR")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .tracking(2)
                                    .foregroundStyle(.gray)
                                
                                HStack {
                                    TextField("Enter Barcode (e.g. 0123456789)", text: $viewModel.barcodeInput)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(10)
                                        .foregroundStyle(.white)
                                        .integerKeyboard()
                                    
                                    Button(action: {
                                        viewModel.simulateBarcodeScan()
                                    }) {
                                        Image(systemName: "barcode.viewfinder")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(10)
                                    }
                                }
                                
                                Text("Tip: Use '0123456789' for Oats, '9876543210' for Protein Shake.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(15)
                            .padding(.horizontal)
                            
                            // Status Messages
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                            
                            if let success = viewModel.successMessage {
                                Text(success)
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .padding(.horizontal)
                            }
                            
                            // Section 2: Manual Log Input Form
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ADD MANUAL FOOD ITEM")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .tracking(2)
                                    .foregroundStyle(.gray)
                                
                                Group {
                                    TextField("Food Name (e.g. Greek Yogurt)", text: $viewModel.itemName)
                                    TextField("Brand (Optional)", text: $viewModel.itemBrand)
                                }
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .foregroundStyle(.white)
                                
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Calories").font(.caption2).foregroundColor(.gray)
                                        TextField("0", text: $viewModel.itemCalories)
                                            .numericKeyboard()
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Protein (g)").font(.caption2).foregroundColor(.gray)
                                        TextField("0", text: $viewModel.itemProtein)
                                            .numericKeyboard()
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Carbs (g)").font(.caption2).foregroundColor(.gray)
                                        TextField("0", text: $viewModel.itemCarbs)
                                            .numericKeyboard()
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Fat (g)").font(.caption2).foregroundColor(.gray)
                                        TextField("0", text: $viewModel.itemFat)
                                            .numericKeyboard()
                                    }
                                }
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(8)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    viewModel.addManualItem()
                                }) {
                                    Text("Add to Plate")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, height: 40)
                                        .background(Color.purple.opacity(0.3))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                                        )
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(15)
                            .padding(.horizontal)
                            
                            // Section 3: Current Plate Items
                            VStack(alignment: .leading, spacing: 10) {
                                Text("YOUR CURRENT PLATE (\(viewModel.items.count) ITEMS)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .tracking(2)
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal)
                                
                                if viewModel.items.isEmpty {
                                    Text("No food items added yet. Scan a barcode or enter macro details manually to compose your meal.")
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white.opacity(0.01))
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                } else {
                                    ForEach(viewModel.items) { item in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name)
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                if let brand = item.brand {
                                                    Text(brand)
                                                        .font(.system(size: 10))
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            Spacer()
                                            
                                            HStack(spacing: 8) {
                                                Text("\(Int(item.macros.calories)) kcal")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                Text("P: \(Int(item.macros.protein))g")
                                                    .font(.caption2)
                                                    .foregroundColor(.orange)
                                                Text("C: \(Int(item.macros.carbs))g")
                                                    .font(.caption2)
                                                    .foregroundColor(.green)
                                                Text("F: \(Int(item.macros.fat))g")
                                                    .font(.caption2)
                                                    .foregroundColor(.yellow)
                                            }
                                        }
                                        .padding(10)
                                        .background(Color.white.opacity(0.03))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                    .onDelete(perform: viewModel.removeItem)
                                }
                            }
                        }
                    }
                    
                    // Submit Meal Button
                    Button(action: {
                        viewModel.submitMeal()
                        dismiss()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Log and Sync Meal")
                            }
                        }
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, height: 50)
                        .background(viewModel.items.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                    .disabled(viewModel.items.isEmpty || viewModel.isLoading)
                }
            }
            .navigationTitle("Log Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func numericKeyboard() -> some View {
        #if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
    
    @ViewBuilder
    func integerKeyboard() -> some View {
        #if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
        self.keyboardType(.numberPad)
        #else
        self
        #endif
    }
}
