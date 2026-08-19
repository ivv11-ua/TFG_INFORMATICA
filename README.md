# Sportly - Sports Product Search and Comparison Mobile Application

**Sportly** is a cross-platform mobile application developed as a Bachelor's Thesis (TFG) in Computer Engineering at the University of Alicante. The platform centralizes the search, price comparison, and technical specification review of sports products from various online retailers (such as Nike, Adidas, Decathlon, Sprinter, etc.) into a single place, facilitating informed and efficient decision-making.

---

## 🚀 Key Features

* **Centralized Search:** Explore sports product catalogs from different brands and stores in real time.
* **Product Comparator:** Side-by-side technical specs and price comparison for up to 3 products simultaneously.
* **Favorites Management:** Save preferred items to monitor price or status updates.
* **Advanced Filters:** Filter items by sport category (Football, Running, Tennis, etc.), brand, and price range[cite: 2].
* **Flexible Authentication:** Sign in using Email/Password, Google Sign-In, or Guest Mode[cite: 2].
* **User Profile:** Customize personal details and profile picture[cite: 2].
* **External Redirection:** Direct link to the official store to complete purchases[cite: 2].

---

## 🛠️ Tech Stack & Technologies

### **Frontend**
* **Framework:** [Flutter](https://flutter.dev/) (Language: Dart)[cite: 2]
* **IDE:** Visual Studio Code / Android Studio[cite: 2]

### **Backend & BaaS (Backend as a Service)**
* **Authentication:** Firebase Authentication (Email/Password and Google Sign-In)[cite: 2]
* **Database:** Cloud Firestore (Real-time NoSQL database)[cite: 2]

### **APIs & External Services**
* **Google Shopping API (SerpAPI):** Fetches real-time products and enables multi-store price comparisons[cite: 2].
* **Nike API (RapidAPI):** Specialized product catalog integration[cite: 2].
* **Key Dependencies:** `http`, `url_launcher`, `image_picker`, `shared_preferences`[cite: 2].

---

## 🏗️ Project Architecture

The project follows the principles of **Clean Architecture / MVVM**, organized within the `lib/` directory as follows[cite: 2]:

```text
lib/
├── data/             # Local and mock data for offline testing
├── models/           # Data models (Product, User, etc.) and API adapters
├── screens/          # UI views (Home, Favorites, Compare, Profile, Auth)
├── services/         # Business logic and integration with Firebase & external APIs
└── main.dart         # Main entry point of the application
```[cite: 2]

---

## 📋 Prerequisites

Before running or building the project, ensure you have:

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart 3.9.2+ compatible)[cite: 2]
* [Android Studio](https://developer.android.com/studio) / VS Code with Flutter and Dart plugins[cite: 2]
* An Android Emulator or physical test device[cite: 2]
* A configured project on [Google Firebase](https://firebase.google.com/)[cite: 2]

---

## 🔧 Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/your-username/sportly.git](https://github.com/your-username/sportly.git)
   cd sportly
