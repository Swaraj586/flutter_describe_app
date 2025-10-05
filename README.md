# Flutter Describe App

A surrounding description app which describes the scene using an on-device LLM.

---

## 📝 Description

This app is under development and aims to help a visually impaired person get a description of their surroundings through voice output. The app can run offline and provide the necessary feedback.

---

## ✨ Features

* **Offline Surrounding Description:** Provides scene descriptions without needing an internet connection.
* **Accessible UI:** The user interface is designed to be friendly for visually impaired users.

---

## 🚀 Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing.

### Prerequisites

* **Flutter SDK:** [Link to Flutter installation guide](https://flutter.dev/docs/get-started/install)

### Installation

1.  **Clone the repo**
    ```sh
    git clone https://github.com/Swaraj586/flutter_describe_app.git
    ```
2.  **Navigate to the project directory**
    ```sh
    cd flutter_describe_app
    ```
3.  **Install dependencies**
    ```sh
    flutter pub get
    ```
4.  **Run the app**
    ```sh
    flutter run
    ```
    > **Note:** Make sure you have a physical device connected with USB debugging enabled. Emulators did not work in my case.

---

## 🛠️ Troubleshooting

If you encounter any build errors or unexpected issues, you can force a clean rebuild of the project by running the following commands in your terminal:

```sh
# Clean the project's build cache
flutter clean

# Get all dependencies again
flutter pub get

# Run the project
flutter run

## ⚙️ Dependencies & Configuration (`pubspec.yaml`)

This is the project's manifest file, central to managing the app's configuration. It defines:

* **Project Metadata:** The app's name, description, and version.
* **Dependencies:** A list of all the external packages from `pub.dev` that the project relies on, such as `flutter_gemma`, `camera`, and `flutter_tts`.
* **Assets:** Any local assets bundled with the app, like fonts, images, or model files.

---

## 📱 Native Platform Directories (`android/` & `ios/`)

These directories contain the native project files for their respective platforms.

* **`android/`:** Holds the Android project, including Gradle scripts, `AndroidManifest.xml`, and any native Java or Kotlin code. You would modify files here for tasks like setting permissions or configuring Android-specific services.
* **`ios/`:** Holds the iOS project, including the Xcode workspace, `Info.plist`, and any native Swift or Objective-C code. This is where you would configure iOS-specific settings, permissions, or capabilities.

## 🚀 Application Entry Point (`main.dart`)

This file is the main entry point for the application. Its primary responsibility is to perform initial setup before the app runs. It first initializes `WidgetsFlutterBinding` and then detects and lists all available cameras on the device. Finally, it launches the `Home` widget as the initial screen, passing it the camera list and the required AI model configuration.

---

## 🤖 Model Configuration (`model.dart`)

All AI model configurations are centralized in the `lib/core/model.dart` file. This file uses a Dart `enum` called `Model` to define the properties and inference parameters for each available Gemma model.

### Adding a New Model

To add a new model, open the `lib/core/model.dart` file and add a new entry to the `Model` enum with the required parameters.

**Template:**
```dart
// Add this inside the Model enum
yourNewModelName(
  url: '[https://your.model.url/model-file.task](https://your.model.url/model-file.task)',
  filename: 'model-file.task',
  displayName: 'My New Model (CPU/GPU) Size',
  preferredBackend: PreferredBackend.cpu, // or .gpu
  modelType: ModelType.gemmaIt, // or .gemma
  temperature: 1.0,
  topK: 64,
  topP: 0.95,
  maxTokens: 4096,
  supportImage: true,
  maxNumImages: 1,
  supportsFunctionCalls: true,
),

## 📥 Model Download Screen (`home.dart`)

The `home.dart` file serves as the initial entry point of the app, acting as a crucial **gatekeeper** to ensure the necessary AI model is available on the user's device before the main application can start.

### Workflow

* **Check for Model:** When the app starts, this screen first checks if the required model file is already downloaded.
* **Display Download UI:** If the model is not found, the user is presented with an interface containing:
    * A "Download" button
    * A progress bar to show the download status
    * An instructional message
* **Proceed to App:** Once the download is complete, the app automatically navigates to the main interface.

---

## 📸 Core Logic: The Scene Describer (`Test1.dart`)

This file is the heart of the application, where the camera, AI model, and text-to-speech engine work together. This screen is displayed after the model has been successfully downloaded.

### Application Flow

The functionality can be broken down into three main phases:

* **Initialization:** When the screen loads, it initializes the camera, the Text-to-Speech (TTS) engine, and the Gemma AI model. A loading overlay is shown during this process.
* **User Interaction:** The user points the camera and presses the "Describe Scene" button. The app captures a picture and sends it to the Gemma model with a predefined prompt.
* **Output & Feedback:** The model returns a text description, which is immediately read aloud by the TTS engine. A "Repeat Description" button allows the user to hear the last description again.

---

## 🎙️ Voice Interaction (`SpeechPage.dart`)

This file uses **speech-to-text** to capture user commands and then takes the necessary steps. It performs NLP tasks by inferencing the **on-device model**. The feature supports only the languages available on the user's device.

**Note:** The current implementation is too slow for real-life usage.

---

## 🗂️ Legacy and Redundant Files

This project may contain files that are not part of the active development source code. These are typically redundant files or files from previous versions kept for archival purposes. Please refer to the main source files for the current implementation.
