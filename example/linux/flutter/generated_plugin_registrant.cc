//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <pushnotification/pushnotification_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) pushnotification_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PushnotificationPlugin");
  pushnotification_plugin_register_with_registrar(pushnotification_registrar);
}
