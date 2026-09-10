# 📺 Enrico Papi Anti-Distrazione: "STUDIA, NON TI DISTRARRE!"

Un'applicazione nativa per **macOS** scritta in **Swift** e **SwiftUI** che utilizza l'accelerazione hardware Apple (**Vision Framework** e Neural Engine) per monitorare lo sguardo e la postura tramite webcam.

Se ti distrai e smetti di guardare lo schermo del Mac (es. guardi il telefono verso il basso, ti volti altrove o lasci la scrivania), compare istantaneamente un overlay a schermo intero sopra qualsiasi finestra o applicazione con la faccia di **Enrico Papi**, la scritta cubitale lampeggiante **"STUDIA, NON TI DISTRARRE!"** e allarmi vocali/sonori!

Appena rialzi lo sguardo verso il computer, l'allarme **scompare automaticamente** e puoi riprendere lo studio!

---

## 🚀 Avvio Rapido

Puoi avviare l'applicazione in uno dei seguenti modi:

1. **Da Terminale**:
   ```bash
   ./run.sh
   ```
   oppure:
   ```bash
   open EnricoPapi.app
   ```
2. **Da Finder**:
   Fai doppio clic sull'applicazione **`EnricoPapi.app`** nella cartella del progetto.

> [!NOTE]
> Al primo avvio macOS richiederà l'autorizzazione all'uso della fotocamera: fai clic su **Consenti**. Tutte le immagini vengono elaborate in tempo reale solo nella RAM del tuo Mac, nessuna immagine viene salvata o trasmessa all'esterno.

---

## 🎯 Come Funziona il Rilevamento dello Sguardo

Il motore integrato analizza la webcam a 60 FPS monitorando:

1. **Sguardo al Telefono / Inclinazione Testa (Pitch)**:
   - Rileva quando abbassi il capo o gli occhi verso la scrivania/grembo per consultare lo smartphone.
2. **Sguardo Altrove / Rotazione Testa (Yaw)**:
   - Rileva se volti la testa a destra o sinistra lontano dal monitor.
3. **Assenza dalla Scrivania**:
   - Rileva se ti alzi e lasci la postazione di studio.
4. **Colpi di Sonno / Occhi Chiusi**:
   - Rileva se le palpebre rimangono chiuse per stanchezza.
5. **Filtro Anti Falsi Positivi**:
   - Puoi impostare un tempo di tolleranza continuo (es. 1.5 secondi) in modo che sbattere normalmente le palpebre o leggere una riga in fondo allo schermo non attivi l'allarme per sbaglio.

---

## ✨ Funzionalità dell'App

- **Overlay di Sistema ad Alto Impatto (`.screenSaver`)**:
  - Compare sopra a qualsiasi applicazione aperta su macOS (PDF a schermo intero in Anteprima, Word, browser, desktop virtuali).
  - Grafica animata di Enrico Papi con bagliore neon, effetto scuotimento dello schermo (*screen shake*) e scritta tridimensionale gigante.
  - Scompare da solo non appena torni a guardare lo schermo.
- **Audio e Voce Italiana (`AVSpeechSynthesizer`)**:
  - Voce con rimproveri casuali:
    - *"Ti ho visto! Studia, non ti distrarre!"*
    - *"Metti giù quel telefono e torna sui libri!"*
    - *"Mooseca! Guarda lo schermo e studia!"*
  - Possibilità di disattivare audio e voce con un clic (per quando studi in biblioteca).
- **Timer Pomodoro Integrato**:
  - 25 minuti di studio concentrato / 5 minuti di pausa caffè.
  - Durante la modalità pausa relax, Enrico Papi va automaticamente in standby per lasciarti guardare il telefono in pace.
- **Contatore "Beccato da Papi"**:
  - Tiene traccia di quante volte sei stato colto in flagrante durante la sessione di studio.
- **Regolazione Sensibilità**:
  - Slider per il tempo di reazione (da 0.5s a 4.0s).
  - Slider per la soglia inclinazione smartphone e rotazione testa.
- **Icona nella Barra dei Menu (Menu Bar)**:
  - L'app continua a proteggerti in background anche se chiudi la finestra di configurazione.

---

## 🖼️ Personalizzare l'Immagine di Enrico Papi

L'app include già una caricatura procedurale vettoriale stilizzata di Enrico Papi con occhiali, fiamme e occhi laser.

Se vuoi usare una foto reale o un meme specifico:
1. Salva la tua immagine preferita nella cartella `Assets/` rinominandola in:
   `Assets/enrico_papi.jpg` oppure `Assets/enrico_papi.png`
2. Esegui `./build_app.sh` per aggiornare il bundle.
3. Riavvia l'applicazione!

---

## 🛠️ Ricompilazione

Per ricompilare l'app in qualsiasi momento:
```bash
./build_app.sh
```
