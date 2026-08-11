//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <bonsoir_windows/bonsoir_windows_plugin_c_api.h>
#include <file_selector_windows/file_selector_windows.h>
#include <flutter_nsd/flutter_nsd_plugin.h>
#include <sqlite3_flutter_libs/sqlite3_flutter_libs_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  BonsoirWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("BonsoirWindowsPluginCApi"));
  FileSelectorWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FileSelectorWindows"));
  FlutterNsdPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterNsdPlugin"));
  Sqlite3FlutterLibsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("Sqlite3FlutterLibsPlugin"));
}
