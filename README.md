# ExifChanger

A native macOS app for batch editing photo metadata (EXIF, IPTC, GPS). Built with SwiftUI for photographers who need to quickly update dates, locations, and keywords on multiple photos.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

### Photo Management
- Drag-and-drop photo import
- File picker via **File → Open Photos** (⌘O)
- Supports JPEG, HEIC, PNG, and TIFF formats
- Thumbnail grid with multi-selection
- Metadata inspector with tabbed view (Image, EXIF, TIFF, GPS, IPTC, Map)

### Date & Time Editor
- Edit DateTimeOriginal, DateTimeDigitized, and DateTime EXIF fields
- "Use Original" to load date from selected photo
- "Now" button to set current date/time
- Option to sync file system dates with EXIF dates

### Location Editor
- Interactive Apple Maps view
- Tap-to-select coordinates on map
- Location search with autocomplete
- "Use my location" for device GPS
- View multiple photo locations on map (blue markers)
- Set new location (red marker)

### Keywords Editor
- Predefined photography keywords:
  - Concert, Wedding, Portrait, Event, Landscape
  - Family, Corporate, Fashion, Product
  - Birthday, Baptism, Graduation
- Custom keyword input
- Keywords stored in IPTC metadata (compatible with Lightroom, Capture One, etc.)

### Localization
- English (en) - default
- German (de)
- Portuguese Brazil (pt-BR)
- Portuguese Portugal (pt-PT)

## Screenshots

| Photo Grid | Editors | Inspector |
|------------|---------|-----------|
| Drag photos, select multiple | Edit date, keywords, location | View all metadata |

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later (for building)

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ExifChanger.git
   cd ExifChanger
   ```

2. Open in Xcode:
   ```bash
   open ExifChanger.xcodeproj
   ```

3. Build and run (⌘R)

## Usage

1. **Add Photos**: Drag photos into the app or use **File → Open Photos** (⌘O)
2. **Select Photos**: Click to select, use "Select All" for batch editing
3. **Edit Metadata**:
   - Set new date/time and click "Apply to Selected"
   - Click keywords to add them, then "Apply to Selected"
   - Tap the map or search for a location, then "Apply to Selected"
4. **Save**: Click "Apply Changes" to write all pending changes to files

### Tips

- Orange dots on thumbnails indicate unsaved changes
- Use **File → Open Photos** instead of drag-and-drop if you get permission errors
- Click the (i) button on any photo to view all its metadata
- Select multiple photos to see all their GPS locations on the map

## Technical Details

- Built with SwiftUI and native Apple frameworks (ImageIO, MapKit, CoreLocation)
- No external dependencies
- App Sandbox enabled with proper entitlements
- In-memory image processing to avoid temp file permission issues

## Project Structure

```
ExifChanger/
├── Models/
│   ├── PhotoItem.swift          # Photo with URL, thumbnail, metadata
│   └── ExifMetadata.swift       # EXIF data structure
├── Views/
│   ├── MainView.swift           # Main layout
│   ├── PhotoDropZone.swift      # Drag-drop area
│   ├── PhotoGridView.swift      # Thumbnail grid
│   ├── DateTimeEditorView.swift # Date picker
│   ├── KeywordSelectorView.swift # Keyword tags
│   ├── LocationPickerView.swift # Map view
│   ├── MetadataInspectorView.swift # Tabbed metadata viewer
│   └── HelpView.swift           # Help window
├── ViewModels/
│   └── PhotoLibraryViewModel.swift
├── Services/
│   ├── ExifService.swift        # ImageIO read/write
│   └── FileSystemService.swift  # File date modification
└── Resources/
    └── Localizable.xcstrings    # Translations
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- Built with SwiftUI and Apple's native frameworks
- Icons from SF Symbols
