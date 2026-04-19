import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news_app/generated/app_localizations.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/strings.dart';
import '../../models/news_model.dart';
import '../../services/news_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'edit_news_screen.dart';
import '../../core/widgets/logout_dialog.dart';
import '../../core/constants/locations.dart';

class CreatorDashboardScreen extends StatefulWidget {
  const CreatorDashboardScreen({super.key});

  @override
  State<CreatorDashboardScreen> createState() => _CreatorDashboardScreenState();
}

class _CreatorDashboardScreenState extends State<CreatorDashboardScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _sourceNameCtrl = TextEditingController();
  final _sourceUrlCtrl = TextEditingController();
  final _readingTimeCtrl = TextEditingController();
  String _category = AppStrings.categories[1]; // Defaults to first non-all category
  String _searchQuery = '';
  bool _isBreaking = false;
  File? _imageFile;
  bool _isLoading = false;
  
  String _locationScope = AppLocations.scopes[0]; // Default to Global
  String? _selectedState;
  String? _selectedDistrict;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _publishNews() async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.fillFieldsAndImage)));
      return;
    }

    if (_locationScope == AppLocations.scopes[1]) { // India
      if (_selectedState == null || _selectedDistrict == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.selectStateAndDistrict)));
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final uid = authService.currentUserData?.uid ?? '';
      
      final storageUrl = await context.read<StorageService>().uploadNewsImage(_imageFile!);
      
      final news = NewsModel(
        id: '', // Handled by Firestore automatically
        title: _titleCtrl.text,
        content: _contentCtrl.text,
        imageUrl: storageUrl,
        category: _category,
        isBreaking: _isBreaking,
        createdAt: DateTime.now(),
        createdBy: uid,
        locationScope: _locationScope,
        state: _selectedState,
        district: _selectedDistrict,
        subtitle: _subtitleCtrl.text.trim().isEmpty ? null : _subtitleCtrl.text.trim(),
        sourceName: _sourceNameCtrl.text.trim().isEmpty ? null : _sourceNameCtrl.text.trim(),
        sourceUrl: _sourceUrlCtrl.text.trim().isEmpty ? null : _sourceUrlCtrl.text.trim(),
        readingTime: _readingTimeCtrl.text.trim().isEmpty 
            ? _calculateReadingTime(_contentCtrl.text) 
            : int.tryParse(_readingTimeCtrl.text.trim()),
      );

      if (!mounted) return;
      await context.read<NewsService>().addNews(news);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.newsPublished)));
        _titleCtrl.clear();
        _contentCtrl.clear();
        setState(() {
          _imageFile = null;
          _isBreaking = false;
          _locationScope = AppLocations.scopes[0];
          _selectedDistrict = null;
          _subtitleCtrl.clear();
          _sourceNameCtrl.clear();
          _sourceUrlCtrl.clear();
          _readingTimeCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _calculateReadingTime(String content) {
    if (content.isEmpty) return 1;
    final words = content.trim().split(RegExp(r'\s+')).length;
    final minutes = (words / 200).ceil(); // Average 200 words per minute
    return minutes == 0 ? 1 : minutes;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.creatorDashboard, style: AppTextStyles.h2),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
               icon: const Icon(Icons.logout),
               onPressed: () {
                 LogoutDialog.show(context, onConfirm: () async {
                   await context.read<AuthService>().signOut();
                   if (context.mounted) {
                     Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                   }
                 });
               },
            )
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            labelStyle: AppTextStyles.subtitle.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.createNewsTab, icon: const Icon(Icons.add_circle_outline)),
              Tab(text: AppLocalizations.of(context)!.managePostsTab, icon: const Icon(Icons.grid_view_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCreateTab(),
            _buildManageTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
                image: _imageFile != null ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover) : null,
              ),
              child: _imageFile == null ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.chooseImage, style: AppTextStyles.subtitle),
                ],
              ) : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            style: AppTextStyles.body,
            decoration: _buildInputDecoration(AppLocalizations.of(context)!.titleHint, Icons.title_outlined),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentCtrl,
            maxLines: 5,
            style: AppTextStyles.body,
            decoration: _buildInputDecoration(AppLocalizations.of(context)!.contentHint, Icons.article_outlined),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            dropdownColor: AppColors.surface,
            style: AppTextStyles.body,
            decoration: _buildInputDecoration(AppLocalizations.of(context)!.categoryHint, Icons.category_outlined),
            items: AppStrings.categories.where((c) => c != 'All').map((String cat) {
              return DropdownMenuItem(value: cat, child: Text(_getCategoryLabel(context, cat)));
            }).toList(),
            onChanged: (val) => setState(() => _category = val!),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.breakingNewsToggle, style: AppTextStyles.body),
            activeThumbColor: AppColors.primary,
            value: _isBreaking,
            onChanged: (val) => setState(() => _isBreaking = val),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.locationScope, style: AppTextStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _locationScope,
            dropdownColor: AppColors.surface,
            style: AppTextStyles.body,
            decoration: _buildInputDecoration(AppLocalizations.of(context)!.locationScope, Icons.public_outlined),
            items: AppLocations.scopes.map((String scope) {
              return DropdownMenuItem(value: scope, child: Text(scope));
            }).toList(),
            onChanged: (val) => setState(() {
              _locationScope = val!;
              _selectedState = null;
              _selectedDistrict = null;
            }),
          ),
          if (_locationScope == AppLocations.scopes[1]) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedState,
              dropdownColor: AppColors.surface,
              style: AppTextStyles.body,
              decoration: _buildInputDecoration(AppLocalizations.of(context)!.selectState, Icons.map_outlined),
              items: AppLocations.indiaStatesAndDistricts.keys.map((String state) {
                return DropdownMenuItem(value: state, child: Text(state));
              }).toList(),
              onChanged: (val) => setState(() {
                _selectedState = val;
                _selectedDistrict = null;
              }),
            ),
            if (_selectedState != null) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedDistrict,
                dropdownColor: AppColors.surface,
                style: AppTextStyles.body,
                decoration: _buildInputDecoration(AppLocalizations.of(context)!.selectDistrict, Icons.location_city_outlined),
                items: AppLocations.indiaStatesAndDistricts[_selectedState!]!.map((String district) {
                  return DropdownMenuItem(value: district, child: Text(district));
                }).toList(),
                onChanged: (val) => setState(() => _selectedDistrict = val),
              ),
            ],
          ],
          const SizedBox(height: 32),
          Text(AppLocalizations.of(context)!.optionalInfo, style: AppTextStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          TextField(
            controller: _subtitleCtrl,
            style: AppTextStyles.body,
            decoration: _buildInputDecoration(AppLocalizations.of(context)!.subtitleHint, Icons.short_text_outlined),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sourceNameCtrl,
                  style: AppTextStyles.body,
                  decoration: _buildInputDecoration(AppLocalizations.of(context)!.sourceNameHint, Icons.source_outlined),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _readingTimeCtrl,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.body,
                  decoration: _buildInputDecoration(AppLocalizations.of(context)!.readingTimeHint, Icons.timer_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sourceUrlCtrl,
            style: AppTextStyles.body,
            decoration: _buildInputDecoration(AppLocalizations.of(context)!.sourceUrlHint, Icons.link_outlined),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _publishNews,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, 
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(AppLocalizations.of(context)!.publishNews, style: AppTextStyles.button),
          )
        ],
      ),
    );
  }

  String _getCategoryLabel(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case 'All': return l10n.catAll;
      case 'Politics': return l10n.catPolitics;
      case 'Sports': return l10n.catSports;
      case 'Tech': return l10n.catTech;
      case 'Local': return l10n.catLocal;
      case 'Business': return l10n.catBusiness;
      case 'Entertainment': return l10n.catEntertainment;
      default: return category;
    }
  }

  Widget _buildManageTab() {
    final uid = context.read<AuthService>().currentUserData?.uid ?? '';
    if (uid.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.notLoggedIn));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchPosts,
              hintStyle: AppTextStyles.subtitle,
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), 
                borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), 
                borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1)),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<NewsModel>>(
            stream: context.read<NewsService>().getNewsByCreator(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('${AppLocalizations.of(context)!.errorLoading} ${snapshot.error}'));
              }
              final allNews = snapshot.data ?? [];
              final filteredNews = allNews.where((n) => n.title.toLowerCase().contains(_searchQuery)).toList();

              if (filteredNews.isEmpty) {
                return Center(child: Text(AppLocalizations.of(context)!.noPostsFound, style: const TextStyle(color: AppColors.textSecondary)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredNews.length,
                itemBuilder: (context, index) {
                  final news = filteredNews[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Dismissible(
                      key: Key(news.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
                      ),
                      onDismissed: (_) {
                        context.read<NewsService>().deleteNews(news.id);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.postDeleted)));
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => EditNewsScreen(news: news)));
                        },
                        child: Container(
                          height: 120,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Hero(
                                tag: 'manage_image_${news.id}',
                                child: Container(
                                  width: 96,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(image: NetworkImage(news.imageUrl), fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(_getCategoryLabel(context, news.category), style: AppTextStyles.badge.copyWith(fontSize: 10, color: AppColors.primary)),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Text(
                                        news.title, 
                                        maxLines: 2, 
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.h2.copyWith(fontSize: 16),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${news.likes.length}',
                                              style: AppTextStyles.subtitle.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              news.isBreaking ? AppLocalizations.of(context)!.breakingBadge : AppLocalizations.of(context)!.statusStandard, 
                                              style: TextStyle(
                                                fontSize: 11, 
                                                fontWeight: FontWeight.bold,
                                                color: news.isBreaking ? AppColors.breakingBadge : AppColors.textSecondary
                                              )
                                            ),
                                          ],
                                        ),
                                        const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.subtitle,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
