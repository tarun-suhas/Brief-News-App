import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:news_app/generated/app_localizations.dart';
import '../../models/news_model.dart';
import '../../services/news_service.dart';
import '../../services/auth_service.dart';
import '../filters/category_chips.dart';
import '../auth/login_screen.dart';
import 'news_card.dart';
import '../../core/widgets/logout_dialog.dart';
import '../../core/constants/locations.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  String _selectedCategory = 'All';
  String? _selectedLocationScope; // null means show all (equivalent to 'All')
  String? _selectedState;
  String? _selectedDistrict;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.location_on_outlined, color: Colors.white),
          onPressed: _showLocationFilter,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              LogoutDialog.show(context, onConfirm: () async {
                await context.read<AuthService>().signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<NewsModel>>(
            stream: context.read<NewsService>().getNewsStream(
              category: _selectedCategory,
              locationScope: _selectedLocationScope,
              state: _selectedState,
              district: _selectedDistrict,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      "${AppLocalizations.of(context)!.errorLoading}\n\n${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text(AppLocalizations.of(context)!.noNews));
              }

              final news = snapshot.data!;
              return PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: news.length,
                itemBuilder: (context, index) {
                  return NewsCard(newsItem: news[index]);
                },
              );
            },
          ),
          
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: CategoryChips(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.locationScope, style: AppTextStyles.h2),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                initialValue: _selectedLocationScope,
                  dropdownColor: AppColors.surface,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.locationScope,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("అన్నీ")), // "All" in Telugu
                    ...AppLocations.scopes.map((scope) {
                      return DropdownMenuItem(value: scope, child: Text(scope));
                    }),
                  ],
                  onChanged: (val) {
                    setModalState(() {
                      _selectedLocationScope = val;
                      _selectedState = null;
                      _selectedDistrict = null;
                    });
                    setState(() {});
                  },
                ),
                if (_selectedLocationScope == AppLocations.scopes[1]) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedState,
                    dropdownColor: AppColors.surface,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.selectState,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("అన్ని రాష్ట్రాలు")), // "All States"
                      ...AppLocations.indiaStatesAndDistricts.keys.map((state) {
                        return DropdownMenuItem(value: state, child: Text(state));
                      }),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        _selectedState = val;
                        _selectedDistrict = null;
                      });
                      setState(() {});
                    },
                  ),
                  if (_selectedState != null) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedDistrict,
                      dropdownColor: AppColors.surface,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.selectDistrict,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("అన్ని జిల్లాలు")), // "All Districts"
                        ...AppLocations.indiaStatesAndDistricts[_selectedState!]!.map((dist) {
                          return DropdownMenuItem(value: dist, child: Text(dist));
                        }),
                      ],
                      onChanged: (val) {
                        setModalState(() => _selectedDistrict = val);
                        setState(() {});
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(AppLocalizations.of(context)!.cancel.replaceFirst(RegExp('.*'), "పూర్తయింది"), style: AppTextStyles.button), // "Done" in Telugu
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
