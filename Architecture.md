# 🧠 Kairos: 

## 📌 Project Overview
This mobile application focuses on employee well-being as it balances "cold" biometric data (via Wearable APIs like Fitbit) with "hot" psychological data (Emotional Check-ins) to monitor stress levels and prevent muscle loss due to workplace sedentism. 

The architecture is built on the principles of **Health Design Thinking**:
- **Human-centered**: Designed with empathy to avoid overwhelming a stressed user.
- **Privacy-first**: Transparent data management to build trust between employees and the company.

---

## 🏛️ UI Architecture (The 4-Tab Navigation)
The app utilizes a flat navigation pattern via a `BottomNavigationBar` paired with an `IndexedStack` to preserve state across tabs.

### 1. Live Dashboard (Home)
Focuses on immediate feedback and context-aware alerts.
- **Stress Gauge**: A real-time visual indicator (0-100) based on HRV (Heart Rate Variability).
- **Quick Metrics**: Daily steps, sleep duration, and active calories.
- **Contextual Muscle Alert**: A smart banner that triggers only after prolonged inactivity (e.g., 60 minutes) suggesting a quick stretch.

<img width="1280" height="720" alt="immagine" src="https://github.com/user-attachments/assets/9e6bd0cd-637f-46cf-80ef-9e66316cce89" />

### 2. Analysis & Trends
Helps the user understand long-term patterns and social determinants of their health.
- **HRV Weekly Trend**: Line charts visualizing stress peaks.
- **Context Logging**: Interface to map daily stress against external factors (e.g., long meetings, traffic).

### 3. Recovery & Check-in
Actionable tools to mitigate stress and physical tension.
- **Exercise Library**: A grid of quick posture/stretching video routines.
- **Emotional Check-in**: A daily rapid slider/emoji input to track perceived psychological stress versus physiological data.

### 4. Profile & Privacy
User control center ensuring total data transparency.
- **User Identity**: Work department and professional role.
- **Privacy Controls**: Toggles to manage what aggregated data is shared with the employer.
- **Device Management**: Wearable API synchronization status.

---

## 💻 Technical Stack & Implementation Plan

### Folder Structure
```text
lib/
 ├── main.dart
 ├── models/          # Data structures (User, HealthMetrics)
 ├── providers/       # State Management (HealthDataProvider)
 ├── screens/         # Main UI Tabs (Home, Analysis, Recovery, Profile)
 ├── services/        # APIs & Background tasks (FitbitAPI, LocalNotifs)
 └── widgets/         # Reusable UI components (StressGauge, MuscleAlert)
```

### 2. Architectural diagramm (Codice SVG)

![App Architecture](./Architecture.svg)


---

# Navigation bar: 

## Homepage

* Colorful widget.
* Pause button
* Quick metrics
* Goal 

## Data Page

* Listview with metrics (with the ability to view them day by day) featuring the Stress Index first.
* Clicking on a single metric shows the trend for that metric (week/month).

## Exercises

* 4 quick "generic" exercises
* Scrollable listview with all exercises
* "Search exercise" button that opens a screen with a body map/image and time.

## User Profile:

* Personal data
* Monthly report (yearly collection)
* Notifications (quick with on/off and settings)
* Goals

