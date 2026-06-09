import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';

class ProfilAvatar extends StatefulWidget {
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const ProfilAvatar({
    super.key,
    required this.size,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<ProfilAvatar> createState() => _ProfilAvatarState();
}

class _ProfilAvatarState extends State<ProfilAvatar> {
  String? _storageUrl;

  @override
  void initState() {
    super.initState();
    _loadStorageUrl();
  }

  Future<void> _loadStorageUrl() async {
    try {
      final apiBaseUrl = await AuthService.getBaseUrl();
      // Replace '/api' suffix with '/storage' to get public storage URL
      setState(() {
        _storageUrl = apiBaseUrl.replaceAll('/api', '/storage');
      });
    } catch (_) {
      setState(() {
        _storageUrl = 'http://10.175.124.237:8000/storage';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final path = userProvider.fotoProfilPath;
        final name = userProvider.namaLengkap;
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

        Widget imageWidget;

        if (path == null || path.isEmpty) {
          imageWidget = _buildInitialsWidget(initial);
        } else if (path.startsWith('/') || path.contains('Content/') || File(path).existsSync()) {
          // Local File
          imageWidget = Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildInitialsWidget(initial),
          );
        } else {
          // Remote File
          final fullUrl = path.startsWith('http')
              ? path
              : '${_storageUrl ?? 'http://10.175.124.237:8000/storage'}/$path';

          imageWidget = CachedNetworkImage(
            imageUrl: fullUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => _buildInitialsWidget(initial),
          );
        }

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: imageWidget,
          ),
        );
      },
    );
  }

  Widget _buildInitialsWidget(String initial) {
    return Container(
      color: widget.backgroundColor ?? const Color(0xFF8B5E3C), // default primary
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: widget.textColor ?? Colors.white,
          fontSize: widget.size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
