import 'package:flutter/material.dart';
import 'package:plop/core/services/notification_service.dart';
import 'package:plop/core/services/user_service.dart';
import 'package:plop/features/contacts/contact_list_screen.dart';
import 'package:plop/features/setup/import_account_screen.dart';
import 'package:plop/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _usernameController = TextEditingController();
  final UserService _userService = UserService();
  int _currentPage = 0;
  bool _isLoading = false;

  void _createUser() async {
    if (_isLoading || _usernameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    await _userService.init();
    final bool success = await _userService.createUser(_usernameController.text);
    if (_userService.hasUser()) {
      await sendFcmTokenToServer();
    }


    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => ContactListScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.serverConnectionError(dotenv.env['BASE_URL']!))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center( // Centre le contenu horizontalement
        child: ConstrainedBox( // Limite la largeur sur les grands écrans
          constraints: const BoxConstraints(maxWidth: 700),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildIntroPage(),
                      _buildFeaturePage(
                        icon: Icons.shield_outlined,
                        title: "Comment ça marche ?",
                        features: [
                          "Aucune inscription, juste un pseudo.",
                          "Ajoutez des contacts avec des codes uniques et temporaires.",
                          "Envoyez des 'Plop' ou des messages rapides.",
                          "Rien n'est stocké sur nos serveurs.",
                        ],
                      ),
                      _buildFeaturePage(
                        icon: Icons.apps_outage_outlined,
                        title: "Quelques cas d'usage",
                        features: [
                          "Prévenir un proche que vous êtes bien arrivé.",
                          "Signaler à votre équipe que la partie en ligne commence.",
                          // "Recevoir une alerte de vos appareils connectés (domotique).",
                          "Un simple 'coucou' sans attendre de réponse.",
                        ],
                      ),
                      _buildFinalPage(),
                    ],
                  ),
                ),
                _buildNavigationControls(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bubble_chart_outlined, size: 100, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          Text(
            "Bienvenue sur Plop",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            "La messagerie ultra-simple, éphémère et respectueuse de votre vie privée.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePage({required IconData icon, required String title, required List<String> features}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Icon(icon, size: 60, color: Theme.of(context).primaryColor)),
          const SizedBox(height: 24),
          Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
          ...features.map((text) => ListTile(
            leading: Icon(Icons.check_circle_outline, color: Colors.green),
            title: Text(text),
          )),
        ],
      ),
    );
  }

  Widget _buildFinalPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.letsGo, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Choisissez votre pseudo',
                    border: OutlineInputBorder(),
                  ),maxLength: 20,
                  onSubmitted: (_) => _createUser(),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _createUser,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      backgroundColor: Colors.green, // Couleur plus visible
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.rocket_launch),
                    label: Text(AppLocalizations.of(context)!.createMyAccount),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ImportAccountScreen()));
                  },
                  child:  Text(AppLocalizations.of(context)!.importAccountTitle),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final url = Uri.parse('https://www.buymeacoffee.com/antoineo'); // URL de don à remplacer
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(AppLocalizations.of(context)!.supportDevelopment),
          )
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Padding(
      // CORRECTION: L'espacement vertical a été ajusté pour une meilleure aération.
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton Précédent
          if (_currentPage > 0)
            OutlinedButton.icon(
              onPressed: () => _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeOut),
              icon: const Icon(Icons.arrow_back),
              label:  Text(AppLocalizations.of(context)!.previous),
            )
          else
            const SizedBox(width: 120), // Espace vide pour garder l'alignement

          // Indicateur de page
          Row(
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey.shade400,
                ),
              );
            }),
          ),

          // Bouton Suivant
          if (_currentPage < 3)
            ElevatedButton.icon(
              onPressed: () => _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeIn),
              label: Text(_currentPage == 2 ? 'Terminer' : 'Suivant'),
              icon: const Icon(Icons.arrow_forward),
            )
          else
            const SizedBox(width: 120), // Espace vide pour garder l'alignement
        ],
      ),
    );
  }
}