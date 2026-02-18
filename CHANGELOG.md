# Changelog

## [1.1.1] - 2026-02-18

### Fixed
- **App Store Compliance**
  - Fixed location permission description (NSLocationUsageDescription) with detailed example
  - App now stays running when main window is closed (standard macOS behavior)
  - Added "New Window" menu item (Cmd+N) in File menu to reopen window
  - Added "Show ExifEasy" menu item (Cmd+0) in Window menu
  - Clicking Dock icon reopens window when closed

## [1.1.0] - 2026-02-15

### Added
- **AI Auto-Tag Feature**
  - Automatic keyword generation using Apple Vision framework
  - Analyzes selected photos and detects objects, scenes, and subjects
  - Keywords applied individually per-photo (not merged across photos)
  - Progress indicator during analysis
  - 40% minimum confidence threshold for suggestions

- **Remove All Keywords**
  - New button to remove all keywords from selected photos
  - Properly clears IPTC keywords from metadata

### Fixed
- **Keyword Removal**: Fixed issue where removing keywords didn't persist - now properly writes empty keyword array to IPTC metadata
- **Metadata Refresh**: Inspector now shows updated metadata immediately after saving (no app restart needed)

### Improved
- **UI Layout**: Split keyword action buttons into two rows for better visibility
- **Right Panel**: Increased minimum width from 320 to 380 for better button labels
- **Metadata Inspector**: Increased label column width to 200px and window width to 600px to prevent text wrapping on long property names

### Localization
- Added translations for new Auto-Tag feature (EN, DE, PT-BR, PT-PT)
- Added "Remove All Keywords" translations

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
