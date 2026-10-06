// lib/screens/counter/pages/settings_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiosk/models/kiosk_setting_model.dart';
import 'package:kiosk/providers/pos_network_service_provider.dart';
import 'package:kiosk/providers/settings_provider.dart';
import 'package:kiosk/theme/common_theme.dart';
import 'package:kiosk/utils/responsive.dart';
import 'package:path/path.dart' as p;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _welcomeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _welcomeController.text = ref.read(settingsProvider).kioskWelcomeMessage;
    });
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final current = ref.read(settingsProvider);
      await ref.read(settingsProvider.notifier).updateKioskSettings(
            KioskSettingsModel(
              gridCount: current.kioskGridCount,
              logoPath: image.path,
              welcomeMessage: _welcomeController.text,
              waitTime: current.kioskWaitTime,
              useIdleScreen: current.useKioskIdleScreen,
              idleMode: current.kioskIdleMode, // ★ idleMode 유지
            ),
          );
    }
  }

  Future<void> _syncToKiosks() async {
    final settings = ref.read(settingsProvider);
    Map<String, String>? imageDatas;

    if (settings.kioskLogoPath.isNotEmpty) {
      final file = File(settings.kioskLogoPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final fileName = p.basename(settings.kioskLogoPath);
        imageDatas = {fileName: base64Encode(bytes)};
      }
    }

    final model = KioskSettingsModel(
      gridCount: settings.kioskGridCount,
      logoPath: settings.kioskLogoPath.isNotEmpty
          ? p.basename(settings.kioskLogoPath)
          : '',
      welcomeMessage: _welcomeController.text,
      waitTime: settings.kioskWaitTime,
      useIdleScreen: settings.useKioskIdleScreen,
      idleMode: settings.kioskIdleMode, // ★ idleMode 동기화 모델에 포함!
    );

    ref
        .read(posNetworkServiceProvider.notifier)
        .broadcastKioskSettings(model, imageDatas: imageDatas);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ 모든 키오스크에 설정이 동기화되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = Responsive(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: baseBackgroundColor[50],
      appBar: AppBar(
        title: const Text('시스템 환경설정',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(rs.padding(20)),
        child: Column(
          children: [
            // 1. POS 관리 설정 섹션
            _buildSection(
              title: 'POS 관리 화면 설정',
              icon: Icons.monitor,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // ★ 신규 주문 자동 팝업 스위치 (OFF 시에도 뚜렷하게 보이도록 색상 명시)
                      SwitchListTile(
                        title: const Text('신규 주문 자동 팝업',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle:
                            const Text('키오스크에서 새 주문 접수 시 대기 주문 창을 자동으로 띄웁니다.'),
                        value: settings.autoPopupPendingOrders,
                        activeColor: PageColors.cateSelect,
                        activeTrackColor:
                            PageColors.cateSelect.withOpacity(0.3),
                        inactiveThumbColor: Colors.grey[600], // 비활성 버튼: 짙은 회색
                        inactiveTrackColor: Colors.grey[300], // 비활성 트랙: 연회색
                        onChanged: (val) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateAutoPopupPendingOrders(val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. 원격 키오스크 제어 섹션
            _buildSection(
              title: '원격 키오스크 제어 (실시간)',
              icon: Icons.settings_remote,
              color: Colors.orangeAccent,
              children: [
                ListTile(
                  title: const Text('키오스크 상단 로고'),
                  subtitle: const Text('키오스크 화면 상단에 표시될 이미지를 선택하세요.'),
                  trailing: settings.kioskLogoPath.isEmpty
                      ? const Icon(Icons.add_photo_alternate_outlined)
                      : Image.file(File(settings.kioskLogoPath),
                          width: 50, height: 50, fit: BoxFit.cover),
                  onTap: _pickLogo,
                ),
                const Divider(),
                _buildSliderTile(
                  label: '키오스크 상품 한 줄 개수',
                  value: settings.kioskGridCount.toDouble(),
                  min: 3,
                  max: 7,
                  onChanged: (val) =>
                      _updateKioskSettingsState(gridCount: val.toInt()),
                  trailing: '${settings.kioskGridCount}개',
                ),
                const Divider(),
                _buildSliderTile(
                  label: '자동 초기화 대기 시간',
                  value: settings.kioskWaitTime.toDouble(),
                  min: 10,
                  max: 60,
                  onChanged: (val) =>
                      _updateKioskSettingsState(waitTime: val.toInt()),
                  trailing: '${settings.kioskWaitTime}초',
                ),
                const Divider(),
                // ★ 대기화면 사용 스위치 (OFF 시에도 뚜렷하게 보이도록 색상 명시)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('대기화면 및 자동 초기화 모드',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    RadioListTile<String>(
                      title: const Text('대기화면(광고) 및 자동 초기화 사용',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('미조작 시 대기화면으로 전환되고 장바구니가 초기화됩니다.'),
                      value: 'use_idle',
                      groupValue: settings.kioskIdleMode,
                      activeColor: PageColors.cateSelect,
                      onChanged: (val) =>
                          _updateKioskSettingsState(idleMode: val),
                    ),
                    RadioListTile<String>(
                      title: const Text('대기화면 없이 자동 초기화',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                          '대기화면 없이 상품 화면에 머물며, 첫 터치 후 미조작 시 장바구니를 초기화합니다.'),
                      value: 'reset_only',
                      groupValue: settings.kioskIdleMode,
                      activeColor: PageColors.cateSelect,
                      onChanged: (val) =>
                          _updateKioskSettingsState(idleMode: val),
                    ),
                    RadioListTile<String>(
                      title: const Text('사용 안 함 (OFF)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('대기화면 전환 및 자동 초기화 기능을 모두 끕니다.'),
                      value: 'off',
                      groupValue: settings.kioskIdleMode,
                      activeColor: PageColors.cateSelect,
                      onChanged: (val) =>
                          _updateKioskSettingsState(idleMode: val),
                    ),
                  ],
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _welcomeController,
                    decoration: const InputDecoration(
                      labelText: '대기화면 안내 문구',
                      border: OutlineInputBorder(),
                      hintText: '예: 터치하여 주문을 시작하세요',
                    ),
                    onChanged: (val) => _updateKioskSettingsState(welcome: val),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _syncToKiosks,
                icon: const Icon(Icons.sync_rounded, color: Colors.white),
                label: const Text('키오스크에 설정 실시간 적용하기',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PageColors.cateSelect,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _updateKioskSettingsState(
      {int? gridCount,
      int? waitTime,
      bool? useIdle,
      String? welcome,
      String? idleMode}) {
    final current = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).updateKioskSettings(
          KioskSettingsModel(
            gridCount: gridCount ?? current.kioskGridCount,
            logoPath: current.kioskLogoPath,
            welcomeMessage: welcome ?? _welcomeController.text,
            waitTime: waitTime ?? current.kioskWaitTime,
            useIdleScreen: useIdle ?? current.useKioskIdleScreen,
            idleMode: idleMode ?? current.kioskIdleMode, // ★ idleMode 유지
          ),
        );
  }

  Widget _buildSection(
      {required String title,
      required IconData icon,
      required List<Widget> children,
      Color color = PageColors.cateSelect}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderTile(
      {required String label,
      required double value,
      required double min,
      required double max,
      required Function(double) onChanged,
      required String trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label)),
          Expanded(
            flex: 5,
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              activeColor: PageColors.cateSelect,
              inactiveColor: Colors.grey[300], // 비활성 트랙: 연회색
              onChanged: onChanged,
            ),
          ),
          SizedBox(
              width: 40,
              child: Text(trailing,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
