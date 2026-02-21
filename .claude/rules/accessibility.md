# Accessibility (A11y) Guidelines

This file contains accessibility standards to ensure the app is usable by everyone.

---

## Core Principles

1. **Perceivable** - Information must be presentable to users in ways they can perceive
2. **Operable** - UI components must be operable by all users
3. **Understandable** - Information and operation must be understandable
4. **Robust** - Content must be robust enough for assistive technologies

---

## Semantics in Flutter

### Use Semantic Widgets

```dart
// ✅ GOOD - explicit semantics
Semantics(
  label: 'Open PDF file',
  hint: 'Double tap to view the PDF document',
  button: true,
  child: PdfCard(pdf: pdf),
)

// ✅ GOOD - use semantic widgets
ElevatedButton(
  onPressed: () => openPdf(pdf),
  child: const Text('Open PDF'),
)

// ❌ BAD - gesture detector without semantics
GestureDetector(
  onTap: () => openPdf(pdf),
  child: PdfCard(pdf: pdf),
)
```

### Add Labels to Custom Widgets

```dart
class PdfCard extends StatelessWidget {
  const PdfCard({super.key, required this.pdf, this.onTap});

  final PdfDocument pdf;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PDF: ${pdf.title}',
      hint: onTap != null ? 'Double tap to open' : null,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Card(child: Text(pdf.title)),
      ),
    );
  }
}
```

---

## Text Scaling

### Support text scaling

```dart
// ✅ GOOD - respects user's text scale settings
Text(
  'My Library',
  style: Theme.of(context).textTheme.titleLarge,
)

// ❌ BAD - hard sizes don't scale
Text(
  'My Library',
  style: TextStyle(fontSize: 24),  // Won't scale!
)
```

### Use MediaQuery for responsive text

```dart
// ✅ GOOD - scales with accessibility settings
Text(
  'My Library',
  style: TextStyle(
    fontSize: 24 * MediaQuery.textScalerOf(context).scale(24),
  ),
)
```

### Set max text scale factor

```dart
MaterialApp(
  builder: (context, child) {
    final textScale = MediaQuery.textScalerOf(context);
    // Prevent extreme text scaling from breaking layout
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        // Clamp text scale between 1.0 and 2.0
        textScaler: TextScaler.linear(
          textScale.scale(1.0).clamp(1.0, 2.0),
        ),
      ),
      child: child!,
    );
  },
)
```

---

## Color and Contrast

### Minimum contrast ratios

| Context | Contrast Ratio |
|---------|---------------|
| Normal text | 4.5:1 |
| Large text (18pt+) | 3:1 |
| UI components | 3:1 |

```dart
// ✅ GOOD - high contrast colors
const TextStyle(
  color: Color(0xFF000000),  // On white background
)

// ❌ BAD - low contrast
const TextStyle(
  color: Color(0xFFCCCCCC),  // Barely visible!
)

// ✅ GOOD - use theme colors that handle contrast
Theme.of(context).colorScheme.onSurface
```

### Don't rely on color alone

```dart
// ❌ BAD - only color indicates status
Container(
  color: Colors.green,  // "Success"
  child: Text('Completed'),
)

// ✅ GOOD - color + icon + text
Row(
  children: [
    Icon(Icons.check_circle, color: Colors.green),
    Text('Completed'),
  ],
)
```

---

## Touch Targets

### Minimum touch target size: 44x44dp

```dart
// ✅ GOOD - adequate touch target
InkWell(
  onTap: () {},
  child: Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    child: Icon(Icons.favorite, size: 24),
  ),
)

// ❌ BAD - too small to tap
GestureDetector(
  onTap: () {},
  child: Icon(Icons.favorite, size: 16),
)
```

### Add padding to small controls

```dart
// ✅ GOOD - padding expands touch target
InkWell(
  onTap: () {},
  child: Padding(
    padding: const EdgeInsets.all(12),  // 24 + 24 padding = 48x48
    child: Icon(Icons.favorite, size: 24),
  ),
)
```

---

## Focus Handling

### Visible focus indicators

```dart
// ✅ GOOD - clear focus state
MaterialApp(
  theme: ThemeData(
    focusColor: Colors.blue.withOpacity(0.5),
    highlightColor: Colors.blue.withOpacity(0.2),
  ),
)
```

### Logical focus order

```dart
// ✅ GOOD - focus follows visual order
Column(
  children: [
    TextField(focusNode: _focus1),  // First
    TextField(focusNode: _focus2),  // Second
    ElevatedButton(
      onPressed: () {},
      focusNode: _focus3,  // Third
    ),
  ],
)

// ❌ BAD - focus order doesn't match visual order
Column(
  children: [
    TextField(focusNode: _focus2),  // Second visually, focused first!
    TextField(focusNode: _focus1),  // First visually, focused second!
  ],
)
```

### FocusScope for keyboard navigation

```dart
// ✅ GOOD - trap focus in dialogs
showDialog(
  context: context,
  builder: (context) => FocusScope(
    onKeyEvent: (node, event) {
      // Handle Tab/Escape
      return KeyEventResult.ignored;
    },
    child: AlertDialog(
      title: const Text('Delete PDF?'),
      actions: [
        TextButton(onPressed: () {}, child: const Text('Cancel')),
        TextButton(onPressed: () {}, child: const Text('Delete')),
      ],
    ),
  ),
)
```

---

## Screen Reader Support

### Test with TalkBack/VoiceOver

```bash
# Android - Enable TalkBack
Settings > Accessibility > TalkBack > On

# iOS - Enable VoiceOver
Settings > Accessibility > VoiceOver > On
```

### Provide meaningful labels

```dart
// ✅ GOOD - descriptive labels
Icon(
  Icons.favorite,
  semanticLabel: pdf.isFavorite
    ? 'Remove from favorites'
    : 'Add to favorites',
)

// ❌ BAD - generic label
Icon(
  Icons.favorite,
  semanticLabel: 'Icon',  // Not helpful!
)

// ✅ GOOD - hint for user actions
TextField(
  decoration: InputDecoration(
    labelText: 'Search PDFs',
    hintText: 'Enter filename or content to search',
  ),
)
```

### Announce state changes

```dart
// ✅ GOOD - announce loading state
class LibraryScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryNotifierProvider);

    return Semantics(
      label: state.isLoading
          ? 'Loading PDF files'
          : 'Loaded ${state.pdfs.length} PDF files',
      child: body,
    );
  }
}
```

---

## Accessibility Features in Flutter

### AccessibilityShortcuts

```dart
// ✅ GOOD - standard shortcuts
Shortcuts(
  shortcuts: <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.select): ActivateIntent(),
  },
  child: Actions(
    actions: <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (intent) => _activate(),
      ),
    },
    child: child,
  ),
)
```

### Exclude from accessibility

```dart
// ✅ GOOD - purely decorative elements
ExcludeSemantics(
  child: Divider(),  // Screen readers will skip
)

// ✅ GOOD - decorative image
Semantics(
  label: '',  // Empty label = decorative
  child: Image.asset('assets/decoration.png'),
)
```

---

## Testing Accessibility

### Use accessibility guidelines

```dart
// Add to tests
testWidgets('should have proper accessibility labels', (tester) async {
  await tester.pumpWidget(MyApp());

  // Check for semantic labels
  expect(
    tester.getSemantics(find.byType(PdfCard)),
    matchesSemantics(
      label: contains('PDF:'),
      hint: contains('Double tap'),
      isButton: true,
    ),
  );
});
```

### Manual testing checklist

- [ ] All interactive elements are at least 44x44dp
- [ ] Text scales properly at 200%
- [ ] Colors have sufficient contrast
- [ ] All images have labels or are marked decorative
- [ ] Focus order matches visual order
- [ ] Screen reader announces all important info
- [ ] State changes are announced (loading, errors)
- [ ] Can navigate app with keyboard only
- [ ] All form fields have labels

---

## Accessibility Best Practices

```dart
// ✅ GOOD - accessible card
class AccessiblePdfCard extends StatelessWidget {
  const AccessiblePdfCard({super.key, required this.pdf, this.onTap});

  final PdfDocument pdf;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PDF document: ${pdf.title}',
      hint: onTap != null
          ? '${pdf.pageCount} pages. Double tap to open.'
          : 'Read-only document',
      button: onTap != null,
      value: pdf.isFavorite ? 'In favorites' : null,
      child: InkWell(
        onTap: onTap,
        canRequestFocus: true,  // Keyboard focusable
        child: Padding(
          padding: const EdgeInsets.all(12),  // Minimum touch target
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${pdf.pageCount} pages',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (pdf.isFavorite)
                Icon(
                  Icons.favorite,
                  semanticLabel: 'In your favorites',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Platform-Specific Accessibility

### Android

```dart
// Android-specific accessibility
if (Theme.of(context).platform == TargetPlatform.android) {
  return Semantics(
    // TalkBack will read this
    label: 'Double tap to open',
    child: child,
  );
}
```

### iOS

```dart
// iOS-specific accessibility
if (Theme.of(context).platform == TargetPlatform.iOS) {
  return Semantics(
    // VoiceOver will read this
    hint: 'Opens the PDF document',
    child: child,
  );
}
```

---

## Accessibility Resources

- [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)
- [Android Accessibility Guide](https://developer.android.com/guide/topics/ui/accessibility)
- [iOS Accessibility Guide](https://developer.apple.com/accessibility/)

---

## Accessibility Checklist for PRs

Before merging, verify:

- [ ] All buttons have labels or use semantic widgets
- [ ] Touch targets are 44x44dp minimum
- [ ] Text respects user's scale settings
- [ ] Colors meet contrast ratios (4.5:1 for normal text)
- [ ] Images have alt text or marked decorative
- [ ] Form fields have associated labels
- [ ] Focus order is logical
- [ ] Screen reader testing performed
- [ ] Keyboard navigation works
- [ ] Loading/error states are announced
