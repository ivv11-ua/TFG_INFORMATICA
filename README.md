# Sportly - Sports Product Search and Comparison Mobile Application

**Sportly** is a cross-platform mobile application developed as a Bachelor's Thesis (TFG) in Computer Engineering at the University of Alicante. The platform centralizes the search, price comparison, and technical specification review of sports products from various online retailers (such as Nike, Adidas, Decathlon, Sprinter, etc.) into a single place, facilitating informed and efficient decision-making.

---

## Key Features

* **Centralized Search:** Explore sports product catalogs from different brands and stores in real time.
* **Product Comparator:** Side-by-side technical specs and price comparison for up to 3 products simultaneously.
* **Favorites Management:** Save preferred items to monitor price or status updates.
* **Advanced Filters:** Filter items by sport category (Football, Running, Tennis, etc.), brand, and price range.
* **Flexible Authentication:** Sign in using Email/Password, Google Sign-In, or Guest Mode.
* **User Profile:** Customize personal details and profile picture.
* **External Redirection:** Direct link to the official store to complete purchases.

---

## Tech Stack & Technologies

### **Frontend**
* **Framework:** [Flutter](https://flutter.dev/) (Language: Dart)
* **IDE:** Visual Studio Code / Android Studio

### **Backend & BaaS (Backend as a Service)**
* **Authentication:** Firebase Authentication (Email/Password and Google Sign-In)
* **Database:** Cloud Firestore (Real-time NoSQL database)

### **APIs & External Services**
* **Google Shopping API:** Fetches real-time products and enables multi-store price comparisons.
* **Key Dependencies:** `http`, `url_launcher`, `image_picker`, `shared_preferences`.

---



## 📋 Prerequisites

Before running or building the project, ensure you have:

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.9.2+ compatible)
* [Android Studio](https://developer.android.com/studio) / VS Code with Flutter and Dart plugins
* An Android Emulator or physical test device
* A configured project on [Google Firebase](https://firebase.google.com/)

---

## Installation & Setup

# 1. Clone the repository and navigate into the project folder
git clone https://github.com/your-username/sportly.git
cd sportly

# 2. Install dependencies
flutter pub get

# 3. Create environment variables file and add your API keys
cp .env.example .env
# SERPAPI_KEY=your_serpapi_key_here
# RAPIDAPI_KEY=your_rapidapi_key_here

# 4. Configure Firebase
flutterfire configure

# 5. Run the application
flutter run
