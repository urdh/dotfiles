dotfiles
========
This project is simply an attempt to organize, version-control and share my own dotfiles across systems I use as well as with other people.
Heavy inspiration was taken from [holman's dotfiles](https://github.com/holman/dotfiles) on Github, but the main script is written from scratch.

The idea is that you'll fragment and sort your dotfiles in subdirectories of `~/.dotfiles`, and then run `dotfiles.rb` to transfer the contents of these files into your home directory.
Two modes of operation are implemented; symlinking and merging.
The default `Rules` file (explained later) showcases pretty much all the features of the rules DSL.
Additional rules can be added to the `Rules` file to customize the operation of `dotfiles.rb`.

Since I use this repository to store my own dotfiles as well, I have organized things into subdirectories. The default `Rules` file runs most of its rules on two of these subdirectories; the `common` directory and one directory corresponding to the current machine.

install
=======
Installing is fairly simple, if you only want the script and none of the version-controlling goodies:

1. `git clone https://github.com/urdh/dotfiles.git ~/.dotfiles`

After moving your dotfiles to subfolders in `~/.dotfiles`, renaming them and customizing the Rules file, simply do this:

1. `cd ~/.dotfiles`
2. `./dotfiles.rb -v`

The script will symlink and merge your files as instructed.

advanced install
----------------
If you plan on version-controlling your dotfiles as well (and feel comfortable using Git), I recommend forking the repository on Github, then creating your own branch(es) for whatever machines you've got dotfiles on (and closing the branches you won't use):

1. [Fork the repository on Github](https://help.github.com/articles/fork-a-repo).
2. `git clone git@github.com:<username>/dotfiles.git ~/.dotfiles`

You can now start moving your dotfiles into `~/.dotfiles`, splitting them into categories, projects or any other organized mess. Customize the `Rules` file and commit+push your initial setup.
I prefer to make one commit for every logical change, since that makes it easy to cherrypick or disable specific files by reverting or transplanting changesets between branches.

If you choose to fork the project, and make useful changes to the `dotfiles.rb` script (or add useful dotfiles to the `contrib/` directory), feel free to [send a pull request](https://help.github.com/articles/using-pull-requests).

the rules
=========
The script reads instructions from `~/.dotfiles/Rules` and applies these to process the files in `~/.dotfiles`.
Each file matches only one rule, and rules are matched in the order that they appear in the `Rules` file.

There are three different instructions available:

* `ignore <regex>` tells the script to ignore all files and directories matching the regular expression `<regex>`.
* `symlink <regex>, <target>` tells the script to create a symlink from `~/<target>` to the file matching `<regex>`. The target filename may contain tokens of the type `$[1-9]` which will be replaced by the corresponding matching group in the regular expression.
* `merge <regex>, <target>, [<group>]` tells the script to merge all files matching `<regex>` directly into the file `<target>`. The files will be appended to `<target>` in lexiographical order. As with `symlink`, `<target>` may contain tokens of the type `$[1-9]` which will be replaced by the corresponding matching group in the regular expression. It will also collect files by the first matching group (unless `<group>` is specified).

Additionally, you can use regular ruby code, the `@machine` variable containing the machine hostname, and the following blocks:

* `directory <dir> do ...` performs the actions in the block, but only matches files in the specified directory.
* `directories <dirs> do ...` does the same thing, but for multiple directories.

license
=======
The script is licensed under the MIT license (and by sending a pull request with changes to the script you agree to licensing the relevant changes under the MIT license as well - but please add your name to the copyright holder list in your pull request):

> Copyright (C) 2012 Simon Sigurdhsson
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

All content in the subdirectories `common`, `lagrange`, `fserv`, `chomsky` and `contrib` is [effectively public-domain](http://creativecommons.org/publicdomain/zero/1.0/) unless otherwise noted.
