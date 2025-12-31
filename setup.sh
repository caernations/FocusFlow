#!/bin/bash

echo "🚀 FocusFlow Setup Script"
echo "=========================="
echo ""

# Step 1: Generate dataset
echo "📊 Step 1: Generating ML training dataset..."
cd MLTraining
swift DatasetGenerator.swift
if [ ! -f "GeneratedDataset.csv" ]; then
    echo "❌ Dataset generation failed"
    exit 1
fi
echo "✅ Dataset generated"
echo ""

# Step 2: Train models (requires macOS with CreateML)
echo "🤖 Step 2: Training ML models..."
echo "Note: This requires macOS 12+ with CreateML framework"
echo "If this fails, you can skip ML models - the app uses fallback heuristics"
echo ""

swift TrainModels.swift 2>&1
if [ -f "FocusClassifier.mlmodel" ] && [ -f "FocusScoreRegressor.mlmodel" ]; then
    echo "✅ Models trained successfully"
    echo ""
    echo "📦 Step 3: To add models to Xcode:"
    echo "   1. Open FocusFlow.xcodeproj in Xcode"
    echo "   2. Drag FocusClassifier.mlmodel and FocusScoreRegressor.mlmodel into the project"
    echo "   3. Ensure they are added to FocusFlow target"
else
    echo "⚠️  ML training skipped or failed"
    echo "   App will use fallback heuristics (still works!)"
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "Next steps:"
echo "   1. Open FocusFlow.xcodeproj in Xcode"
echo "   2. Build and run (Cmd+R)"
echo "   3. Start a focus session to test"
