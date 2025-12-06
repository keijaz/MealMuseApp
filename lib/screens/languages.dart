// lang.dart
import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/translation_helper.dart';
import 'navbar.dart';

// --------------------------------------------------------------------------
// --- COLOR CONSTANTS (Consistent with account_screen.dart) ---
// --------------------------------------------------------------------------
const Color _kButtonColor = Color(0xFF5B8A94);
const Color _kScreenBackgroundColor = Colors.white;
const Color _kSearchBorderColor = Color(0xFFF3F3F3);
const Color _kSubtleGray = Color(0xFFF5F5F5); 
// --------------------------------------------------------------------------


class Lang extends StatefulWidget {
	const Lang({super.key});
	@override
		LangState createState() => LangState();
	}

class LangState extends State<Lang> {
	@override
	void initState() {
		super.initState();
		// Listen to locale changes and rebuild screen
		LocaleProvider().localeNotifier.addListener(_onLocaleChanged);
	}

	@override
	void dispose() {
		LocaleProvider().localeNotifier.removeListener(_onLocaleChanged);
		super.dispose();
	}

	void _onLocaleChanged() {
		setState(() {});
	}

	@override
	Widget build(BuildContext context) {
		final isDarkMode = ThemeProvider().darkModeEnabled;
		final backgroundColor = isDarkMode ? const Color(0xFF121212) : _kScreenBackgroundColor;
		final textColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
		final dividerColor = isDarkMode ? const Color(0xFF3A3A3A) : _kSearchBorderColor;
		final langTitle = TranslationHelper.get('language');

		return Scaffold(
			bottomNavigationBar: CustomBottomNavBar(
				onTabContentTapped: (index) {},
				currentIndex: 4,
				navContext: context,
			),
			body: SafeArea(
				child: Container(
					constraints: const BoxConstraints.expand(),
					color: backgroundColor,
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							// Sleek Header Section (Consistent with account_screen.dart)
							Padding(
								padding: const EdgeInsets.only(top: 20, bottom: 20, left: 15, right: 15),
								child: Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: [
										// Back Button (Functional)
										GestureDetector(
											onTap: () => Navigator.pop(context),
											child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 28),
										),
										Text(
										langTitle,
										style: TextStyle(
											color: textColor,
											fontSize: 32,
										),
										),
										const SizedBox(width: 34), // Spacer
									],
								),
							),
							Divider(color: dividerColor, thickness: 1.5, height: 0),
							
							Expanded(
								child: SingleChildScrollView(
									padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											// Language selection is wired to LocaleProvider; use ValueListenableBuilder to reflect changes instantly
											ValueListenableBuilder<Locale?>(
												valueListenable: LocaleProvider().localeNotifier,
												builder: (context, locale, _) {
												final langCode = locale?.languageCode ?? 'en';
												final englishLabel = TranslationHelper.get('english');
												final urduLabel = TranslationHelper.get('urdu');
												return Column(
													children: [
														_LanguageSelectionTile(
															language: englishLabel,
															isSelected: langCode == 'en',
															onTap: () async {
															await LocaleProvider().setLocale(const Locale('en'));
														},
														),
														_LanguageSelectionTile(
															language: urduLabel,
															isSelected: langCode == 'ur',
															onTap: () async {
															await LocaleProvider().setLocale(const Locale('ur'));
														},
														),
													],
												);
												},
											),
										],
									),
								),
							),
						],
					),
				),
			),
			// bottomNavigationBar: _BottomNavigationBar(
			//   navigateTo: _navigateTo,
			//   navigateHome: _navigateHome,
			//   // Active Profile Icon in the Nav Bar for this screen
			//   navigateToProfile: () => _navigateTo(context, const ProfileNSettings()),
			//   activeIcon: Icons.person,
			// ),
			);
	}
}

// --------------------------------------------------------------------------
// --- WIDGET: Language Selection Tile (New) ---
// --------------------------------------------------------------------------
class _LanguageSelectionTile extends StatelessWidget {
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageSelectionTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeProvider().darkModeEnabled;
    final unselectedColor = isDarkMode ? const Color(0xFF2A2A2A) : _kSubtleGray;
    final unselectedTextColor = isDarkMode ? const Color(0xFFE1E1E1) : Colors.black;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? _kButtonColor : unselectedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kButtonColor : unselectedColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? _kButtonColor.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        margin: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: TextStyle(
                color: isSelected ? Colors.white : unselectedTextColor,
                fontSize: 18,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}