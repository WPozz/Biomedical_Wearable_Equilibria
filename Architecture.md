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
Theapp utilizes a flat navigation pattern via a `BottomNavigationBar` paired with an `IndexedStack` to preserve state across tabs.

### 1. Homepage
Focuses on immediate feedback and context-aware alerts.
- widget colorato (sort of graphic indicator)
- Tasto pausa 
- Metriche veloci 
- Facce sorridenti (feedback della giornata) 
- Obiettivo (mini-counter)


<img width="1024" height="559" alt="immagine" src="https://github.com/user-attachments/assets/a48ede11-f659-4b8f-9480-52470c5c2d91" />

---

### 2. Analysis & Trends
- listview con metriche (con possibilità di vederle giorno per giorno) con Stress Index per primo.
- Cliccando sulla singola metrica si vede il trend di quella metrica (settimana/mese)

<img width="1024" height="559" alt="immagine" src="https://github.com/user-attachments/assets/d76f4338-d7f8-434e-85b0-916db6504a18" />

---

### 3. Recovery & Check-in
Actionable tools to mitigate stress and physical tension.
- 4 esercizi "generici" rapidi (al centro)
- listview scrollabile con tutti gli esercizi (filtrabili in ordine alfabetico, di tempo o per distretto)
- tasto di "cerca esercizio" che apre uno schermo con immagine del corpo (indica cosa vorresti allenare) e tempo (quanto tempo hai a disposizione)

<img width="1024" height="559" alt="immagine" src="https://github.com/user-attachments/assets/1c965142-bf16-4a57-975f-8d2fe39cc2fa" />

---

### 4. Profile & Privacy
User control center ensuring total data transparency.
- Dati personali
- Report mensile (raccolta annuale)
- Notifiche (veloce con on-off e impostazioni)
- Obiettivi

<img width="1024" height="559" alt="immagine" src="https://github.com/user-attachments/assets/c1ca03e6-66d1-41e3-98b7-8e65d7e8250c" />

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

![App Architecture](./Architecture.svg)


### 3. Demo (da prendere con le pinze) 

https://app.nowa.dev/home-page


> Nota: Potrebbe capitare che un processo "asincrono" venga compilato dopo il build method che dovrebbe aggiornare (Esempio di counter con valore Null di partenza, il valore di default era Null e non il valore precedente per un missmatch nella velocità di compilazione). Questo classico errore di save-state si può risolvere con uno special widget "future builder". Future builder è un widget che builda seguendo il valore di un "future". 


