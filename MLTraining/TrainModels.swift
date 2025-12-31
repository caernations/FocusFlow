#!/usr/bin/env swift
//
//  TrainModels.swift
//  FocusFlow ML Training
//
//  Trains classification and regression models using Create ML
//  Run: swift TrainModels.swift
//
//  Prerequisites: macOS 12.0+, Xcode Command Line Tools
//

import Foundation
import CreateML

// MARK: - Model Training
class FocusFlowMLTrainer {
    let datasetPath: String
    let outputDirectory: String

    init(datasetPath: String, outputDirectory: String = ".") {
        self.datasetPath = datasetPath
        self.outputDirectory = outputDirectory
    }

    /// Train classification model (DeepFocus, ShallowFocus, Distracted)
    func trainClassificationModel() {
        print("\n🎯 Training Classification Model")
        print("=================================")

        do {
            // Load data
            print("📂 Loading dataset from: \(datasetPath)")
            let data = try MLDataTable(contentsOf: URL(fileURLWithPath: datasetPath))

            // Split into training and validation (80/20 split)
            let (trainingData, validationData) = data.randomSplit(by: 0.8, seed: 42)

            print("📊 Training samples: \(trainingData.rows.count)")
            print("📊 Validation samples: \(validationData.rows.count)")

            // Define features
            let featureColumns = [
                "session_duration",
                "app_switch_count",
                "screen_lock_count",
                "start_hour",
                "day_of_week",
                "notification_count"
            ]

            // Train model
            print("\n🔧 Training classifier...")
            let classifier = try MLClassifier(
                trainingData: trainingData,
                targetColumn: "label",
                featureColumns: featureColumns
            )

            // Evaluate
            print("\n📈 Model Evaluation:")
            let evaluation = classifier.evaluation(on: validationData)
            print("   Validation Accuracy: \(String(format: "%.2f%%", evaluation.classificationError * 100))")

            // Training metrics
            let trainingMetrics = classifier.trainingMetrics
            print("   Training Accuracy: \(String(format: "%.2f%%", trainingMetrics.classificationError * 100))")

            // Save model
            let modelPath = (outputDirectory as NSString).appendingPathComponent("FocusClassifier.mlmodel")
            try classifier.write(to: URL(fileURLWithPath: modelPath))

            print("\n✅ Classification model saved: \(modelPath)")

            // Print confusion matrix insights
            if let confusionMatrix = try? evaluation.confusion {
                print("\n📊 Confusion Matrix:")
                print(confusionMatrix)
            }

        } catch {
            print("❌ Error training classification model: \(error)")
        }
    }

    /// Train regression model (focus_score prediction)
    func trainRegressionModel() {
        print("\n📊 Training Regression Model")
        print("=============================")

        do {
            // Load data
            print("📂 Loading dataset from: \(datasetPath)")
            let data = try MLDataTable(contentsOf: URL(fileURLWithPath: datasetPath))

            // Split into training and validation (80/20 split)
            let (trainingData, validationData) = data.randomSplit(by: 0.8, seed: 42)

            print("📊 Training samples: \(trainingData.rows.count)")
            print("📊 Validation samples: \(validationData.rows.count)")

            // Define features
            let featureColumns = [
                "session_duration",
                "app_switch_count",
                "screen_lock_count",
                "start_hour",
                "day_of_week",
                "notification_count"
            ]

            // Train model
            print("\n🔧 Training regressor...")
            let regressor = try MLRegressor(
                trainingData: trainingData,
                targetColumn: "focus_score",
                featureColumns: featureColumns
            )

            // Evaluate
            print("\n📈 Model Evaluation:")
            let evaluation = regressor.evaluation(on: validationData)
            print("   Validation RMSE: \(String(format: "%.4f", evaluation.rootMeanSquaredError))")
            print("   Max Error: \(String(format: "%.4f", evaluation.maximumError))")

            // Training metrics
            let trainingMetrics = regressor.trainingMetrics
            print("   Training RMSE: \(String(format: "%.4f", trainingMetrics.rootMeanSquaredError))")

            // Save model
            let modelPath = (outputDirectory as NSString).appendingPathComponent("FocusScoreRegressor.mlmodel")
            try regressor.write(to: URL(fileURLWithPath: modelPath))

            print("\n✅ Regression model saved: \(modelPath)")

        } catch {
            print("❌ Error training regression model: \(error)")
        }
    }

    /// Train both models
    func trainAll() {
        print("🚀 FocusFlow ML Training Pipeline")
        print("==================================\n")

        // Verify dataset exists
        guard FileManager.default.fileExists(atPath: datasetPath) else {
            print("❌ Error: Dataset not found at \(datasetPath)")
            print("   Please run DatasetGenerator.swift first")
            return
        }

        // Train classification model
        trainClassificationModel()

        // Train regression model
        trainRegressionModel()

        print("\n✨ Training complete!")
        print("\n📝 Next steps:")
        print("   1. Copy .mlmodel files to Xcode project")
        print("   2. Add models to target membership")
        print("   3. Build and run app")
    }
}

// MARK: - Main Execution
let currentPath = FileManager.default.currentDirectoryPath
let datasetPath = (currentPath as NSString).appendingPathComponent("GeneratedDataset.csv")

// Check if dataset exists
if !FileManager.default.fileExists(atPath: datasetPath) {
    print("⚠️  Dataset not found. Generating dataset first...")
    print("    Run: swift DatasetGenerator.swift\n")
    exit(1)
}

let trainer = FocusFlowMLTrainer(
    datasetPath: datasetPath,
    outputDirectory: currentPath
)

trainer.trainAll()

print("\n🎉 All models trained successfully!")
print("📦 Models ready for integration into FocusFlow app")
