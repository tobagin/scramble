# Desktop file
desktop_configured = configure_file(
  input: 'io.github.tobagin.scramble.desktop.in',
  output: app_id + '.desktop.in.configured',
  configuration: conf
)
desktop_file = i18n.merge_file(
  input: desktop_configured,
  output: app_id + '.desktop',
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

# Metainfo file (AppStream)
metainfo_in = configure_file(
  input: 'io.github.tobagin.scramble.metainfo.xml.in',
  output: app_id + '.metainfo.xml.in',
  configuration: conf
)

metainfo_file = i18n.merge_file(
  input: metainfo_in,
  output: app_id + '.metainfo.xml',
  po_dir: '../po',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'metainfo')
)

# Validate metainfo file
appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
  test('Validate metainfo file', appstreamcli,
    args: ['validate', '--no-net', '--explain', metainfo_file]
  )
endif

# GSettings schema
gschema_file = configure_file(
  input: 'io.github.tobagin.scramble.gschema.xml.in',
  output: app_id + '.gschema.xml',
  configuration: conf
)
install_data(gschema_file,
  install_dir: join_paths(get_option('datadir'), 'glib-2.0/schemas')
)

# Compile GSettings schema for local testing
compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test('Validate schema file', compile_schemas,
    args: ['--strict', '--dry-run', meson.current_build_dir()]
  )
endif

# Subdirectories
subdir('ui')
subdir('resources')
