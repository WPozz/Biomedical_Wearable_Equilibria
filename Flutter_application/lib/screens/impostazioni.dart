import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application/providers/settings_provider.dart';
import 'package:flutter_application/screens/goals.dart';
import 'package:flutter_application/screens/notifiche.dart';

class ImpostazioniScreen extends StatelessWidget {
  const ImpostazioniScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final isItalian = settings.isItalian;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isItalian ? 'Impostazioni' : 'Settings',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // --- SEZIONE 1: IMPOSTAZIONI GENERALI ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // 1. Goals
                      _buildSettingsTile(
                        context: context,
                        title: isItalian ? 'Obiettivi' : 'Goals',
                        icon: Icons.emoji_events_outlined,
                        color: colorScheme.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GoalsScreen(),
                          ),
                        ),
                      ),
                      
                      const Divider(height: 1, indent: 60, endIndent: 20),

                      // 2. Notifications
                      _buildSettingsTile(
                        context: context,
                        title: isItalian ? 'Notifiche' : 'Notifications',
                        icon: Icons.notifications_outlined,
                        color: colorScheme.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificheScreen(),
                          ),
                        ),
                      ),

                      const Divider(height: 1, indent: 60, endIndent: 20),

                      // 3. Language 
                      _buildLanguageTile(context, settings, colorScheme),

                      const Divider(height: 1, indent: 60, endIndent: 20),

                      // 4. Change password
                      _buildSettingsTile(
                        context: context,
                        title: isItalian ? 'Cambia password' : 'Change password',
                        icon: Icons.lock_outline,
                        color: colorScheme.primary,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- SEZIONE 2: PRIVACY E HR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  isItalian ? 'PRIVACY' : 'PRIVACY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.people_outline, color: colorScheme.primary),
                    ),
                    title: Text(
                      isItalian ? 'Condividi dati con HR' : 'Share data with HR',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isItalian
                          ? 'Contribuisci in modo anonimo al report stress del tuo reparto'
                          : 'Anonymously contribute to your department stress report',
                    ),
                    value: settings.shareHRData,
                    activeColor: colorScheme.primary,
                    // MODIFICA LOGICA: Controlliamo se si sta accendendo o spegnendo
                    onChanged: (newValue) {
                      if (newValue == true) {
                        // Vuole accenderlo: apriamo il dialogo
                        _mostraDialogoConsensoHR(context, settings, colorScheme);
                      } else {
                        // Vuole spegnerlo: spegniamo subito senza chiedere nulla
                        context.read<SettingsProvider>().setShareHRData(false);
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 12),

              // Nota informativa
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  isItalian
                      ? '🔒 I tuoi dati individuali non saranno mai visibili all\'HR. Viene condivisa solo la media anonima del reparto.'
                      : '🔒 Your individual data is never visible to HR. Only the anonymous department average is shared.',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // --- Finestra di dialogo per il consenso HR ---
  void _mostraDialogoConsensoHR(BuildContext context, SettingsProvider settings, ColorScheme colorScheme) {
    final isItalian = settings.isItalian;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isItalian ? "Consenso condivisione — Kairos" : "Data sharing consent — Kairos",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          // Usiamo ScrollView per evitare che il testo sbordi su schermi piccoli
          content: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.4),
                children: [
                  TextSpan(
                    text: isItalian
                        ? "Abilitando questa opzione, acconsenti a condividere i tuoi dati di benessere pseudonimizzati con il dipartimento HR della tua organizzazione.\n\n"
                        : "By enabling this option, you agree to share your pseudonymised wellness data with your organisation's HR department.\n\n",
                  ),
                  TextSpan(
                    text: isItalian ? "Cosa viene condiviso: " : "What is shared: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: isItalian
                        ? "I tuoi dati vengono trasmessi a un server sicuro utilizzando un identificatore pseudonimo — il tuo nome e i tuoi dettagli personali non vengono mai inclusi. I dati vengono aggregati a livello di reparto prima di essere resi accessibili all'HR. Solo queste medie aggregate a livello di reparto sono visibili al personale HR.\n\n"
                        : "Your data is transmitted to a secure server using a pseudonymous identifier — your name and personal details are never included. Data is aggregated at department level before being made accessible to HR. Only these aggregated, department-level averages are visible to HR personnel.\n\n",
                  ),
                  TextSpan(
                    text: isItalian ? "Cosa non viene condiviso: " : "What is not shared: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: isItalian
                        ? "Nessuna informazione di identificazione personale viene trasmessa. Le tue misurazioni individuali vengono elaborate esclusivamente allo scopo di calcolare le medie di reparto e non sono accessibili all'HR in alcuna forma individuale.\n\n"
                        : "No personally identifiable information is transmitted. Your individual measurements are processed solely for the purpose of computing department averages and are not accessible to HR in any individual form.\n\n",
                  ),
                  TextSpan(
                    text: isItalian ? "Chi può accedervi: " : "Who can access it: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: isItalian
                        ? "Solo il personale HR autorizzato all'interno della tua organizzazione può accedere ai report aggregati del reparto.\n\n"
                        : "Only authorised HR personnel within your organisation may access the aggregated department reports.\n\n",
                  ),
                  TextSpan(
                    text: isItalian ? "Per quanto tempo vengono conservati: " : "How long is it kept: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: isItalian
                        ? "I dati individuali pseudonimizzati vengono conservati sul server per il tempo minimo necessario a calcolare gli aggregati mensili, dopodiché solo il report aggregato viene conservato per un massimo di 12 mesi.\n\n"
                        : "Pseudonymised individual data is retained on the server for the minimum time necessary to compute monthly aggregates, after which only the aggregated report is kept for up to 12 months.\n\n",
                  ),
                  TextSpan(
                    text: isItalian ? "I tuoi diritti: " : "Your rights: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: isItalian
                        ? "Puoi revocare il tuo consenso in qualsiasi momento disabilitando questa opzione in Impostazioni → Privacy. La revoca ha effetto immediato e impedisce qualsiasi condivisione futura. I dati aggregati trasmessi in precedenza non possono essere rimossi retroattivamente, poiché fanno parte di medie di reparto anonimizzate. Hai anche il diritto di richiedere la cancellazione dei tuoi dati pseudonimizzati dai nostri server in qualsiasi momento contattando [il titolare del trattamento dei dati della tua organizzazione].\n\n"
                        : "You may withdraw your consent at any time by disabling this option in Settings → Privacy. Withdrawal takes effect immediately and prevents any future sharing. Previously transmitted aggregated data cannot be retroactively removed, as it forms part of anonymised department averages. You also have the right to request deletion of your pseudonymised data from our servers at any time by contacting [your organisation's data controller].\n\n",
                  ),
                  TextSpan(
                    text: isItalian
                        ? "Toccando \"Acconsento\", confermi di aver letto e compreso quanto sopra."
                        : "By tapping \"I agree\", you confirm that you have read and understood the above.",
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                isItalian ? "Annulla" : "Cancel",
                style: const TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                // Chiude semplicemente la finestra, il bottone resta su OFF
                Navigator.pop(context);
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
              child: Text(
                isItalian ? "Acconsento" : "I agree",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                // Manda il segnale di accensione al provider e chiude
                context.read<SettingsProvider>().setShareHRData(true);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // --- Tile LINGUA con bottom sheet ---
  Widget _buildLanguageTile(BuildContext context, SettingsProvider settings, ColorScheme colorScheme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(Icons.language, color: colorScheme.primary),
      ),
      title: Text(
        settings.isItalian ? 'Lingua' : 'Language',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            settings.isItalian ? 'Italiano 🇮🇹' : 'English 🇬🇧',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
      onTap: () => _mostraSceltaLingua(context, settings, colorScheme),
    );
  }

  void _mostraSceltaLingua(BuildContext context, SettingsProvider settings, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(settings.isItalian ? 'Scegli la lingua' : 'Choose language', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: const Text('🇮🇹', style: TextStyle(fontSize: 28)),
                  title: const Text('Italiano', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  trailing: settings.isItalian ? Icon(Icons.check_circle, color: colorScheme.primary, size: 28) : null,
                  onTap: () {
                    context.read<SettingsProvider>().setLocale(const Locale('it'));
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 28)),
                  title: const Text('English', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  trailing: !settings.isItalian ? Icon(Icons.check_circle, color: colorScheme.primary, size: 28) : null,
                  onTap: () {
                    context.read<SettingsProvider>().setLocale(const Locale('en'));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Tile generica ---
  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}