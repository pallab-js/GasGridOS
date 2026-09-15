# GasGrid Manager

A professional, enterprise-grade macOS desktop application for comprehensive monitoring, management, and control of gas grid distribution network operations.

## Features

### Core Features
- **Dashboard** - Real-time overview with KPIs, alerts, and system status
- **Network Map** - Interactive pipeline network visualization
- **Asset Management** - Track stations, pipelines, sensors, and valves
- **Alert System** - Critical/warning/info alerts with notifications
- **Reports** - Generate and export operational reports
- **Settings** - Configure app preferences

### Phase 2 Features
- **Interactive Charts** - Swift Charts integration with pressure, flow rate, and temperature trends
- **Time Range Selection** - Filter data by 1H, 6H, 24H, 1W, 1M
- **Station Performance** - Horizontal scrolling cards with real-time metrics
- **Network Overview** - Statistics panel with key metrics
- **Valve Management** - Dedicated valve list view with search

### Phase 3 Features
- **Real-time Simulation** - Live data updates every 5 seconds
- **Maintenance Scheduling** - Track and manage maintenance tasks
- **Export Functionality** - Export data to CSV, JSON, or PDF
- **Alert Detail View** - View and acknowledge alerts with notes

### Phase 4 Features
- **Keyboard Shortcuts** - Keyboard shortcut display (WIP)
- **Accessibility Settings** - VoiceOver, contrast, and motion settings
- **About View** - App information and version details
- **Settings Tabs** - Organized settings with multiple sections

## Testing

Run the test suite:
```bash
swift test
```

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 6.0+
- Xcode 16.0+

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/pallab-js/GasGridOS.git
   cd GasGridOS
   ```

2. Build the project:
   ```bash
   swift build
   ```

3. Run the app:
   ```bash
   swift run GasGridManager
   ```

## Project Structure

```
GasGridManager/
├── Sources/
│   ├── App/                    # App entry point
│   ├── Models/                 # Data models
│   │   ├── Core/              # Core model structs
│   │   └── Enums/             # Enumerations
│   ├── ViewModels/            # View models (MVVM)
│   ├── Views/                 # SwiftUI views
│   │   ├── Dashboard/         # Dashboard views
│   │   ├── Network/           # Network map views
│   │   ├── Assets/            # Asset management views
│   │   ├── Alerts/            # Alert views
│   │   ├── Reports/           # Report views
│   │   ├── Settings/          # Settings views
│   │   └── Common/            # Shared UI components
│   ├── Services/              # Business logic services
│   │   ├── DataPersistence/   # Database operations
│   │   ├── NetworkMonitoring/ # Sensor data services
│   │   ├── AlertManagement/   # Alert services
│   │   ├── Analytics/         # Analytics services
│   │   └── Integration/       # Spotlight & Shortcuts
│   └── Utilities/             # Helpers and extensions
└── Tests/                     # Unit tests
```

## Architecture

The app follows MVVM (Model-View-ViewModel) architecture with:

- **Models** - Data structures for network stations, pipelines, sensors, etc.
- **Views** - SwiftUI views for the user interface
- **ViewModels** - Business logic and state management
- **Services** - Data persistence, alert management, analytics

## Data Storage

The app uses SQLite (via GRDB.swift) for local data persistence, enabling full offline operation.

## Real-time Features

The app includes a real-time simulator that:
- Updates station data every 5 seconds
- Simulates pressure, flow rate, and temperature variations
- Generates alerts when values exceed thresholds
- Displays live status indicator in sidebar

## App Navigation

```
├── Dashboard          (KPIs, Charts, Alerts, Status)
├── Network Map        (Interactive pipeline visualization)
├── Assets             (Station & pipeline management)
├── Valves             (Valve list with search)
├── Alerts             (Alert list with filters)
├── Maintenance        (Task scheduling & tracking)
├── Reports            (Report generation)
├── Export             (CSV/JSON export)
└── Settings           (General, Notifications, Appearance, Accessibility, Keyboard, About)
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2026 Pallab Chakraborty
