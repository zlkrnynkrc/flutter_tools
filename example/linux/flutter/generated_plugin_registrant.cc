//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <object_tools/object_tools_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) object_tools_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "ObjectToolsPlugin");
  object_tools_plugin_register_with_registrar(object_tools_registrar);
}
