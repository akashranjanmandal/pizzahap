import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_api_service.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});
  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _loading = false;
  String _searchQuery = '';
  bool _showUnavailable = true; // Admin sees everything by default

  List<Product> get _filtered {
    var list = _products;
    if (!_showUnavailable) list = list.where((p) => p.isAvailable).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final adminProv = context.read<AdminProvider>();
      final results = await Future.wait([
        // Use admin endpoint so we get ALL products including unavailable
        AdminApiService.getAdminProducts(showUnavailable: true),
        ApiService.getCategories(),
      ]);
      _products   = results[0] as List<Product>;
      _categories = results[1] as List<Category>;
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to load products', isError: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── Add product ────────────────────────────────────────────────
  void _showAddProduct() {
    final nameCtrl  = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    bool isVeg = true, isFeatured = false, saving = false;
    int? selectedCatId = _categories.isNotEmpty ? _categories.first.id : null;
    File? pickedImage;

    _showSheet(
      title: 'Add New Product',
      builder: (ctx, setModal) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image picker
          _ImagePicker(
            file: pickedImage,
            onPick: () async {
              final f = await _pickImage();
              if (f != null) setModal(() => pickedImage = f);
            },
          ),
          const SizedBox(height: 14),

          // Category
          if (_categories.isNotEmpty) ...[
            _label('Category'),
            _Dropdown<int>(
              value: selectedCatId,
              items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setModal(() => selectedCatId = v),
            ),
            const SizedBox(height: 12),
          ],

          _Field(ctrl: nameCtrl,  label: 'Product Name', hint: 'e.g. Margherita Pizza'),
          const SizedBox(height: 10),
          _Field(ctrl: priceCtrl, label: 'Base Price (₹)', hint: '199', isNumber: true),
          const SizedBox(height: 10),
          _Field(ctrl: descCtrl,  label: 'Description (optional)', hint: 'Describe the product', maxLines: 2),
          const SizedBox(height: 14),

          Row(children: [
            _Chip(label: 'Veg',      value: isVeg,      color: const Color(AppColors.vegGreen), onChanged: (v) => setModal(() => isVeg = v)),
            const SizedBox(width: 10),
            _Chip(label: 'Featured', value: isFeatured, color: const Color(AppColors.accent),   onChanged: (v) => setModal(() => isFeatured = v)),
          ]),
          const SizedBox(height: 20),

          _ActionBtn(
            label: 'Create Product',
            loading: saving,
            onTap: () async {
              if (nameCtrl.text.trim().isEmpty) { showSnack(ctx,'Name required',isError:true); return; }
              final price = double.tryParse(priceCtrl.text.trim());
              if (price == null || price <= 0) { showSnack(ctx,'Enter valid price',isError:true); return; }
              setModal(() => saving = true);
              Navigator.pop(ctx);
              try {
                final result = await AdminApiService.createProduct({
                  'name': nameCtrl.text.trim(), 'base_price': price,
                  'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  'category_id': selectedCatId ?? 1,
                  'is_veg': isVeg, 'is_featured': isFeatured,
                });
                if (pickedImage != null && result['product_id'] != null) {
                  try {
                    final imgUrl = await AdminApiService.uploadProductImage(result['product_id'] as int, pickedImage!);
                    await CachedNetworkImage.evictFromCache(imgUrl);
                  } catch (_) {}
                }
                if (mounted) { showSnack(context, '✅ Product created!'); _load(); }
              } on ApiException catch (e) {
                if (mounted) showSnack(context, e.message, isError: true);
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Edit product ───────────────────────────────────────────────
  void _editProduct(Product p) {
    final nameCtrl  = TextEditingController(text: p.name);
    final priceCtrl = TextEditingController(text: p.basePrice.toStringAsFixed(0));
    bool isAvailable = p.isAvailable, isFeatured = p.isFeatured;
    File? pickedImage;
    bool uploadingImage = false;
    final adminProv = context.read<AdminProvider>();
    // local_available reflects the location-specific toggle (if scoped admin)
    bool locAvailable = (p as dynamic).locationAvailable ?? true;

    _showSheet(
      title: p.name,
      builder: (ctx, setModal) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Row(children: [
            _ImagePicker(
              file: pickedImage,
              existingUrl: p.imageUrl,
              size: 90,
              onPick: () async {
                final f = await _pickImage();
                if (f != null) setModal(() => pickedImage = f);
              },
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                pickedImage != null ? 'New image selected' : (p.imageUrl != null ? '✅ Image set' : 'No image'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (pickedImage != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: uploadingImage ? null : () async {
                    setModal(() => uploadingImage = true);
                    try {
                      final newUrl = await AdminApiService.uploadProductImage(p.id, pickedImage!);
                      // Evict old image from cache so new one shows immediately
                      if (p.imageUrl != null) {
                        await CachedNetworkImage.evictFromCache(p.imageUrl!);
                      }
                      await CachedNetworkImage.evictFromCache(newUrl);
                      setModal(() { pickedImage = null; uploadingImage = false; });
                      if (mounted) { showSnack(context,'✅ Image uploaded!'); _load(); }
                    } on ApiException catch (e) {
                      setModal(() => uploadingImage = false);
                      if (mounted) showSnack(context, e.message, isError: true);
                    }
                  },
                  icon: uploadingImage
                    ? const SizedBox(width:14,height:14,child:CircularProgressIndicator(strokeWidth:2))
                    : const Icon(Icons.upload_outlined, size:16),
                  label: Text(uploadingImage ? 'Uploading…' : 'Upload'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal:10,vertical:6),minimumSize:Size.zero),
                ),
              ],
            ])),
          ]),
          const SizedBox(height: 14),

          _Field(ctrl: nameCtrl,  label: 'Name'),
          const SizedBox(height: 10),
          _Field(ctrl: priceCtrl, label: 'Base Price (₹)', isNumber: true),
          const SizedBox(height: 14),

          Row(children: [
            _Chip(
              label: 'Available (global)', value: isAvailable,
              color: const Color(AppColors.success),
              onChanged: (v) => setModal(() => isAvailable = v),
            ),
            const SizedBox(width: 10),
            _Chip(
              label: 'Featured', value: isFeatured,
              color: const Color(AppColors.accent),
              onChanged: (v) => setModal(() => isFeatured = v),
            ),
          ]),

          // ── Per-location toggle ──────────────────────────────
          if (adminProv.adminLocationId != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.store_outlined, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Available at your branch', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(adminProv.adminLocationName ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ])),
                Switch(
                  value: locAvailable,
                  activeThumbColor: const Color(AppColors.primary),
                  onChanged: (v) async {
                    setModal(() => locAvailable = v);
                    try {
                      await AdminApiService.setProductLocationAvailability(p.id, v);
                      if (mounted) showSnack(context, v ? '✅ Enabled at branch' : '⛔ Disabled at branch');
                      _load();
                    } on ApiException catch (e) {
                      setModal(() => locAvailable = !v);
                      if (mounted) showSnack(context, e.message, isError: true);
                    }
                  },
                ),
              ]),
            ),
          ],

          // ── Super admin: full matrix ─────────────────────────
          if (adminProv.adminLocationId == null) ...[
            const SizedBox(height: 14),
            _LocationMatrix(productId: p.id),
          ],

          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () async {
                final ok = await _confirm(context, 'Remove Product?',
                  'This hides the product globally from all menus.');
                if (ok) {
                  Navigator.pop(ctx);
                  await AdminApiService.deleteProduct(p.id);
                  if (mounted) { showSnack(context,'Product removed'); _load(); }
                }
              },
              style: OutlinedButton.styleFrom(foregroundColor: const Color(AppColors.error), side: const BorderSide(color: Color(AppColors.error))),
              child: const Text('Remove'),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final price = double.tryParse(priceCtrl.text.trim());
                await AdminApiService.updateProduct(p.id, {
                  if (nameCtrl.text.trim().isNotEmpty) 'name': nameCtrl.text.trim(),
                  if (price != null) 'base_price': price,
                  'is_available': isAvailable,
                  'is_featured':  isFeatured,
                });
                if (mounted) { showSnack(context,'✅ Updated!'); _load(); }
              },
              child: const Text('Save Changes'),
            )),
          ]),
        ],
      ),
    );
  }

  // ── Shared bottom sheet helper ─────────────────────────────────
  void _showSheet({required String title, required Widget Function(BuildContext, StateSetter) builder}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              )),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 16),
              builder(ctx, setModal),
            ]),
          ),
        ),
      ),
    );
  }

  Future<File?> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    return picked != null ? File(picked.path) : null;
  }

  Future<bool> _confirm(BuildContext ctx, String title, String msg) async =>
    await showDialog<bool>(
      context: ctx,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 10),
            Text(msg, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(AppColors.error)),
                child: const Text('Confirm'),
              )),
            ]),
          ]),
        ),
      ),
    ) ?? false;

  @override
  Widget build(BuildContext context) {
    final adminProv = context.read<AdminProvider>();
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Menu'),
          if (adminProv.adminLocationName != null)
            Text('📍 ${adminProv.adminLocationName}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
        actions: [
          IconButton(
            icon: Icon(_showUnavailable ? Icons.visibility : Icons.visibility_off),
            tooltip: _showUnavailable ? 'Showing all' : 'Hiding unavailable',
            onPressed: () => setState(() => _showUnavailable = !_showUnavailable),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: const Color(AppColors.background),
                border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProduct,
        backgroundColor: const Color(AppColors.primary),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)))
        : RefreshIndicator(
            color: const Color(AppColors.primary),
            onRefresh: _load,
            child: _filtered.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🍕', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No products found', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                  if (!_showUnavailable) ...[
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => setState(() => _showUnavailable = true),
                      child: const Text('Show unavailable products')),
                  ],
                ]))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) {
                    final p = _filtered[i];
                    final locAvail = (p as dynamic).locationAvailable ?? true;
                    return GestureDetector(
                      onTap: () => _editProduct(p),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: !p.isAvailable
                            ? Border.all(color: Colors.red.shade200, width: 1.5)
                            : !locAvail
                              ? Border.all(color: Colors.orange.shade300, width: 1.5)
                              : null,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Stack(children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              child: PizzaNetImage(url: p.imageUrl, height: 110, width: double.infinity),
                            ),
                            if (!p.isAvailable)
                              Positioned.fill(child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                                ),
                                child: const Center(child: Text('UNAVAILABLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 9))),
                              ))
                            else if (!locAvail)
                              Positioned.fill(child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.6),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                ),
                                child: const Center(child: Text('OFF AT\nTHIS BRANCH', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 9))),
                              )),
                            Positioned(top: 6, left: 6, child: VegBadge(isVeg: p.isVeg)),
                            if (p.isFeatured)
                              Positioned(top: 6, right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(AppColors.accent), borderRadius: BorderRadius.circular(5)),
                                  child: const Text('★', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                                )),
                          ]),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text('₹${p.basePrice.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.w800, fontSize: 13)),
                                const Spacer(),
                                Icon(Icons.edit_outlined, size: 13, color: Colors.grey.shade400),
                              ]),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
          ),
    );
  }
}

// ── Location availability matrix (super admin only) ──────────────
class _LocationMatrix extends StatefulWidget {
  final int productId;
  const _LocationMatrix({required this.productId});
  @override
  State<_LocationMatrix> createState() => _LocationMatrixState();
}

class _LocationMatrixState extends State<_LocationMatrix> {
  List<Map<String, dynamic>> _matrix = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final m = await AdminApiService.getProductAvailabilityMatrix(widget.productId);
      setState(() { _matrix = m; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Availability by Location', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 8),
      ..._matrix.map((row) {
        final locId   = row['location_id'] as int;
        final locName = row['location_name'] as String;
        bool avail    = row['is_available'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: avail ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: avail ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Row(children: [
            Icon(Icons.store_outlined, size: 16, color: avail ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(locName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            Switch(
              value: avail,
              activeThumbColor: const Color(AppColors.success),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) async {
                setState(() => row['is_available'] = v);
                try {
                  await AdminApiService.setProductLocationAvailabilityForLocation(
                    widget.productId, locId, v);
                } catch (_) { setState(() => row['is_available'] = !v); }
              },
            ),
          ]),
        );
      }),
    ]);
  }
}

// ── Small helper widgets ─────────────────────────────────────────
class _ImagePicker extends StatelessWidget {
  final File? file;
  final String? existingUrl;
  final double size;
  final VoidCallback onPick;
  const _ImagePicker({this.file, this.existingUrl, this.size = double.infinity, required this.onPick});

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (file != null) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(file!, fit: BoxFit.cover, width: size == double.infinity ? double.infinity : size, height: size == double.infinity ? 120 : size),
      );
    } else if (existingUrl != null) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: PizzaNetImage(url: existingUrl, width: size == double.infinity ? double.infinity : size, height: size == double.infinity ? 120 : size),
      );
    } else {
      inner = Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined, size: 30, color: Colors.grey.shade400),
        const SizedBox(height: 6),
        Text(size == double.infinity ? 'Add Image (optional)' : 'Change',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ]);
    }
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: size == double.infinity ? double.infinity : size,
        height: size == double.infinity ? 120 : size,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: inner,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final bool isNumber;
  final int maxLines;
  const _Field({required this.ctrl, required this.label, this.hint, this.isNumber = false, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    const SizedBox(height: 6),
    TextField(
      controller: ctrl, maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint, isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    ),
  ]);
}

Widget _label(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
);

class _Dropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _Dropdown({this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(value: value, isExpanded: true, items: items, onChanged: onChanged),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _Chip({required this.label, required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: value ? color : Colors.grey.shade300, width: value ? 1.5 : 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(value ? Icons.check_circle : Icons.circle_outlined, size: 14, color: value ? color : Colors.grey.shade400),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: value ? color : Colors.grey.shade600)),
      ]),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 50,
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      child: loading
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
    ),
  );
}
