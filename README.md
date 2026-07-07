# **Biomedical Wearable Project**

## **Working Groups:**

Sustainable Development Goal 3 (Good health and well-being: Ensure healthy lives and promote well-being for all at all ages), Target 3.5 (Strengthen the prevention and treatment of substance abuse, including narcotic drug abuse and harmful use of alcohol). For more information see: https://sdgs.un.org/goals/goal3. (Max number of groups: 5)


# 🧠 Kairos: Stress Monitoring & Muscle Mass Loss Prevention

---

## 1. Input Data

### Wearable Data (API Synchronization: (Fitbit))

* **Heart Rate (HR / HRV):** Heart rate and Heart Rate Variability (crucial for stress).
* **Sleep:** Total hours.
* **Movement:** Daily steps.

### User Data (Manual Entry)

**Essential:**

* Age
* Gender
* Height and Weight
* Job profession/occupation
* Company department

**Non-Essential (for advanced profiling):**

* Commuting method (Car, public transport, bike, walking).
* Weekly physical activity level and type.
* Specific medical conditions or previous injuries.

---

## 2. Processing and Results (Output)

### User Side (Employee)

* **Real-time Stress Index:** (Low 🟢, Medium 🟡, High 🔴) based on HRV and sleep quality.
* **Sedentary Notifications:** Warnings if you have been inactive for too long.
* **Reports:** Weekly, monthly, and yearly dashboards (highlighting the most stressful days/months).

### Company Side (Employer / HR)

* **Corporate Wellness Dashboard:** Wellness supervision through **exclusively aggregated and anonymous** data.
* **Department Comparison:** Comparative analysis (e.g., Logistics vs. Administration).
* **Benchmark:** Comparison of corporate wellness against the local/national industry average.

---

## 3. Additional Features and Gamification

* **Postural Exercises:** Short video clips/illustrations for desk or workstation stretching.
* **Login System:** Secure authentication with Email and Password (possible expansion to corporate SSO or Google/Apple login).

---

## 4. Target Audience and Future Developments

**Main Target:**

* Office workers (sedentary).
* Truck drivers / bus drivers / pilots (ergonomic risk).
* Nurses / doctors (exhausting shifts and high acute stress).

**Future Development Roadmap:**

* **Stress Map:** Geographical or floor-plan mapping of locations and jobs with the highest risk.
* **Company Ranking:** Rating system to rank companies (and departments) based on stress levels and guaranteed well-being, useful for attracting talent.
* **Less Obtrusive Measurement:** Using smart bracelets/rings instead of watches to make measurement less invasive and stressful for the user.

---

## 5. Onboarding Questionnaire (Done)

1. **Is your job physically active or sedentary?** *(Very sedentary / Mostly standing / Very active)*
2. **How often can you take a break of at least 2 minutes?** *(Less than every hour / Every 1-2 hours / Every 3-4 hours / Almost never)*
3. **How important is mental health in the workplace to you?** *(Scale from 1 to 5)*
4. **Would you like your employer to care more about employee mental health?** *(Yes / Indifferent / No)*
5. **Would you wear a smartwatch during the day (and at night) to monitor your well-being, ensuring data anonymity from the company?** *(Yes, always / Only during the day / No)*
6. **Would you like to have an overview of your mental health and stress trends?** *(Yes / No)*
7. **How often do you exercise?**
* Less than 3 times a week
* 3-5 times a week
* Almost every day


8. **What would you like to know about your well-being in the workplace?** *(Open text field for feedback and ideas)*

> **⚠️ Notes on Privacy and GDPR:**
> Due to privacy laws, individual health or stress data **cannot** be sent to the employer. The system must **anonymize and aggregate** the data. The employer will only see group statistics (e.g., "IT Department"), without ever tracing back to the individual employee.
> 
> **💪 Note on Muscle Mass:**
> To track muscle mass loss in the absence of direct data from standard wearables, it is recommended to integrate data from impedance body scales or specific strength training tracking.
