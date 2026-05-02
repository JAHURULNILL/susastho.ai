import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScanPreviewCard extends StatelessWidget {
  const ScanPreviewCard({
    super.key,
    required this.image,
  });

  final XFile image;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.file(
          File(image.path),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
