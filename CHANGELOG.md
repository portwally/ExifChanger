# Changelog

## [1.0.0] - 2026-02-14

### Added
- **Photo Management**
  - Drag-and-drop photo import (JPEG, HEIC, PNG, TIFF)
  - File picker via File > Open Photos (Cmd+O)
  - Thumbnail grid with multi-selection support
  - Select All / Deselect / Remove / Clear All controls

- **Date & Time Editor**
  - Edit DateTimeOriginal, DateTimeDigitized, and DateTime EXIF fields
  - Date format follows user's system locale settings
  - "Use Original" button to load date from selected photo
  - "Now" button to set current date/time
  - Option to sync file system dates with EXIF dates

- **Location Editor**
  - Interactive Apple Maps view
  - Tap-to-select coordinates on map
  - Location search with autocomplete
  - "Use my location" button for device GPS
  - "Load from Photo" to use existing GPS data
  - Remove GPS data option

- **Keywords Editor**
  - Predefined photography keywords:
    - Concert, Wedding, Portrait, Event, Landscape
    - Family, Corporate, Fashion, Product
    - Birthday, Baptism, Graduation
  - Custom keyword input field
  - Multi-select chip/tag UI
  - Keywords stored in IPTC metadata (compatible with Lightroom, Capture One, etc.)

- **Metadata Inspector**
  - View all EXIF, TIFF, GPS, and IPTC metadata
  - Organized by category
  - Raw metadata view option
  - Accessible via double-click or context menu on photos

- **Localization**
  - English (en) - default
  - German (de) - full translation
  - Portuguese Brazil (pt-BR) - full translation
  - Portuguese Portugal (pt-PT) - full translation

- **macOS Integration**
  - Native SwiftUI interface
  - App Sandbox with proper entitlements
  - Menu bar integration with keyboard shortcuts

### Technical Details
- Built with SwiftUI and native Apple frameworks (ImageIO, MapKit, CoreLocation)
- No external dependencies
- Supports macOS sandboxed file access
- In-memory image processing to avoid temp file permission issues
