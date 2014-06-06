# complete latexdef -s t -l tex --description 'Use given format of TeX' -r -a 'tex latex context'
# complete latexdef -s s -l source --description 'Try to show the original source code of the command definition'
# complete latexdef -s v -l value --description 'Show value of command instead (i.e. \the\command)'
# complete latexdef -s E -l Environment --description 'Every command name is taken as an environment name'
# complete latexdef -s P -l preamble --description 'Show definition of the command inside the preamble'
# complete latexdef -s B -l beforeclass --description 'Show definition of the command before \documentclass'
# complete latexdef -s p -l package --description 'Load given tex-file, package or module' -r
# complete latexdef -s c -l class --description 'Load given class instead of default' -r
# complete latexdef -s e -l environment --description 'Show definition inside the given environment' -r
# complete latexdef -s o -l othercode --description 'Add other code into the preamble before the definition is shown' -r
# complete latexdef -s b -l before --description 'Place code before definition is shown' -r
# complete latexdef -s a -l after --description 'Place code after definition is shown' -r
# complete latexdef -s f -l find --description 'Find file where the command sequence was defined'
# complete latexdef -s F -l Find --description 'Show full filepath of the file where the command sequence was defined'
# complete latexdef -s l -l list --description 'List user level command sequences of the given packages'
# complete latexdef -s L -l list-defs --description 'List user level command sequences and their shorten definitions of the given packages'
# complete latexdef -l list-all --description 'List all command sequences of the given packages'
# complete latexdef -l list-defs-all --description 'List all command sequences and their shorten definitions of the given packages'
# complete latexdef -s i -l ignore-cmds --description 'Ignore the following command sequence(s) in the above lists' -r
# complete latexdef -s I -l ignore-regex --description 'gnore all command sequences in the above lists which match the given Perl regular expression(s)' -r
# complete latexdef -s k -l pgf-keys --description 'Takes commands as pgfkeys and displays their definitions'
# complete latexdef -s K -l pgf-Keys --description 'Takes commands as pgfkeys and displays their definitions'
# complete latexdef -s V -l version --description 'Together with -p or -c prints version of LaTeX package(s) or class, respectively'
# complete latexdef -l edit --description 'Opens the file holding the macro definition'
# complete latexdef -l editor --description 'Can be used to set the used editor' -r
# complete latexdef -l tempdir --description 'Use given existing directory for temporary files' -r
# complete latexdef -s h -l help --description 'Print help and quit' -x
