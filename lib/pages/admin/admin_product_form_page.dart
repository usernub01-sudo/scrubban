import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';

class AdminProductFormPage extends StatefulWidget {
  final Product? product;

  const AdminProductFormPage({super.key, this.product});

  @override
  State<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String? _uploadedImageUrl;
  bool _uploading = false;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description ?? '';
      _priceCtrl.text = p.price.toStringAsFixed(2);
      _isActive = p.isActive;
      _uploadedImageUrl = p.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final name = _nameCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      final price = double.parse(_priceCtrl.text.trim());
      final imageUrl = _uploadedImageUrl;

      if (_isEditing) {
        await _productService.updateProduct(
          id: widget.product!.id,
          name: name,
          description: desc,
          price: price,
          isActive: _isActive,
          imageUrl: imageUrl,
        );
      } else {
        await _productService.createProduct(
          name: name,
          description: desc,
          price: price,
          isActive: _isActive,
          imageUrl: imageUrl,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(fontSize: 13, letterSpacing: 0.3),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() => _uploading = true);

      final bytes = await picked.readAsBytes();
      final url = await _storageService.uploadProductImage(
        bytes: bytes,
        fileName: picked.name,
      );

      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = url;
        _uploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image uploaded',
            style: TextStyle(fontSize: 13, letterSpacing: 0.3),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $e',
            style: const TextStyle(fontSize: 13, letterSpacing: 0.3),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _saving,
          child: Column(
            children: [
              _buildTopBar(),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Section: Basic info
                            _buildSectionLabel('BASIC INFORMATION'),
                            const SizedBox(height: 16),

                            _buildField(
                              controller: _nameCtrl,
                              label: 'Product Name',
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                  ? 'Name is too short'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            _buildField(
                              controller: _descCtrl,
                              label: 'Description',
                              maxLines: 4,
                            ),
                            const SizedBox(height: 14),

                            _buildField(
                              controller: _priceCtrl,
                              label: 'Price (EGP)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Price is required';
                                }
                                final n = double.tryParse(v.trim());
                                if (n == null) return 'Price must be a number';
                                if (n < 0) return 'Price cannot be negative';
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Section: Image
                            _buildSectionLabel('PRODUCT IMAGE'),
                            const SizedBox(height: 16),
                            _buildImageSection(),
                            const SizedBox(height: 32),

                            // Section: Status
                            _buildSectionLabel('STATUS'),
                            const SizedBox(height: 16),
                            _buildStatusToggle(),
                            const SizedBox(height: 40),

                            // Save button
                            _buildSaveButton(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Top Bar
  // ============================================================
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 22),
            color: Colors.black87,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                _isEditing ? 'EDIT PRODUCT' : 'NEW PRODUCT',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ============================================================
  // Section Label
  // ============================================================
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.5,
        color: Color(0xFF999999),
      ),
    );
  }

  // ============================================================
  // Field
  // ============================================================
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: Color(0xFF666666),
          fontWeight: FontWeight.w400,
        ),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black87, width: 1.4),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.red, width: 1.4),
        ),
      ),
    );
  }

  // ============================================================
  // Image Section
  // ============================================================
  Widget _buildImageSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview
        Container(
          width: 100,
          height: 100,
          color: const Color(0xFFF7F7F7),
          child: _buildImagePreview(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _uploading || _saving ? null : _pickAndUploadImage,
                  icon: _uploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black87,
                          ),
                        )
                      : const Icon(Icons.upload_outlined, size: 16),
                  label: Text(
                    _uploading
                        ? 'UPLOADING...'
                        : (_uploadedImageUrl == null
                              ? 'CHOOSE IMAGE'
                              : 'CHANGE IMAGE'),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.black87, width: 1),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ),
              if (_uploadedImageUrl != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _uploading || _saving
                      ? null
                      : () => setState(() => _uploadedImageUrl = null),
                  icon: const Icon(Icons.close, size: 14, color: Colors.red),
                  label: const Text(
                    'REMOVE IMAGE',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
      return const Center(
        child: Icon(Icons.image_outlined, size: 32, color: Color(0xFFCCCCCC)),
      );
    }
    return Image.network(
      _uploadedImageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black26,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 32,
          color: Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  // ============================================================
  // Status Toggle
  // ============================================================
  Widget _buildStatusToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
      ),
      child: InkWell(
        onTap: _saving ? null : () => setState(() => _isActive = !_isActive),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isActive
                          ? 'Visible to customers on the store'
                          : 'Hidden from customers',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              // Custom toggle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: _isActive ? Colors.black87 : const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: _isActive
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Save Button
  // ============================================================
  Widget _buildSaveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isEditing ? 'SAVE CHANGES' : 'CREATE PRODUCT',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }
}
