#!/usr/bin/env python3

import os
import subprocess
import sys

def main():
    if not os.environ.get('DESTDIR'):
        print('Updating icon cache...')
        subprocess.call(['gtk-update-icon-cache', '-qtf', os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share/icons/hicolor')])
        
        print('Updating desktop database...')
        subprocess.call(['update-desktop-database', '-q', os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share/applications')])
        
        print('Compiling GSettings schemas...')
        subprocess.call(['glib-compile-schemas', os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share/glib-2.0/schemas')])

if __name__ == '__main__':
    main()