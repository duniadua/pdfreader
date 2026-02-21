# Flutter Performance Guidelines

This file contains performance best practices for Flutter development in this project.

---

## Core Principles

1. **Measure first** - Profile before optimizing
2. **Optimize for the common case** - Focus on frequent operations
3. **Avoid premature optimization** - Correct code first, fast code second
4. **Target 60fps** - Jank-free UI on target devices

---

## Build Performance

### Build Modes

| Mode | When to Use | Performance |
|------|-------------|-------------|
| `debug` | Development | Slow, with assertions |
| `profile` | Performance testing | Near-release, profiling enabled |
| `release` | Production | Fastest, fully optimized |

```bash
# Run in profile mode for performance testing
flutter run --profile

# Build release to test final performance
flutter build apk --release
flutter build ios --release
```

### Reduce Build Time

```yaml
# pubspec.yaml - only import what you need
dependencies:
  # Don't do this:
  # cupertino_icons: ^1.0.0  # Not needed for Android-only

  # Do this:
  flutter:
    sdk: flutter
```

```bash
# Use dart analysis cache
flutter analyze --build-cache

# Parallel builds
flutter build apk --release --target-platform android-arm64
```

---

## Widget Performance

### Const Constructors

```dart
// ✅ GOOD - const widgets are cached and reused
const SizedBox(height: 16)
const Text('Loading...')
const Icon(Icons.home)

// ❌ BAD - rebuilt on every frame
SizedBox(height: 16)
Text('Loading...')
```

### Avoid rebuilds with const

```dart
// ✅ GOOD - const prevents rebuild
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(  // const widget
      padding: EdgeInsets.all(16),
      child: Text('Hello'),  // const widget
    );
  }
}

// ❌ BAD - unnecessary rebuilds
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Text('Hello'),
    );
  }
}
```

### Extract const widgets

```dart
// ✅ GOOD - separate const widgets
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Text('My Library', style: headerStyle);
  }
}

static const headerStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
);

// ❌ BAD - inline construction
@override
Widget build(BuildContext context) {
  return Text(
    'My Library',
    style: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  );
}
```

---

## ListView Performance

### Use ListView.builder for long lists

```dart
// ✅ GOOD - lazy builds only visible items
ListView.builder(
  itemCount: pdfs.length,
  itemBuilder: (context, index) {
    return PdfCard(pdf: pdfs[index]);
  },
)

// ❌ BAD - builds all items at once
ListView(
  children: pdfs.map((pdf) => PdfCard(pdf: pdf)).toList(),
)
```

### Add itemExtent for predictable heights

```dart
ListView.builder(
  itemExtent: 80,  // Improves scrolling performance
  itemCount: pdfs.length,
  itemBuilder: (context, index) => PdfCard(pdf: pdfs[index]),
)
```

### Use AutomaticKeepAliveClientMixin

```dart
class PdfCard extends ConsumerStatefulWidget {
  const PdfCard({super.key, required this.pdf});

  final PdfDocument pdf;

  @override
  ConsumerState<PdfCard> createState() => _PdfCardState();
}

class _PdfCardState extends ConsumerState<PdfCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;  // Keep state when scrolling away

  @override
  Widget build(BuildContext context) {
    super.build(context);  // Required
    return Card(child: Text(widget.pdf.title));
  }
}
```

---

## State Management Performance

### Watch only what you need

```dart
// ✅ GOOD - watch only specific value
final pdfs = ref.watch(libraryNotifierProvider.select((state) => state.pdfs));
return PdfListView(pdfs: pdfs);

// ❌ BAD - watch entire state when only using one field
final state = ref.watch(libraryNotifierProvider);
return PdfListView(pdfs: state.pdfs);
```

### Use Provider families for unique keys

```dart
// ✅ GOOD - family creates separate instances
final thumbnailProvider = thumbnailProviderFamily(pdfId);

// ✅ GOOD - dispose when not needed
ref.invalidate(thumbnailProviderFamily(pdfId));
```

---

## Image Performance

### Use cached_network_image for network images

```yaml
dependencies:
  cached_network_image: ^3.3.0
```

```dart
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  maxWidthDiskCache: 500,  // Limit cache size
  memCacheWidth: 300,       // Limit memory usage
)
```

### Compress images

```dart
// For local images, use flutter_image_compress
dependencies:
  flutter_image_compress: ^2.0.0

final compressed = await FlutterImageCompress.compressWithFile(
  file.path,
  quality: 85,
  minWidth: 300,
  minHeight: 300,
);
```

### Use Image.asset correctly

```dart
// ✅ GOOD - specify size to avoid decoding full resolution
Image.asset(
  'assets/thumbnails/default.png',
  width: 100,
  height: 100,
  fit: BoxFit.cover,
)

// ❌ BAD - decodes full resolution
Image.asset('assets/large_image.png')
```

---

## Async Performance

### Use Isolates for heavy computation

```dart
import 'dart:async';
import 'dart:isolate';

// ✅ GOOD - run parsing in isolate
Future<List<PdfMetadata>> parsePdfs(List<String> paths) async {
  return await Isolate.run(() {
    return paths.map((path) => _parsePdf(path)).toList();
  });
}

// ❌ BAD - blocks UI thread
Future<List<PdfMetadata>> parsePdfs(List<String> paths) async {
  final results = <PdfMetadata>[];
  for (final path in paths) {
    results.add(_parsePdf(path));  // Blocks!
  }
  return results;
}
```

### Debounce rapid events

```dart
import 'package:async/async.dart';

// ✅ GOOD - debounce search input
final debounce = EventBus();

searchQueryNotifier.addListener(() {
  debounce.fire(searchQuery);
});

debounce.on<String>().debounce(const Duration(milliseconds: 300)).listen((query) {
  _performSearch(query);
});
```

---

## Memory Performance

### Dispose controllers and resources

```dart
class _MyWidgetState extends State<MyWidget> {
  late final TextEditingController _controller;
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _animation = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();  // ✅ Always dispose
    _animation.dispose();   // ✅ Always dispose
    super.dispose();
  }
}
```

### Use WeakReference for caches

```dart
import 'dart:developer' as developer;

class ThumbnailCache {
  final _cache = <String, developer.WeakReference<Uint8List>>{};

  void put(String key, Uint8List data) {
    _cache[key] = developer.WeakReference(data);
  }

  Uint8List? get(String key) {
    return _cache[key]?.target;
  }
}
```

### Clear large data when not needed

```dart
@override
void dispose() {
  _clearLargeData();
  super.dispose();
}

void _clearLargeData() {
  _largePdfData = null;
  _thumbnails.clear();
}
```

---

## Hive Performance

### Use lazy boxes for large data

```dart
// ✅ GOOD - lazy box doesn't load all data
final box = await Hive.openLazyBox<PdfDocument>('pdfs');

// Get specific item
final pdf = await box.get('pdf_id');

// ❌ BAD - regular box loads all data
final box = await Hive.openBox<PdfDocument>('pdfs');
```

### Compact Hive files periodically

```dart
// Run occasionally to reduce file size
await Hive.compact();
```

### Use appropriate key types

```dart
// ✅ GOOD - string keys for documents
await box.put('pdf_123', pdfDocument);

// ✅ GOOD - int keys for indexed data
await indexedBox.put(0, item);
```

---

## Rendering Performance

### Avoid opacity in animated widgets

```dart
// ❌ BAD - opacity causes repaint
AnimatedOpacity(
  opacity: 0.5,
  child: ExpensiveWidget(),
)

// ✅ GOOD - use fadeInImage or other optimizations
FadeInImage.assetNetwork(
  placeholder: 'assets/placeholder.png',
  image: url,
)
```

### Use RepaintBoundary

```dart
RepaintBoundary(
  child: ExpensiveWidgetThatUpdatesOften(),
)
```

### Avoid saveLayer calls

```dart
// ❌ BAD - causes saveLayer
ColorFiltered(
  colorFilter: ColorFilter.mode(Colors.red, BlendMode.color),
  child: Widget(),
)

// ✅ GOOD - use opacity if possible
Opacity(
  opacity: 0.5,
  child: Widget(),
)
```

---

## Performance Profiling

### Flutter DevTools

```bash
# Run app with profiling
flutter run --profile

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Timeline view in DevTools

```
1. Record performance
2. Interact with app
3. Stop recording
4. Analyze frames:
   - Green: Good (<16ms)
   - Yellow: Warning (16-30ms)
   - Red: Bad (>30ms)
```

### Memory profiling in DevTools

```
1. Open Memory tab
2. Take snapshot at start
3. Use app features
4. Take another snapshot
5. Diff to find memory growth
```

### Performance Overlay

```dart
MaterialApp(
  showPerformanceOverlay: true,  // Show in debug mode
  home: MyHomePage(),
)
```

---

## Performance Checklist

Before considering code "performance-ready":

- [ ] Profiled in `--profile` mode
- [ ] No janky scrolling (60fps achieved)
- [ ] Const constructors used where possible
- [ ] ListView.builder for long lists
- [ ] Controllers disposed properly
- [ ] Large operations in isolates
- [ ] Images optimized (compressed, sized)
- [ ] No memory leaks (verified with DevTools)
- [ ] Hive boxes using lazy loading for large datasets
- [ ] Animations use RepaintBoundary where needed
- [ ] Unnecessary watches removed from providers

---

## Common Performance Anti-Patterns

```dart
// ❌ DON'T: Build large lists eagerly
final items = heavyData.map((e) => ExpensiveWidget(e)).toList();
return ListView(children: items);

// ✅ DO: Build lazily
return ListView.builder(
  itemCount: heavyData.length,
  itemBuilder: (ctx, i) => ExpensiveWidget(heavyData[i]),
);

// ❌ DON'T: Rebuild entire widget for small change
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: ExpensiveChild(),
    );
  }
}

// ✅ DO: Extract static parts
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _Container(child: ExpensiveChild());
  }
}

class _Container extends StatelessWidget {
  const _Container({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}
```

---

## Performance Metrics to Track

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Frame rate | 60fps | DevTools Timeline |
| App startup | <2 seconds | Stopwatch on main() |
| First frame | <100ms | DevTools Performance |
| Memory usage | <200MB | DevTools Memory |
| APK size | <50MB | Build output |
| Build time | <60 seconds | Time build command |
