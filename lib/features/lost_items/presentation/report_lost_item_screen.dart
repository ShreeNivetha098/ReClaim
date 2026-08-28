import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/models/lost_item_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class ReportLostItemScreen extends ConsumerStatefulWidget {
  const ReportLostItemScreen({super.key});

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
  File? _selectedImage;
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
    _valueController.dispose();
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
      initialDate: _dateLost,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
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
      if (_selectedImage != null) {
        uploadedImageUrl = await repo.uploadImage(_selectedImage!, 'lost_items');
      }

      final now = DateTime.now();
      final newLostItem = LostItemModel(
        id: '',
        ownerId: user?.uid ?? 'guest',
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
        title: const Text('Report Lost Item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Optional Image Picker Header
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
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
                              Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primary),
                              SizedBox(height: 8),
                              Text(
                                'Upload Image (Optional)',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Photos help identify lost items faster',
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
                  hint: 'e.g. WildHorn Leather Wallet / Casio FX-991EX',
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

                // Date Lost Selector
                const Text(
                  'Date Lost *',
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
                          DateFormat('MMM dd, yyyy').format(_dateLost),
                          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
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
                  text: 'Submit Lost Item Report',
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
