# FocusFlow ML Training Pipeline

This directory contains the complete machine learning pipeline for FocusFlow, including dataset generation and model training using Create ML.

## Overview

The ML pipeline consists of two main components:

1. **DatasetGenerator.swift** - Generates synthetic focus session data with realistic distributions
2. **TrainModels.swift** - Trains classification and regression models using Create ML

## Quick Start

### 1. Generate Dataset

```bash
cd MLTraining
swift DatasetGenerator.swift
```

This creates `GeneratedDataset.csv` with 500 focus sessions containing:
- Realistic behavioral patterns (app switches, notifications, etc.)
- Time-based features (hour, day of week)
- Ground truth labels and focus scores

### 2. Train Models

```bash
swift TrainModels.swift
```

This generates two Core ML models:
- **FocusClassifier.mlmodel** - Classifies sessions into DeepFocus/ShallowFocus/Distracted
- **FocusScoreRegressor.mlmodel** - Predicts focus score (0.0-1.0)

### 3. Integrate into Xcode

1. Drag `.mlmodel` files into Xcode project
2. Ensure they're added to target membership
3. Xcode auto-generates Swift interfaces
4. Models are ready for on-device inference

## Dataset Schema

### Input Features
- `session_duration` (Int) - Session length in seconds
- `app_switch_count` (Int) - Number of app switches during session
- `screen_lock_count` (Int) - Number of screen locks
- `start_hour` (Int, 0-23) - Hour session started
- `day_of_week` (Int, 0-6) - Day of week (0=Sunday)
- `notification_count` (Int) - Notifications received

### Labels
- `label` (String) - Classification: DeepFocus, ShallowFocus, or Distracted
- `focus_score` (Double, 0.0-1.0) - Regression target

## Label Generation Logic

### Classification Rules
```
DeepFocus:
  - duration > 1500s (25+ minutes) AND
  - app_switch_count < 2

ShallowFocus:
  - duration between 600-1500s (10-25 minutes)

Distracted:
  - duration < 600s (< 10 minutes) OR
  - app_switch_count > 5
```

### Focus Score Formula
```
focus_score = weighted_sum(
  normalized_duration * 0.4,
  app_switch_penalty * 0.3,
  notification_penalty * 0.2,
  screen_lock_penalty * 0.1
)

Penalties:
- app_switch_penalty = exp(-app_switch_count * 0.3)
- notification_penalty = max(0, 1.0 - notification_count * 0.1)
- screen_lock_penalty = max(0, 1.0 - screen_lock_count * 0.15)
```

## Data Distribution

The generator creates realistic distributions:

### Session Types
- 30% DeepFocus
- 50% ShallowFocus
- 20% Distracted

### Time Patterns
- 40% morning (9-11 AM)
- 30% afternoon (2-4 PM)
- 15% early morning (6-9 AM)
- 15% evening (5-10 PM)

### Days
- 80% weekdays
- 20% weekends

## Model Architecture

Create ML automatically selects optimal algorithms:

### Classification Model
- Algorithm: Boosted Tree (typically)
- Input: 6 numerical features
- Output: 3-class categorical (DeepFocus, ShallowFocus, Distracted)
- Evaluation: Accuracy, confusion matrix

### Regression Model
- Algorithm: Boosted Tree (typically)
- Input: 6 numerical features
- Output: Continuous value [0.0, 1.0]
- Evaluation: RMSE, max error

## Requirements

- macOS 12.0 or later
- Xcode Command Line Tools
- Swift 5.5+
- CreateML framework (included in macOS)

## Privacy & On-Device ML

✅ **All training and inference happens on-device**
- No cloud APIs
- No user data leaves the device
- Models are small (~50KB each)
- Inference is near-instant (<10ms)

## Customization

### Adjust Dataset Size
```swift
let generator = DatasetGenerator(numberOfSamples: 1000)
```

### Modify Label Rules
Edit `computeGroundTruthLabel()` in DatasetGenerator.swift

### Change Feature Engineering
Edit `computeFocusScore()` for different score calculations

## Troubleshooting

### "Dataset not found" error
Run DatasetGenerator.swift before TrainModels.swift

### Import errors in Xcode
Ensure .mlmodel files are added to app target

### Poor model performance
- Increase dataset size (1000+ samples)
- Adjust label generation logic
- Review feature distributions

## Next Steps

After training:
1. Copy models to `FocusFlow/Resources/`
2. Implement `MLManager.swift` for inference
3. Integrate predictions into UI
4. Test with real focus sessions
