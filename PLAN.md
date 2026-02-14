# ExifChanger - Implementation Plan

## Context
Building a simple macOS app for non-technical users to batch-edit photo metadata. Users can drag photos into the app, change the date/time taken, set GPS location via Apple Maps, and inspect all EXIF data. Changes are written to both EXIF metadata and file system dates.

## Architecture Overview

```
ExifChanger/
├── Models/
│   ├── PhotoItem.swift          # Photo with URL, thumbnail, metadata
│   └── ExifMetadata.swift       # EXIF data structure (dates, GPS, camera info, keywords)
├── Views/
│   ├── MainView.swift           # HSplitView: photos left, editors right
│   ├── PhotoDropZone.swift      # Drag-drop area with visual feedback
│   ├── PhotoGridView.swift      # Thumbnail grid with selection
│   ├── DateTimeEditorView.swift # Date/time picker for editing
│   ├── KeywordSelectorView.swift # Photography keyword tags selector
│   ├── LocationPickerView.swift # Apple Maps with search & pin placement
│   └── MetadataInspectorView.swift # Full EXIF viewer (sheet)
├── ViewModels/
│   └── PhotoLibraryViewModel.swift # Central state management
├── Services/
│   ├── ExifService.swift        # ImageIO read/write (EXIF + IPTC)
│   └── FileSystemService.swift  # File date modification
└── Resources/
    └── Localizable.xcstrings    # English & Portuguese translations
```

## Key Features
- Batch drag-and-drop photo import
- Date/time editing with locale-aware formatting
- GPS location via Apple Maps
- Photography keyword tags (Concert, Wedding, Portrait, etc.)
- Full metadata inspector
- English & Portuguese localization
