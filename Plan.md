# 🧠 App: Monitoraggio Stress + Prevenzione Perdita Massa Muscolare

---

## 1. Dati in Ingresso (Input)

### Dati da Wearable (Sincronizzazione API:  (Fitbit)
* **Heart Rate (HR / HRV):** Battito cardiaco e Variabilità della Frequenza Cardiaca (cruciale per lo stress).
* **Sonno:** Ore totali, fasi del sonno, interruzioni.
* **Movimento:** Passi giornalieri, calorie bruciate (attive e a riposo).
* **Dati corporei (Se disponibili):** Composizione corporea da bilance smart (Massa grassa / Massa magra).

### Dati Utente (Inserimento Manuale)

**Essenziali:**
* Età
* Sesso
* Altezza e Peso
* Professione lavorativa
* Reparto aziendale di appartenenza

**Non Essenziali (per profilazione avanzata):**
* Modalità di spostamento casa-lavoro (Auto, mezzi pubblici, bici, a piedi).
* Livello e tipo di attività fisica settimanale.
* Patologie specifiche o infortuni pregressi.

---

## 2. Elaborazione e Risultati (Output)

### Lato Utente (Dipendente)
* **Indice di Stress in tempo reale:** (Basso 🟢, Medio 🟡, Alto 🔴) basato su HRV e qualità del sonno.
* **Notifiche di Sedentarietà:** Avvisi (Warning) se si è fermi da troppo tempo.
* **Trend Personale:** Analisi predittiva (es. *"Hai un indice di stress alto da 3 giorni, conviene che riduci il carico di lavoro oggi"*).
* **Resoconti:** Dashboard settimanale, mensile e annuale (con evidenza dei giorni/mesi più stressanti).

### Lato Azienda (Datore di lavoro / HR)
* **Dashboard Benessere Aziendale:** Supervisione del benessere tramite dati **esclusivamente aggregati e anonimi**.
* **Confronto Reparti:** Analisi comparativa (es. Logistica vs Amministrazione).
* **Benchmark:** Confronto del benessere aziendale rispetto alla media locale/nazionale del settore.

---

## 3. Funzionalità Aggiuntive e Gamification

* **Esercizi Posturali:** Brevi pillole video/illustrazioni per stretching alla scrivania o in postazione.
* **Check-in Emotivo:** Questionario giornaliero rapido quantificabile tramite "faccine" (emoticon) o slider, per incrociare lo stress percepito con i dati fisiologici.
* **Sistema di Login:** Autenticazione sicura con Email e Password (possibile espansione a SSO aziendale o Google/Apple login).

---

## 4. Target e Sviluppi Futuri

**Target Principale:**
* Lavoratori d'ufficio (sedentari).
* Camionisti / autisti autobus / piloti (rischio ergonomico).
* Infermieri / medici (turni logoranti e alto stress acuto).

**Roadmap Sviluppi Futuri:**
* **Mappa dello stress:** Mappatura geografica o per planimetria dei luoghi e lavori a maggior rischio.
* **Classifica Aziende:** Sistema di rating per classificare le aziende (e i reparti) in base al livello di stress e benessere garantito, utile per attrarre talenti.
* **Misurazione meno ingombrante**: Utilizzare braccialetti / anelli al posto dell'orologio per rendere la misurazione meno invasiva e stressante per l'utilizzatore.

---

## 5. Questionario di Onboarding (Fatto)

1. **Il tuo lavoro è fisicamente attivo o sedentario?** *(Molto sedentario / Prevalentemente in piedi / Molto attivo)*
2. **Ogni quanto tempo riesci a fare una pausa di almeno 2 minuti?** *(Meno di ogni ora / Ogni 1-2 ore / Ogni 3-4 ore / Quasi mai)*
3. **Quanto è importante per te la salute mentale sul luogo di lavoro?** *(Scala da 1 a 5)*
4. **Vorresti che il tuo datore di lavoro si interessasse di più alla salute mentale dei dipendenti?** *(Sì / Indifferente / No)*
5. **Indosseresti uno smart watch durante la giornata (e di notte) per monitorare il tuo benessere, garantendo l'anonimato dei dati verso l'azienda?** *(Sì, sempre / Solo di giorno / No)*
6. **Vorresti avere un quadro dell'andamento del tuo stato di salute mentale e stress?** *(Sì / No)*
7. **Ogni quanto tempo fai esercizio fisico?** * Meno di 3 volte a settimana
   * 3-5 volte a settimana
   * Praticamente tutti i giorni
8. **Cosa vorresti sapere riguardo al tuo benessere sul posto di lavoro?** *(Campo di testo aperto per feedback e idee)*


> **⚠️ Note su Privacy e GDPR:**
> Per le leggi sulla privacy, **non si possono** inviare dati sanitari o di stress individuali al datore di lavoro. Il sistema dovrà **anonimizzare e aggregare** i dati. Il datore di lavoro vedrà solo statistiche di gruppo (es. "Reparto IT"), senza mai risalire al singolo dipendente.
>
> **💪 Nota sulla Massa Muscolare:**
> Per tracciare la perdita di massa muscolare in assenza di dati diretti dai normali wearable, è raccomandabile integrare i dati di bilance impedenziometriche o il tracciamento specifico degli allenamenti di forza.
