import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/image_store_service.dart';
import '../../../shared/models/found_item_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/form_parts.dart';
import '../../../shared/widgets/item_image.dart';
import '../../../core/services/reclaim_repository.dart' show DuplicateReportException;

class ReportFoundItemScreen extends ConsumerStatefulWidget {
  /// When set, the form edits this report instead of creating a new one.
  final FoundItemModel? existingItem;

  const ReportFoundItemScreen({super.key, this.existingItem});

  @override
  ConsumerState<ReportFoundItemScreen> createState() => _ReportFoundItemScreenState();
}

class _ReportFoundItemScreenState extends ConsumerState<ReportFoundItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _colourController = TextEditingController();
  final _locationController = TextEditingController();
  final _currentHolderController = TextEditingController();

  String _selectedCategory = 'ID Card';
  DateTime _dateFound = DateTime.now();
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  bool _securityOfficeSubmitted = false;
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
    _locationController.text = item.locationFound;
    _currentHolderController.text = item.currentHolder;
    _selectedCategory = _categories.contains(item.category) ? item.category : 'Other';
    _dateFound = item.dateFound;
    _securityOfficeSubmitted = item.securityOfficeSubmitted;
    _existingImageUrl = item.imageUrl;
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _colourController.dispose();
    _locationController.dispose();
    _currentHolderController.dispose();
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
    return _dateFound.isBefore(limit) ? _dateFound : limit;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFound,
      firstDate: _earliestDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateFound = picked);
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
      final newFoundItem = FoundItemModel(
        id: '',
        finderId: user?.uid ?? 'guest',
        reporterName: user != null && user.name.trim().isNotEmpty ? user.name : 'Unknown user',
        reporterEmail: user?.email ?? '',
        itemName: _itemNameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        brand: _brandController.text.trim().isEmpty ? 'N/A' : _brandController.text.trim(),
        colour: _colourController.text.trim().isEmpty ? 'N/A' : _colourController.text.trim(),
        dateFound: _dateFound,
        locationFound: _locationController.text.trim(),
        imageUrl: uploadedImageUrl ?? '',
        currentHolder: _currentHolderController.text.trim().isEmpty
            ? 'Finder / Security Office'
            : _currentHolderController.text.trim(),
        securityOfficeSubmitted: _securityOfficeSubmitted,
        status: 'ACTIVE',
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(foundItemsProvider.notifier).addFoundItem(newFoundItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Found Item Reported Successfully!'),
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
      dateFound: _dateFound,
      locationFound: _locationController.text.trim(),
      imageUrl: uploadedImageUrl ?? _existingImageUrl ?? '',
      currentHolder: _currentHolderController.text.trim().isEmpty
          ? 'Finder / Security Office'
          : _currentHolderController.text.trim(),
      securityOfficeSubmitted: _securityOfficeSubmitted,
    );

    await ref.read(foundItemsProvider.notifier).updateFoundItem(updated);
    if (existing.imageUrl != updated.imageUrl) {
      await ImageStoreService.delete(existing.imageUrl);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Found item report updated'),
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
        title: Text(_isEditing ? 'Edit Found Item' : 'Report Found Item'),
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
                  gradient: AppColors.foundGradient,
                  icon: Icons.volunteer_activism_rounded,
                  title: _isEditing ? 'Update your report' : 'Thanks for helping out!',
                  subtitle: 'A few details help the owner recognise their item.',
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
                  subtitle: 'A clear photo helps the owner find it',
                  color: AppColors.found,
                ),
                const SizedBox(height: 20),

                // Item Name
                CustomTextField(
                  label: 'Item Name *',
                  hint: 'e.g. Dell Wireless Mouse / WildHorn Leather Wallet',
                  controller: _itemNameController,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Item name is required' : null,
                ),
                const SizedBox(height: 16),

                // Category
                const FieldLabel('Category *'),
                CategoryPicker(
                  selected: _selectedCategory,
                  color: AppColors.found,
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
                const SizedBox(height: 16),

                // Description
                CustomTextField(
                  label: 'Description *',
                  hint: 'Describe condition, exact spot where found, and distinguishing marks...',
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
                        hint: 'e.g. Dell, Casio',
                        controller: _brandController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Colour',
                        hint: 'e.g. Black, Silver',
                        controller: _colourController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date
                const FieldLabel('Date found *'),
                DateField(date: _dateFound, onTap: () => _selectDate(context)),
                const SizedBox(height: 16),

                // Location Found
                CustomTextField(
                  label: 'Location Found *',
                  hint: 'e.g. Block B Lab 2 / Library Desk 14',
                  controller: _locationController,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Location found is required' : null,
                ),
                const SizedBox(height: 16),

                // Current Holder
                CustomTextField(
                  label: 'Current Item Holder',
                  hint: 'e.g. Security Desk / Lab Assistant Office',
                  controller: _currentHolderController,
                  prefixIcon: const Icon(Icons.person_pin_circle_outlined),
                ),
                const SizedBox(height: 16),

                // Security Office Submitted Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.secondary,
                  title: const Text(
                    'Submitted to Security Office?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text('Item has been physically handed over to campus security desk'),
                  value: _securityOfficeSubmitted,
                  onChanged: (val) => setState(() => _securityOfficeSubmitted = val),
                ),
                const SizedBox(height: 24),

                // Submit Button
                CustomButton(
                  text: _isEditing ? 'Save Changes' : 'Submit Found Item Report',
                  type: CustomButtonType.secondary,
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
