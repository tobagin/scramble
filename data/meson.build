# Desktop file
desktop_file = i18n.merge_file(
  input: 'io.github.tobagin.scramble.desktop.in',
  output: 'io.github.tobagin.scramble.desktop',
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

# Validate desktop file
desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test('Validate desktop file', desktop_utils,
    args: [desktop_file]
  )
endif

# Appdata file
appdata_file = i18n.merge_file(
  input: 'io.github.tobagin.scramble.appdata.xml.in',
  output: 'io.github.tobagin.scramble.appdata.xml',
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'metainfo')
)

# Validate appdata file
appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
  test('Validate appdata file', appstreamcli,
    args: ['validate', '--no-net', '--explain', appdata_file]
  )
endif

# GSettings schema
install_data('io.github.tobagin.scramble.gschema.xml',
  install_dir: join_paths(get_option('datadir'), 'glib-2.0/schemas')
)

# Compile GSettings schema for local testing
compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test('Validate schema file', compile_schemas,
    args: ['--strict', '--dry-run', meson.current_source_dir()]
  )
endif

# Subdirectories
subdir('icons')
subdir('ui')
subdir('resources')