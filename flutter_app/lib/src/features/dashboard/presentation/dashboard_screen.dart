import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_header.dart';
import '../../../shared_ui/gp_icons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static final List<_DashboardItem> _featuredItems = [
    _DashboardItem(
      title: 'Anamnese',
      subtitle: 'Gesundheitsdaten',
      description: 'Medizinische Vorgeschichte',
      icon: GpIcons.anamnesis,
      route: '/health/anamnesis',
      colors: GpColors.blue,
    ),
    _DashboardItem(
      title: 'Heilberufe',
      subtitle: 'Ärzte & Therapeuten',
      description: 'Behandler und Kontakte',
      icon: GpIcons.healthcare,
      route: '/health/professionals',
      colors: GpColors.green,
    ),
    _DashboardItem(
      title: 'Behandlung',
      subtitle: 'Historie',
      description: 'Behandlungen und Befunde',
      icon: GpIcons.treatmentHistory,
      route: '/health/treatments',
      colors: GpColors.teal,
    ),
    _DashboardItem(
      title: 'Impfpass',
      subtitle: 'Impfungen',
      description: 'Impfschutz und Nachweise',
      icon: GpIcons.vaccination,
      route: '/prevention/vaccination',
      colors: GpColors.violet,
    ),
    _DashboardItem(
      title: 'Medikation',
      subtitle: 'Medikamente',
      description: 'Einnahme und Bestand',
      icon: GpIcons.medication,
      route: '/medication',
      colors: GpColors.orange,
    ),
    _DashboardItem(
      title: 'Termine',
      subtitle: 'Arzttermine',
      description: 'Planung und Erinnerungen',
      icon: GpIcons.appointments,
      route: '/appointments',
      colors: GpColors.redGradient,
    ),
    _DashboardItem(
      title: 'Allergien',
      subtitle: 'Warnhinweise',
      description: 'Allergien und Risiken',
      icon: GpIcons.allergies,
      route: '/dashboard/health',
      colors: GpColors.yellow,
    ),
    _DashboardItem(
      title: 'Vorsorge',
      subtitle: 'Checkups',
      description: 'Vorsorge und Prävention',
      icon: GpIcons.prevention,
      route: '/prevention/care',
      colors: GpColors.indigo,
    ),
    _DashboardItem(
      title: 'Blutdruck',
      subtitle: 'Messwerte',
      description: 'Blutdruck und Puls',
      icon: GpIcons.bloodPressure,
      route: '/vitals/blood-pressure',
      colors: GpColors.rose,
    ),
    _DashboardItem(
      title: 'Gewicht',
      subtitle: 'BMI & Verlauf',
      description: 'Gewichtskontrolle',
      icon: GpIcons.weight,
      route: '/vitals/weight',
      colors: GpColors.violet,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GpHeader(
            actions: [
              IconButton(
                tooltip: 'Benachrichtigungen',
                onPressed: () => context.go('/notifications'),
                icon: const Icon(Icons.notifications_none),
              ),
              IconButton(
                tooltip: 'Datenschutz',
                onPressed: () => context.go('/privacy'),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [GpColors.redSurface, Colors.white],
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    children: [
                      _EmergencyButton(
                        onTap: () => context.go('/emergency/offline'),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                        children: [
                          _GradientActionTile(
                            label: 'KI-Coach',
                            icon: GpIcons.aiCoach,
                            colors: GpColors.purplePink,
                            onTap: () => context.go('/ai/coach'),
                          ),
                          _GradientActionTile(
                            label: 'Scan',
                            icon: GpIcons.scan,
                            colors: GpColors.indigo,
                            onTap: () => context.go('/documents/scan'),
                          ),
                          _GradientActionTile(
                            label: 'Tagesplan',
                            icon: GpIcons.dailyPlan,
                            colors: GpColors.orange,
                            onTap: () => context.go('/medication/daily-plan'),
                          ),
                          _GradientActionTile(
                            label: 'KI-Chat',
                            icon: GpIcons.chat,
                            colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                            onTap: () => context.go('/ai/coach'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.05,
                        children: [
                          _GradientActionTile(
                            label: 'Familienkreis',
                            icon: GpIcons.family,
                            colors: GpColors.teal,
                            onTap: () => context.go('/family'),
                          ),
                          _GradientActionTile(
                            label: 'Wechselwirkungen',
                            icon: GpIcons.interactions,
                            colors: GpColors.amberOrange,
                            onTap: () =>
                                context.go('/medication/interaction-checker'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ExportButton(onTap: () => context.go('/export')),
                      const SizedBox(height: 18),
                      _FeatureCarousel(
                        controller: _pageController,
                        item: _featuredItems[_currentIndex],
                        onOpen: () =>
                            context.go(_featuredItems[_currentIndex].route),
                        onPrevious: () => _goToPage(_currentIndex - 1),
                        onNext: () => _goToPage(_currentIndex + 1),
                        onChanged: (index) =>
                            setState(() => _currentIndex = index),
                        itemBuilder: (context, index) => _FeatureCard(
                          item: _featuredItems[index],
                          onOpen: () => context.go(_featuredItems[index].route),
                        ),
                        itemCount: _featuredItems.length,
                      ),
                      const SizedBox(height: 16),
                      _PageDots(
                        count: _featuredItems.length,
                        index: _currentIndex,
                        onTap: _goToPage,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ALLE BEREICHE',
                        style: TextStyle(
                          color: GpColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.28,
                        children: [
                          for (final item in _featuredItems)
                            _AreaCard(
                              item: item,
                              onTap: () => context.go(item.route),
                            ),
                          _AreaCard(
                            item: const _DashboardItem(
                              title: 'Dokumente',
                              subtitle: 'Scans',
                              description: 'Gescannte Unterlagen',
                              icon: GpIcons.scan,
                              route: '/documents',
                              colors: GpColors.indigo,
                            ),
                            onTap: () => context.go('/documents'),
                          ),
                          _AreaCard(
                            item: const _DashboardItem(
                              title: 'Notfall',
                              subtitle: 'Kontakte',
                              description: 'Notfallkontakte',
                              icon: GpIcons.emergency,
                              route: '/emergency/setup',
                              colors: GpColors.redGradient,
                            ),
                            onTap: () => context.go('/emergency/setup'),
                          ),
                          _AreaCard(
                            item: const _DashboardItem(
                              title: 'Demenz',
                              subtitle: 'Unterstützung',
                              description: 'Alltag und Hinweise',
                              icon: Icons.elderly_outlined,
                              route: '/dementia',
                              colors: GpColors.green,
                            ),
                            onTap: () => context.go('/dementia'),
                          ),
                          _AreaCard(
                            item: const _DashboardItem(
                              title: 'Speicher',
                              subtitle: 'Lokal',
                              description: 'Lokale Daten',
                              icon: Icons.storage_outlined,
                              route: '/privacy/storage',
                              colors: GpColors.grayDark,
                            ),
                            onTap: () => context.go('/privacy/storage'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToPage(int index) {
    final target = (index + _featuredItems.length) % _featuredItems.length;
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }
}

class _DashboardItem {
  const _DashboardItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.route,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String route;
  final List<Color> colors;
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GradientSurface(
      colors: GpColors.redGradient,
      radius: 8,
      onTap: onTap,
      child: const SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(GpIcons.emergency, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOS Notfall',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Im Notfall hier drücken',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientActionTile extends StatelessWidget {
  const _GradientActionTile({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GradientSurface(
      colors: colors,
      radius: 8,
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GradientSurface(
      colors: GpColors.grayDark,
      radius: 8,
      onTap: onTap,
      child: const SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(GpIcons.export, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'Gesundheitsakte exportieren',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCarousel extends StatelessWidget {
  const _FeatureCarousel({
    required this.controller,
    required this.item,
    required this.onOpen,
    required this.onPrevious,
    required this.onNext,
    required this.onChanged,
    required this.itemBuilder,
    required this.itemCount,
  });

  final PageController controller;
  final _DashboardItem item;
  final VoidCallback onOpen;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onChanged;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: controller,
            itemCount: itemCount,
            onPageChanged: onChanged,
            itemBuilder: itemBuilder,
          ),
          Positioned(
            left: 8,
            child: _RoundNavButton(icon: Icons.chevron_left, onTap: onPrevious),
          ),
          Positioned(
            right: 8,
            child: _RoundNavButton(icon: Icons.chevron_right, onTap: onNext),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.item, required this.onOpen});

  final _DashboardItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 16,
      shadowColor: const Color(0x33000000),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      item.colors.first.withValues(alpha: 0.12),
                      item.colors.last.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 74, vertical: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: item.colors,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 42),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GpColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GpColors.textSecondary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _GradientSurface(
                    colors: item.colors,
                    radius: 8,
                    onTap: onOpen,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 14,
                      ),
                      child: Text(
                        'Öffnen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundNavButton extends StatelessWidget {
  const _RoundNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: const Color(0x33000000),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFFE5E7EB), width: 2),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Icon(icon, size: 34, color: Color(0xFF374151)),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.index,
    required this.onTap,
  });

  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: i == index
                  ? GpColors.emergencyRed
                  : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onTap(i),
                child: SizedBox(width: i == index ? 32 : 8, height: 8),
              ),
            ),
          ),
      ],
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.item, required this.onTap});

  final _DashboardItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: const Color(0x1A000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.colors,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: Colors.white, size: 25),
              ),
              const SizedBox(height: 9),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GpColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: GpColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientSurface extends StatelessWidget {
  const _GradientSurface({
    required this.colors,
    required this.radius,
    required this.onTap,
    required this.child,
  });

  final List<Color> colors;
  final double radius;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}
