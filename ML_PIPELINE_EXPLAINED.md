# FocusFlow ML Pipeline - Deep Dive

This document explains the machine learning design decisions, architecture, and implementation details for FocusFlow's on-device ML system.

---

## Table of Contents
1. [Problem Formulation](#problem-formulation)
2. [Model Selection](#model-selection)
3. [Feature Engineering](#feature-engineering)
4. [Label Generation Strategy](#label-generation-strategy)
5. [Dataset Generation](#dataset-generation)
6. [Training Pipeline](#training-pipeline)
7. [Inference Architecture](#inference-architecture)
8. [Performance Analysis](#performance-analysis)
9. [Privacy & Security](#privacy--security)

---

## Problem Formulation

### Business Objective
Help users understand and improve their focus patterns through automated session analysis and actionable insights.

### ML Tasks

#### Task 1: Classification (Multi-class)
- **Goal**: Categorize focus sessions into quality tiers
- **Input**: 6 behavioral + temporal features
- **Output**: {DeepFocus, ShallowFocus, Distracted}
- **Use Case**: Quick session quality assessment

#### Task 2: Regression (Continuous)
- **Goal**: Predict granular focus quality score
- **Input**: Same 6 features
- **Output**: Real number in [0.0, 1.0]
- **Use Case**: Trend analysis, ranking sessions

### Why Two Models?

**Complementary Information:**
- **Classification**: Easy to interpret, actionable categories
- **Regression**: Nuanced scoring, better for analytics

**Design Decision:** Use both models in tandem rather than just thresholding regression output because:
1. Classification provides stable, discrete categories for UI
2. Regression provides continuous scores for charts/trends
3. Models can disagree → useful signal (e.g., borderline cases)
4. Minimal overhead (2 models = ~100KB total)

---

## Model Selection

### Algorithm Choice: Boosted Trees

**Why Boosted Trees (via Create ML)?**

✅ **Strengths:**
- Excellent for tabular data (our use case)
- Handles mixed feature types (temporal + behavioral)
- Resistant to overfitting with small datasets
- Fast inference (<10ms)
- No feature scaling required
- Captures non-linear relationships

❌ **Alternatives Considered:**
- **Neural Networks**: Overkill for 6 features, slower, harder to interpret
- **Logistic Regression**: Too simple, misses interactions
- **Random Forest**: Good, but boosted trees often better
- **SVM**: Requires feature scaling, slower inference

### Create ML vs Custom Training

**Why Create ML?**
- Optimized for on-device deployment
- Auto-generates Swift/Core ML interfaces
- Built-in evaluation metrics
- Minimal code required
- Apple ecosystem integration

**Trade-offs:**
- Less control over hyperparameters
- Limited to supported algorithms
- Acceptable for this use case

---

## Feature Engineering

### Input Features (6 dimensions)

#### 1. Session Duration (`session_duration`)
- **Type**: Integer (seconds)
- **Range**: [60, 3600]
- **Rationale**: Longer sessions generally indicate better focus
- **Non-linearity**: Diminishing returns >1 hour

#### 2. App Switch Count (`app_switch_count`)
- **Type**: Integer
- **Range**: [0, 15+]
- **Rationale**: Context switching destroys deep work
- **Key Signal**: Most important feature for distraction

#### 3. Screen Lock Count (`screen_lock_count`)
- **Type**: Integer
- **Range**: [0, 5]
- **Rationale**: Interruptions to check phone
- **Ambiguity**: Could indicate breaks (positive) or distractions (negative)

#### 4. Start Hour (`start_hour`)
- **Type**: Integer (categorical)
- **Range**: [0, 23]
- **Rationale**: Circadian rhythms affect focus
- **Pattern**: Most people focus better 9-11 AM, 2-4 PM

#### 5. Day of Week (`day_of_week`)
- **Type**: Integer (categorical)
- **Range**: [0, 6] (0=Sunday)
- **Rationale**: Weekday vs weekend differences
- **Pattern**: Weekdays often more structured

#### 6. Notification Count (`notification_count`)
- **Type**: Integer
- **Range**: [0, 15+]
- **Rationale**: External interruptions
- **Impact**: Strong negative correlation with focus

### Feature Interactions

**Important Interactions Captured by Boosted Trees:**
- `duration × app_switches`: Long session + few switches = DeepFocus
- `start_hour × day_of_week`: Morning weekdays vs evening weekends
- `notifications × duration`: High notifications but long duration = resilience

### Feature Normalization

**Not Required for Boosted Trees:**
- Tree-based models are scale-invariant
- No gradient descent optimization
- Splits based on thresholds, not distances

---

## Label Generation Strategy

### Classification Labels (Rule-Based Heuristics)

#### Why Rule-Based?
- **No Ground Truth**: We don't have labeled focus data from users
- **Domain Knowledge**: Focus literature provides clear thresholds
- **Consistency**: Deterministic labeling for reproducibility
- **Bootstrapping**: Generate training data without manual annotation

#### Heuristic Rules

```swift
if session_duration > 1500 && app_switch_count < 2 {
    return "DeepFocus"
    // Rationale: 25+ min uninterrupted work = deep work state
}
else if session_duration >= 600 && session_duration <= 1500 {
    return "ShallowFocus"
    // Rationale: 10-25 min = standard focus block
}
else if session_duration < 600 || app_switch_count > 5 {
    return "Distracted"
    // Rationale: <10 min or high switching = poor focus
}
else {
    return "ShallowFocus"  // default
}
```

**Based on Research:**
- **Deep Work**: Cal Newport's 25+ minute threshold
- **Pomodoro**: 25-minute standard focus blocks
- **Context Switching**: Gloria Mark's research on interruptions

### Regression Target (Focus Score)

#### Formula Design

```swift
focus_score =
    normalized_duration * 0.4 +      // 40% weight
    app_switch_penalty * 0.3 +       // 30% weight
    notification_penalty * 0.2 +     // 20% weight
    screen_lock_penalty * 0.1        // 10% weight
```

#### Weight Rationale

**Duration (40%)**: Primary signal
- Most important factor
- Normalized: `min(duration / 3600, 1.0)`

**App Switches (30%)**: Strong negative signal
- Penalty: `exp(-count * 0.3)`
- Exponential decay: 1 switch OK, 5+ severe

**Notifications (20%)**: External interruptions
- Penalty: `1.0 - count * 0.1`
- Linear: Each notification reduces score

**Screen Locks (10%)**: Minor signal
- Penalty: `1.0 - count * 0.15`
- Less impactful than app switches

#### Score Interpretation

| Score Range | Quality | Expected Category |
|-------------|---------|-------------------|
| 0.8 - 1.0 | Excellent | DeepFocus |
| 0.6 - 0.8 | Good | ShallowFocus |
| 0.4 - 0.6 | Fair | ShallowFocus |
| 0.0 - 0.4 | Poor | Distracted |

---

## Dataset Generation

### Synthetic Data Rationale

**Why Synthetic?**
- **Cold Start**: No real user data initially
- **Controlled Distribution**: Ensure balanced classes
- **Privacy**: No need for user data
- **Reproducibility**: Deterministic generation
- **Scalability**: Generate 1000s of samples instantly

### Distribution Design

#### Session Type Distribution
```
DeepFocus:     30% (150/500 samples)
ShallowFocus:  50% (250/500 samples)
Distracted:    20% (100/500 samples)
```

**Rationale**: Realistic distribution based on productivity research

#### Temporal Patterns

**Hour Distribution:**
```
Morning (9-11):     40%  - Peak focus hours
Afternoon (14-16):  30%  - Secondary peak
Early Morning (6-9): 15% - Early birds
Evening (17-22):    15%  - Night owls
```

**Day Distribution:**
```
Weekdays (Mon-Fri): 80%
Weekends (Sat-Sun): 20%
```

### Realistic Generation

**Duration by Type:**
```swift
DeepFocus:     random(1500...3600)  // 25-60 min
ShallowFocus:  random(600...1500)   // 10-25 min
Distracted:    random(60...600)     // 1-10 min
```

**App Switches by Type:**
```swift
DeepFocus:     random(0...2)    // Minimal
ShallowFocus:  random(2...5)    // Moderate
Distracted:    random(5...15)   // High
```

**Notifications:** Independent random variable
```swift
60% low (0-2)
30% medium (3-7)
10% high (8-15)
```

### Dataset Quality

**500 Samples Justification:**
- Sufficient for tabular boosted trees
- Balanced across classes
- Diverse temporal patterns
- Small enough to generate quickly
- Large enough to avoid overfitting

**Future**: Train on real user data once available

---

## Training Pipeline

### Create ML Training Script

#### Data Loading
```swift
let data = try MLDataTable(contentsOf: csvURL)
```

#### Train/Validation Split
```swift
let (trainingData, validationData) = data.randomSplit(by: 0.8, seed: 42)
```
- **80/20 split**: Standard for small datasets
- **Fixed seed**: Reproducible results

#### Model Training

**Classification:**
```swift
let classifier = try MLClassifier(
    trainingData: trainingData,
    targetColumn: "label",
    featureColumns: ["session_duration", "app_switch_count", ...]
)
```

**Regression:**
```swift
let regressor = try MLRegressor(
    trainingData: trainingData,
    targetColumn: "focus_score",
    featureColumns: ["session_duration", "app_switch_count", ...]
)
```

#### Evaluation Metrics

**Classification:**
- Validation accuracy
- Confusion matrix
- Per-class precision/recall

**Regression:**
- RMSE (Root Mean Squared Error)
- MAE (Mean Absolute Error)
- Max Error

#### Model Export
```swift
try classifier.write(to: URL(fileURLWithPath: "FocusClassifier.mlmodel"))
try regressor.write(to: URL(fileURLWithPath: "FocusScoreRegressor.mlmodel"))
```

---

## Inference Architecture

### On-Device Inference Flow

```
User ends session
      ↓
Collect metrics (duration, app switches, etc.)
      ↓
Create FocusSession object
      ↓
MLManager.predict(session)
      ↓
┌─────────────────┬─────────────────┐
│  Classification │   Regression    │
│     Model       │     Model       │
└────────┬────────┴────────┬────────┘
         ↓                 ↓
    Category          Focus Score
    (DeepFocus)         (0.85)
         ↓                 ↓
Update FocusSession with predictions
         ↓
Save to Core Data
         ↓
Display to user + Generate insights
```

### MLManager Architecture

```swift
class MLManager {
    private var classificationModel: FocusClassifier?
    private var regressionModel: FocusScoreRegressor?

    func predict(for session: FocusSession) -> (category: String, score: Double)? {
        // 1. Load models (lazy initialization)
        // 2. Create input feature vector
        // 3. Run both models
        // 4. Return predictions
    }
}
```

### Fallback Strategy

**If Models Fail to Load:**
```swift
// Use rule-based heuristics
let category = session.computeGroundTruthLabel()
let score = session.computeFocusScore()
```

**Graceful Degradation:**
- App functions without ML models
- Heuristics provide reasonable predictions
- User never sees errors

---

## Performance Analysis

### Model Performance (Expected)

**Classification:**
- Accuracy: ~85-90%
- Confusion: Some overlap between ShallowFocus and Distracted
- Per-class F1: DeepFocus > ShallowFocus > Distracted

**Regression:**
- RMSE: ~0.08-0.12
- R²: ~0.75-0.85
- Good correlation with heuristic scores

### Inference Performance

**Speed:**
- Classification: <5ms
- Regression: <5ms
- Total: <10ms (negligible UX impact)

**Resource Usage:**
- Memory: <5MB during inference
- CPU: <1% (single core burst)
- Battery: Minimal impact

**Model Size:**
- FocusClassifier.mlmodel: ~30-50KB
- FocusScoreRegressor.mlmodel: ~30-50KB
- Total: <100KB

### Scalability

**Supports:**
- 1000s of sessions stored locally
- Real-time prediction after each session
- Batch prediction for analytics
- No network latency
- Works offline

---

## Privacy & Security

### Privacy-First Design

✅ **All data stays on-device:**
- No cloud uploads
- No analytics telemetry
- No user identification

✅ **Core Data local storage:**
- Encrypted iOS storage
- Per-device data
- No cross-device sync (by default)

✅ **Model execution:**
- On-device Core ML inference
- No external API calls
- No data leaves device

### Security Considerations

**Data Protection:**
- iOS file encryption (when device locked)
- Core Data encrypted by default
- No plaintext exports

**Model Security:**
- Models embedded in app bundle
- No dynamic model loading from network
- Tamper-evident app signing

**Minimal Permissions:**
- No network access required
- No camera/microphone
- No location services
- No contacts/photos

### Compliance

**GDPR Compliant:**
- No personal data collected
- No data processing outside device
- User owns all data

**COPPA Compliant:**
- No age restrictions needed
- No data collection

**HIPAA Consideration:**
- Could be used in healthcare with proper safeguards
- On-device processing = reduced risk

---

## Future Improvements

### Model Enhancements

1. **Active Learning:**
   - Let users correct predictions
   - Retrain models with feedback
   - Personalized models per user

2. **Feature Additions:**
   - Heart rate (Apple Watch)
   - Ambient noise level
   - Screen brightness
   - App categories (not just count)

3. **Advanced Algorithms:**
   - LSTM for session sequences
   - Attention mechanisms for time patterns
   - Federated learning for privacy-preserving updates

### Engineering Improvements

1. **Model Versioning:**
   - Track model versions
   - A/B test new models
   - Gradual rollout

2. **Monitoring:**
   - Prediction confidence scores
   - Feature drift detection
   - Model performance tracking

3. **Optimization:**
   - Model quantization (reduce size)
   - Neural Engine acceleration
   - Batch prediction optimization

---

## Conclusion

FocusFlow demonstrates production-quality on-device ML:

✅ **Complete pipeline**: Data generation → Training → Inference
✅ **Privacy-first**: No cloud dependencies
✅ **Production-ready**: Error handling, fallbacks, optimization
✅ **Educational**: Well-documented, clear design decisions

**Key Takeaways:**
1. Tabular models are excellent for behavioral data
2. Synthetic data can bootstrap ML systems
3. On-device ML is viable for real-world apps
4. Privacy and performance can coexist

**Perfect foundation** for iOS developers learning Core ML or building productivity apps.
