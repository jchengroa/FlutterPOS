# FlutterPOS

Minimal, elegant, and ready-to-run Point of Sale system built with Flutter.

## Features

- Responsive POS dashboard for desktop, web, and mobile layouts
- Product catalog with category filtering and indexed prefix search
- Cart management with quantity controls and instant totals
- Checkout flow with tax calculation and inventory deduction
- Recent sales panel with transaction summaries
- Local backend service layer implemented in Dart

## Tech Stack

- Flutter
- Dart
- `intl` for currency and date formatting

## Architecture

The project is split into frontend and backend layers inside the Flutter app:

- `lib/app.dart`: UI, layout, widgets, and interactions
- `lib/state/pos_controller.dart`: presentation state and orchestration
- `lib/data/services/local_pos_backend.dart`: local backend/service layer
- `lib/data/models/*`: core entities for products, cart items, and sales
- `lib/data/seeds.dart`: starter catalog data

## Data Structures and Algorithms

- `LinkedHashMap<String, Product>` for O(1) product lookup by id
- `LinkedHashMap<String, CartItem>` for O(1) cart insert, update, and remove
- Category index with `Map<String, Set<String>>` for efficient filtering
- Prefix search index with `Map<String, Set<String>>` for fast token-prefix search
- Cart totals and analytics computed with linear folds over current collections

This keeps the core operations efficient:

- Add to cart: O(1)
- Update cart quantity: O(1)
- Product lookup: O(1)
- Category filter: O(k)
- Prefix search: O(t + m), where `t` is query token work and `m` is matched ids

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK bundled with Flutter

If Flutter is not on `PATH`, this repo was prepared with a local SDK at:

```powershell
C:\Users\jchen\flutter\bin\flutter.bat
```

### Install dependencies

```powershell
C:\Users\jchen\flutter\bin\flutter.bat pub get
```

### Run the app

```powershell
C:\Users\jchen\flutter\bin\flutter.bat run
```

### Run checks

```powershell
C:\Users\jchen\flutter\bin\flutter.bat analyze
C:\Users\jchen\flutter\bin\flutter.bat test
```

## Default POS Scope

- Catalog browsing
- Search and filtering
- Cart and quantity updates
- Checkout and tax
- Inventory updates
- Sales history snapshot

## Notes

- The backend is local and in-memory for frictionless startup and cross-platform compatibility.
- Seed data is included so the app is usable immediately after launch.
- The project scaffold includes Android, iOS, Web, Windows, Linux, and macOS targets.
