# FocusFlow Setup Guide

Complete step-by-step instructions to build and run FocusFlow.

---

## Prerequisites

### Required Software
- **macOS 12.0 or later** (Monterey, Ventura, or Sonoma)
- **Xcode 14.0 or later**
- **Command Line Tools** for Xcode
- **iOS Simulator** or physical iOS device (iOS 15.0+)

### Install Xcode Command Line Tools
```bash
xcode-select --install
```

Verify installation:
```bash
swift --version
# Should output: Swift version 5.x or later
```

---

## Step 1: Generate ML Training Dataset

### Navigate to ML Training Directory
```bash
cd FocusFlow/MLTraining
```

### Run Dataset Generator
```bash
swift DatasetGenerator.swift
```

**Expected Output:**
```
🚀 FocusFlow Dataset Generator
==============================

✅ Dataset generated successfully: GeneratedDataset.csv
   Total samples: 500
   DeepFocus: 150
   ShallowFocus: 250
   Distracted: 100

📊 Sample data preview:
First 5 rows:
  [1] Duration: 2156s, Switches: 1, Label: DeepFocus, Score: 0.78
  [2] Duration: 823s, Switches: 3, Label: ShallowFocus, Score: 0.54
  ...

✨ Done! Ready for Create ML training.
```

### Verify CSV Creation
```bash
ls -lh GeneratedDataset.csv
# Should show ~40-50KB file

head -n 5 GeneratedDataset.csv
# Should show CSV header + data rows
```

---

## Step 2: Train ML Models

### Run Model Training Script
```bash
swift TrainModels.swift
```

**Expected Output:**
```
🚀 FocusFlow ML Training Pipeline
==================================

🎯 Training Classification Model
=================================
📂 Loading dataset from: .../GeneratedDataset.csv
📊 Training samples: 400
📊 Validation samples: 100

🔧 Training classifier...
📈 Model Evaluation:
   Validation Accuracy: 88.00%
   Training Accuracy: 92.00%

✅ Classification model saved: FocusClassifier.mlmodel

📊 Training Regression Model
=============================
📂 Loading dataset from: .../GeneratedDataset.csv
📊 Training samples: 400
📊 Validation samples: 100

🔧 Training regressor...
📈 Model Evaluation:
   Validation RMSE: 0.0987
   Max Error: 0.2134
   Training RMSE: 0.0756

✅ Regression model saved: FocusScoreRegressor.mlmodel

✨ Training complete!

📝 Next steps:
   1. Copy .mlmodel files to Xcode project
   2. Add models to target membership
   3. Build and run app

🎉 All models trained successfully!
```

### Verify Model Files
```bash
ls -lh *.mlmodel
# Should show two files:
# FocusClassifier.mlmodel      (~30-50KB)
# FocusScoreRegressor.mlmodel  (~30-50KB)
```

---

## Step 3: Add ML Models to Xcode Project

### Option A: Using Xcode GUI (Recommended)

1. **Open Xcode Project**
   ```bash
   cd ../..  # Return to project root
   open FocusFlow.xcodeproj
   ```

2. **Add Model Files**
   - In Xcode, select `FocusFlow` folder in Project Navigator
   - Right-click → "Add Files to 'FocusFlow'..."
   - Navigate to `MLTraining/` folder
   - Select both `.mlmodel` files:
     - `FocusClassifier.mlmodel`
     - `FocusScoreRegressor.mlmodel`
   - ✅ Check "Copy items if needed"
   - ✅ Ensure "FocusFlow" target is selected
   - Click "Add"

3. **Verify Target Membership**
   - Click on each `.mlmodel` file in Project Navigator
   - In File Inspector (right panel), verify "Target Membership"
   - ✅ "FocusFlow" should be checked

4. **Check Auto-Generated Interfaces**
   - Click on `FocusClassifier.mlmodel`
   - Select "Predictions" tab
   - You should see auto-generated Swift class interface
   - Repeat for `FocusScoreRegressor.mlmodel`

### Option B: Manual File Copy

```bash
# From project root
cp MLTraining/FocusClassifier.mlmodel FocusFlow/Resources/
cp MLTraining/FocusScoreRegressor.mlmodel FocusFlow/Resources/

# Then add to Xcode project via GUI (Option A, step 2)
```

---

## Step 4: Build the Project

### Clean Build Folder (Recommended)
In Xcode:
- **Product → Clean Build Folder** (or `Cmd+Shift+K`)

### Build for Simulator
```bash
# From command line
xcodebuild -project FocusFlow.xcodeproj \
           -scheme FocusFlow \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           clean build
```

Or in Xcode:
- Select **iPhone 15** simulator
- **Product → Build** (or `Cmd+B`)

**Expected Output:**
```
Build Succeeded
```

### Troubleshooting Build Errors

#### Error: "Model file not found"
**Solution:**
- Verify `.mlmodel` files are in project
- Check target membership is enabled
- Clean and rebuild

#### Error: "Ambiguous use of FocusClassifier"
**Solution:**
- Delete placeholder classes in `MLManager.swift` (lines 100-150)
- Xcode auto-generates these from `.mlmodel` files
- Keep placeholder classes ONLY if models are not added yet

#### Error: "Core Data model not found"
**Solution:**
- Verify `FocusFlow.xcdatamodeld` exists in Resources/
- Check target membership
- Clean and rebuild

---

## Step 5: Run the App

### Launch in Simulator

**Option A: Xcode**
1. Select **iPhone 15** (or any iOS 15+ simulator)
2. Click **Run** button (▶) or press `Cmd+R`

**Option B: Command Line**
```bash
xcodebuild -project FocusFlow.xcodeproj \
           -scheme FocusFlow \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           run
```

### Launch on Physical Device

1. Connect iPhone/iPad via USB
2. In Xcode, select your device from device menu
3. **Signing & Capabilities** tab:
   - Select your Apple Developer account
   - Choose provisioning profile
4. Click **Run** (▶)

**First Launch:**
- iOS may prompt "Developer Mode" requirement
- Enable in Settings → Privacy & Security → Developer Mode
- Restart device

---

## Step 6: Test the App

### First Run Checklist

1. **App Launches Successfully**
   - No crash on launch
   - Three tabs visible: Focus, Analytics, Insights

2. **Focus Tab**
   - Timer displays "25:00"
   - "Start Focus" button present
   - Metrics cards show "0"

3. **Start a Test Session**
   - Tap "Start Focus"
   - Timer counts down
   - Session metrics increment (simulated)
   - Tap "End" after 10-20 seconds

4. **Verify ML Prediction**
   - "Session Complete!" card appears
   - Shows predicted category (likely "Distracted" for short session)
   - Shows focus score (likely low, ~20-40%)

5. **Check Analytics Tab**
   - Navigate to "Analytics"
   - "Total Sessions" shows 1
   - Session appears in "Top Performing Sessions"

6. **Check Insights Tab**
   - Navigate to "Insights"
   - May show "Not Enough Data Yet" (need 5+ sessions)
   - Complete more sessions to see insights

### Console Output

In Xcode console, you should see:
```
✅ Classification model loaded
✅ Regression model loaded
🎯 Session classified as: Distracted
📊 Focus score: 0.32
```

If you see model loading errors:
```
❌ Failed to load classification model
   Note: Run MLTraining scripts and add .mlmodel files to Xcode
```
→ Revisit Step 3

---

## Step 7: Generate More Sessions (Optional)

To test analytics and insights, generate multiple sessions:

### Quick Test Sessions

1. **Varied Durations**
   - Short session: 5 minutes → Distracted
   - Medium session: 15 minutes → ShallowFocus
   - Long session: 30 minutes → DeepFocus

2. **Increment Metrics**
   - During session, simulate behaviors:
   - App switches (increment counter)
   - Notifications (increment counter)
   - Observe impact on predictions

3. **Different Times of Day**
   - Change system time (Simulator)
   - Complete sessions at different hours
   - Check hourly distribution chart

### Insights Trigger

After **5+ diverse sessions**, insights should appear:
- Peak focus hours
- Notification impact
- App switching patterns

---

## Customization Guide

### Change Default Timer Duration

**File:** `FocusFlow/ViewModels/FocusTimerViewModel.swift`

```swift
// Line ~15
@Published var timeRemaining: TimeInterval = 25 * 60 // Change this

// Example: 50 minutes
@Published var timeRemaining: TimeInterval = 50 * 60
```

### Adjust Color Scheme

**File:** `FocusFlow/Utilities/Extensions.swift`

```swift
// Lines ~60-70
static func categoryColor(for category: String) -> Color {
    switch category {
    case "DeepFocus":
        return .green  // Change to .purple, .blue, etc.
    // ...
    }
}
```

### Modify Classification Rules

**File:** `FocusFlow/Models/FocusSession.swift`

```swift
// Lines ~45-55
func computeGroundTruthLabel() -> String {
    if sessionDuration > 1500 && appSwitchCount < 2 {
        return "DeepFocus"  // Adjust thresholds
    }
    // ...
}
```

**After modifying rules:**
1. Regenerate dataset (Step 1)
2. Retrain models (Step 2)
3. Replace `.mlmodel` files in Xcode (Step 3)
4. Rebuild app (Step 4)

---

## Troubleshooting Common Issues

### App Crashes on Launch

**Symptom:** App opens briefly then closes

**Solutions:**
1. Check Xcode console for error messages
2. Verify Core Data model is in project
3. Clean build folder and rebuild
4. Delete app from simulator and reinstall

### No Data in Analytics

**Symptom:** Analytics shows "0 sessions"

**Solutions:**
1. Complete at least one focus session
2. Check selected time range (default: Week)
3. Verify Core Data is saving (check console logs)

### Charts Not Rendering

**Symptom:** Charts show empty or missing

**Solutions:**
1. Ensure iOS 16.0+ for Swift Charts
2. Check deployment target in Xcode
3. Complete multiple sessions for meaningful data
4. Verify session has predictions (category + score)

### Models Not Loading

**Symptom:** Console shows "Model file not found"

**Solutions:**
1. Verify both `.mlmodel` files are in Xcode project
2. Check target membership is enabled
3. Rebuild project (Cmd+Shift+K → Cmd+B)
4. If models still fail, app uses fallback heuristics (still works)

### Insights Not Appearing

**Symptom:** "Not Enough Data Yet" message

**Expected Behavior:**
- Need 5+ sessions for most insights
- Need diverse session types
- Need sessions at different hours/days

**Solutions:**
1. Complete more focus sessions
2. Vary session durations (short, medium, long)
3. Complete sessions at different times
4. Check console for insight generation logs

---

## Development Workflow

### Iterating on ML Models

1. **Modify Dataset Generation**
   ```bash
   cd MLTraining
   # Edit DatasetGenerator.swift
   swift DatasetGenerator.swift
   ```

2. **Retrain Models**
   ```bash
   swift TrainModels.swift
   ```

3. **Update Xcode**
   - Delete old `.mlmodel` files from Xcode
   - Add new `.mlmodel` files
   - Clean and rebuild

4. **Test Predictions**
   - Delete app data (reset simulator)
   - Run new sessions
   - Verify predictions match expectations

### Testing with Real Data

To test with your own data:

1. **Export Template CSV**
   ```bash
   head -n 1 MLTraining/GeneratedDataset.csv > my_data.csv
   ```

2. **Add Your Sessions**
   - Edit `my_data.csv` manually
   - Follow CSV format exactly

3. **Train Models**
   ```bash
   cd MLTraining
   swift TrainModels.swift  # Modify to load your CSV
   ```

---

## Next Steps

### Extend the App

**Feature Ideas:**
- [ ] Export sessions to CSV
- [ ] Custom timer durations (UI picker)
- [ ] Session notes/tags
- [ ] Focus streaks & achievements
- [ ] Widget support
- [ ] Apple Watch companion app
- [ ] Dark mode customization
- [ ] CloudKit sync across devices

### Integrate Real APIs

**Production Enhancements:**
- [ ] Screen Time API for real app usage
- [ ] UNUserNotificationCenter for notification count
- [ ] Background tasks for screen lock detection
- [ ] HealthKit integration (heart rate, sleep)
- [ ] Focus Mode integration (iOS 15+)

### ML Improvements

- [ ] User feedback on predictions (active learning)
- [ ] Personalized models per user
- [ ] Session sequence analysis (LSTM)
- [ ] Anomaly detection (unusual patterns)
- [ ] Model A/B testing

---

## Resources

### Documentation
- **README.md**: Project overview
- **ML_PIPELINE_EXPLAINED.md**: Deep dive into ML design
- **MLTraining/README.md**: ML training specifics

### Code Files
- **Models/**: Core Data schema
- **ViewModels/**: Business logic
- **Views/**: SwiftUI UI
- **ML/**: Core ML integration

### Apple Documentation
- [Core ML Documentation](https://developer.apple.com/documentation/coreml)
- [Create ML Documentation](https://developer.apple.com/documentation/createml)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Core Data Documentation](https://developer.apple.com/documentation/coredata)

---

## Support

### Issues?

1. **Check console logs** in Xcode
2. **Review documentation** in this repo
3. **Verify all setup steps** were completed
4. **Clean and rebuild** project
5. **Reset simulator** if needed

### Success Checklist

✅ Dataset generated (500 samples)
✅ Models trained (2 `.mlmodel` files)
✅ Models added to Xcode project
✅ App builds without errors
✅ App launches in simulator
✅ First session completes successfully
✅ ML predictions appear
✅ Analytics show session data
✅ Insights generate after 5+ sessions

**All checked? You're ready to build amazing focus apps!** 🎯
