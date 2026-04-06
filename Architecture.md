# 🧠 Stress Monitor & Muscle Preservation App  Architecture: 

> ( Nome da scegliere )

## 📌 Project Overview
This mobile application focuses on employee well-being as it balances "cold" biometric data (via Wearable APIs like Fitbit) with "hot" psychological data (Emotional Check-ins) to monitor stress levels and prevent muscle loss due to workplace sedentism. 

The architecture is built on the principles of **Health Design Thinking**:
- **Human-centered**: Designed with empathy to avoid overwhelming a stressed user.
- **Privacy-first**: Transparent data management to build trust between employees and the company.

> ( altra roba di Cappon ) 

---

## 🏛️ UI Architecture (The 4-Tab Navigation)
The app utilizes a flat navigation pattern via a `BottomNavigationBar` paired with an `IndexedStack` to preserve state across tabs.

### 1. Live Dashboard (Home)
Focuses on immediate feedback and context-aware alerts.
- **Stress Gauge**: A real-time visual indicator (0-100) based on HRV (Heart Rate Variability).
- **Quick Metrics**: Daily steps, sleep duration, and active calories.
- **Contextual Muscle Alert**: A smart banner that triggers only after prolonged inactivity (e.g., 60 minutes) suggesting a quick stretch.

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

### 2. Diagramma Architetturale (Codice SVG)

