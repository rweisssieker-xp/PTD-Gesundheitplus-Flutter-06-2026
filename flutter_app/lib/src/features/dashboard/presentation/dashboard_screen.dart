import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_language_controller.dart';
import '../../../shared_ui/gp_colors.dart';
import '../../../shared_ui/gp_footer.dart';
import '../../../shared_ui/gp_header.dart';
import '../../../shared_ui/gp_icons.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  static const _featuredItemCount = 10;

  List<_DashboardItem> _featuredItems(AppLanguage language) => [
    _DashboardItem(
      title: language.t(AppText.anamnesis),
      subtitle: language.t(AppText.anamnesisSubtitle),
      description: language.t(AppText.anamnesisDesc),
      openLabel: language.t(AppText.open),
      icon: GpIcons.anamnesis,
      route: '/health/anamnesis',
      colors: GpColors.blue,
    ),
    _DashboardItem(
      title: language.t(AppText.healthcare),
      subtitle: language.t(AppText.healthcareSubtitle),
      description: language.t(AppText.healthcareDesc),
      openLabel: language.t(AppText.open),
      icon: GpIcons.healthcare,
      route: '/health/professionals',
      colors: GpColors.green,
    ),
    _DashboardItem(
      title: language.t(AppText.treatmentHistory),
      subtitle: language.t(AppText.treatmentHistorySubtitle),
      description: language.t(AppText.treatmentHistoryDesc),
      openLabel: language.t(AppText.open),
      icon: GpIcons.treatmentHistory,
      route: '/health/treatments',
      colors: GpColors.teal,
    ),
    _DashboardItem(
      title: language.t(AppText.vaccination),
      subtitle: language.t(AppText.vaccinationSubtitle),
      description: language.t(AppText.vaccinationDesc),
      openLabel: language.t(AppText.open),
      icon: GpIcons.vaccination,
      route: '/prevention/vaccination',
      colors: GpColors.purple,
    ),
    _DashboardItem(
      title: language.t(AppText.medication),
      subtitle: language.t(AppText.medicationSubtitle),
      description: language.t(AppText.medicationDesc),
      openLabel: language.t(AppText.open),
      icon: GpIcons.medication,
      route: '/medication',
      colors: GpColors.orange,
    ),
    _DashboardItem(
      title: language.t(AppText.appointments),
      subtitle: language.t(AppText.appointmentsSubtitle),
      description: language.t(AppText.appointmentsDesc),
      openLabel: language.t(AppText.open),
      icon: GpIcons.appointments,
      route: '/appointments',
      colors: GpColors.redGradient,
    ),
    _DashboardItem(
      title: language.t(AppText.allergies),
      subtitle: language.t(AppText.allergiesSubtitle),
      description: language.t(AppText.allergiesDesc),
      openLabel: language.t(AppText.open),
      icon: GpIcons.allergies,
      route: '/health/allergies',
      colors: GpColors.yellow,
    ),
    _DashboardItem(
      title: language.t(AppText.prevention),
      subtitle: language.t(AppText.preventionSubtitle),
      description: language.t(AppText.preventionDesc),
      openLabel: language.t(AppText.open),
      icon: GpIcons.prevention,
      route: '/prevention/care',
      colors: GpColors.indigo,
    ),
    _DashboardItem(
      title: language.t(AppText.bloodPressure),
      subtitle: language.t(AppText.bloodPressureSubtitle),
      description: language.t(AppText.bloodPressureDesc),
      openLabel: language.t(AppText.open),
      icon: GpIcons.bloodPressure,
      route: '/vitals/blood-pressure',
      colors: GpColors.rose,
    ),
    _DashboardItem(
      title: language.t(AppText.weight),
      subtitle: language.t(AppText.weightSubtitle),
      description: language.t(AppText.weightDesc),
      openLabel: language.t(AppText.open),
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
    final language =
        ref.watch(appLanguageControllerProvider).valueOrNull ?? AppLanguage.de;
    final featuredItems = _featuredItems(language);
    if (_currentIndex >= featuredItems.length) {
      _currentIndex = 0;
    }
    return Scaffold(
      body: Column(
        children: [
          GpHeader(
            actions: [
              const GpLanguageButton(),
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
                        onSettingsTap: () => context.go('/emergency/setup'),
                      ),
                      const SizedBox(height: 12),
                      GridView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 80,
                            ),
                        children: [
                          _GradientActionTile(
                            label: 'KI-Coach',
                            icon: GpIcons.aiCoach,
                            colors: GpColors.purplePink,
                            onTap: () => context.go('/ai/coach'),
                          ),
                          _GradientActionTile(
                            label: language.t(AppText.scanDocument),
                            icon: GpIcons.scan,
                            colors: GpColors.indigo,
                            onTap: () => context.go('/documents/scan'),
                          ),
                          _GradientActionTile(
                            label: language.t(AppText.dailyPlan),
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
                      GridView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 80,
                            ),
                        children: [
                          _GradientActionTile(
                            label: language.t(AppText.familyCircle),
                            icon: GpIcons.family,
                            colors: GpColors.teal,
                            onTap: () => context.go('/family'),
                          ),
                          _GradientActionTile(
                            label: language.t(AppText.interactionCheck),
                            icon: GpIcons.interactions,
                            colors: GpColors.amberOrange,
                            onTap: () =>
                                context.go('/medication/interaction-checker'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ExportButton(
                        label: language.t(AppText.healthExport),
                        onTap: () => context.go('/export'),
                      ),
                      const SizedBox(height: 14),
                      _FeatureCarousel(
                        controller: _pageController,
                        item: featuredItems[_currentIndex],
                        onOpen: () =>
                            context.go(featuredItems[_currentIndex].route),
                        onPrevious: () => _goToPage(_currentIndex - 1),
                        onNext: () => _goToPage(_currentIndex + 1),
                        onChanged: (index) =>
                            setState(() => _currentIndex = index),
                        itemBuilder: (context, index) => _FeatureCard(
                          item: featuredItems[index],
                          onOpen: () => context.go(featuredItems[index].route),
                        ),
                        itemCount: featuredItems.length,
                      ),
                      const SizedBox(height: 24),
                      _PageDots(
                        count: featuredItems.length,
                        index: _currentIndex,
                        onTap: _goToPage,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        language.t(AppText.allAreas),
                        style: const TextStyle(
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
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.28,
                        children: [
                          for (final item in featuredItems)
                            _AreaCard(
                              item: item,
                              onTap: () => context.go(item.route),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const GpFooter(),
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
    final target = (index + _featuredItemCount) % _featuredItemCount;
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
    required this.openLabel,
    required this.icon,
    required this.route,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final String description;
  final String openLabel;
  final IconData icon;
  final String route;
  final List<Color> colors;
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.onTap, required this.onSettingsTap});

  final VoidCallback onTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: GpColors.redDeep),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GpColors.redDark, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: const SizedBox(
                height: 96,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 40),
                      SizedBox(height: 6),
                      Text(
                        '🚨 NOTFALL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Im Notfall hier drücken',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onSettingsTap,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.settings_outlined, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
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
  const _ExportButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GradientSurface(
      colors: GpColors.grayDark,
      radius: 8,
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(GpIcons.export, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
      height: 430,
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
            left: 2,
            child: _RoundNavButton(icon: Icons.chevron_left, onTap: onPrevious),
          ),
          Positioned(
            right: 2,
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
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
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
                    child: Icon(item.icon, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          color: GpColors.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: GpColors.textSecondary,
                      fontSize: 18,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _GradientSurface(
                    colors: item.colors,
                    radius: 8,
                    onTap: onOpen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 15,
                      ),
                      child: Text(
                        item.openLabel,
                        style: const TextStyle(
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
          width: 64,
          height: 64,
          child: Icon(icon, size: 36, color: Color(0xFF374151)),
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
