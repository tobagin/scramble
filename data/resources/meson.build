# GResource compilation
scramble_gresource = gnome.compile_resources('scramble',
  'scramble.gresource.xml',
  gresource_bundle: true,
  install: true,
  install_dir: pkgdatadir,
  source_dir: meson.current_build_dir() / '..' / 'ui',
  dependencies: ui_files
)