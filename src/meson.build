# Configure the main script
configure_file(
  input: 'scramble.in',
  output: 'scramble',
  configuration: conf,
  install: true,
  install_dir: get_option('bindir'),
  install_mode: 'rwxr-xr-x'
)

# Install Python source files
python_sources = [
  '__main__.py',
  'main.py',
  'window.py',
  'metadata.py',
  'preferences_dialog.py',
  '_version.py'
]

install_data(python_sources,
  install_dir: moduledir
)