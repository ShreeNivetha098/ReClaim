import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/image_store_service.dart';
import '../../../shared/models/lost_item_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/form_parts.dart';
import '../../../shared/widgets/item_image.dart';
import '../../../core/services/reclaim_repository.dart' show DuplicateReportException;

class ReportLostItemScreen extends ConsumerStatefulWidget {
  /// When set, the form edits this report instead of creating a new one.
  final LostItemModel? existingItem;

  const ReportLostItemScreen({super.key, this.existingItem});

  @override
  ConsumerState<ReportLostItemScreen> createState() => _ReportLostItemScreenState();
}

class _ReportLostItemScreenState extends ConsumerState<ReportLostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _colourController = TextEditingController();
  final _locationController = TextEditingController();
  final _valueController = TextEditingController();

  String _selectedCategory = 'ID Card';
  DateTime _dateLost = DateTime.now();
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingItem != null;
  bool get _hasPhoto => _imageBytes != null || (_existingImageUrl?.isNotEmpty ?? false);

  final List<String> _categories = [
    'ID Card',
    'Wallet',
    'Keys',
    'Books',
    'Calculator',
    'Electronics',
    'Bag',
    'Bottle',
    'Documents',
    'Accessories',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item == null) return;
    String orBlank(String value) => value == 'N/A' ? '' : value;
    _itemNameController.text = item.itemName;
    _descriptionController.text = item.description;
    _brandController.text = orBlank(item.brand);
    _colourController.text = orBlank(item.colour);
    _locationController.text = item.locationLost;
    _valueController.text = orBlank(item.approximateValue);
    _selectedCategory = _categories.contains(item.category) ? item.category : 'Other';
    _dateLost = item.dateLost;
    _existingImageUrl = item.imageUrl;
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _colourController.dispose();
    _locationController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isSubmitting) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: ImageStoreService.pickerMaxDimension,
        maxHeight: ImageStoreService.pickerMaxDimension,
        imageQuality: ImageStoreService.pickerQuality,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Reports go back 90 days, or further when editing an older report.
  DateTime get _earliestDate {
    final limit = DateTime.now().subtract(const Duration(days: 90));
    return _dateLost.isBefore(limit) ? _dateLost : limit;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateLost,
      firstDate: _earliestDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateLost = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);
      final repo = ref.read(repositoryProvider);

      String? uploadedImageUrl;
      if (_imageBytes != null) {
        uploadedImageUrl = await repo.uploadImageBytes(_imageBytes!);
      }

      if (_isEditing) {
        await _saveChanges(uploadedImageUrl);
        return;
      }

      final now = DateTime.now();
      final newLostItem = LostItemModel(
        id: '',
        ownerId: user?.uid ?? 'guest',
        reporterName: user != null && user.name.trim().isNotEmpty ? user.name : 'Unknown user',
        reporterEmail: user?.email ?? '',
        itemName: _itemNameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        brand: _brandController.text.trim().isEmpty ? 'N/A' : _brandController.text.trim(),
        colour: _colourController.text.trim().isEmpty ? 'N/A' : _colourController.text.trim(),
        dateLost: _dateLost,
        locationLost: _locationController.text.trim(),
        approximateValue: _valueController.text.trim().isEmpty ? 'N/A' : _valueController.text.trim(),
        imageUrl: uploadedImageUrl,
        status: 'ACTIVE',
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(lostItemsProvider.notifier).addLostItem(newLostItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lost Item Reported Successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is DuplicateReportException ? e.message : 'Error reporting item: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _saveChanges(String? uploadedImageUrl) async {
    final existing = widget.existingItem!;
    final updated = existing.copyWith(
      itemName: _itemNameController.text.trim(),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? 'N/A' : _brandController.text.trim(),
      colour: _colourController.text.trim().isEmpty ? 'N/A' : _colourController.text.trim(),
      dateLost: _dateLost,
      locationLost: _locationController.text.trim(),
      approximateValue: _valueController.text.trim().isEmpty ? 'N/A' : _valueController.text.trim(),
      imageUrl: uploadedImageUrl ?? _existingImageUrl ?? '',
    );

    await ref.read(lostItemsProvider.notifier).updateLostItem(updated);
    if (existing.imageUrl != updated.imageUrl) {
      await ImageStoreService.delete(existing.imageUrl);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lost item report updated'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Widget _photoPreview() {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return ItemImage(
      imageUrl: _existingImageUrl!,
      fit: BoxFit.cover,
      placeholder: (_) => const Center(child: CircularProgressIndicator()),
      error: (_) => const Icon(Icons.broken_image_outlined, size: 40, color: AppColors.textMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Lost Item' : 'Report Lost Item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormIntro(
                  gradient: AppColors.lostGradient,
                  icon: Icons.search_rounded,
                  title: _isEditing ? 'Update your report' : 'Tell us what you lost',
                  subtitle: 'The more detail you add, the better we can match it.',
                ),
                const SizedBox(height: 20),

                PhotoPickerBox(
                  preview: _hasPhoto ? _photoPreview() : null,
                  onPick: _pickImage,
                  onRemove: () => setState(() {
                    _imageBytes = null;
                    _existingImageUrl = null;
                  }),
                  title: 'Add a photo',
                  subtitle: 'Optional, but it helps people recognise it',
                  color: AppColors.lost,
                ),
                const SizedBox(height: 20),

                // Item Name
                CustomTextField(
                  label: 'Item Name *',
                  hint: 'e.g. WildHorn Leather Wallet / Casio FX-991EX',
                  controller: _itemNameController,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Item name is required' : null,
                ),
                const SizedBox(height: 16),

                // Category
                const FieldLabel('Category *'),
                CategoryPicker(
                  selected: _selectedCategory,
                  color: AppColors.lost,
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
                const SizedBox(height: 16),

                // Description
                CustomTextField(
                  label: 'Description *',
                  hint: 'Detailed description, stickers, unique features, or contents inside...',
                  controller: _descriptionController,
                  maxLines: 3,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),

                // Row: Brand & Colour
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Brand',
                        hint: 'e.g. Casio, Dell',
                        controller: _brandController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Colour',
                        hint: 'e.g. Black, Blue',
                        controller: _colourController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date
                const FieldLabel('Date lost *'),
                DateField(date: _dateLost, onTap: () => _selectDate(context)),
                const SizedBox(height: 16),

                // Location Lost
                CustomTextField(
                  label: 'Location Lost *',
                  hint: 'e.g. Central Library 2nd Floor / Block B Lab 3',
                  controller: _locationController,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Location lost is required' : null,
                ),
                const SizedBox(height: 16),

                // Approximate Value
                CustomTextField(
                  label: 'Approximate Value',
                  hint: 'e.g. ₹1,500',
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: _isEditing ? 'Save Changes' : 'Submit Lost Item Report',
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
