import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String ownerName;
  final String businessName;
  final String? photoUrl;
  final VoidCallback onEditTap;
  final VoidCallback onPhotoTap;

  const ProfileHeader({
    super.key,
    required this.ownerName,
    required this.businessName,
    this.photoUrl,
    required this.onEditTap,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8C6239), // Golden brown
            Color(0xFF5C3A21), // Dark brown
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C3A21).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              // Avatar
              GestureDetector(
                onTap: onPhotoTap,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFFF5E6D3), // Cream
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                    child: photoUrl == null
                        ? Text(
                            ownerName.isNotEmpty ? ownerName[0].toUpperCase() : 'O',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B5E3C),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              // Small edit button overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4A853), // Accent gold
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPhotoTap,
                      customBorder: const CircleBorder(),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Owner Name
          Text(
            ownerName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          // Business Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: Color(0xFFF5E6D3),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                businessName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFF5E6D3), // Cream
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Edit Profile Button (Small text link)
          TextButton.icon(
            onPressed: onEditTap,
            icon: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFFF5E6D3)),
            label: const Text(
              'Ubah Profil',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5E6D3),
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: Colors.white.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
