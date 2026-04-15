import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.nav,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text('Configuración', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: AppColors.border),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                const _SectionLabel('Cuenta'),
                _SettingsTile(icon: Icons.person_outline_rounded, label: 'Perfil', onTap: () {}),
                _SettingsTile(icon: Icons.lock_outline_rounded,   label: 'Privacidad & Seguridad', onTap: () {}),
                _SettingsTile(icon: Icons.notifications_outlined, label: 'Notificaciones', onTap: () {}),

                const SizedBox(height: 24),
                const _SectionLabel('Apariencia'),
                _SettingsTile(icon: Icons.dark_mode_outlined,     label: 'Tema oscuro', onTap: () {}, trailing: _GradientSwitch()),
                _SettingsTile(icon: Icons.language_rounded,       label: 'Idioma', onTap: () {}),

                const SizedBox(height: 24),
                const _SectionLabel('Acerca de'),
                _SettingsTile(icon: Icons.info_outline_rounded,   label: 'Versión', onTap: () {}, trailing: const Text('1.0.0', style: TextStyle(color: AppColors.muted, fontSize: 13))),
                _SettingsTile(icon: Icons.help_outline_rounded,   label: 'Ayuda & Soporte', onTap: () {}),

                const SizedBox(height: 24),

                // Logout tile (danger style)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.primary),
                    title: const Text('Cerrar sesión', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                    onTap: () {},
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.muted, letterSpacing: 0.5)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.muted, size: 20),
        title: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.w400)),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.faint, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _GradientSwitch extends StatefulWidget {
  @override
  State<_GradientSwitch> createState() => _GradientSwitchState();
}

class _GradientSwitchState extends State<_GradientSwitch> {
  bool value = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      activeColor: AppColors.primary,
      onChanged: (v) => setState(() => value = v),
    );
  }
}