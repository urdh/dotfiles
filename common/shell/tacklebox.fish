# Tacklebox repositories
set tacklebox_path ~/.tackle/justinmayer/tackle \
                   ~/.tackle/urdh/tackle

# Initial setup, including theme
set tacklebox_modules
set tacklebox_plugins
set tacklebox_theme urdh

# Things from urdh/tackle and justinmayer/tackle
set tacklebox_modules $tacklebox_modules
set tacklebox_plugins $tacklebox_plugins \
                      up pip extract grc

# Finally, load Tacklebox itself
source ~/.tacklebox/tacklebox.fish
