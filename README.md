# Quran Karim Offline (Quran Warsh & Hafs)

A Flutter application for reading the Holy Quran offline. This app is designed to provide a seamless reading experience without the need for an internet connection, supporting both Warsh and Hafs narrations.

## Features

- **Offline Reading**: Access the complete Holy Quran anytime, anywhere without an internet connection.
- **Multiple Narrations**: Supports both **Warsh** and **Hafs** narrations.
- **Reading Modes**:
  - **Night Mode**: A dark theme for comfortable reading in low-light environments (with inverted page colors for better visibility).
  - **Light Mode**: Standard reading mode with a clear white background.
- **Bookmarks**: Save your current page and easily return to it later.
- **Navigation**:
  - Jump to a specific page number.
  - Slider navigation.
  - Next/Previous page buttons.
- **Interactive Information**: Displays Hizb, Juz, and Rub type for the current page.
- **Screen Awake**: Keeps the screen on while reading using `wakelock_plus`.
- **Share**: Ability to share the application link.
- **Sajda Notifications**: Alerts the user when there is a Sajda on the current page.

## Screenshots

_(Placeholder for screenshots - Add screenshots here)_

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.10.1 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/eaf-microservice/quran_warsh_hafs.git
    cd quran_warsh_hafs
    ```

2.  **Install dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run the application:**

    ```bash
    flutter run
    ```

## Project Structure

```
lib/
├── main.dart                 # Entry point of the application
├── screens/
│   ├── home_screen.dart      # Main landing screen
│   ├── read_screen.dart      # The core reading interface (PageView, Logic)
│   └── settings_screen.dart  # Settings page (Theme, Narration, Data management)
├── utils/
│   ├── quran_devision.dart   # Data and logic for Quran divisions (Hizb, Juz)
│   ├── quran_sajda.dart      # Sajda locations data
│   ├── quran_surahs.dart     # Surah names and information
│   └── show_toast.dart       # Utility for showing toast notifications
└── widgets/
    └── about.dart            # About dialog/widget
```

## Dependencies

- [`flutter`](https://flutter.dev/): SDK.
- [`cupertino_icons`](https://pub.dev/packages/cupertino_icons): Default icons asset for using Cupertino icons.
- [`shared_preferences`](https://pub.dev/packages/shared_preferences): For persisting local data like bookmarks, last page, and settings.
- [`wakelock_plus`](https://pub.dev/packages/wakelock_plus): To keep the screen awake during reading.
- [`fluttertoast`](https://pub.dev/packages/fluttertoast): For displaying toast messages (e.g., Sajda alerts).
- [`share_plus`](https://pub.dev/packages/share_plus): For sharing the app content/link.

## Assets

The application uses asset images for the Quran pages located in:

- `assets/images/warsh/`
- `assets/images/hafs/`
- `assets/images/khatem/`

Ensure these assets are correctly placed and configured in `pubspec.yaml` (as they currently are).

## Contributing

Contributions are welcome! If you have any suggestions or improvements, please create a pull request or open an issue.

## License

[MIT License](LICENSE) (or specify your license)
