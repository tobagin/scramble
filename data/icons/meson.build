# Application icons
# Install the correct icon based on profile (development vs production)
if get_option('profile') == 'development'
  install_data('hicolor/scalable/apps/io.github.tobagin.scramble.Devel.svg',
    install_dir: join_paths(get_option('datadir'), 'icons/hicolor/scalable/apps'),
    rename: app_id + '.svg'
  )
else
  install_data('hicolor/scalable/apps/io.github.tobagin.scramble.svg',
    install_dir: join_paths(get_option('datadir'), 'icons/hicolor/scalable/apps'),
    rename: app_id + '.svg'
  )
endif