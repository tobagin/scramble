# Blueprint UI files
blueprint_files = [
  'window.blp',
  'metadata_row.blp',
  'preferences_dialog.blp'
]

ui_files = []
foreach blueprint_file : blueprint_files
  ui_file = blueprint_file.split('.blp')[0] + '.ui'
  ui_files += custom_target(ui_file,
    input: blueprint_file,
    output: ui_file,
    command: [blueprint_compiler, 'compile', '--output', '@OUTPUT@', '@INPUT@']
  )
endforeach

# Install UI files
install_data(ui_files,
  install_dir: join_paths(pkgdatadir, 'ui')
)