project('scramble',
  version: '1.0.0',
  meson_version: '>= 0.62.0',
  default_options: [
    'warning_level=2',
    'werror=false',
  ],
)

i18n = import('i18n')
gnome = import('gnome')
python = import('python')

# Python installation
py_installation = python.find_installation('python3')
if not py_installation.found()
  error('Python 3 installation not found')
endif

# Project variables
project_id = 'io.github.tobagin.scramble'
pkgdatadir = join_paths(get_option('prefix'), get_option('datadir'), meson.project_name())
moduledir = join_paths(pkgdatadir, 'scramble')
localedir = join_paths(get_option('prefix'), get_option('localedir'))

# Configuration
conf = configuration_data()
conf.set('VERSION', meson.project_version())
conf.set('localedir', localedir)
conf.set('pkgdatadir', pkgdatadir)

# Dependencies
dependency('glib-2.0')
dependency('gobject-introspection-1.0')
dependency('gtk4')
dependency('libadwaita-1')

# Blueprint compiler
blueprint_compiler = find_program('blueprint-compiler', required: true)

# Subdirectories
subdir('data')
subdir('src')
subdir('po')

# Post-install script
gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)