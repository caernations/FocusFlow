import Foundation
import CoreML

/// ML Design Decision: Using tabular models for interpretability and speed
/// - Classification: Predicts focus quality category
/// - Regression: Predicts continuous focus score
/// - Both models use same input features for consistency
/// - On-device inference ensures privacy and low latency (<10ms)

class MLManager {
    static let shared = MLManager()

    // Model instances (lazy loaded)
    private var classificationModel: FocusClassifier?
    private var regressionModel: FocusScoreRegressor?

    private init() {
        loadModels()
    }

    // MARK: - Model Loading

    /// Load Core ML models (called on init)
    private func loadModels() {
        do {
            // Load classification model
            let classifierConfig = MLModelConfiguration()
            classifierConfig.computeUnits = .all // Use Neural Engine if available
            self.classificationModel = try FocusClassifier(configuration: classifierConfig)
            print("✅ Classification model loaded")
        } catch {
            print("❌ Failed to load classification model: \(error)")
            print("   Note: Run MLTraining scripts and add .mlmodel files to Xcode")
        }

        do {
            // Load regression model
            let regressorConfig = MLModelConfiguration()
            regressorConfig.computeUnits = .all
            self.regressionModel = try FocusScoreRegressor(configuration: regressorConfig)
            print("✅ Regression model loaded")
        } catch {
            print("❌ Failed to load regression model: \(error)")
            print("   Note: Run MLTraining scripts and add .mlmodel files to Xcode")
        }
    }

    // MARK: - Inference

    /// Predict focus category and score for a session
    func predict(for session: FocusSession) -> (category: String, score: Double)? {
        // Classify session
        guard let category = predictCategory(for: session) else {
            print("⚠️ Classification failed")
            return nil
        }

        // Predict score
        guard let score = predictScore(for: session) else {
            print("⚠️ Regression failed")
            return nil
        }

        return (category, score)
    }

    /// Predict focus category only
    private func predictCategory(for session: FocusSession) -> String? {
        guard let model = classificationModel else {
            print("⚠️ Classification model not loaded")
            return fallbackClassification(for: session)
        }

        do {
            // Create input
            let input = FocusClassifierInput(
                session_duration: Int64(session.sessionDuration),
                app_switch_count: Int64(session.appSwitchCount),
                screen_lock_count: Int64(session.screenLockCount),
                start_hour: Int64(session.startHour),
                day_of_week: Int64(session.dayOfWeek),
                notification_count: Int64(session.notificationCount)
            )

            // Run inference
            let prediction = try model.prediction(input: input)
            return prediction.label

        } catch {
            print("❌ Prediction error: \(error)")
            return fallbackClassification(for: session)
        }
    }

    /// Predict focus score only
    private func predictScore(for session: FocusSession) -> Double? {
        guard let model = regressionModel else {
            print("⚠️ Regression model not loaded")
            return session.computeFocusScore()
        }

        do {
            // Create input
            let input = FocusScoreRegressorInput(
                session_duration: Int64(session.sessionDuration),
                app_switch_count: Int64(session.appSwitchCount),
                screen_lock_count: Int64(session.screenLockCount),
                start_hour: Int64(session.startHour),
                day_of_week: Int64(session.dayOfWeek),
                notification_count: Int64(session.notificationCount)
            )

            // Run inference
            let prediction = try model.prediction(input: input)
            return prediction.focus_score

        } catch {
            print("❌ Prediction error: \(error)")
            return session.computeFocusScore()
        }
    }

    /// Fallback classification using rule-based heuristics
    private func fallbackClassification(for session: FocusSession) -> String {
        return session.computeGroundTruthLabel()
    }

    // MARK: - Batch Prediction

    /// Predict for multiple sessions (useful for analytics)
    func predictBatch(sessions: [FocusSession]) -> [(session: FocusSession, category: String, score: Double)] {
        return sessions.compactMap { session in
            guard let prediction = predict(for: session) else { return nil }
            return (session, prediction.category, prediction.score)
        }
    }

    // MARK: - Model Info

    /// Check if models are loaded
    var modelsLoaded: Bool {
        return classificationModel != nil && regressionModel != nil
    }

    /// Get model metadata
    func getModelInfo() -> String {
        var info = "ML Models Status:\n"
        info += classificationModel != nil ? "✅ Classifier: Loaded\n" : "❌ Classifier: Not loaded\n"
        info += regressionModel != nil ? "✅ Regressor: Loaded\n" : "❌ Regressor: Not loaded\n"
        return info
    }
}

// MARK: - Placeholder Model Classes (will be auto-generated by Xcode)
// These are placeholders until .mlmodel files are added to the project

/// Placeholder for auto-generated FocusClassifier class
/// Xcode will generate this when FocusClassifier.mlmodel is added
class FocusClassifier {
    init(configuration: MLModelConfiguration) throws {
        throw NSError(domain: "MLManager", code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "Model file not found. Add FocusClassifier.mlmodel to project."])
    }

    func prediction(input: FocusClassifierInput) throws -> FocusClassifierOutput {
        throw NSError(domain: "MLManager", code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
    }
}

struct FocusClassifierInput {
    let session_duration: Int64
    let app_switch_count: Int64
    let screen_lock_count: Int64
    let start_hour: Int64
    let day_of_week: Int64
    let notification_count: Int64
}

struct FocusClassifierOutput {
    let label: String
}

/// Placeholder for auto-generated FocusScoreRegressor class
class FocusScoreRegressor {
    init(configuration: MLModelConfiguration) throws {
        throw NSError(domain: "MLManager", code: 2,
                     userInfo: [NSLocalizedDescriptionKey: "Model file not found. Add FocusScoreRegressor.mlmodel to project."])
    }

    func prediction(input: FocusScoreRegressorInput) throws -> FocusScoreRegressorOutput {
        throw NSError(domain: "MLManager", code: 2,
                     userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
    }
}

struct FocusScoreRegressorInput {
    let session_duration: Int64
    let app_switch_count: Int64
    let screen_lock_count: Int64
    let start_hour: Int64
    let day_of_week: Int64
    let notification_count: Int64
}

struct FocusScoreRegressorOutput {
    let focus_score: Double
}
