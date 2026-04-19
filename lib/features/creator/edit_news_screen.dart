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
import '../../core/constants/locations.dart';

class EditNewsScreen extends StatefulWidget {
  final NewsModel news;
  const EditNewsScreen({super.key, required this.news});

  @override
  State<EditNewsScreen> createState() => _EditNewsScreenState();
}

class _EditNewsScreenState extends State<EditNewsScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late String _category;
  late bool _isBreaking;
  File? _newImageFile;
  bool _isLoading = false;

  late String _locationScope;
  String? _selectedState;
  String? _selectedDistrict;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _sourceNameCtrl;
  late TextEditingController _sourceUrlCtrl;
  late TextEditingController _readingTimeCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.news.title);
    _contentCtrl = TextEditingController(text: widget.news.content);
    _category = widget.news.category;
    _isBreaking = widget.news.isBreaking;
    _locationScope = widget.news.locationScope;
    _selectedState = widget.news.state;
    _selectedDistrict = widget.news.district;
    _subtitleCtrl = TextEditingController(text: widget.news.subtitle);
    _sourceNameCtrl = TextEditingController(text: widget.news.sourceName);
    _sourceUrlCtrl = TextEditingController(text: widget.news.sourceUrl);
    _readingTimeCtrl = TextEditingController(text: widget.news.readingTime?.toString());
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newImageFile = File(picked.path));
    }
  }

  Future<void> _updateNews() async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.fillAllFields)));
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
      String finalImageUrl = widget.news.imageUrl;
      
      if (_newImageFile != null) {
        finalImageUrl = await context.read<StorageService>().uploadNewsImage(_newImageFile!);
      }
      
      final updatedNews = NewsModel(
        id: widget.news.id,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        imageUrl: finalImageUrl,
        category: _category,
        isBreaking: _isBreaking,
        createdAt: widget.news.createdAt,
        createdBy: widget.news.createdBy,
        locationScope: _locationScope,
        state: _selectedState,
        district: _selectedDistrict,
        likes: widget.news.likes,
        subtitle: _subtitleCtrl.text.trim().isEmpty ? null : _subtitleCtrl.text.trim(),
        sourceName: _sourceNameCtrl.text.trim().isEmpty ? null : _sourceNameCtrl.text.trim(),
        sourceUrl: _sourceUrlCtrl.text.trim().isEmpty ? null : _sourceUrlCtrl.text.trim(),
        readingTime: _readingTimeCtrl.text.trim().isEmpty 
            ? _calculateReadingTime(_contentCtrl.text) 
            : int.tryParse(_readingTimeCtrl.text.trim()),
      );

      if (!mounted) return;
      await context.read<NewsService>().updateNews(updatedNews);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.newsUpdated)),
        );
        Navigator.pop(context);
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
    final minutes = (words / 200).ceil();
    return minutes == 0 ? 1 : minutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.edit, style: AppTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                  image: _newImageFile != null 
                      ? DecorationImage(image: FileImage(_newImageFile!), fit: BoxFit.cover) 
                      : DecorationImage(image: NetworkImage(widget.news.imageUrl), fit: BoxFit.cover),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                    ),
                  ),
                ),
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
              initialValue: AppStrings.categories.contains(_category) ? _category : AppStrings.categories[1],
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
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
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
                items: (AppLocations.indiaStatesAndDistricts[_selectedState!] ?? []).map((String district) {
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
              onPressed: _isLoading ? null : _updateNews,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, 
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(AppLocalizations.of(context)!.updateNews, style: AppTextStyles.button),
            )
          ],
        ),
      ),
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
}
