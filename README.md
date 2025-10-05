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
    git clone [https://github.com/Swaraj586/flutter_describe_app.git](https://github.com/Swaraj586/flutter_describe_app.git)
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
