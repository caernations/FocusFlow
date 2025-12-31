# FocusFlow

**Privacy-first iOS productivity app with on-device Core ML**

Pomodoro timer + ML-powered focus analysis. Everything runs on-device.

## Quick Start

```bash
# 1. Generate dataset & train models
./setup.sh

# 2. Open in Xcode
open FocusFlow.xcodeproj

# 3. Build and run
# If ML models are added: Full ML predictions
# If not: App uses fallback heuristics (still works great)
```

## Features

- **Focus Timer**: Pomodoro-style session tracking
- **ML Classification**: DeepFocus / ShallowFocus / Distracted
- **Focus Score**: 0-100% quality rating
- **Analytics**: Charts, trends, session history
- **AI Insights**: Rule-based productivity recommendations

## Tech Stack

- SwiftUI + MVVM
- Core Data persistence
- Core ML inference (<10ms)
- Create ML training (tabular models)
- Swift Charts for analytics

## Project Structure

```
FocusFlow/
├── Models/          # Core Data schema
├── ViewModels/      # Business logic
├── Views/           # SwiftUI UI
├── ML/              # Core ML + insights
└── Resources/       # Assets, data models

MLTraining/
├── DatasetGenerator.swift  # Synthetic data (500 samples)
├── TrainModels.swift       # Create ML training
└── GeneratedDataset.csv    # Training data
```

## How It Works

### Dataset Generation
- 500 synthetic focus sessions
- Realistic behavioral patterns
- Rule-based labels (DeepFocus, ShallowFocus, Distracted)
- Focus score formula based on duration, interruptions

### ML Models
- **Classifier**: Predicts session category (~85-90% accuracy)
- **Regressor**: Predicts focus score (RMSE ~0.08-0.12)
- Both use 6 features: duration, app switches, notifications, etc.

### On-Device Inference
```swift
let prediction = MLManager.shared.predict(for: session)
// Returns (category: "DeepFocus", score: 0.85)
```

## Customization

**Change timer duration:**
```swift
// FocusTimerViewModel.swift line 15
@Published var sessionDuration: TimeInterval = 25 * 60 // seconds
```

**Adjust classification rules:**
```swift
// FocusSession.swift computeGroundTruthLabel()
// Modify thresholds, then regenerate dataset & retrain models
```

## Requirements

- iOS 15.0+
- Xcode 14.0+
- macOS 12.0+ (for Create ML training)

## License

MIT
