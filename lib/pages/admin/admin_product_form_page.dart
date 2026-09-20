import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';

class AdminProductFormPage extends StatefulWidget {
  /// لو null → إضافة، لو مش null → تعديل
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

  // رابط الصورة الحالي (من الداتابيز أو من رفع جديد)
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
      Navigator.pop(context, true); // true = اتعمل حفظ
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حصل خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // الصور
  // ============================================================

  Widget _buildImagePreview() {
    if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
      return const Icon(Icons.image_outlined, size: 40, color: Colors.grey);
    }
    return Image.network(
      _uploadedImageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (picked == null) return; // المستخدم قفل الـpicker

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
          content: Text('تم رفع الصورة'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل رفع الصورة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل منتج' : 'إضافة منتج'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---------- اسم المنتج ----------
                    TextFormField(
                      controller: _nameCtrl,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'اسم المنتج *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'الاسم قصير جدًا'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // ---------- الوصف ----------
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'الوصف',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---------- السعر ----------
                    TextFormField(
                      controller: _priceCtrl,
                      enabled: !_saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'السعر (EGP) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'الرجاء إدخال السعر';
                        }
                        final n = double.tryParse(v.trim());
                        if (n == null) return 'السعر لازم يكون رقم';
                        if (n < 0) return 'السعر مش ممكن يكون سالب';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ---------- الصورة ----------
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'صورة المنتج',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // معاينة الصورة
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _buildImagePreview(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: _uploading || _saving
                                            ? null
                                            : _pickAndUploadImage,
                                        icon: _uploading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(Icons.upload_file),
                                        label: Text(
                                          _uploading
                                              ? 'جاري الرفع...'
                                              : (_uploadedImageUrl == null
                                                    ? 'اختر صورة'
                                                    : 'تغيير الصورة'),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      if (_uploadedImageUrl != null) ...[
                                        const SizedBox(height: 6),
                                        TextButton.icon(
                                          onPressed: _uploading || _saving
                                              ? null
                                              : () {
                                                  setState(
                                                    () => _uploadedImageUrl =
                                                        null,
                                                  );
                                                },
                                          icon: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          label: const Text(
                                            'إزالة الصورة',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---------- نشط / مخفي ----------
                    Card(
                      margin: EdgeInsets.zero,
                      child: SwitchListTile(
                        title: const Text('المنتج نشط'),
                        subtitle: const Text(
                          'لو مفعّل، هيظهر للعملاء على الموقع',
                        ),
                        value: _isActive,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _isActive = v),
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ---------- زر الحفظ ----------
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEditing ? 'حفظ التعديلات' : 'إضافة المنتج',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
