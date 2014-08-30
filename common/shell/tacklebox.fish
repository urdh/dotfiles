# Tacklebox repositories
set tacklebox_path ~/.tackle/bpinto/oh-my-fish \
                   ~/.tackle/urdh/oh-my-fish \
                   ~/.tackle/justinmayer/tackle \
                   ~/.tackle/urdh/tackle

# Initial setup, including theme
set tacklebox_modules
set tacklebox_plugins
set tacklebox_theme urdh

# Things from urdh/tackle and justinmayer/tackle
set tacklebox_modules $tacklebox_modules
set tacklebox_plugins $tacklebox_plugins \
                      up pip extract grc

# Things from urdh/oh-my-fish and bpinto/oh-my-fish
set tacklebox_modules $tacklebox_modules
set tacklebox_plugins $tacklebox_plugins

# Finally, load Tacklebox itself
source ~/.tacklebox/tacklebox.fish
