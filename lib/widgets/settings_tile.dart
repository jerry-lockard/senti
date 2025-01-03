import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.description,
    this.iconColor = Colors.white,
    this.switchColor,
    this.trailing,
    this.leadingImage,
    this.showDivider = false,
    this.onTap,
    this.trailingWidget,
    this.subtitleWidget,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final String? description;
  final Color iconColor;
  final Color? switchColor;
  final Widget? trailing;
  final String? leadingImage;
  final bool showDivider;
  final VoidCallback? onTap;
  final Widget? trailingWidget;
  final Widget? subtitleWidget;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          color: Theme.of(context).colorScheme.surface,
          child: ListTile(
            onTap: onTap,
            leading:
                leadingImage != null
                    ? Image.asset(
                      leadingImage!,
                      width: 40,
                      height: 40,
                      color: Theme.of(context).colorScheme.primary,
                    )
                    : Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(icon, color: iconColor),
                      ),
                    ),
            title: Text(
              title,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle:
                subtitleWidget ??
                (subtitle != null
                    ? Text(
                      subtitle!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                    : null),
            trailing:
                trailingWidget ??
                (trailing ??
                    Switch(
                      value: value,
                      onChanged: onChanged,
                      activeColor:
                          switchColor ?? Theme.of(context).colorScheme.primary,
                    )),
          ),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (showDivider)
          Divider(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ],
    );
  }
}
