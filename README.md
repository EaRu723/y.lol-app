# Y.lol - Conversational AI App

Y.lol is an iOS application built with SwiftUI that provides a unique chat interface featuring distinct AI conversation modes (Yin and Yang). It includes authentication via Sign in with Apple, a smooth onboarding experience, and a clean, document-like chat interface supporting text and images.

<!-- Optional: Add a screenshot or GIF here -->
<!-- ![App Screenshot](path/to/screenshot.png) -->

## Features

*   **SwiftUI Interface:** Modern, declarative UI built entirely with SwiftUI.
*   **MVVM Architecture:** Clear separation of concerns between views, view models, and models.
*   **Firebase Backend:** Leverages Firebase for core backend services:
    *   **Firestore:** For storing chat messages and user data.
    *   **Authentication:** Secure user login via Sign in with Apple.
    *   **Cloud Storage:** For handling image uploads.
    *   **Cloud Functions:** (Assumed for AI interaction/backend logic - *Specify if used*)
*   **Dual AI Modes:** Switch between distinct "Yin" and "Yang" conversational styles.
*   **Rich Chat Interface:** Supports text messages and image uploads with camera/photo library integration.
*   **Link Previews:** Automatically generates previews for URLs shared in chat.
*   **Onboarding Flow:** Introduces new users to the app's features.
*   **Theming:** Supports both Light and Dark modes with a custom color palette.
*   **Haptic Feedback:** Enhances user interactions.

## Technology Stack

*   **UI:** SwiftUI
*   **Architecture:** MVVM
*   **Backend:** Firebase (Firestore, Authentication, Storage, Functions)
*   **Authentication:** Sign in with Apple
*   **Package Management:** Swift Package Manager
*   **Language:** Swift

## Getting Started

### Prerequisites

*   Xcode (Latest version recommended)
*   An Apple Developer Account (for Sign in with Apple capability)
*   A Firebase project

### Setup Instructions

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/your-username/y.lol.git
    cd y.lol
    ```
    *(Replace `your-username/y.lol.git` with your actual repository URL)*

2.  **Firebase Setup:**
    *   Create a new project on the [Firebase Console](https://console.firebase.google.com/).
    *   Enable the following services for your project:
        *   **Firestore Database:** Create a Firestore database. You'll likely need to define security rules.
        *   **Authentication:** Enable the "Sign in with Apple" sign-in provider. You'll need to configure this with your Apple Developer account details (App ID, Services ID, private key).
        *   **Storage:** Enable Cloud Storage and configure security rules (e.g., allow authenticated users to read/write).
        *   **Cloud Functions:** (If you use Cloud Functions for backend logic/AI interaction) Set up Cloud Functions. You may need to deploy the functions from a separate backend codebase (not included in this iOS repo).
    *   Register your iOS app with the Firebase project:
        *   Go to Project Settings > General.
        *   Click "Add app" and select iOS.
        *   Enter your app's Bundle ID (found in Xcode: Target > Signing & Capabilities).
        *   Download the `GoogleService-Info.plist` file.
    *   **Add Your Config File:** Place the `GoogleService-Info.plist` file you downloaded from *your* Firebase project into the root of the `y.lol` Xcode project folder (the same directory as `y.lol.xcodeproj`).
    *   **Crucially, ensure this file is added to the main `y.lol` target in Xcode.** This file is required for the app to connect to Firebase services and will cause a crash at launch if missing.
    *   **Do not commit `GoogleService-Info.plist` to Git.** The provided `.gitignore` file should prevent this automatically, as this file contains sensitive project keys specific to your Firebase instance. Each developer needs to use their own configuration file.

3.  **Configuration (Secrets):**
    *   *(Add steps here if you abstracted API keys or other secrets into environment variables or a separate configuration file. Explain how to create this file, perhaps from an example template like `.env.example`)*
    *   Ensure any necessary API keys or backend endpoints are correctly configured according to your setup.

4.  **Open in Xcode:**
    *   Open the `y.lol.xcodeproj` file in Xcode.

5.  **Dependencies:**
    *   Xcode should automatically resolve Swift Package Manager dependencies. If not, go to `File > Packages > Resolve Package Versions`.

6.  **Build and Run:**
    *   Select a simulator or connect a physical device.
    *   Build and run the application (Cmd+R). You'll need to run on a physical device to test Sign in with Apple fully.

## Contributing

Contributions are welcome! Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines on how to contribute to the project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 