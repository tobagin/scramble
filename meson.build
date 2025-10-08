project('scramble', 'vala',
  version: '1.2.0',
  meson_version: '>= 0.62.0',
  default_options: [
    'warning_level=2',
    'werror=false',
  ],
)

i18n = import('i18n')
gnome = import('gnome')

# Project variables

if get_option('profile') == 'development'
    app_id = 'io.github.tobagin.scramble.Devel'
    app_name = 'Scramble (Devel)'
else
    app_id = 'io.github.tobagin.scramble'
    app_name = 'Scramble'
endif


pkgdatadir = join_paths(get_option('prefix'), get_option('datadir'), meson.project_name())
localedir = join_paths(get_option('prefix'), get_option('localedir'))

# Configuration for generated config
conf = configuration_data()
conf.set('VERSION', meson.project_version())
conf.set('localedir', localedir)
conf.set('pkgdatadir', pkgdatadir)
conf.set('APP_ID', app_id)
conf.set('APP_NAME', app_name)
conf.set('APP_PATH', app_id.replace('.', '/'))

# Dependencies (for Vala/GTK application)
glib_dep = dependency('glib-2.0')
gio_dep = dependency('gio-2.0')
gtk_dep = dependency('gtk4')
adw_dep = dependency('libadwaita-1')
gdkpixbuf_dep = dependency('gdk-pixbuf-2.0')
gexiv2_dep = dependency('gexiv2-0.16', required: true)

# Blueprint compiler
blueprint_compiler = find_program('blueprint-compiler', required: true)

# Compile blueprints
blueprints = []

# Compile window.blp
window_ui = custom_target(
    'window.ui',
    input: files('data/ui/window.blp'),
    output: 'window.ui',
    command: [
        blueprint_compiler,
        'compile',
        '--output', '@OUTPUT@',
        '--typelib-path', '/usr/lib/x86_64-linux-gnu/girepository-1.0',
        '@INPUT@'
    ]
)
blueprints += window_ui

# Compile metadata_row.blp
metadata_row_ui = custom_target(
    'metadata_row.ui',
    input: files('data/ui/metadata_row.blp'),
    output: 'metadata_row.ui',
    command: [
        blueprint_compiler,
        'compile',
        '--output', '@OUTPUT@',
        '--typelib-path', '/usr/lib/x86_64-linux-gnu/girepository-1.0',
        '@INPUT@'
    ]
)
blueprints += metadata_row_ui

# Compile preferences_dialog.blp
preferences_dialog_ui = custom_target(
    'preferences_dialog.ui',
    input: files('data/ui/preferences_dialog.blp'),
    output: 'preferences_dialog.ui',
    command: [
        blueprint_compiler,
        'compile',
        '--output', '@OUTPUT@',
        '--typelib-path', '/usr/lib/x86_64-linux-gnu/girepository-1.0',
        '@INPUT@'
    ]
)
blueprints += preferences_dialog_ui

# Compile shortcuts-window.blp
shortcuts_window_ui = custom_target(
    'shortcuts-window.ui',
    input: files('data/ui/shortcuts-window.blp'),
    output: 'shortcuts-window.ui',
    command: [
        blueprint_compiler,
        'compile',
        '--output', '@OUTPUT@',
        '--typelib-path', '/usr/lib/x86_64-linux-gnu/girepository-1.0',
        '@INPUT@'
    ]
)
blueprints += shortcuts_window_ui

# Configure GResource XML with app path
gresource_xml = configure_file(
  input: 'data/resources/scramble.gresource.xml',
  output: 'scramble.gresource.xml',
  configuration: conf
)

# Generate resources
scramble_gresource = gnome.compile_resources(
    'scramble',
    gresource_xml,
    source_dir: [meson.current_build_dir()],
    dependencies: blueprints,
    c_name: 'scramble'
)

# SVG Icons removed

# PNG Icons for all sizes - try simple install_data approach
icon_sizes = ['16', '32', '48', '64', '128', '256', '512']
foreach size : icon_sizes
    install_data(
        'data/icons/hicolor/' + size + 'x' + size + '/apps/io.github.tobagin.scramble.png',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / size + 'x' + size + '/apps',
        rename: app_id + '.png'
    )
endforeach

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
