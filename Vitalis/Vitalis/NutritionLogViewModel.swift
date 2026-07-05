import Foundation
import Observation
import VitalisCore
import VitalisPersistence

@Observable
public final class NutritionLogViewModel {
    private let nutritionRepository: NutritionRepositoryProtocol
    
    public var items: [FoodItem] = []
    public var barcodeInput: String = ""
    public var isBarcodeMethod = false
    
    // Manual item form bindings
    public var itemName: String = ""
    public var itemBrand: String = ""
    public var itemCalories: String = ""
    public var itemProtein: String = ""
    public var itemCarbs: String = ""
    public var itemFat: String = ""
    
    // UI state
    public var isLoading = false
    public var errorMessage: String? = nil
    public var successMessage: String? = nil
    
    public init(nutritionRepository: NutritionRepositoryProtocol) {
        self.nutritionRepository = nutritionRepository
    }
    
    public func addManualItem() {
        errorMessage = nil
        successMessage = nil
        
        guard !itemName.isEmpty else {
            errorMessage = "Food name is required"
            return
        }
        
        let cals = Double(itemCalories) ?? 0.0
        let prot = Double(itemProtein) ?? 0.0
        let carbs = Double(itemCarbs) ?? 0.0
        let fat = Double(itemFat) ?? 0.0
        
        let macros = Macros(calories: cals, carbs: carbs, fat: fat, protein: prot)
        let brand = itemBrand.isEmpty ? nil : itemBrand
        
        let item = FoodItem(
            name: itemName,
            brand: brand,
            macros: macros
        )
        
        items.append(item)
        
        // Clear manual inputs
        itemName = ""
        itemBrand = ""
        itemCalories = ""
        itemProtein = ""
        itemCarbs = ""
        itemFat = ""
        
        successMessage = "Added manual item!"
    }
    
    public func simulateBarcodeScan() {
        errorMessage = nil
        successMessage = nil
        
        guard !barcodeInput.isEmpty else { return }
        
        // Define mock lookup table
        let mockBarcodes: [String: (name: String, brand: String, calories: Double, carbs: Double, fat: Double, protein: Double)] = [
            "0123456789": ("Steel Cut Oats", "Quaker Oats", 150.0, 27.0, 3.0, 6.0),
            "9876543210": ("Whey Protein Shake", "Optimum Nutrition", 130.0, 3.0, 1.5, 25.0)
        ]
        
        if let match = mockBarcodes[barcodeInput] {
            let macros = Macros(calories: match.calories, carbs: match.carbs, fat: match.fat, protein: match.protein)
            let item = FoodItem(
                name: match.name,
                brand: match.brand,
                macros: macros,
                confidenceScore: 1.0
            )
            items.append(item)
            barcodeInput = ""
            isBarcodeMethod = true
            successMessage = "Scanned \(match.name) successfully!"
        } else {
            errorMessage = "Barcode \(barcodeInput) not found in database. Enter macro details manually below."
        }
    }
    
    public func submitMeal() {
        guard !items.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        let method: LoggingMethod = isBarcodeMethod ? .barcode : .manual
        
        Task {
            do {
                try await nutritionRepository.logMeal(method: method, items: items)
                await MainActor.run {
                    self.items.removeAll()
                    self.isBarcodeMethod = false
                    self.isLoading = false
                    self.successMessage = "Meal logged successfully!"
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    public func removeItem(at offsets: IndexSet) {
        for index in offsets.sorted().reversed() {
            if index < items.count {
                items.remove(at: index)
            }
        }
        if items.isEmpty {
            isBarcodeMethod = false
        }
    }
}
