import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/cccd_photo_service.dart';
import '../../core/theme/app_colors.dart';

class CCCDPhotoPicker extends StatefulWidget {
  final String? initialPhotoUrl;
  final ValueChanged<String?> onPhotoChanged;
  final Color? primaryColor;

  const CCCDPhotoPicker({
    super.key,
    this.initialPhotoUrl,
    required this.onPhotoChanged,
    this.primaryColor,
  });

  @override
  State<CCCDPhotoPicker> createState() => _CCCDPhotoPickerState();
}

class _CCCDPhotoPickerState extends State<CCCDPhotoPicker> {
  final CCCDPhotoService _photoService = CCCDPhotoService();

  File? _localImage;
  String? _uploadedPhotoUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _uploadedPhotoUrl = widget.initialPhotoUrl;
  }

  Color get _primaryColor => widget.primaryColor ?? AppColors.primary;

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn ảnh CCCD',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: _primaryColor),
                ),
                title: const Text('Chụp ảnh'),
                subtitle: const Text('Sử dụng camera để chụp CCCD'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromCamera: true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.purple),
                ),
                title: const Text('Chọn từ thư viện'),
                subtitle: const Text('Chọn ảnh CCCD có sẵn'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromCamera: false);
                },
              ),
              if (_uploadedPhotoUrl != null || _localImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Xóa ảnh'),
                  subtitle: const Text('Xóa ảnh CCCD hiện tại'),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    final file = await _photoService.pickImage(fromCamera: fromCamera);
    if (file != null) {
      setState(() {
        _localImage = file;
        _isUploading = true;
      });

      // Upload to Firebase Storage
      final url = await _photoService.uploadCCCDPhoto(file);

      if (mounted) {
        setState(() {
          _isUploading = false;
          if (url != null) {
            _uploadedPhotoUrl = url;
            widget.onPhotoChanged(url);
          }
        });

        if (url == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể upload ảnh. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _localImage = null;
      _uploadedPhotoUrl = null;
    });
    widget.onPhotoChanged(null);
  }

  void _showFullImage() {
    if (_localImage == null && _uploadedPhotoUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Ảnh CCCD'),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (_localImage != null)
              Image.file(_localImage!, fit: BoxFit.contain)
            else if (_uploadedPhotoUrl != null)
              Image.network(
                _uploadedPhotoUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _localImage != null || _uploadedPhotoUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh CCCD/CMND',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: hasPhoto ? _showFullImage : _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasPhoto ? _primaryColor : Colors.grey[300]!,
                width: hasPhoto ? 2 : 1,
              ),
            ),
            child: _buildContent(hasPhoto),
          ),
        ),
        if (hasPhoto)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Chụp lại'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFullImage,
                    icon: const Icon(Icons.zoom_in, size: 18),
                    label: const Text('Xem ảnh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContent(bool hasPhoto) {
    if (_isUploading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 12),
          const Text(
            'Đang upload ảnh...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    if (_localImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              _localImage!,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_uploadedPhotoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _uploadedPhotoUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: _primaryColor,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 48),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_a_photo,
              size: 32,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chụp ảnh CCCD/CMND',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nhấn để chụp hoặc chọn ảnh',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
