#!/bin/bash
# Monitor adb logcat for thumbnail generation and library activity
# This script helps verify the fixes work correctly

echo "========================================="
echo "Thumbnail Generation Monitoring Script"
echo "========================================="
echo ""
echo "Monitoring for:"
echo "✓ Thumbnail generation success"
echo "✓ Cache invalidation"
echo "✓ Library state updates"
echo "✓ Slider value errors"
echo ""
echo "Patterns to watch for:"
echo "  [ThumbnailService] ✓ Thumbnail generated successfully"
echo "  [ThumbnailService] Failed to close PDF:"
echo "  [LibraryNotifier] invalidatePdf"
echo "  allPdfs="
echo "  Value -1.0"
echo ""
echo "Press Ctrl+C to stop monitoring"
echo "========================================="
echo ""

# Clear previous logs
adb logcat -c

# Start monitoring with key patterns
adb logcat -v time | while read line; do
  # Filter for relevant patterns
  if echo "$line" | grep -q -E "Thumbnail|invalidate|Library|allPdfs|slider|Value -1|PdfDocument|pdf"; then
    # Highlight important patterns
    if echo "$line" | grep -q "✓ Thumbnail generated successfully"; then
      echo "🎯 $line"
    elif echo "$line" | grep -q "Failed to close PDF"; then
      echo "⚠️  $line"
    elif echo "$line" | grep -q "invalidatePdf"; then
      echo "🔄 $line"
    elif echo "$line" | grep -q "allPdfs="; then
      echo "📚 $line"
    elif echo "$line" | grep -q "Value -1"; then
      echo "❌ $line"
    elif echo "$line" | grep -q "error\|Error\|ERROR"; then
      echo "💥 $line"
    else
      echo "   $line"
    fi
  fi
done
