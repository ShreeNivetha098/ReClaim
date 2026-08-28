import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/found_item_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class ReportFoundItemScreen extends ConsumerStatefulWidget {
  const ReportFoundItemScreen({super.key});

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
  File? _selectedImage;
  bool _securityOfficeSubmitted = false;
  bool _isSubmitting = false;

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
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFound,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateFound = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Image is strictly REQUIRED for found items
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo is required when reporting a found item for verification.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);
      final repo = ref.read(repositoryProvider);

      final uploadedImageUrl = await repo.uploadImage(_selectedImage!, 'found_items');

      final now = DateTime.now();
      final newFoundItem = FoundItemModel(
        id: '',
        finderId: user?.uid ?? 'guest',
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
            content: Text('Error reporting item: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Found Item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mandatory Image Picker Header
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedImage == null ? AppColors.secondary : AppColors.divider,
                        width: _selectedImage == null ? 2 : 1,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 44, color: AppColors.secondary),
                              SizedBox(height: 8),
                              Text(
                                'Upload Photo (REQUIRED) *',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Proof photo is mandatory for reporting found items',
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                  ),
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

                // Category Dropdown
                const Text(
                  'Category *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
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

                // Date Found Selector
                const Text(
                  'Date Found *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(_dateFound),
                          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.secondary),
                      ],
                    ),
                  ),
                ),
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
                  text: 'Submit Found Item Report',
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
