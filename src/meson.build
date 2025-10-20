# Generate config for runtime paths
config_vala = configure_file(
  input: 'Config.vala.in',
  output: 'Config.vala',
  configuration: conf
)

srcs = [
  config_vala,
  'Main.vala',
  'Window.vala',
  'dialogs/AboutDialog.vala',
  'dialogs/ComparisonDialog.vala',
  'dialogs/PreferencesDialog.vala',
  'dialogs/ShortcutsWindow.vala',
  'widgets/MetadataRow.vala',
  'core/BatchProcessor.vala',
  'core/ImageOperations.vala',
  'core/MetadataDisplay.vala',
  'core/MetadataExporter.vala',
  'utils/FileValidator.vala',
  'utils/SecureMemory.vala',
]

deps = [glib_dep, gio_dep, gtk_dep, adw_dep, gdkpixbuf_dep]
if gexiv2_dep.found()
  deps += gexiv2_dep
endif

vala_extra_args = []
c_extra_args = [
  '-DGETTEXT_PACKAGE="' + meson.project_name() + '"',
  '-DLOCALEDIR="' + localedir + '"',
]
if gexiv2_dep.found()
  vala_extra_args += ['-D', 'HAVE_GEXIV2']
endif
if get_option('profile') == 'development'
  vala_extra_args += ['-D', 'DEVELOPMENT']
endif

# Provide resources to valac for GtkTemplate resolution
vala_extra_args += [
  '--gresources=' + meson.project_build_root() / 'scramble.gresource.xml',
  '--gresourcesdir=' + meson.project_build_root(),
]

executable('scramble',
  sources: srcs + [scramble_gresource],
  dependencies: deps,
  vala_args: vala_extra_args,
  c_args: c_extra_args,
  install: true
)
