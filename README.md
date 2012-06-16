dotfiles
========
This project is simply an attempt to organize, version-control and share my own dotfiles across systems I use as well as with other people.
Heavy inspiration was taken from [holman's dotfiles](https://github.com/holman/dotfiles) on Github, but the main script is written from scratch.

The idea is that you'll fragment and sort your dotfiles in subdirectories of `~/.dotfiles`, and then run `dotfiles.rb` to transfer the contents of these files into your home directory.
Two modes of operation are implemented; symlinking and merging.
The default `Rules` file (explained later) is set up to symlink everything matching `*/<name>.symlink` to `~/.<name>` (this includes directories), while it merges all files matching `*/<name>.merge/*` into `~/.<name>`.
Additional rules can be added to the `Rules` file to customize the operation of `dotfiles.rb`.

Since I use this repository to store my own dotfiles as well, I have organized things into branches.
The `default` branch will only contain the `dotfiles.rb` script, a sample `Rules` file and this `README`-file. Other branches, appropriately given the same name as the machines they originate from, contain custom tweaks to the `Rules` file and collections of fragmented dotfiles. Feel free to cherrypick files or changesets from these branches (see below).

install
=======
Installing is fairly simple, if you only want the script and none of the version-controlling goodies:

1. `hg clone https://urdh@bitbucket.org/urdh/dotfiles\#default ~/.dotfiles`

After moving your dotfiles to subfolders in `~/.dotfiles` and renaming them appropriately (to `<name>.symlink`), simply run the `dotfiles.rb` script:

1. `cd ~/.dotfiles`
2. `./dotfiles.rb -v`

The script will symlink and merge your files as instructed.

advanced install
----------------
If you plan on version-controlling your dotfiles as well (and feel comfortable using Mercurial), I recommend forking the repository on Bitbucket, then creating your own branch(es) for whatever machines you've got dotfiles on (and closing the branches you won't use):

1. [Fork the repository on Bitbucket](https://confluence.atlassian.com/display/BITBUCKET/Forking+a+bitbucket+Repository).
2. `hg clone ssh://hg@bitbucket.org/<username>/dotfiles ~/.dotfiles`
3. `cd ~/.dotfiles`
4. `for branch in $(hg branches | awk '{if ($1 != "default") print $1}'); do
  hg update $branch && hg ci --close-branch -m"Closing $branch" && hg update default
done`
5. `hg branch $(hostname -s) && hg ci -m"Created $(hostname -s)"`
6. `hg push`

You can now start moving your dotfiles into `~/.dotfiles`, splitting them into categories, projects or any other organized mess.
I prefer to make one commit for every change and/or new file, since that makes it easy to cherrypick or disable specific files by reverting or transplanting changesets between branches.
Just make sure you stay on the branch belonging to the machine you're on, or things might go wrong.

If you choose to fork the project, and make useful changes to the `dotfiles.rb` script (or any of the files in `default`), feel free to transplant the changes into the `default` branch and [send a pull request](https://confluence.atlassian.com/display/BITBUCKET/_Fork+Pull+Request).

the rules
=========
The script reads instructions from `~/.dotfiles/Rules` and applies these to process the files in `~/.dotfiles`.
Each file matches only one rule, and rules are matched in the order that they appear in the `Rules` file.

There are three different instructions available:

* `ignore <regex>` tells the script to ignore all files and directories matching the regular expression `<regex>`.
* `symlink <regex>, <target>` tells the script to create a symlink from `~/<target>` to the file matching `<regex>`. The target filename may contain tokens of the type `$[1-9]` which will be replaced by the corresponding matching group in the regular expression.
* `merge <regex>, <target>, [<group>]` tells the script to merge all files matching `<regex>` directly into the file `<target>`. The files will be appended to `<target>` in lexiographical order. As with `symlink`, `<target>` may contain tokens of the type `$[1-9]` which will be replaced by the corresponding matching group in the regular expression. It will also collect files by the first matching group (unless `<group>` is specified).

The default rules are designed to do the following:

* Ignore any temporary or backup files.
* Merge files from `*/<file>.merge/*` to `~/.<file>`
* Symlink files from `*/<file>.symlink` to `~/.<file>`

cherrypicking
=============
Cherrypicking between branches or from other repositories is useful if you'd like to make the same change on all your machines (i.e. copy it to all branches) or if you'd like to import someone else's dotfiles.
You are more than welcome to cherrypick anything you'd like from my branches as well.

cherrypicking between branches
------------------------------
Cherrypicking between branches is simple.
Find the changeset you want to cherrypick, here denoted by `<cset>` and simply transplant it into the active branch (you have to activate the [`transplant` extension](http://mercurial.selenic.com/wiki/TransplantExtension)):

1. `hg pull -u`
2. `hg transplant <cset>`

cherrypicking from another repository
-------------------------------------
Most of the time, it's probably easier to just get a copy of the file you want and manually add it to the repository.
What might work reasonably well is cherrypicking from other forks of this repository.
It's basically the same as picking from another branch; just find the changeset `<cset>` you want to cherrypick, and the URI you'd clone the repository from.
Proceed with a transplant:

1. `hg pull -u`
2. `hg transplant -s ssh://hg@bitbucket.org/<whoever>/dotfiles <cset>`

This pretty much assumes that the repository has the exact same format as yours (i.e. is also forked from this project), but it *should* work.

license
=======
The script (all files in the `default` branch) is licensed under the MIT license (and by sending a pull request you agree to licensing the relevant changes under the MIT license as well - but please add your name to the copyright holder list in your pull request):

> Copyright (C) 2012 Simon Sigurdhsson
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

All content of the branches that isn't also in `default` is [effectively public-domain](http://creativecommons.org/publicdomain/zero/1.0/) unless otherwise noted.
