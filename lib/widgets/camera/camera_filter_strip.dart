import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraFilterStrip extends StatefulWidget {
  const CameraFilterStrip({
    super.key,
    required this.state,
    required this.filters,
  });

  final CameraState state;
  final List<AwesomeFilter> filters;

  @override
  State<CameraFilterStrip> createState() => _CameraFilterStripState();
}

class _CameraFilterStripState extends State<CameraFilterStrip> {
  int? _textureId;

  @override
  void initState() {
    super.initState();
    _loadTexture();
  }

  Future<void> _loadTexture() async {
    final int? textureId = await widget.state.previewTextureId(0);
    if (!mounted) return;
    setState(() => _textureId = textureId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AwesomeFilter>(
      stream: widget.state.filter$,
      initialData: widget.state.filter,
      builder: (context, snapshot) {
        final AwesomeFilter selected = snapshot.data ?? AwesomeFilter.None;

        return SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: widget.filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final AwesomeFilter filter = widget.filters[index];
              final bool isSelected = filter.id == selected.id;

              return _FilterPreviewTile(
                filter: filter,
                textureId: _textureId,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.state.setFilter(filter);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _FilterPreviewTile extends StatelessWidget {
  const _FilterPreviewTile({
    required this.filter,
    required this.textureId,
    required this.isSelected,
    required this.onTap,
  });

  final AwesomeFilter filter;
  final int? textureId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFD60A)
                      : Colors.white38,
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _FilterThumbnail(
                  colorFilter: filter.preview,
                  textureId: textureId,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filter.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFD60A) : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterThumbnail extends StatelessWidget {
  const _FilterThumbnail({
    required this.colorFilter,
    required this.textureId,
  });

  final ColorFilter colorFilter;
  final int? textureId;

  @override
  Widget build(BuildContext context) {
    final Widget previewSource = textureId != null
        ? OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 60,
                height: 60 / (9 / 16),
                child: Texture(textureId: textureId!),
              ),
            ),
          )
        : const _FilterPlaceholder();

    return ColorFiltered(
      colorFilter: colorFilter,
      child: previewSource,
    );
  }
}

class _FilterPlaceholder extends StatelessWidget {
  const _FilterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5C6BC0),
            Color(0xFF26A69A),
            Color(0xFFFFB74D),
          ],
        ),
      ),
    );
  }
}
