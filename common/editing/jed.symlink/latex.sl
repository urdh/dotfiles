% File:          latex.sl      -*- mode: SLang; mode: fold -*-
%
% Author:        Guido Gonzato, guido.gonzato@univr.it
%                Contributions by G\"unter Milde, 
%                Milde@ife.et.tu-dresden.de;
%                J\"org Sommer, joerg@alea.gnuu.de
%
% Description:   an enhanced latex mode that aims at making the writing
%                of LaTeX documents a breeze.
%                
% Installation:  copy latex.sl to $JED_ROOT/lib (back up the original file
%                latex.sl beforehand), then add these lines to your .jedrc:
%                
%                  add_mode_for_extension ("latex", "tex");
%                  enable_dfa_syntax_for_mode ("LaTeX");
%                
%                You'll also want to create the DFA cache table. Add 
%                "latex.sl" to the list in the file preparse.sl, then 
%                (as root) run the command:
%                
%                  jed -batch -n -l preparse
%                
%                CAVEAT: this file is incompatible with folding mode,
%                due to clashing ^Cf key binding. See the documentation
%                for details.
%                
% Version:       1.4.4
%
% Last updated:	 20 February 2004

% -----

require ("keydefs");

% custom variables

% output profile: "dvi", "ps", "eps", "dvipdf", "pdf"
custom_variable ("LaTeX_Default_Output", "pdf");
custom_variable ("LaTeX_Indent", 2);
custom_variable ("LaTeX_Article_Default_Options", "a4paper,12pt");
custom_variable ("LaTeX_Book_Default_Options",    "twoside,11pt");
custom_variable ("LaTeX_Letter_Default_Options",  "a4paper,12pt");
custom_variable ("LaTeX_Report_Default_Options",  "twoside,12pt");
custom_variable ("LaTeX_Slides_Default_Options",  "a4paper,landscape");
custom_variable ("LaTeX_Default_Language", "english,italian"); % for Babel
custom_variable ("LaTeX_Rerun", "y"); % for xrefs
custom_variable ("LaTeX_Load_Modules", "y");
% DOS/Windows users: make sure helper programs are in the PATH
#ifdef WIN32
custom_variable ("LaTeX_View_Dvi_Cmd", "yap");
custom_variable ("LaTeX_View_Ps_Cmd",  "gsview32");
custom_variable ("LaTeX_View_Pdf_Cmd", "gsview32");
custom_variable ("LaTeX_Print_Cmd",    "gsview32");
custom_variable ("LaTeX_Clearup_Cmd",
                 "del *.out *.aux *.lo? *.to?");
custom_variable ("LaTeX_Modules_Dir", JED_ROOT + "\\lib\\latex\\");
#else
custom_variable ("LaTeX_View_Dvi_Cmd", "xdvi");
custom_variable ("LaTeX_View_Ps_Cmd",  "gv -watch");
custom_variable ("LaTeX_View_Pdf_Cmd", "skim");
custom_variable ("LaTeX_Print_Cmd",    "lpr");
custom_variable ("LaTeX_Clearup_Cmd",
                 "/bin/rm -f *.out *.aux *.lo? *.to?");
custom_variable ("LaTeX_Modules_Dir", JED_ROOT + "/lib/latex/");
#endif
variable custom_variables =
  "LaTeX_Indent,LaTeX_Article_Default_Options," +
  "LaTeX_Book_Default_Options,LaTeX_Letter_Default_Options," +
  "LaTeX_Report_Default_Options,LaTeX_Slides_Default_Options," +
  "LaTeX_Default_Language,LaTeX_Rerun,LaTeX_View_Dvi_Cmd," +
  "LaTeX_View_Ps_Cmd,LaTeX_View_Pdf_Cmd,LaTeX_Print_Cmd";

static variable TRUE         = 1;
static variable FALSE        = 0;
static variable NOTFOUND     = 0;
static variable ERROR        = 255;
static variable WARNING      = -1;
static variable RERUN        = -2;
static variable NO_PUSH_SPOT = FALSE;
static variable PUSH_SPOT    = TRUE;
static variable NO_POP_SPOT  = FALSE;
static variable POP_SPOT     = TRUE;
static variable ITEM_LABEL   = FALSE;
static variable USE_MASTER   = FALSE;
#ifdef UNIX
static variable devnull      = " >/dev/null 2>&1 &";
#else
static variable devnull      = " >NUL";
#endif
static variable LaTeX_Compose_Cmd = "latex" +
  " -interaction=nonstopmode";
static variable LaTeX_Compose_Pdf_Cmd = "pdflatex" +
  " -interaction=nonstopmode";
static variable LaTeX_Dvips_Cmd = "dvips";
static variable LaTeX_Eps_Options = " -i -E"; % every page a file, eps output
static variable LaTeX_Dvipdf_Cmd = "dvipdf";
static variable LaTeX_Bibtex_Cmd = "bibtex";
static variable LaTeX_Makeindex_Cmd = "makeindex";
static variable LaTeX_Buffer;
static variable Math_Mode = FALSE;

% -----

% this function is sto^H^H^H borrowed from the original latex.sl

define tex_complete_symbol ()
{
  variable symbol, completion;
  variable insertbuf = whatbuf(), searchbuf = "*ltx-comp*";
   
  !if (bufferp(searchbuf)) {
    sw2buf(searchbuf);
    insert_file( expand_jedlib_file("ltx-comp.dat") ); bob();
    set_buffer_modified_flag(0);
    sw2buf(insertbuf);
    bury_buffer(searchbuf);
  }
  
  push_spot();
  push_mark();
  bskip_word();
  symbol = bufsubstr();
  setbuf(searchbuf);
   
  !if (bol_fsearch(sprintf("\\%s", symbol))) bob(); % wrap to start
   
  if (bol_fsearch(sprintf("\\%s", symbol))) {
    go_right_1 ();
    go_right(strlen(symbol));
    push_mark_eol();
    completion = bufsubstr();
  }
  
  else {
    setbuf(insertbuf);
    pop_mark_0 ();
    pop_spot();
    error("No completion found");
  }
  
  setbuf(insertbuf);
  goto_spot ();
  push_mark();
  !if (ffind_char (' ')) eol();
  del_region();
  insert(completion);
  pop_spot();
}

% -----

% this is copied from my context-sensitive help system.
% Maybe some day it'll be included in the Jed distribution;
% in that case, I'll remove this duplicated function.

define latex_info_help ()
{
  variable str, topic;
  % get the word under the cursor
  push_spot ();
  define_word ("_0-9A-Za-z\\");
  skip_word ();
  push_mark ();
  bskip_word ();
  topic = bufsubstr ();
  pop_mark_0 ();
  pop_spot ();
  info_mode ();
  info_find_node ("(latex)");
  info_find_node ("Command Index");
  !if (fsearch ("* " + topic))
    error (sprintf ("%s not found!", topic));
  skip_word ();
  () = right (1);
  skip_word ();
  bskip_word (); % beginning of node name
  push_spot ();
  push_mark ();
  eol ();
  () = left (1);
  str = bufsubstr ();
  pop_mark_0 ();
  pop_spot ();
  info_find_node (str);
  () = fsearch (topic);
}

% code to manage compressed files; from compress.sl

static variable
  Compressed_File_Exts = [".gz", ".Z", ".bz2"],
  Compress_File_Pgms = ["gzip %s", "compress %s", "bzip2 %s"],
  Uncompress_File_Pgms = ["gzip -d %s", "uncompress %s", "bzip2 -d %s"],
  compressed = FALSE,
  cmp_method,
  tmpfile;

static define check_is_compressed (file)
{
  variable ext = path_extname (file);
  variable i = where (ext == Compressed_File_Exts);

  if (length (i)) {
    compressed = TRUE;
    return i[0];
  }
  compressed = FALSE;
  return -1;
}

% required stuff and variables

require ("texcom");
% autoload ("latex_toggle_math_mode", "ltx-math");
autoload ("latex_insert_math", "ltx-math");
autoload ("latex_math_mode", "ltx-math");

WRAP_INDENTS = 1; % you really want this

% very simple (but effective!) parsing mechanism of the LaTeX log

static define getline ();

static variable
  LaTeX_Compile_Buffer =   "*LaTeX log*",
  LaTeX_Dvips_Buffer =     "*dvips log*",
  LaTeX_Bibtex_Buffer =    "*bibtex log*",
  LaTeX_Makeindex_Buffer = "*makeindex log*",
  LaTeX_Xdvi_Buffer =      "*xdvi log*",
  LaTeX_Xpdf_Buffer =      "*xpdf log*",
  LaTeX_Gv_Buffer =        "*gv log*",
  LaTeX_Tree_Buffer =      "*LaTeX Tree*",
  latex_file,
  latex_file_dir,
  line_mark,
  errors_parsed = FALSE;

define goto_error_line ()
{
  variable line, tmp = get_word_chars ();
  bol ();
  define_word ("0-9");
  skip_word ();
  push_mark ();
  bskip_word ();
  line = integer (bufsubstr ());
  sw2buf (LaTeX_Buffer);
  call ("one_window");
  goto_line (line);
  define_word (tmp);
}

define find_next_error ()
{
  variable str, found;
  
  if (FALSE == errors_parsed)
    return;
  pop2buf (LaTeX_Compile_Buffer);
  found = fsearch ("! ");
  % TODO: skip warnings
  % some LaTeX error messages don't start in "! "
  if (NOTFOUND == found)
    found = fsearch ("l.");
  () = right (2);
  (str,) = getline ();
  beep ();
  flush (str);
  if (NOTFOUND != found) {
    eol (); % move over
    % fix "file not found"
    found = fsearch ("not found on input");
  }
  goto_error_line ();
}

define latex_parse_errors ()
{
  if (TRUE == compressed) {
    variable cmd;
    (,latex_file_dir,,) = getbuf_info ();
    cmd = sprintf (Compress_File_Pgms [cmp_method],
                   dircat (latex_file_dir, tmpfile));
    run_shell_cmd (cmd);
  }
  pop2buf (LaTeX_Compile_Buffer);
  set_readonly (1);
  bob ();
  errors_parsed = TRUE;
  find_next_error ();
}

% -----

define latex_compile_and_parse (cmd)
{
  variable key, exitcode = TRUE, exit_status;
  LaTeX_Buffer = whatbuf ();
  sw2buf (LaTeX_Compile_Buffer);
  set_readonly (0);
  erase_buffer ();
  exit_status = run_shell_cmd (cmd);
  
  if (FALSE == exit_status) {
    % handle warnings
    bob ();
    if (0 != fsearch ("Font Warning")) {
      flush ("Font Warning.");
      beep ();
      usleep (1000);
      exitcode = WARNING;
    }
    if (0 != fsearch ("Overfull")) {
      flush ("Warning - Overfulls.");
      beep ();
      usleep (1000);
      exitcode = WARNING;
    }
    if (0 != fsearch ("Underfull")) {
      flush ("Warning - Underfulls.");
      beep ();
      usleep (1000);
      exitcode = WARNING;
    }
    % else
    if (0 != fsearch ("Rerun to get")) {
      flush ("Rerun to get cross-references right.");
      beep ();
      usleep (1000);
      exitcode = RERUN;
    }
    % else
    % after "Rerun to get" = no hope
    if (0 != fsearch ("There were undefined")) {
      flush ("There were undefined references.");
      beep ();
      exitcode = WARNING;
    }
    % else
    if ( (WARNING != exitcode) and (RERUN != exitcode)) {
      flush ("Success!");
      exitcode = TRUE;
    }
    sw2buf (LaTeX_Buffer);
    return exitcode;
  }
  else { % latex returned != 0, errors or warnings found
    latex_parse_errors ();
    return ERROR;
  }
} % latex_compile_and_parse ()

% -----

% composing

public define latex_select_output ()
{
  variable default = LaTeX_Default_Output;
  LaTeX_Default_Output =
    read_with_completion ("dvi,ps,eps,pdf,dvipdf",
                          "LaTeX output: dvi,ps,eps,pdf,dvipdf",
                          default, "", 's');
  if (andelse
    {strcmp (LaTeX_Default_Output, "dvi")}
    {strcmp (LaTeX_Default_Output, "ps")}
    {strcmp (LaTeX_Default_Output, "eps")}
    {strcmp (LaTeX_Default_Output, "pdf")}
    {strcmp (LaTeX_Default_Output, "dvipdf")}) 
    {
      beep ();
      flush ("Unknown output format - defaulting to 'dvi'.");
      LaTeX_Default_Output = "dvi";
    }
}

% -----

public define latex_clearup ()
{
  variable bat;
#ifdef UNIX
  run_shell_cmd ("cd " + latex_file_dir + "; " + LaTeX_Clearup_Cmd);
#elifdef WIN32
  delete_file (bat);
  write_string_to_file  ("cd " + latex_file_dir + "\n", bat);
  append_string_to_file (LaTeX_Clearup_Cmd + "\n", bat);
  run_shell_cmd (bat);
#endif
  flush ("Temporary files deleted.");
}

public define latex_compose ()
{
  variable tmp, bat, dvi, cmd, cmd2, status;
  
  !if (USE_MASTER)
    (latex_file, latex_file_dir,,) = getbuf_info ();
  % is this a compressed file?
  cmp_method = check_is_compressed (dircat (latex_file_dir, latex_file));
  if (-1 != cmp_method) {
    tmpfile = path_sans_extname (latex_file);
    cmd = sprintf (Uncompress_File_Pgms [cmp_method],
                   dircat (latex_file_dir, latex_file));
    flush ("Uncompressing buffer...");
    run_shell_cmd (cmd);
    latex_file = path_sans_extname (latex_file);
  }
  dvi = path_sans_extname (dircat (latex_file_dir, latex_file)) + ".dvi";
  bat = path_sans_extname (dircat (latex_file_dir, latex_file)) + ".bat";
  
  switch (LaTeX_Default_Output)
    { case "dvi":
      cmd = LaTeX_Compose_Cmd;
      cmd2 = "";
    }
    { case "ps":
      cmd = LaTeX_Compose_Cmd;
      cmd2 = LaTeX_Dvips_Cmd;
    }
    { case "eps":
      cmd = LaTeX_Compose_Cmd;
      cmd2 = LaTeX_Dvips_Cmd + LaTeX_Eps_Options;
    }
    { case "dvipdf":
      cmd = LaTeX_Compose_Cmd;
      cmd2 = LaTeX_Dvipdf_Cmd;
    }
    { case "pdf": 
      cmd = LaTeX_Compose_Pdf_Cmd;
      cmd2 = "";
    }

  % run latex or whatever
  save_buffers ();
  flush ("Composing... (output profile: " + LaTeX_Default_Output + ")");
  % cd to the right directory
  tmp = "cd " + latex_file_dir + "; " + cmd + " " +
    dircat (latex_file_dir, latex_file);
#ifdef UNIX
  !if (strcmp ("y", LaTeX_Rerun)) {
    do {
      status = latex_compile_and_parse (tmp);
      if (ERROR != status)
        flush ("Rerunning...");
    } while (RERUN == status);
    if (ERROR != status) {
      flush ("All runs done.");
      errors_parsed = FALSE;
    }
  }
  else
    status = latex_compile_and_parse (tmp);
#elifdef WIN32
  % build a .bat file, then run it
  if (TRUE == file_status (bat))
    delete_file (bat);
  write_string_to_file ("cd " + latex_file_dir + "\n", bat);
  append_string_to_file (cmd + " " + 
			 dircat (latex_file_dir, latex_file) + "\n", bat);
  !if (strcmp ("y", LaTeX_Rerun)) {
    do {
      status = latex_compile_and_parse (bat);
      if (ERROR != status)
        flush ("Rerunning...");
    } while (RERUN == status);
    if (ERROR != status) {
      flush ("All runs done.");
      errors_parsed = FALSE;
    }
  }
  else
    status = latex_compile_and_parse (bat);
  % the .bat file will be deleted later
#endif
  
  if (ERROR == status)
    return;
  
  % if cmd2 isn't void, run dvips or whatever
  if (strlen(cmd2)) {
    flush ("Running: " + cmd2 + " " + dircat (latex_file_dir, dvi));
    sw2buf (LaTeX_Dvips_Buffer);
    set_readonly (0);
    erase_buffer ();
#ifdef UNIX
    % cd to the source directory, so that included files can be found
    if (0 != run_shell_cmd ("cd " + latex_file_dir + "; " +
                            cmd2 + " " + dvi + " 2>&1"))
#elifdef WIN32
    delete_file (bat);
    write_string_to_file  ("cd " + latex_file_dir + "\n", bat);
    append_string_to_file (cmd2 + " " + dvi + "\n", bat);
    if (0 != run_shell_cmd (bat))
#endif
      error ("Could not run " + cmd2 + " " + 
             dircat (latex_file_dir, latex_file));
  } % if (strlen(cmd2))
  if (TRUE == compressed) {
    cmd = sprintf (Compress_File_Pgms [cmp_method],
                   dircat (latex_file_dir, tmpfile));
    run_shell_cmd (cmd);
  }
%  if (ERROR != status)
  flush ("Done.");
  errors_parsed = FALSE;
  sw2buf (LaTeX_Buffer);
}

% customising, viewing, printing, etc.

% -----

public define latex_customise ()
{
  variable tmp, var, value;
  var = read_with_completion (custom_variables,
                              "Variable to change (press TAB to list):",
                              "", "", 's');
  tmp = sprintf ("New value (now \"%s\"):", string (eval (var)));
  value = (read_mini (tmp, "", ""));
  !if (strcmp (var, "LaTeX_Indent"))
    tmp = string (value);
  else
    tmp = "\"" + string (value) + "\"";
  eval (var + "=" + tmp);
}

define latex_master_file ()
{
  variable mf =
    read_mini ("Set this buffer as master file (y/n)?",
                           "n", "");
  if ( (mf [0] == 'y') or (mf [0] == 'Y') ) {
    USE_MASTER = TRUE;
    (latex_file, latex_file_dir,,) = getbuf_info ();
  }
  else
    USE_MASTER = FALSE;
}

public define latex_view ()
{
  variable i, dvi, ps, pdf;
  !if (USE_MASTER)
    (latex_file, latex_file_dir,,) = getbuf_info ();
  i = check_is_compressed (dircat (latex_file_dir, latex_file));
  if (-1 != i) % remove the extension
    latex_file = path_sans_extname (latex_file);
  dvi = path_sans_extname (dircat (latex_file_dir, latex_file)) + ".dvi";
  ps  = path_sans_extname (dircat (latex_file_dir, latex_file)) + ".ps";
  pdf = path_sans_extname (dircat (latex_file_dir, latex_file)) + ".pdf";
  
  switch (LaTeX_Default_Output)
    
   { case "dvi":
     if (1 != file_status (dvi)) {
       beep ();
       flush ("No file " + dvi + "! Building it...");
       usleep (2000);
       LaTeX_Default_Output = "dvi";
       latex_compose ();
     }
     flush ("Running: " + LaTeX_View_Dvi_Cmd +
            " " + dvi + " (building fonts...)");
     sw2buf (LaTeX_Xdvi_Buffer);
     set_readonly (0);
     erase_buffer ();
#ifdef UNIX
     if (0 != run_shell_cmd ("cd " + latex_file_dir + "; " + 
                         LaTeX_View_Dvi_Cmd + " " + dvi + devnull))
#elifdef WIN32
     if (0 != run_shell_cmd (LaTeX_View_Dvi_Cmd + " " + dvi))
#endif
       error ("Could not run " + LaTeX_View_Dvi_Cmd + " " + dvi);
     sw2buf (LaTeX_Buffer);
   }
     
   { case "ps":
     if (1 != file_status (dvi)) {
       beep ();
       flush ("No file " + dvi + "! Building it...");
       usleep (2000);
       LaTeX_Default_Output = "dvi";
       latex_compose ();
     }
     flush ("Running: " + LaTeX_View_Ps_Cmd + " " + ps);
     sw2buf (LaTeX_Gv_Buffer);
     set_readonly (0);
     erase_buffer ();
     if (0 != run_shell_cmd (LaTeX_View_Ps_Cmd + " " + ps + devnull))
       error ("Could not run " + LaTeX_View_Ps_Cmd + " " + ps);
     sw2buf (LaTeX_Buffer);
   }

   { case "dvipdf" or case "pdf":
     if (1 != file_status (pdf)) {
       beep ();
       flush ("No file " + pdf + "! Building it...");
       usleep (2000);
       LaTeX_Default_Output = "pdf";
       latex_compose ();
     }
     flush ("Running: " + LaTeX_View_Pdf_Cmd +  " " + pdf);
     sw2buf (LaTeX_Xpdf_Buffer);
     set_readonly (0);
     erase_buffer ();
     if (0 != run_shell_cmd (LaTeX_View_Pdf_Cmd +  " " + pdf + devnull))
       error ("Could not run " + LaTeX_View_Pdf_Cmd + " " + pdf);
     sw2buf (LaTeX_Buffer);
   }
}

% -----

public define latex_psprint ()
{
  variable cmd, ps;
  !if (USE_MASTER)
    (latex_file, latex_file_dir,,) = getbuf_info ();
  % is this a compressed file?
  % cmp_method = check_is_compressed (dircat (latex_file_dir, latex_file));
  if (TRUE == compressed)
    latex_file = path_sans_extname (latex_file);
  ps = path_sans_extname (dircat (latex_file_dir, latex_file)) + ".ps";
  if (1 != file_status (ps))
    error ("No file " + ps + " to print!");
  cmd = LaTeX_Print_Cmd + " " + ps;
  cmd = read_mini ("Print command:", "", cmd);
  () = run_shell_cmd (cmd + devnull);
  flush ("Done (printing).");
}

% -----

public define latex_bibtex ()
{
  variable bib;
  !if (USE_MASTER)
    (latex_file, latex_file_dir,,) = getbuf_info ();
  if (TRUE == compressed)
    latex_file = path_sans_extname (latex_file);
  bib = path_sans_extname (dircat (latex_file_dir, latex_file));
  flush ("BibTeX'ing " + bib);
  sw2buf (LaTeX_Bibtex_Buffer);
  if (0 != run_shell_cmd (LaTeX_Bibtex_Cmd + " " + bib))
    error ("Error bibTeX'ing " + bib + "!");
  sw2buf (LaTeX_Buffer);
  flush ("Done.");
}

% -----

public define latex_makeindex ()
{
  variable idx;
  !if (USE_MASTER)
    (latex_file, latex_file_dir,,) = getbuf_info ();
  if (TRUE == compressed)
    latex_file = path_sans_extname (latex_file);
  idx = path_sans_extname (dircat (latex_file_dir, latex_file)) + ".idx";
  flush ("Processing the index...");
  sw2buf (LaTeX_Makeindex_Buffer);
  if (0 != run_shell_cmd (LaTeX_Makeindex_Cmd + " " + idx))
    error ("Error processing " + idx + "!");
  sw2buf (LaTeX_Buffer);
  flush ("Done.");
}

% -----

define latex_mode_help ()
{
  variable file = expand_jedlib_file ("latex.hlp");
  () = read_file (file);
  pop2buf (whatbuf ());
  most_mode ();
  call ("one_window");
  set_readonly (1);
}

% some utility functions

% this function is used to make indented environments
static define latex_insert_pair_around_lines (left, right)
{
  variable col;
  check_region (1); % spot pushed
  narrow ();
  bob ();
  col = what_column () - 1;
  insert (left);
  insert_spaces (col);
  do {
    insert_spaces (LaTeX_Indent);
    bol ();
  } while (down (1));
  eob ();
  insert ("\n");
  insert_spaces (col);
  insert (right);
  widen ();
  pop_spot ();
}

static define latex_insert_pair_around_region (left, right)
{
  exchange_point_and_mark ();
  insert (left);
  exchange_point_and_mark ();
  insert (right);
  pop_spot ();
  pop_mark_0 ();
}

define latex_insert_tags (tag1, tag2, do_push_spot, do_pop_spot)
{
  variable
    chr = what_char (),
    tmp = get_word_chars ();
  if ('\\' == chr)
    chr = '\0'; % avoid the \ problem
  % if the current position is within a word, then select it
  if ( (0 == markp ()) and % no region defined
       (0 == string_match (" \t\n", char (chr), 1)) ) {
    % ok, the cursor isn't on a space
    () = right (1);
    define_word ("_0-9A-Za-z\\");
    bskip_word ();
    push_mark ();
    skip_word ();
    define_word (tmp);
  }
  % if a region is defined, insert the tags around it
  if (markp () ) {
    check_region (0);
    latex_insert_pair_around_region (tag1, tag2);
    return;
  }
  % the remaining cases
  insert (tag1);
  if (do_push_spot)
    push_spot ();
  insert (tag2);
  if (do_pop_spot)
    pop_spot ();
}

% -----

define latex_begin_end (param1, param2, do_push_spot, do_pop_spot)
{
  variable col = what_column () - 1;
  variable env1, env2;

  env1 = sprintf ("\\begin{%s}%s\n", param1, param2);
  env2 = sprintf ("\\end{%s}", param1);
  if (markp () ) {
    check_region (0);
    latex_insert_pair_around_lines (env1, env2);
    return;
  }
  insert (env1);
  insert_spaces (col + LaTeX_Indent);
  if (do_push_spot)
    push_spot ();
  insert ("\n");
  insert_spaces (col);
  insert (env2);
  if (do_pop_spot)
    pop_spot ();
}

% -----

define latex_cmd (cmd, do_push_spot)
{
  latex_insert_tags (sprintf ("\\%s{", cmd), "}",
                     do_push_spot, do_push_spot);
}

define latex_loglike (cmd)
{
  latex_insert_tags (sprintf ("\\%s(", cmd), ")",
                     PUSH_SPOT, POP_SPOT);
}

% -----

define latex_cmd_with_arg (cmd, arg)
{
  latex_insert_tags (sprintf ("\\%s{", cmd), "}", PUSH_SPOT, NO_POP_SPOT);
  insert (sprintf ("{%s}", arg));
  pop_spot ();
}

% -----

static variable benv_line, eenv_line; % needed later

define latex_is_within_environment ()
{
  variable eline, benv, eenv;
  push_spot ();
  if (0 == bsearch ("\\begin{"))
    return FALSE;
  () = right (7); % skip \begin{
  push_mark ();
  skip_chars ("A-Za-z0-9");
  benv = bufsubstr ();
  benv_line = what_line ();
  pop_mark_0 ();
  if (0 == fsearch ("\\end{"))
    return FALSE;
  eline = what_line;
  () = right (5);
  push_mark ();
  skip_chars ("A-Za-z0-9");
  eenv = bufsubstr ();
  eenv_line = what_line ();
  pop_mark_0 ();
  pop_spot ();
  if (eline <= what_line)
    return FALSE;
  if (strcmp (benv, eenv))
    return FALSE;
  else
    return TRUE;
}

% -----

static variable std_env =
  "abstract,array,center,description,displaymath," +
  "enumerate,eqnarray,equation,figure,flushleft," +
  "flushright,itemize,list,minipage,picture," +
  "quotation,quote,tabbing,table,tabular," +
  "thebibliography,theorem,titlepage,verbatim,verse";

define latex_rename_environment ()
{
  variable newenv;
  if (FALSE == latex_is_within_environment ())
    error ("Not within an environment!");
  newenv =
    read_with_completion (std_env, "Which environment (TAB to list)?",
                          "", "", 's');
  push_spot ();
  () = bsearch ("\\begin{");
  () = right (7);
  delete_word ();
  insert (newenv);
  () = fsearch ("\\end{");
  () = right (5);
  delete_word ();
  insert (newenv);
  pop_spot ();
}

% -----

static variable std_fonts =
    "textrm,textit,emph,textmd,textbf,textup,textsl," +
    "textsf,textsc,texttt,verb,textnormal,underline";

static variable std_sizes =
  "tiny,scriptsize,footnotesize,small," +
  "normalsize,large,Large,LARGE,huge,Huge";

define latex_modify_font (oldfont, newfont)
{
  variable chr = what_char (), font, tmp = get_word_chars ();
  
  push_spot ();
  if (0 == bsearch ("\\")) {
    beep ();
    flush ("The cursor is not within curly braces.");
  }
  () = right (1);
  define_word ("A-Za-z");
  push_mark ();
  skip_word ();
  font = bufsubstr ();
  pop_mark_0 ();
  
  if (is_substr (oldfont, font)) {
    % delete the font definition
    if (0 == strlen (newfont)) {
      define_word ("\\A-Za-z{");
      bskip_word (); % back to \
      define_word ("\\A-Za-z");
      delete_word ();
      call ("delete_char_cmd"); % delete '}' then its match
      push_spot ();
      if (1 != find_matching_delimiter ('{')) {
        pop_spot ();
        pop_spot ();
        error ("Warning - there were unbalanced braces!");
      }
      call ("delete_char_cmd"); % delete '{'
      pop_spot ();
    }
    else { % rename the font - no warnings for unbalanced {}
      define_word ("A-Za-z");
      bskip_word ();
      delete_word ();
      insert (newfont);
    }
  }
  else {
    beep ();
    flush ("Could not find a valid font definition.");
  }
  define_word (tmp);
  pop_spot ();
}

define latex_rename_font ()
{
  
  variable newfont =
    read_with_completion (std_fonts, "Which font (TAB to list)?",
                          "", "", 's');
  latex_modify_font (std_fonts, newfont);
}

define latex_insert_font ()
{
  variable tmp =
    read_with_completion (std_fonts, "Which font (TAB to list)?",
                          "", "", 's');
  !if (strcmp (tmp, "verb"))
    latex_insert_tags ("\\verb|", "|", TRUE, TRUE);
  else
    latex_cmd (tmp, TRUE);
}

define latex_resize_font ()
{
  variable newsize =
    read_with_completion (std_sizes, "Which size (TAB to list)?",
                          "", "", 's');
  latex_modify_font (std_sizes, newsize);
}

% -----

define latex_insert (cmd)
{ vinsert ("\\%s ", cmd); }

define latex_insert_nospace (cmd)
{ vinsert ("\\%s", cmd); }

define latex_insert_newline (cmd)
{ vinsert ("\\%s\n", cmd); }

define latex_open_env ()
{
  variable col = what_column (), env = 
    read_with_completion (std_env, "Which environment (TAB to list)?",
                          "", "", 's');
  vinsert ("\\begin{%s}\n", env);
  insert_spaces (col + LaTeX_Indent - 1);
}

% this is J\"org's
define latex_close_env ()
{
  push_spot ();
  
  ERROR_BLOCK {
    pop_spot ();
  }
  
  % Idea: increase for every \end we found and decrease for ever \begin
  %       we found. If we have 0, the founded \begin is for our \end.
  variable ends = 1;
  forever {
    push_mark ();
    !if (bsearch("\\begin{")) {
      pop_mark (1);
      error ("No \\begin{} found");
    }
    --ends;
    push_spot ();
    
    variable tmp = bufsubstr(), pos = 0;
    % see if there are any \ends between our \end and the found \begin
    do {
      variable ret = is_substr(tmp[[pos:]], "\\end{");
      pos += ret;
      if (ret > 0)
        ++ends;
    } while (ret > 0);
    
    pop_spot();
    if (ends == 0) {
      () = right (7);
      push_mark ();
      if (ffind_char ('}') == 0) {
        pop_mark (1);
        error("Malformed \\begin{}");
      }
      
      variable env = bufsubstr();
      pop_spot ();
      if (what_column () > LaTeX_Indent) 
        {
          () = left (LaTeX_Indent);
          deln (LaTeX_Indent);
        }
      insert ("\\end{" + env + "}");
      return;
    }
  }
}

% -----

% Templates

define latex_article ()
{
  vinsert ("\\documentclass[%s]{article}\n\n",
	   LaTeX_Article_Default_Options);
  insert ("\\begin{document}\n\n");
  insert ("\\title{");
  push_spot ();
  insert ("}\n\n");
  insert ("\\author{}\n\n");
  insert ("\\date{}\n\n");
  insert ("\\thanks{}\n\n");
  insert ("\\maketitle\n\n");
  insert ("\\begin{abstract}\n");
  insert ("\\end{abstract}\n\n");
  insert ("\\tableofcontents\n");
  insert ("\\listoftables\n");
  insert ("\\listoffigures\n\n");
  insert ("\\section{}\n\n");
  insert ("\\end{document}");
  pop_spot ();
}

define latex_book ()
{
  vinsert ("\\documentclass[%s]{book}\n\n",
	   LaTeX_Book_Default_Options);
  insert ("\\begin{document}\n\n");
  insert ("\\frontmatter\n");
  insert ("\\title{");
  push_spot ();
  insert ("}\n\n");
  insert ("\\author{}\n\n");
  insert ("\\date{}\n\n");
  insert ("\\maketitle\n\n");
  insert ("\\tableofcontents\n");
  insert ("\\listoftables\n");
  insert ("\\listoffigures\n\n");
  insert ("\\mainmatter\n\n");
  insert ("\\part{}\n\n");
  insert ("\\chapter{}\n\n");
  insert ("\\section{}\n\n");
  insert ("\\end{document}");
  pop_spot ();
}

define latex_letter ()
{
  vinsert ("\\documentclass[%s]{letter}\n\n",
	   LaTeX_Letter_Default_Options);
  insert ("\\begin{document}\n\n");
  insert ("\\address\n{\n% return address\n}\n");
  insert ("\\signature{");
  push_spot ();
  insert ("}\n");
  insert ("\\begin{letter}\n{\n% recipient's address\n}\n");
  insert ("\\opening{}\n\n");
  insert ("\\closing{}\n");
  insert ("\\ps{}\n");
  insert ("\\cc{}\n");
  insert ("\\encl{}\n");
  insert ("\\end{letter}\n");
  insert ("\\end{document}\n");
  pop_spot ();
}

define latex_report ()
{
  vinsert ("\\documentclass[%s]{report}\n\n",
	   LaTeX_Report_Default_Options);
  insert ("\\begin{document}\n\n");
  insert ("\\title{}\n");
  push_spot ();
  insert ("\\author{}\n\n");
  insert ("\\date{}\n\n");
  insert ("\\maketitle\n\n");
  insert ("\\begin{abstract}\n");
  insert ("\\end{abstract}\n\n");
  insert ("\\tableofcontents\n");
  insert ("\\listoftables\n");
  insert ("\\listoffigures\n\n");
  insert ("\\part{}\n\n");
  insert ("\\chapter{}\n\n");
  insert ("\\section{}\n\n");
  insert ("\\end{document}");
  pop_spot ();
}

define latex_slides ()
{
  vinsert ("\\documentclass[%s]{slides}\n\n",
	   LaTeX_Slides_Default_Options);
  insert ("\\begin{document}\n\n");
  insert ("\\title{");
  push_spot ();
  insert ("}\n\\author{}\n");
  insert ("\\date{}\n\n");
  insert ("\\maketitle\n\n");
  insert ("\\end{document}");
  pop_spot ();
}

% Environments

define latex_insert_package (msg)
{
  variable spot, tmp;
  % look for the appropriate package
  push_spot ();
  bob ();
  spot = re_fsearch (sprintf ("\\usepackage.*{%s}", msg));
  if (0 == spot) { % not found
    () = fsearch ("\\documentclass");
    eol ();
    vinsert ("\n\\usepackage{%s}", msg);
    flush (sprintf ("Note: \\usepackage{%s} inserted.", msg));
  }
  pop_spot ();
}

define latex_env_item ()
{
  variable tmp;

  if (TRUE == ITEM_LABEL)
    tmp = "item []";
  else
    tmp = "item";

  latex_insert (tmp);
}

define latex_env_itemize (what)
{
  variable col = what_column () - 1;
  !if (strcmp (what, "itemize"))
    ITEM_LABEL = FALSE;
  else
    ITEM_LABEL = TRUE;
  insert (sprintf ("\\begin{%s}\n", what));
  insert_spaces (col + LaTeX_Indent);
  latex_env_item ();
  push_spot ();
  insert ("\n");
  insert_spaces (col);
  insert (sprintf ("\\end{%s}\n", what));
  pop_spot ();
}

define latex_env_description ()
{
  latex_begin_end ("description", "", PUSH_SPOT, POP_SPOT);
  ITEM_LABEL = TRUE;
}

define latex_env_figure ()
{
  % if a prefix argument (e.g. ESC 1) was entered,
  % then insert the extended form
  variable
    col = what_column () - 1,
    arg = prefix_argument (-1);
  insert ("\\begin{figure}[htbp]\n");
  insert_spaces (col + LaTeX_Indent);
  insert ("\\centering\n");
  insert_spaces (col + LaTeX_Indent);
  push_spot ();
  if (arg == -1)
    insert ("\\includegraphics[scale=|width=|height=]{file.eps}\n");
  else
    insert ("\\includegraphics{}\n");
  insert_spaces (col + LaTeX_Indent);
  insert ("\\caption{}\n");
  insert_spaces (col + LaTeX_Indent);
  insert ("\\label{fig:}\n");
  insert_spaces (col);
  insert ("\\end{figure}");
  latex_insert_package ("graphicx");
  pop_spot ();
}

define latex_env_picture ()
{ latex_begin_end ("picture", "(width,height)(x offset,y offset)",
		     PUSH_SPOT, POP_SPOT);
}

define latex_env_custom ()
{
  variable custom = read_mini ("What environment?", Null_String, "");
  latex_begin_end (custom, "", PUSH_SPOT, POP_SPOT);
}

% tables

static variable table_columns = 3;

define latex_table_row (do_push_spot)
{
  variable i, col;

  col = what_column () - 1;
  if (do_push_spot)
    push_spot ();
  loop (table_columns - 1) {
    insert (" &");
  }
  insert (" \\\\");
  if (do_push_spot)
    pop_spot ();
}

define is_integer (str)
{
  if (Integer_Type == _slang_guess_type (str))
    return (integer (str));
  else
    return -1;
}

define latex_table_template (flag_tabular)
{
  variable col = what_column () - 1;
  variable i, align, table_col_str, ok;

  do {
    table_col_str = read_mini ("Columns?", Null_String, "4");
    table_columns = is_integer (table_col_str);
    if (-1 == table_columns) {
      ok = FALSE;
      beep ();
      message ("Wrong value! ");
    }
    else
      ok = TRUE;
  } while (FALSE == ok);

  align = "{|";
  loop (table_columns)
    align = align + "l|";
  align = align + "}";

  !if (flag_tabular) {
    insert ("\\begin{table}[htbp]\n");
    insert_spaces (col + LaTeX_Indent);
  }
  insert ("\\centering\n");
  insert_spaces (col + LaTeX_Indent);
  vinsert ("\\begin{tabular}%s\n", align);
  insert_spaces (col + LaTeX_Indent);
  insert ("\\hline\n");
  insert_spaces (col + LaTeX_Indent);
  push_spot ();
  latex_table_row (NO_PUSH_SPOT);
  insert ("\n");
  insert_spaces (col + LaTeX_Indent);
  insert ("\\hline\n");
  if (flag_tabular)
    insert ("\\end{tabular}\n");
  else {
    insert_spaces (col + LaTeX_Indent);
    insert ("\\end{tabular}\n");
    insert_spaces (col + LaTeX_Indent);
    latex_cmd ("caption", NO_PUSH_SPOT);
    insert ("\n");
    insert_spaces (col + LaTeX_Indent);
    insert ("\\label{tab:}\n");
    insert_spaces (col);
    insert ("\\end{table}");
  }
  pop_spot ();
}

define latex_complete_environment ()
{
  variable tmp =
    read_with_completion (std_env, "Which environment (TAB to list)?",
                          "", "", 's');
  switch (tmp)
  { case "description": latex_env_description (); }
  { case "figure": latex_env_figure (); }
  { case "minipage": latex_begin_end ("minipage", 
                                      "[c]{\\linewidth}",
                                      TRUE, TRUE); 
  }
  { case "tabular": latex_table_template (TRUE); }
  { case "table": latex_table_template (TRUE); }
  { case "thebibliography": latex_begin_end ("thebibliography",
                                             "{99}",
                                             TRUE, TRUE); 
  }
  { latex_begin_end (tmp, "", TRUE, TRUE); }
}

% -----

% Paragraph

define latex_par_frame ()
{
  variable str;
  str = "\\begin{boxedminipage}[c]{\\linewidth}\n";
  latex_insert_tags (str, "\\end{boxedminipage}\n", PUSH_SPOT, POP_SPOT);
  latex_insert_package ("boxedminipage");
}

define latex_par_bgcolour ()
{
  variable str;
  variable colour = read_mini ("What colour?", Null_String, "");
  str = sprintf ("\\colorbox{%s}{", colour);
  latex_insert_tags (str, "}", PUSH_SPOT, POP_SPOT);
  latex_insert_package ("color");
}

define latex_par_fgcolour ()
{
  variable str;
  variable colour = read_mini ("What colour?", Null_String, "");
  str = sprintf ("\\textcolor{%s}{", colour);
  latex_insert_tags (str, "}", PUSH_SPOT, POP_SPOT);
  latex_insert_package ("color");
}

define latex_includegraphics ()
{
  % if a prefix argument (e.g. ESC 1) was given, then insert
  % the extended form
  variable arg = prefix_argument (-1);
  if (arg == -1) % no prefix argument
    latex_cmd ("includegraphics", PUSH_SPOT);
  else
    latex_cmd ("includegraphics[scale=|width=|height=]", PUSH_SPOT);
  latex_insert_package ("graphicx");
}

define latex_linebreak ()
{
  insert ("\\\\*[");
  push_spot ();
  insert ("]");
  pop_spot ();
}

% misc

define latex_insert_braces ()
{
  insert ("{}");
  go_left_1 ();
}

define latex_insert_dollar ()
{
  insert ("$$");
  go_left_1 ();
}

define latex_greek_letter ()
{
  variable tmp = expand_keystring (_Reserved_Key_Prefix);
  flush (sprintf ("Press %sm + letter (e.g. %sma = \\alpha)", 
		  tmp, tmp));
}

define latex_arrow ()
{
  % right arrows
  if (LAST_CHAR == '>') {
    % 3 chars
    if (blooking_at ("|--")) {
      () = left (3);
      deln (3);
      insert ("{\\longmapsto}");
      return;
    }
    % 2 chars
    if (blooking_at ("--")) {
      go_left (2);
      deln (2);
      insert ("{\\longrightarrow}");
      return;
    }
    if (blooking_at ("==")) {
      go_left (2);
      deln (2);
      insert ("{\\Longrightarrow}");
      return;
    }
    if (blooking_at ("|-")) {
      () = left (2);
      deln (2);
      insert ("{\\mapsto}");
      return;
    }
    % left-right
    if (blooking_at ("< -")) {
      go_left (3);
      deln (3);
      insert ("{\\leftrightarrow}");
      return;
    }
    if (blooking_at ("< =")) {
      go_left (3);
      deln (3);
      insert ("{\\Leftrightarrow}");
      return;
    }
    if (blooking_at ("-")) {
      go_left (1);
      deln (1);
      insert ("{\\rightarrow}");
      return;
    }
    if (blooking_at ("=")) {
      go_left (1);
      deln (1);
      insert ("{\\Rightarrow}");
      return;
    }
    insert (">");
  }
  % simple left arrows
  if (LAST_CHAR == '-') {
    if (blooking_at ("< -")) {
      go_left (3);
      deln (3);
      insert ("{\\longleftarrow}");
      return;
    }
    if (blooking_at ("<")) {
      go_left (1);
      deln (1);
      insert ("{\\leftarrow}");
      return;
    }
    insert ("-");
  }
  % double left arrows
  if (LAST_CHAR == '=') {
    if (blooking_at ("< =")) {
      go_left (3);
      deln (3);
      insert ("{\\Longleftarrow}");
      return;
    }
    if (blooking_at ("<")) {
      go_left (1);
      deln (1);
      insert ("{\\Leftarrow}");
      return;
    }
    insert ("=");
  }    
}

define toggle_math_mode ()
{
  $1 = "LaTeX-Mode";
  if (FALSE == Math_Mode) {
    Math_Mode = TRUE;
    definekey ("latex_insert_math", "`", $1);
    flush ("Math mode enabled.");
  }
  else {
    Math_Mode = FALSE;
    undefinekey ("`", $1);
    definekey ("quoted_insert", "`", $1);
     flush ("Math mode disabled.");
  }
}

define latex_url ()
{
  latex_insert_tags ("\\url{", "}", PUSH_SPOT, POP_SPOT);
  latex_insert_package ("url");
}

define latex_indent_line ()
{
  variable arg = prefix_argument (-1);
  push_spot ();
  bol ();
  if (arg == -1) % no prefix argument
    insert_spaces (LaTeX_Indent);
  else
    loop (LaTeX_Indent)
      if (' ' == what_char ())
        call ("delete_char_cmd");
  pop_spot ();
}

define latex_indent_environment ()
{
  if (FALSE == latex_is_within_environment ())
    error ("Not within an environment!");
  push_spot ();
  goto_line (benv_line);
  down (1);
  while (what_line () < eenv_line) {
    latex_indent_line ();
    () = down (1);
  }
  pop_spot ();
}

% let's finish

% this function is for the Template/Packages menu

define latex_babel ()
{
  variable tmp = sprintf ("\\usepackage[%s]{babel}\n", 
        LaTeX_Default_Language); 
  insert (tmp);
}

define latex_index_word ()
{
  variable tmp;
  if ( (0 == markp ()) and % no region defined
       (0 == string_match (" \t\n", char (what_char()), 1)) ) {
    % ok, the cursor isn't on a space
    () = right (1);
    bskip_word ();
    push_mark ();
    skip_word ();
    tmp = bufsubstr ();
    pop_mark_0 ();
  }
  else {
    beep ();
    flush ("The cursor is not on a word.");
    return;
  }
  bskip_word ();
  insert ("\\index{" + tmp + "}");
}

define latex_makeidx ()
{
  push_spot ();
  bob ();
  if (0 == fsearch ("\\documentclass")) {
    error ("No \\documentclass definition yet.");
    return;
  }
  () = down (1);
  insert ("\\usepackage{makeidx}\n");
  if (0 == fsearch ("\\begin{document}")) {
    error ("No \\begin{document} definition yet.");
    return;
  }
  insert ("\\makeindex\n\n");
  eob ();
  if (0 == bsearch ("\\end{document}")) {
    error ("No \\end{document} definition yet.");
    return;
  }
  insert ("\\printindex\n\n");
  pop_spot ();
}

define latex_index_subentry ()
{
  latex_cmd ("index", TRUE);
  if ('}' != what_char ())
    () = left (1);
  insert ("!");
}

define latex_index_beginrange ()
{
  latex_cmd ("index", TRUE);
  if ('}' != what_char ())
    () = left (1);
  insert ("|(");
}

define latex_index_endrange ()
{
  latex_cmd ("index", TRUE);
  if ('}' != what_char ())
    () = left (1);
  insert ("|)");
}

define latex_index_sortorder ()
{
  latex_cmd ("index", TRUE);
  if ('}' != what_char ())
    () = left (1);
  insert ("@");
}

define latex_index_specialformat ()
{
  latex_cmd ("index", TRUE);
  if ('}' != what_char ())
    () = left (1);
  insert ("|");
}

% -----

% Document structure

static define getline ()
{
  variable line, numline;
  push_mark ();
  eol ();
  line = bufsubstr ();
  pop_mark_0 ();
  numline = what_line ();
  return (line, numline);
}


% this one creates the buffer that contains the
% document tree (structure)
define latex_build_doc_tree ()
{
  variable i, found, line, numline,
    num_sections = 0,
    level = -1,
    case_search = CASE_SEARCH;
  variable sections = String_Type [8];
  
  LaTeX_Buffer = whatbuf ();
  sw2buf (LaTeX_Tree_Buffer);
  set_readonly (0);
  erase_buffer ();
  insert ("Document structure ('q' to quit, <Return> or double click to select):\n\n");
  sw2buf (LaTeX_Buffer);
  push_spot ();
  bob ();
  
  % let's start with \begin{document}
  if (0 == fsearch ("\\begin{document}"))
    error ("No \\begin{document} found!");
  % get the line
  (line, numline) = getline ();
  sw2buf (LaTeX_Tree_Buffer);
  % TODO: find a better solution
  vinsert ("%6d%s", numline, "   ");
  insert (line + "\n");
  
  sections [0] = "\\part{";
  sections [1] = "\\chapter{";
  sections [2] = "\\section{";
  sections [3] = "\\subsection{";
  sections [4] = "\\subsubsection{";
  sections [5] = "\\paragraph{";
  sections [6] = "\\subparagraph{";
  sections [7] = "\\label{";
  
  % now, let's search for sectioning commands.
  % The algorithm is horrible, but it works and is probably more
  % efficient than the "right" one.
  
  CASE_SEARCH = 1;
  for (i = 0; i < 8; i++) {
    sw2buf (LaTeX_Buffer);
    bob ();
    do {
    
      found = FALSE;
      sw2buf (LaTeX_Buffer);
      if (0 != fsearch (sections [i])) {
        if (-1 == level)
          level = i; % first level of indentation
        if (0 == bfind ("%")) { % not in a comment
          (line, numline) = getline ();
          num_sections++;
          sw2buf (LaTeX_Tree_Buffer);
          vinsert ("%6d%s", numline, "   ");
          insert_spaces ((i - level + 1) * LaTeX_Indent);
          insert (line + "\n");
        }
        found = TRUE;
        () = down (1);
      }
    } while (TRUE == found);
  }
  CASE_SEARCH = case_search;
  
  % ok, now the tree is done; let's sort it
  sw2buf (LaTeX_Tree_Buffer);
  bob ();
  () = down (2);
  push_mark ();
  () = down (num_sections);
  eol ();
  sort ();
  pop_mark_0 ();
  set_readonly (1);
  latex_mode ();
  setbuf_info (getbuf_info () & 0xFE); % not modified
  sw2buf (LaTeX_Buffer);
  pop_spot ();
}

static define update_tree_hook ()
{
  line_mark = create_line_mark (color_number ("menu_selection"));
}

define latex_browse_tree ()
{
  variable tmode = "tree";
  !if (keymap_p (tmode))
    make_keymap (tmode);
  definekey ("delbuf (whatbuf())", "q", tmode);
  definekey ("goto_error_line", "\r", tmode);
  latex_build_doc_tree ();
  sw2buf (LaTeX_Tree_Buffer);
  set_buffer_hook ("update_hook", &update_tree_hook);
  set_readonly (1);
  use_keymap (tmode);
  set_mode (tmode, 0);
  set_buffer_hook ("mouse_2click", "goto_error_line");
}

% The Menu

% -----

% copied from popups.sl
static define add_files_popup_with_callback (parent, popup, dir, pattern)
{
  variable files, i;

  if (strcmp ("y", LaTeX_Load_Modules))
    return;
  
  files = listdir (dir);
  if (files == NULL)
    return;
  i = where (array_map (Int_Type, &string_match, files, pattern, 1));
  if (length (i) == 0)
    return;
  files = files [i];
  files = files [array_sort (files)];
  menu_append_popup (parent, popup);
  popup = parent + "." + popup;
   
  foreach (files) {
    variable file = ();
    file = path_sans_extname (file);
    menu_append_popup (popup, file);
    () = evalfile (dircat (LaTeX_Modules_Dir, file));
  }
}

% -----

define latex_goto_next_paragraph ()
{
  if (0 != re_fsearch ("^$"))
    () = right (1);
}

define latex_goto_prev_paragraph ()
{
  if (0 != re_bsearch ("^$"))
    () = left (1);
}

% -----

define init_menu (menu)
{
  variable tmp;
  % templates
  menu_append_popup (menu, "&Templates");
  $1 = sprintf ("%s.&Templates", menu);
  menu_append_item ($1, "&article", "latex_article");
  menu_append_item ($1, "&book", "latex_book");
  menu_append_item ($1, "&letter", "latex_letter");
  menu_append_item ($1, "&report", "latex_report");
  menu_append_item ($1, "&slides", "latex_slides");
  % templates/packages
  % these aren't bound to any key
  menu_append_popup ($1, "&Packages");
  $1 = sprintf ("%s.&Templates.&Packages", menu);
  menu_append_item ($1, "alltt",
                    "latex_insert_newline (\"usepackage\{alltt\}\")");
  menu_append_item ($1, "amsmath",
                    "latex_insert_newline (\"usepackage\{amsmath\}\")");
  menu_append_item ($1, "babel", "latex_babel");
  menu_append_item ($1, "booktabs",
                    "latex_insert_newline (\"usepackage\{booktabs\}\")");
  menu_append_item ($1, "calc",
                    "latex_insert_newline (\"usepackage\{calc\}\")");
  menu_append_item ($1, "color", 
        "latex_insert_newline (\"usepackage\{color\}\")");
  tmp = "latex_insert_newline (\"usepackage\{epic\}\");";
  tmp = tmp + "latex_insert_newline (\"usepackage\{eepic\}\")";
  menu_append_item ($1, "eepic", tmp);
  tmp = "latex_insert_newline (\"usepackage\{fancyhdr\}\");";
  tmp = tmp + "latex_insert_newline (\"pagestyle\{fancy\}\")";
  menu_append_item ($1, "fancyhdr", tmp);
  menu_append_item ($1, "fancyvrb", 
        "latex_insert_newline (\"usepackage\{fancyvrb\}\")");
  menu_append_item ($1, "geometry",
                    "latex_insert_newline (\"usepackage\{geometry\}\")");
  menu_append_item ($1, "graphicx", 
        "latex_insert_newline (\"usepackage\{graphicx\}\")");
  menu_append_item ($1, "hyperref", 
        "latex_insert_newline (\"usepackage" + 
                    "[colorlinks,urlcolor=blue]\{hyperref\}\")");
  menu_append_item ($1, "inputenc", 
        "latex_insert_newline (\"usepackage[latin1]\{inputenc\}}\")");
  menu_append_item ($1, "longtable",
                    "latex_insert_newline (\"usepackage\{longtable\}\")");
  menu_append_item ($1, "makeidx",
                    "latex_insert_newline (\"usepackage\{makeidx\}\")");
  menu_append_item ($1, "moreverb", 
        "latex_insert_newline (\"usepackage\{moreverb\}\")");
  menu_append_item ($1, "makeidx", 
        "latex_makeidx");
  menu_append_item ($1, "psfrag", 
        "latex_insert_newline (\"usepackage\{psfrag\}\")");
  menu_append_item ($1, "pslatex",
                    "latex_insert_newline (\"usepackage\{pslatex\}\")");
  menu_append_item ($1, "rotating", 
        "latex_insert_newline (\"usepackage\{rotating\}\")");
  menu_append_item ($1, "url", 
        "latex_insert_newline (\"usepackage\{url\}\")");
  % environments
  menu_append_popup (menu, "&Environments");
  $1 = sprintf ("%s.&Environments", menu);
  menu_append_item ($1, "&array", 
        "latex_begin_end (\"array\", \"{ll}\", 1, 1)");
  menu_append_item ($1, "&center", 
        "latex_begin_end (\"center\", \"\", 1, 1)");
  menu_append_item ($1, "&description", 
        "latex_env_itemize (\"description\")");
  menu_append_item ($1, "displaymat&h", 
        "latex_begin_end (\"displaymath\", \"\", 1, 1)");
  menu_append_item ($1, "&enumerate", 
        "latex_begin_end (\"enumerate\", \"\", 1, 1)");
  menu_append_item ($1, "eq&narray", 
        "latex_begin_end (\"eqnarray\", \"\", 1, 1)");
  menu_append_item ($1, "e&quation", 
        "latex_begin_end (\"equation\", \"\", 1, 1)");
  menu_append_item ($1, "&figure", "latex_env_figure ()");
  menu_append_item ($1, "flush&left", 
        "latex_begin_end (\"flushleft\", \"\", 1, 1)");
  menu_append_item ($1, "flush&Right", 
        "latex_begin_end (\"flushright\", \"\", 1, 1)");
  menu_append_item ($1, "&Itemize", "latex_env_itemize (\"itemize\")");
  menu_append_item ($1, "\\&item", "latex_env_item");
%  menu_append_item ($1, "&Letter", "latex_env_letter ()");
  menu_append_item ($1, "&List", "latex_begin_end (\"list\", \"\", 1, 1)");
  menu_append_item ($1, "&minipage", 
        "latex_begin_end (\"minipage\", \"[c]{\\\\linewidth}\", 1, 1)");
  menu_append_item ($1, "&picture", 
        "latex_begin_end (\"picture\", \"\", 1, 1)");
  menu_append_item ($1, "&Quotation", 
        "latex_begin_end (\"quotation\", \"\", 1, 1)");
  menu_append_item ($1, "qu&ote", "latex_begin_end (\"quote\", \"\", 1, 1)");
  menu_append_item ($1, "ta&bbing", 
        "latex_begin_end (\"tabbing\", \"\", 1, 1)");
  menu_append_item ($1, "&table", "latex_table_template (0)");
  menu_append_item ($1, "table &row", "latex_table_row (1)");
  menu_append_item ($1, "tab&ular", "latex_table_template (1)");
  menu_append_item ($1, "thebibliograph&y", 
        "latex_begin_end (\"thebibliography\", \"{99}\", 1, 1)");
  menu_append_item ($1, "t&Heorem", 
        "latex_begin_end (\"theorem\", \"\", 1, 1)");
  menu_append_item ($1, "titlepa&ge", 
        "latex_begin_end (\"titlepage\", \"\", 1, 1)");
  menu_append_item ($1, "&verbatim", 
        "latex_begin_end (\"verbatim\", \"\", 1, 1)");
  menu_append_item ($1, "ver&se", "latex_begin_end (\"verse\", \"\", 1, 1)");
  menu_append_item ($1, "&Custom...", "latex_env_custom");
  menu_append_item ($1, "re&Name...", "latex_rename_environment");
  menu_append_item ($1, "in&Dent", "latex_indent_environment");
  % font
  menu_append_popup (menu, "&Font");
  $1 = sprintf ("%s.&Font", menu);
  menu_append_item ($1, "\\text&rm", "latex_cmd (\"textrm\", 1)");
  menu_append_item ($1, "\\text&it", "latex_cmd (\"textit\", 1)");
  menu_append_item ($1, "\\&emph",   "latex_cmd (\"emph\", 1)");
  menu_append_item ($1, "\\text&md", "latex_cmd (\"textmd\", 1)");
  menu_append_item ($1, "\\text&bf", "latex_cmd (\"textmd\", 1)");
  menu_append_item ($1, "\\text&up", "latex_cmd (\"textup\", 1)");
  menu_append_item ($1, "\\text&sl", "latex_cmd (\"textsl\", 1)");
  menu_append_item ($1, "\\texts&f", "latex_cmd (\"textsf\", 1)");
  menu_append_item ($1, "\\texts&c", "latex_cmd (\"textsc\", 1)");
  menu_append_item ($1, "\\text&tt", "latex_cmd (\"texttt\", 1)");
  menu_append_item ($1, "\\&verb", 
                    "latex_insert_tags (\"\\\\verb|\", \"|\", 1, 1)");
  menu_append_item ($1, "\\text&normal", "latex_cmd (\"textnormal\", 1)");
  menu_append_item ($1, "\\un&derline", "latex_cmd (\"underline\", 1)");
  menu_append_item ($1, "&Delete", "latex_modify_font (\"\")");
  menu_append_item ($1, "re&Name", "latex_rename_font");
  % Font popups:
  % font/size, font/environment, font/math
  menu_append_popup ($1, "&Size");
  menu_append_popup ($1, "As &Environment");
  menu_append_popup ($1, "&Math");
  $1 = sprintf ("%s.&Font.&Size", menu);
  menu_append_item ($1, "\\&tiny", "latex_cmd (\"tiny\", 1)");
  menu_append_item ($1, "\\s&criptsize", 
        "latex_cmd (\"scriptsize\", 1)");
  menu_append_item ($1, "\\&footnotesize", 
        "latex_cmd (\"footnotesize\", 1)");
  menu_append_item ($1, "\\&small", "latex_cmd (\"small\", 1)");
  menu_append_item ($1, "\\&normalsize", "latex_cmd (\"normalsize\", 1)");
  menu_append_item ($1, "\\&large", "latex_cmd (\"large\", 1)");
  menu_append_item ($1, "\\&Large", "latex_cmd (\"Large\", 1)");
  menu_append_item ($1, "\\L&ARGE", "latex_cmd (\"LARGE\", 1)");
  menu_append_item ($1, "\\&huge", "latex_cmd (\"huge\", 1)");
  menu_append_item ($1, "\\&Huge", "latex_cmd (\"Huge\", 1)");
  menu_append_item ($1, "re&Size", "latex_resize_font");
  % font/environment
  $1 = sprintf ("%s.&Font.As &Environment", menu);
  menu_append_item ($1, "&rmfamily", 
        "latex_begin_end (\"rmfamily\", \"\", 1, 1)");
  menu_append_item ($1, "&itshape", 
        "latex_begin_end (\"itshape\", \"\", 1, 1)");
  menu_append_item ($1, "&mdseries", 
        "latex_begin_end (\"mdseries\", \"\", 1, 1)");
  menu_append_item ($1, "&bfseries", 
        "latex_begin_end (\"bfseries\", \"\", 1, 1)");
  menu_append_item ($1, "&upshape", 
        "latex_begin_end (\"upshape\", \"\", 1, 1)");
  menu_append_item ($1, "&slshape", 
        "latex_begin_end (\"slshape\", \"\", 1, 1)");
  menu_append_item ($1, "s&ffamily", 
        "latex_begin_end (\"sffamily\", \"\", 1, 1)");
  menu_append_item ($1, "s&cshape", 
        "latex_begin_end (\"scshape\", \"\", 1, 1)");
  menu_append_item ($1, "&ttfamily", 
        "latex_begin_end (\"ttfamily\", \"\", 1, 1)");
  menu_append_item ($1, "&normalfont", 
        "latex_begin_end (\"normalfont\", \"\", 1, 1)");
  % font/math
  $1 = sprintf ("%s.&Font.&Math", menu);
  menu_append_item ($1, "\\mathr&m", "latex_cmd (\"mathrm\", 1)");
  menu_append_item ($1, "\\math&bf", "latex_cmd (\"mathbf\", 1)");
  menu_append_item ($1, "\\math&sf", "latex_cmd (\"mathsf\", 1)");
  menu_append_item ($1, "\\math&tt", "latex_cmd (\"mathtt\", 1)");
  menu_append_item ($1, "\\math&it", "latex_font_mathit");
  menu_append_item ($1, "\\math&normal", "latex_cmd (\"mathnormal\", 1)");
  menu_append_item ($1, "\\mathversion{bold}",
                    "latex_cmd (\"mathversion{bold}\", 1)");
  menu_append_item ($1, "\\mathversion{normal}",
                    "latex_cmd (\"mathversion{normal}\", 1)");
  % sections
  menu_append_popup (menu, "&Sections");
  $1 = sprintf ("%s.&Sections", menu);
  menu_append_item ($1, "\\p&art", "latex_cmd (\"part\", 1)");
  menu_append_item ($1, "\\&chapter", "latex_cmd (\"chapter\", 1)");
  menu_append_item ($1, "\\&section", "latex_cmd (\"section\", 1)");
  menu_append_item ($1, "\\s&ubsection", "latex_cmd (\"subsection\", 1)");
  menu_append_item ($1, "\\su&bsubsection", 
        "latex_cmd (\"subsubsection\", 1)");
  menu_append_item ($1, "\\&paragraph", "latex_cmd (\"paragraph\", 1)");
  menu_append_item ($1, "\\subparagrap&h", 
        "latex_cmd (\"subparagraph\", 1)");
  % paragraph
  menu_append_popup (menu, "&Paragraph");
  $1 = sprintf ("%s.&Paragraph", menu);
  menu_append_item ($1, "F&ramed Paragraph", "latex_par_frame");
  menu_append_item ($1, "&background Colour", "latex_par_bgcolour");
  menu_append_item ($1, "&foreground Colour", "latex_par_fgcolour");
  menu_append_item ($1, "\\par&indent",
                    "insert (\"\\\\setlength{\\\\parindent}{0pt}\\n\")");
  menu_append_item ($1, "\\par&skip",
                    "insert (\"\\\\setlength{\\\\parskip}{3pt}\\n\")");
  menu_append_item ($1, "\\&marginpar", 
        "latex_cmd (\"marginpar\", 1)");
  menu_append_item ($1, "\\foot&note", 
        "latex_cmd (\"footnote\", 1)");
  menu_append_item ($1, "\\inc&ludegraphics", "latex_includegraphics");
  % paragraph popups:
  % paragraph/margins, paragraph/breaks, paragraph/boxes, paragraph/spaces
  menu_append_popup ($1, "&Margins");
  menu_append_popup ($1, "Brea&ks");
  menu_append_popup ($1, "&Spaces");
  menu_append_popup ($1, "Bo&xes");
  $1 = sprintf ("%s.&Paragraph.&Margins", menu);
  menu_append_item ($1, "\\&leftmargin",
        "latex_cmd (\"setlength{\\\\leftmargin}\", 1)");
  menu_append_item ($1, "\\&rightmargin",
        "latex_cmd (\"setlength{\\\\rightmargin}\", 1)");
  menu_append_item ($1, "\\&evensidemargin",
        "latex_cmd (\"setlength{\\\\evensidemargin}\", 1)");
  menu_append_item ($1, "\\&oddsidemargin",
        "latex_cmd (\"setlength{\\\\oddsidemargin}\", 1)");
  menu_append_item ($1, "\\&topmargin",
        "latex_cmd (\"setlength{\\\\topmargin}\", 1)");
  menu_append_item ($1, "\\text&width",
        "latex_cmd (\"setlength{\\\\textwidth}\", 1)");
  menu_append_item ($1, "\\text&height",
        "latex_cmd (\"setlength{\\\\textheight}\", 1)");
  $1 = sprintf ("%s.&Paragraph.Brea&ks", menu);
  menu_append_item ($1, "\\new&line", "insert (\"\\\\newline\\n\")");
  menu_append_item ($1, "\\\\&*[]", "latex_linebreak");
  menu_append_item ($1, "\\line&break", "insert (\"\\\\linebreak[1]\\n\")");
  menu_append_item ($1, "\\new&page", "insert (\"\\\\newpage\\n\")");
  menu_append_item ($1, "\\&clearpage", "insert (\"\\\\clearpage\\n\")");
  menu_append_item ($1, "\\clear&doublepage",
        "insert (\"\\\\cleardoublepage\\n\")");
  menu_append_item ($1, "\\pageb&reak", "insert (\"\\\\pagebreak\\n\")");
  menu_append_item ($1, "\\&nolinebreak",
        "insert (\"\\\\nolinebreak[1]\\n\")");
  menu_append_item ($1, "\\n&opagebreak", "insert (\"\\\\nopagebreak\\n\")");
  menu_append_item ($1, "\\&enlargethispage",
        "insert (\"\\\\enlargethispage\\n\")");
  % paragraph/spaces
  $1 = sprintf ("%s.&Paragraph.&Spaces", menu);
  menu_append_item ($1, "\\&frenchspacing",
                    "insert (\"\\\\frenchspacing\\n\")");
  menu_append_item ($1, "\\&@.", "insert (\"\\\\@.\\n\")");
  menu_append_item ($1, "\\&dotfill", "insert (\"\\\\dotfill\\n\")");
  menu_append_item ($1, "\\&hfill", "insert (\"\\\\hfill\\n\")");
  menu_append_item ($1, "\\h&rulefill", "insert (\"\\\\hrulefill\\n\")");
  menu_append_item ($1, "\\&smallskip", "insert (\"\\\\smallskip\\n\")");
  menu_append_item ($1, "\\&medskip", "insert (\"\\\\medskip\\n\")");
  menu_append_item ($1, "\\&bigskip", "insert (\"\\\\bigskip\\n\")");
  menu_append_item ($1, "\\&vfill", "insert (\"\\\\vfill\\n\")");
  menu_append_item ($1, "\\hspace", "insert (\"\\\\hspace\\n\")");
  menu_append_item ($1, "\\vs&pace", "insert (\"\\\\vspace\\n\")");
  menu_append_item ($1, "Set \\baselines&kip",
                    "insert (\"\\\\baselineskip 2\\\\baselineskip\\n\")");
  % paragraph/boxes
  $1 = sprintf ("%s.&Paragraph.Bo&xes", menu);
  menu_append_item ($1, "\\&fbox", "latex_cmd (\"fbox\", 1)");
  menu_append_item ($1, "\\f&ramebox", 
        "latex_cmd (\"framebox[\\\\width][c]\", 1)");
  menu_append_item ($1, "\\&mbox", "latex_cmd (\"mbox\", 1)");
  menu_append_item ($1, "\\ma&kebox", 
        "latex_cmd (\"makebox[\\\\width][c]\", 1)");
  menu_append_item ($1, "\\&newsavebox", "latex_cmd (\"newsavebox\", 1)");
  menu_append_item ($1, "\\ru&le", 
        "latex_cmd (\"rule{\\\\linewidth}\", 1)");
  menu_append_item ($1, "\\save&box", 
        "latex_cmd (\"savebox{}[\\\\linewidth][c]\", 1)");
  menu_append_item ($1, "\\&sbox", 
        "latex_cmd (\"sbox{}\", 1)");
  menu_append_item ($1, "\\&usebox", 
        "latex_cmd (\"usebox\", 1)");
  % links
  menu_append_popup (menu, "&Links");
  $1 = sprintf ("%s.&Links", menu);
  menu_append_item ($1, "\\&label", "latex_cmd (\"label\", 1)");
  menu_append_item ($1, "\\&ref", "latex_cmd (\"ref\", 1)");
  menu_append_item ($1, "\\&cite", "latex_cmd (\"cite\", 1)");
  menu_append_item ($1, "\\&nocite", "latex_cmd (\"nocite\", 1)");
  menu_append_item ($1, "\\&url", "latex_url");
  % index
  menu_append_popup (menu, "&Index");
  $1 = sprintf ("%s.&Index", menu);
  menu_append_item ($1, "\\&index", "latex_cmd (\"index\", 1)");
  menu_append_item ($1, "\\&index{entry!subentry}", "latex_index_subentry");
  menu_append_item ($1, "\\&index{entry|(}", "latex_index_beginrange");
  menu_append_item ($1, "\\&index{entry|)}", "latex_index_endrange");
  menu_append_item ($1, "\\&index{sortentry@textentry)}",
                    "latex_index_sortorder");
  menu_append_item ($1, "\\&index{entry|format)}",
                    "latex_index_specialformat");
  % math
  menu_append_popup (menu, "&Math");
  $1 = sprintf ("%s.&Math", menu);
  % math popups:
  % math/greek letter, math/accents, math/binary relations,
  % math/operators, math/arrows, math/misc
  menu_append_item ($1, "&Toggle Math Mode", "toggle_math_mode");
  menu_append_item ($1, "&Greek Letter...", "latex_greek_letter");
  menu_append_item ($1, "&_{}  subscript", 
        "latex_insert_tags (\"_{\", \"}\", 1, 1)");
  menu_append_item ($1, "&^{}  superscript",
        "latex_insert_tags (\"^{\", \"}\", 1, 1)");
  menu_append_item ($1, "\\&frac",
                    "latex_insert_tags (\"\\\\frac{\", \"}{}\", 1, 1)");
  menu_append_item ($1, "\\&int",
                    "latex_insert_tags (\"\\\\int_{\", \"}^{}\", 1, 1)");
  menu_append_item ($1, "\\&lim",
                    "latex_insert_tags (\"\\\\lim_{\", \"}\", 1, 1)");
  menu_append_item ($1, "\\&oint",
                    "latex_insert_tags (\"\\\\oint_{\", \"}^{}\", 1, 1)");
  menu_append_item ($1, "\\&prod",
                    "latex_insert_tags (\"\\\\prod_{\", \"}^{}\", 1, 1)");
  menu_append_item ($1, "\\&sum",
                    "latex_insert_tags (\"\\\\sum_{\", \"}^{}\", 1, 1)");
  menu_append_item ($1, "\\s&qrt",
                    "latex_insert_tags (\"\\\\sqrt[]{\", \"}\", 1, 1)");
  menu_append_popup ($1, "&Accents");
  menu_append_popup ($1, "&Delimiters");
  menu_append_popup ($1, "&Functions");
  menu_append_popup ($1, "Binary &Relations");
  menu_append_popup ($1, "Binary &Operators");
  menu_append_popup ($1, "S&paces");
  menu_append_popup ($1, "Arro&ws");
  menu_append_popup ($1, "&Misc");
  % math/accents
  $1 = sprintf ("%s.&Math.&Accents", menu);
  menu_append_item ($1, "\\hat", "latex_cmd (\"hat\", 1)");
  menu_append_item ($1, "\\acute", "latex_cmd (\"acute\", 1)");
  menu_append_item ($1, "\\bar", "latex_cmd (\"bar\", 1)");
  menu_append_item ($1, "\\dot", "latex_cmd (\"dot\", 1)");
  menu_append_item ($1, "\\breve", "latex_cmd (\"breve\", 1)");
  menu_append_item ($1, "\\check", "latex_cmd (\"check\", 1)");
  menu_append_item ($1, "\\grave", "latex_cmd (\"grave\", 1)");
  menu_append_item ($1, "\\vec", "latex_cmd (\"vec\", 1)");
  menu_append_item ($1, "\\ddot", "latex_cmd (\"ddot\", 1)");
  menu_append_item ($1, "\\tilde", "latex_cmd (\"tilde\", 1)");
  % constructs
  menu_append_item ($1, "\\widetilde", "latex_cmd (\"widetilde\", 1)");
  menu_append_item ($1, "\\widehat", "latex_cmd (\"widehat\", 1)");
  menu_append_item ($1, "\\overleftarrow",
                    "latex_cmd (\"overleftarrow\", 1)");
  menu_append_item ($1, "\\overrightarrow",
                    "latex_cmd (\"overrightarrow\", 1)");
  menu_append_item ($1, "\\overline", "latex_cmd (\"overline\", 1)");
  menu_append_item ($1, "\\underline", "latex_cmd (\"underline\", 1)");
  menu_append_item ($1, "\\overbrace", "latex_cmd (\"overbrace\", 1)");
  menu_append_item ($1, "\\underbrace", "latex_cmd (\"underbrace\", 1)");
  % math/delimiters
  $1 = sprintf ("%s.&Math.&Delimiters", menu);
  menu_append_item ($1, "\\left (", "latex_insert (\"left(\")");
  menu_append_item ($1, "\\right)", "latex_insert (\"right)\")");
  menu_append_item ($1, "\\left[", "latex_insert (\"left[\")");
  menu_append_item ($1, "\\right]", "latex_insert (\"right[\")");
  menu_append_item ($1, "\\left{", "latex_insert (\"left\\\\{\")");
  menu_append_item ($1, "\\right}", "latex_insert (\"right\\\\}\")");
  menu_append_item ($1, "\\rmoustache", "latex_insert (\"rmoustache\")");
  menu_append_item ($1, "\\lmoustache", "latex_insert (\"lmoustache\")");
  menu_append_item ($1, "\\rgroup", "latex_insert (\"rgroup\")");
  menu_append_item ($1, "\\lgroup", "latex_insert (\"lgroup\")");
  menu_append_item ($1, "\\arrowvert", "latex_insert (\"arrowvert\")");
  menu_append_item ($1, "\\Arrowvert", "latex_insert (\"Arrowvert\")");
  menu_append_item ($1, "\\bracevert", "latex_insert (\"bracevert\")");
  menu_append_item ($1, "\\lfloor", "latex_insert (\"lfloor\")");
  menu_append_item ($1, "\\rfloor", "latex_insert (\"rfloor\")");
  menu_append_item ($1, "\\lceil", "latex_insert (\"lceil\")");
  menu_append_item ($1, "\\rceil", "latex_insert (\"rceil\")");
  menu_append_item ($1, "\\langle", "latex_insert (\"langle\")");
  menu_append_item ($1, "\\rangle", "latex_insert (\"rangle\")");
  menu_append_item ($1, "\\|", "latex_insert (\"\\|\")");
  % math/functions
  $1 = sprintf ("%s.&Math.&Functions", menu);
  menu_append_item ($1, "\\arccos", "latex_loglike (\"\\arccos\")");
  menu_append_item ($1, "\\arcsin", "latex_loglike (\"\\arcsin\")");
  menu_append_item ($1, "\\arctan", "latex_loglike (\"\\arctan\")");
  menu_append_item ($1, "\\arg", "latex_loglike (\"\\arg\")");
  menu_append_item ($1, "\\cos", "latex_loglike (\"\\cos\")");
  menu_append_item ($1, "\\cosh", "latex_loglike (\"\\cosh\")");
  menu_append_item ($1, "\\cot", "latex_loglike (\"\\cot\")");
  menu_append_item ($1, "\\coth", "latex_loglike (\"\\coth\")");
  menu_append_item ($1, "\\csc", "latex_loglike (\"\\csc\")");
  menu_append_item ($1, "\\deg", "latex_loglike (\"\\deg\")");
  menu_append_item ($1, "\\det", "latex_loglike (\"\\det\")");
  menu_append_item ($1, "\\dim", "latex_loglike (\"\\dim\")");
  menu_append_item ($1, "\\exp", "latex_loglike (\"\\exp\")");
  menu_append_item ($1, "\\gcd", "latex_loglike (\"\\gcd\")");
  menu_append_item ($1, "\\hom", "latex_loglike (\"\\hom\")");
  menu_append_item ($1, "\\inf", "latex_loglike (\"\\inf\")");
  menu_append_item ($1, "\\ker", "latex_loglike (\"\\ker\")");
  menu_append_item ($1, "\\lg", "latex_loglike (\"\\lg\")");
  menu_append_item ($1, "\\lim", "latex_loglike (\"\\lim\")");
  menu_append_item ($1, "\\liminf", "latex_loglike (\"\\liminf\")");
  menu_append_item ($1, "\\limsup", "latex_loglike (\"\\limsup\")");
  menu_append_item ($1, "\\ln", "latex_loglike (\"\\ln\")");
  menu_append_item ($1, "\\log", "latex_loglike (\"\\log\")");
  menu_append_item ($1, "\\max", "latex_loglike (\"\\max\")");
  menu_append_item ($1, "\\min", "latex_loglike (\"\\min\")");
  menu_append_item ($1, "\\Pr", "latex_loglike (\"\\Pr\")");
  menu_append_item ($1, "\\sec", "latex_loglike (\"\\sec\")");
  menu_append_item ($1, "\\sin", "latex_loglike (\"\\sin\")");
  menu_append_item ($1, "\\sinh", "latex_loglike (\"\\sinh\")");
  menu_append_item ($1, "\\sup", "latex_loglike (\"\\sup\")");
  menu_append_item ($1, "\\tan", "latex_loglike (\"\\tan\")");
  menu_append_item ($1, "\\tanh", "latex_loglike (\"\\tanh\")");
  % math/binary relations
  $1 = sprintf ("%s.&Math.Binary &Relations", menu);
  menu_append_item ($1, "\\leq", "latex_insert (\"leq\")");
  menu_append_item ($1, "\\geq", "latex_insert (\"geq\")");
  menu_append_item ($1, "\\equiv", "latex_insert (\"equiv\")");
  menu_append_item ($1, "\\models", "latex_insert (\"models\")");
  menu_append_item ($1, "\\prec", "latex_insert (\"prec\")");
  menu_append_item ($1, "\\succ", "latex_insert (\"succ\")");
  menu_append_item ($1, "\\sim", "latex_insert (\"sim\")");
  menu_append_item ($1, "\\perp", "latex_insert (\"perp\")");
  menu_append_item ($1, "\\preceq", "latex_insert (\"preceq\")");
  menu_append_item ($1, "\\succeq", "latex_insert (\"succeq\")");
  menu_append_item ($1, "\\simeq", "latex_insert (\"simeq\")");
  menu_append_item ($1, "\\mid", "latex_insert (\"mid\")");
  menu_append_item ($1, "\\ll", "latex_insert (\"ll\")");
  menu_append_item ($1, "\\gg", "latex_insert (\"gg\")");
  menu_append_item ($1, "\\asymp", "latex_insert (\"asymp\")");
  menu_append_item ($1, "\\parallel", "latex_insert (\"parallel\")");
  menu_append_item ($1, "\\subset", "latex_insert (\"subset\")");
  menu_append_item ($1, "\\supset", "latex_insert (\"supset\")");
  menu_append_item ($1, "\\approx", "latex_insert (\"approx\")");
  menu_append_item ($1, "\\bowtie", "latex_insert (\"bowtie\")");
  menu_append_item ($1, "\\subseteq", "latex_insert (\"subseteq\")");
  menu_append_item ($1, "\\supseteq", "latex_insert (\"supseteq\")");
  menu_append_item ($1, "\\cong", "latex_insert (\"cong\")");
  menu_append_item ($1, "\\Join", "latex_insert (\"Join\")");
  menu_append_item ($1, "\\sqsubset", "latex_insert (\"sqsubset\")");
  menu_append_item ($1, "\\sqsupset", "latex_insert (\"sqsupset\")");
  menu_append_item ($1, "\\neq", "latex_insert (\"neq\")");
  menu_append_item ($1, "\\smile", "latex_insert (\"smile\")");
  menu_append_item ($1, "\\sqsubseteq", "latex_insert (\"sqsubseteq\")");
  menu_append_item ($1, "\\sqsupseteq", "latex_insert (\"sqsupseteq\")");
  menu_append_item ($1, "\\doteq", "latex_insert (\"doteq\")");
  menu_append_item ($1, "\\frown", "latex_insert (\"frown\")");
  menu_append_item ($1, "\\in", "latex_insert (\"in\")");
  menu_append_item ($1, "\\ni", "latex_insert (\"ni\")");
  menu_append_item ($1, "\\propto", "latex_insert (\"propto\")");
  menu_append_item ($1, "\\vdash", "latex_insert (\"vdash \")");
  menu_append_item ($1, "\\dashv", "latex_insert (\"dashv \")");
  menu_append_item ($1, "\\not", "latex_insert (\"not \")");
  % math/binary operators
  $1 = sprintf ("%s.&Math.Binary &Operators", menu);
  menu_append_item ($1, "\\pm", "latex_insert (\"pm\")");
  menu_append_item ($1, "\\cap", "latex_insert (\"cap\")");
  menu_append_item ($1, "\\diamond", "latex_insert (\"diamond\")");
  menu_append_item ($1, "\\oplus", "latex_insert (\"oplus\")");
  menu_append_item ($1, "\\mp", "latex_insert (\"mp\")");
  menu_append_item ($1, "\\cup", "latex_insert (\"cup\")");
  menu_append_item ($1, "\\bigtriangleup",
                    "latex_insert (\"bigtriangleup\")");
  menu_append_item ($1, "\\ominus", "latex_insert (\"ominus\")");
  menu_append_item ($1, "\\times", "latex_insert (\"times\")");
  menu_append_item ($1, "\\uplus", "latex_insert (\"uplus\")");
  menu_append_item ($1, "\\bigtriangledown",
                    "latex_insert (\"bigtriangledown\")");
  menu_append_item ($1, "\\otimes", "latex_insert (\"otimes\")");
  menu_append_item ($1, "\\div", "latex_insert (\"div\")");
  menu_append_item ($1, "\\sqcap", "latex_insert (\"sqcap\")");
  menu_append_item ($1, "\\triangleleft",
                    "latex_insert (\"triangleleft\")");
  menu_append_item ($1, "\\oslash", "latex_insert (\"oslash\")");
  menu_append_item ($1, "\\ast", "latex_insert (\"ast\")");
  menu_append_item ($1, "\\sqcup", "latex_insert (\"sqcup\")");
  menu_append_item ($1, "\\triangleright",
                    "latex_insert (\"triangleright\")");
  menu_append_item ($1, "\\odot", "latex_insert (\"odot\")");
  menu_append_item ($1, "\\star", "latex_insert (\"star\")");
  menu_append_item ($1, "\\vee", "latex_insert (\"vee\")");
  menu_append_item ($1, "\\bigcirc", "latex_insert (\"bigcirc\")");
  menu_append_item ($1, "\\circ", "latex_insert (\"circ\")");
  menu_append_item ($1, "\\wedge", "latex_insert (\"wedge\")");
  menu_append_item ($1, "\\dagger", "latex_insert (\"dagger\")");
  menu_append_item ($1, "\\bullet", "latex_insert (\"bullet\")");
  menu_append_item ($1, "\\setminus", "latex_insert (\"setminus\")");
  menu_append_item ($1, "\\ddagger", "latex_insert (\"ddagger\")");
  menu_append_item ($1, "\\cdot", "latex_insert (\"cdot\")");
  menu_append_item ($1, "\\wr", "latex_insert (\"wr\")");
  menu_append_item ($1, "\\analg", "latex_insert (\"analg\")");
  % math/spaces
  $1 = sprintf ("%s.&Math.S&paces", menu);
  menu_append_item ($1, "\\;", "insert (\"\\\\; \")");
  menu_append_item ($1, "\\:", "insert (\"\\\\> \")");
  menu_append_item ($1, "\\,", "insert (\"\\\\, \")");
  menu_append_item ($1, "\\!", "insert (\"\\\\! \")");
  % math/arrows
  $1 = sprintf ("%s.&Math.Arro&ws", menu);
  menu_append_item ($1, "\\leftarrow", "latex_insert (\"leftarrow\")");
  menu_append_item ($1, "\\Leftarrow", "latex_insert (\"Leftarrow\")");
  menu_append_item ($1, "\\longleftarrow",
                    "latex_insert (\"longleftarrow\")");
  menu_append_item ($1, "\\Longleftarrow",
                    "latex_insert (\"Longleftarrow\")");
  menu_append_item ($1, "\\rightarrow", "latex_insert (\"rightarrow\")");
  menu_append_item ($1, "\\longrightarrow",
                    "latex_insert (\"longrightarrow\")");
  menu_append_item ($1, "\\Rightarrow", "latex_insert (\"Rightarrow\")");
  menu_append_item ($1, "\\Longrightarrow",
                    "latex_insert (\"Longrightarrow\")");
  menu_append_item ($1, "\\uparrow", "latex_insert (\"uparrow\")");
  menu_append_item ($1, "\\Uparrow", "latex_insert (\"Uparrow\")");
  menu_append_item ($1, "\\downarrow", "latex_insert (\"downarrow\")");
  menu_append_item ($1, "\\Downarrow", "latex_insert (\"Downarrow\")");
  menu_append_item ($1, "\\leftrightarrow",
                    "latex_insert (\"leftrightarrow\")");
  menu_append_item ($1, "\\Leftrightarrow",
                    "latex_insert (\"Leftrightarrow\")");
  menu_append_item ($1, "\\longleftrightarrow",
        "latex_insert (\"longleftrightarrow\")");
  menu_append_item ($1, "\\Longleftrightarrow",
        "latex_insert (\"Longleftrightarrow\")");
  menu_append_item ($1, "\\updownarrow", "latex_insert (\"updownarrow\")");
  menu_append_item ($1, "\\Updownarrow", "latex_insert (\"Updownarrow\")");
  menu_append_item ($1, "\\mapsto", "latex_insert (\"mapsto\")");
  menu_append_item ($1, "\\longmapsto", "latex_insert (\"longmapsto\")");
  menu_append_item ($1, "\\hookleftarrow",
                    "latex_insert (\"hookleftarrow\")");
  menu_append_item ($1, "\\hookrightarrow",
                    "latex_insert (\"hookrightarrow\")");
  menu_append_item ($1, "\\leftarpoonup", "latex_insert (\"leftarpoonup\")");
  menu_append_item ($1, "\\rightarpoonup",
                    "latex_insert (\"rightarpoonup\")");
  menu_append_item ($1, "\\leftarpoondown",
                    "latex_insert (\"leftarpoondown\")");
  menu_append_item ($1, "\\rightarpoondown",
                    "latex_insert (\"rightarpoondown\")");
  menu_append_item ($1, "\\nearrow", "latex_insert (\"nearrow\")");
  menu_append_item ($1, "\\searrow", "latex_insert (\"searrow\")");
  menu_append_item ($1, "\\swarrow", "latex_insert (\"swarrow\")");
  menu_append_item ($1, "\\nwarrow", "latex_insert (\"nwarrow\")");
  % math/misc
  $1 = sprintf ("%s.&Math.&Misc", menu);
  menu_append_item ($1, "\\ldots", "latex_insert (\"ldots\")");
  menu_append_item ($1, "\\cdots", "latex_insert (\"cdots\")");
  menu_append_item ($1, "\\vdots", "latex_insert (\"vdots\")");
  menu_append_item ($1, "\\ddots", "latex_insert (\"ddots\")");
  menu_append_item ($1, "\\aleph", "latex_insert (\"aleph\")");
  menu_append_item ($1, "\\prime", "latex_insert (\"prime\")");
  menu_append_item ($1, "\\forall", "latex_insert (\"forall\")");
  menu_append_item ($1, "\\infty", "latex_insert (\"infty\")");
  menu_append_item ($1, "\\hbar", "latex_insert (\"hbar\")");
  menu_append_item ($1, "\\emptyset", "latex_insert (\"emptyset\")");
  menu_append_item ($1, "\\exists", "latex_insert (\"exists\")");
  menu_append_item ($1, "\\nabla", "latex_insert (\"nabla\")");
  menu_append_item ($1, "\\surd", "latex_insert (\"surd\")");
  menu_append_item ($1, "\\triangle", "latex_insert (\"triangle\")");
  menu_append_item ($1, "\\imath", "latex_insert (\"imath\")");
  menu_append_item ($1, "\\jmath", "latex_insert (\"jmath\")");
  menu_append_item ($1, "\\ell", "latex_insert (\"ell\")");
  menu_append_item ($1, "\\neg", "latex_insert (\"neg\")");
  menu_append_item ($1, "\\top", "latex_insert (\"top\")");
  menu_append_item ($1, "\\flat", "latex_insert (\"flat\")");
  menu_append_item ($1, "\\natural", "latex_insert (\"natural\")");
  menu_append_item ($1, "\\sharp", "latex_insert (\"sharp\")");
  menu_append_item ($1, "\\wp", "latex_insert (\"wp\")");
  menu_append_item ($1, "\\bot", "latex_insert (\"bot\")");
  menu_append_item ($1, "\\clubsuit", "latex_insert (\"clubsuit\")");
  menu_append_item ($1, "\\diamondsuit", "latex_insert (\"diamondsuit\")");
  menu_append_item ($1, "\\heartsuit", "latex_insert (\"heartsuit\")");
  menu_append_item ($1, "\\spadesuit", "latex_insert (\"spadesuit\")");
  menu_append_item ($1, "\\Re", "latex_insert (\"Re\")");
  menu_append_item ($1, "\\Im", "latex_insert (\"Im\")");
  menu_append_item ($1, "\\angle", "latex_insert (\"angle\")");
  menu_append_item ($1, "\\partial", "latex_insert (\"partial\")");
  % bibliography
  menu_append_popup (menu, "Bibliograph&y");
  $1 = sprintf ("%s.Bibliograph&y", menu);
  menu_append_item ($1, "&thebibliography", 
        "latex_begin_end (\"thebibliography\", \"{99}\", 1, 1)");
  menu_append_item ($1, "\\bib&item",
                    "latex_cmd (\"bibitem\", 1)");
  menu_append_item ($1, "\\&bibliography",
                    "latex_insert (\"bibliography\")");
  menu_append_item ($1, "\\bibliography&style",
                    "latex_insert (\"bibliographystyle\")");
  add_files_popup_with_callback (menu, "Mod&ules",
                               LaTeX_Modules_Dir,
                               "\\C^.*\\.sl$");
  % separator
  $1 = sprintf ("%s", menu);
  menu_append_separator ($1);
  menu_append_item ($1, "&Customise Defaults", "latex_customise");
  menu_append_item ($1, "Set M&aster File", "latex_master_file");
  menu_append_item ($1, "Select &Output", "latex_select_output");
  menu_append_item ($1, "&Compose", "latex_compose");
  menu_append_item ($1, "&View", "latex_view");
#ifndef WIN32
  menu_append_item ($1, "P&rint", "latex_psprint");
#endif
  menu_append_item ($1, "&BibTeX", "latex_bibtex");
  menu_append_item ($1, "Makeinde&x", "latex_makeindex");
  menu_append_item ($1, "&Document Structure", "latex_browse_tree");
  menu_append_item ($1, "&Remove Tmp Files", "latex_clearup");
  menu_append_separator ($1);
  menu_append_item(menu, "Latex &Info pages",
		   "info_mode(); info_find_node(\"(latex)\");");
  menu_append_item ($1, "LaTeX Mode &Help", "latex_mode_help");
}

% The Keymap

% -----

% normally, folding and latex mode are incompatible because of clashing 
% ^Cf... key bindings. I don't want to give up ^Cf, so this key binding 
% can be customized using the following variable.

custom_variable ("LaTeX_Font_Key", "f"); % suggested alternative: "n"

define latex_keymap ()
{
  $1 = "LaTeX-Mode";
  !if (keymap_p ($1))
    make_keymap ($1);
  use_keymap ($1);

  % templates - ^CT or ^C^T
  definekey_reserved ("latex_article", "ta", $1);
  definekey_reserved ("latex_article", "^T^A", $1);
  definekey_reserved ("latex_book",    "tb", $1);
  definekey_reserved ("latex_book",    "^T^B", $1);
  definekey_reserved ("latex_letter",  "tl", $1);
  definekey_reserved ("latex_letter",  "^T^L", $1);
  definekey_reserved ("latex_report",  "tr", $1);
  definekey_reserved ("latex_report",  "^T^R", $1);
  definekey_reserved ("latex_slides",  "ts", $1);
  definekey_reserved ("latex_slides",  "^T^S", $1);
  definekey_reserved ("latex_notice",  "tn", $1);
  definekey_reserved ("latex_notice",  "^T^N", $1);
  % environments - ^CE
  definekey_reserved ("latex_begin_end (\"array\", \"{ll}\", 1, 1)",
                      "ea", $1);
  definekey_reserved ("latex_begin_end (\"array\", \"{ll}\", 1, 1)",
                      "^E^A", $1);
  definekey_reserved ("latex_begin_end (\"center\", \"\", 1, 1)", "ec", $1);
  definekey_reserved ("latex_begin_end (\"center\", \"\", 1, 1)", "^E^C", $1);
  definekey_reserved ("latex_env_itemize (\"description\")",
                      "ed", $1);
  definekey_reserved ("latex_env_itemize (\"description\")",
                      "^E^D", $1);
  definekey_reserved ("latex_begin_end (\"displaymath\", \"\", 1, 1)",
                      "eh", $1);
  definekey_reserved ("latex_begin_end (\"displaymath\", \"\", 1, 1)",
                      "^E^H", $1);
  definekey_reserved ("latex_begin_end (\"enumerate\", \"\", 1, 1)",
                      "ee", $1);
  definekey_reserved ("latex_begin_end (\"enumerate\", \"\", 1, 1)",
                      "^E^E", $1);
  definekey_reserved ("latex_begin_end (\"eqnarray\", \"\", 1, 1)",
                      "en", $1);
  definekey_reserved ("latex_begin_end (\"eqnarray\", \"\", 1, 1)",
                      "^E^N", $1);
  definekey_reserved ("latex_begin_end (\"equation\", \"\", 1, 1)",
                      "eq", $1);
  definekey_reserved ("latex_begin_end (\"equation\", \"\", 1, 1)",
                      "^E^Q", $1);
  definekey_reserved ("latex_env_figure ()", "ef", $1);
  definekey_reserved ("latex_env_figure ()", "^E^F", $1);
  definekey_reserved ("latex_begin_end (\"flushleft\", \"\", 1, 1)",
                      "el", $1);
  definekey_reserved ("latex_begin_end (\"flushright\", \"\", 1, 1)",
                      "eR", $1);
  definekey_reserved ("latex_env_item",    "ei", $1);
  definekey_reserved ("latex_env_item",    "^E^I", $1);
  definekey_reserved ("latex_env_itemize (\"itemize\")", "eI", $1);
  % definekey_reserved ("latex_env_letter", "eL", $1);
  definekey_reserved ("latex_begin_end (\"list\", \"\", 1, 1)", "eL", $1);
  definekey_reserved ("latex_begin_end (\"list\", \"\", 1, 1)", "^E^L", $1);
  definekey_reserved ("latex_begin_end (\"minipage\"," + 
                      " \"[c]{\\\\linewidth}\", 1, 1)", "em", $1);
  definekey_reserved ("latex_begin_end (\"minipage\"," + 
                      " \"[c]{\\\\linewidth}\", 1, 1)", "^E^M", $1);
  definekey_reserved ("latex_begin_end (\"picture\", \"\", 1, 1)",
                      "ep", $1);
  definekey_reserved ("latex_begin_end (\"picture\", \"\", 1, 1)",
                      "^E^P", $1);
  definekey_reserved ("latex_begin_end (\"quotation\", \"\", 1, 1)",
                      "eQ", $1);
  definekey_reserved ("latex_begin_end (\"quote\", \"\", 1, 1)", "eo", $1);
  definekey_reserved ("latex_begin_end (\"quote\", \"\", 1, 1)", "^E^O", $1);
  definekey_reserved ("latex_begin_end (\"tabbing\", \"\", 1, 1)", "eb", $1);
  definekey_reserved ("latex_begin_end (\"tabbing\", \"\", 1, 1)",
                      "^E^B", $1);
  definekey_reserved ("latex_table_template (1)", "eu", $1);
  definekey_reserved ("latex_table_template (1)", "^E^U", $1);
  definekey_reserved ("latex_table_template (0)", "et", $1);
  definekey_reserved ("latex_table_template (0)", "^E^T", $1);
  definekey_reserved ("latex_table_row (1)", "er", $1);
  definekey_reserved ("latex_table_row (1)", "^E^R", $1);
  definekey_reserved ("latex_begin_end (\"thebibliography\", \"{99}\", 1, 1)",
                      "ey", $1);
  definekey_reserved ("latex_begin_end (\"thebibliography\", \"{99}\", 1, 1)",
                      "^E^Y", $1);
  definekey_reserved ("latex_begin_end (\"theorem\", \"\", 1, 1)", "eH", $1);
  definekey_reserved ("latex_begin_end (\"titlepage\", \"\", 1, 1)",
                      "eg", $1);
  definekey_reserved ("latex_begin_end (\"titlepage\", \"\", 1, 1)",
                      "^E^G", $1);
  definekey_reserved ("latex_begin_end (\"verbatim\", \"\", 1, 1)",
                      "ev", $1);
  definekey_reserved ("latex_begin_end (\"verbatim\", \"\", 1, 1)",
                      "^E^V", $1);
  definekey_reserved ("latex_begin_end (\"verse\", \"\", 1, 1)", "es", $1);
  definekey_reserved ("latex_begin_end (\"verse\", \"\", 1, 1)", "^E^S", $1);
  definekey_reserved ("latex_env_custom", "eC", $1);
  definekey_reserved ("latex_rename_environment", "eN", $1);
  definekey_reserved ("latex_indent_environment", "eD", $1);
  definekey_reserved ("latex_complete_environment", "e\t", $1);
  % fonts - ^CF (normally)
  definekey_reserved ("latex_cmd (\"textrm\", 1)", LaTeX_Font_Key + "r", $1);
  definekey_reserved ("latex_cmd (\"textit\", 1)", LaTeX_Font_Key + "i", $1);
  definekey_reserved ("latex_cmd (\"emph\", 1)",   LaTeX_Font_Key + "e", $1);
  definekey_reserved ("latex_cmd (\"textmd\", 1)", LaTeX_Font_Key + "m", $1);
  definekey_reserved ("latex_cmd (\"textbf\", 1)", LaTeX_Font_Key + "b", $1);
  definekey_reserved ("latex_cmd (\"textup\", 1)", LaTeX_Font_Key + "u", $1);
  definekey_reserved ("latex_cmd (\"textsl\", 1)", LaTeX_Font_Key + "s", $1);
  definekey_reserved ("latex_cmd (\"textsf\", 1)", LaTeX_Font_Key + "f", $1);
  definekey_reserved ("latex_cmd (\"textsc\", 1)", LaTeX_Font_Key + "c", $1);
  definekey_reserved ("latex_cmd (\"texttt\", 1)", LaTeX_Font_Key + "t", $1);
  definekey_reserved ("latex_insert_tags (\"\\\\verb|\", \"|\", 1, 1)", 
                      LaTeX_Font_Key + "v", $1);
  definekey_reserved ("latex_cmd (\"textnormal\", 1)",
                      LaTeX_Font_Key + "n", $1);
  definekey_reserved ("latex_cmd (\"underline\", 1)",
                      LaTeX_Font_Key + "d", $1);
  definekey_reserved ("latex_modify_font (\"\")", LaTeX_Font_Key + "D", $1);
  definekey_reserved ("latex_rename_font", LaTeX_Font_Key + "N", $1);
  definekey_reserved ("latex_cmd (\"textrm\", 1)", LaTeX_Font_Key + "^R", $1);
%  definekey_reserved ("latex_cmd (\"textit\", 1)", LaTeX_Font_Key + "^I", $1);
  definekey_reserved ("latex_cmd (\"emph\", 1)",   LaTeX_Font_Key + "^E", $1);
  definekey_reserved ("latex_cmd (\"textmd\", 1)", LaTeX_Font_Key + "^M", $1);
  definekey_reserved ("latex_cmd (\"textbf\", 1)", LaTeX_Font_Key + "^B", $1);
  definekey_reserved ("latex_cmd (\"textup\", 1)", LaTeX_Font_Key + "^U", $1);
  definekey_reserved ("latex_cmd (\"textsl\", 1)", LaTeX_Font_Key + "^S", $1);
  definekey_reserved ("latex_cmd (\"textsf\", 1)", LaTeX_Font_Key + "^F", $1);
  definekey_reserved ("latex_cmd (\"textsc\", 1)", LaTeX_Font_Key + "^C", $1);
  definekey_reserved ("latex_cmd (\"texttt\", 1)", LaTeX_Font_Key + "^T", $1);
  definekey_reserved ("latex_insert_tags (\"\\\\verb|\", \"|\", 1, 1)", 
                      LaTeX_Font_Key + "^V", $1);
  definekey_reserved ("latex_cmd (\"textnormal\", 1)",
                      LaTeX_Font_Key + "^N", $1);
  definekey_reserved ("latex_cmd (\"underline\", 1)",
                      LaTeX_Font_Key + "^D", $1);
  definekey_reserved ("latex_insert_font", LaTeX_Font_Key + "^I", $1);
  % font size - ^CZ
  definekey_reserved ("latex_cmd (\"tiny\", 1)", "zt", $1);
  definekey_reserved ("latex_cmd (\"tiny\", 1)", "^Z^T", $1);
  definekey_reserved ("latex_cmd (\"scriptsize\", 1)", "zc", $1);
  definekey_reserved ("latex_cmd (\"scriptsize\", 1)", "^Z^C", $1);
  definekey_reserved ("latex_cmd (\"footnotesize\", 1)", "zf", $1);
  definekey_reserved ("latex_cmd (\"footnotesize\", 1)", "^Z^F", $1);
  definekey_reserved ("latex_cmd (\"small\", 1)", "zs", $1);
  definekey_reserved ("latex_cmd (\"small\", 1)", "^Z^S", $1);
  definekey_reserved ("latex_cmd (\"normalsize\", 1)", "zn", $1);
  definekey_reserved ("latex_cmd (\"normalsize\", 1)", "^Z^N", $1);
  definekey_reserved ("latex_cmd (\"large\", 1)", "zl", $1);
  definekey_reserved ("latex_cmd (\"large\", 1)", "^Z^L", $1);
  definekey_reserved ("latex_cmd (\"Large\", 1)", "zL", $1);
  definekey_reserved ("latex_cmd (\"LARGE\", 1)", "zA", $1);
  definekey_reserved ("latex_cmd (\"LARGE\", 1)", "^Z^A", $1);
  definekey_reserved ("latex_cmd (\"huge\", 1)", "zh", $1);
  definekey_reserved ("latex_cmd (\"huge\", 1)", "^Z^H", $1);
  definekey_reserved ("latex_cmd (\"Huge\", 1)", "zH", $1);
  definekey_reserved ("latex_resize_font", "zS", $1);
  % sections - ^CS
  definekey_reserved ("latex_cmd (\"chapter\", 1)", "sc", $1);
  definekey_reserved ("latex_cmd (\"chapter\", 1)", "^S^C", $1);
  definekey_reserved ("latex_cmd (\"section\", 1)", "ss", $1);
  definekey_reserved ("latex_cmd (\"section\", 1)", "^S^S", $1);
  definekey_reserved ("latex_cmd (\"subsection\", 1)", "su", $1);
  definekey_reserved ("latex_cmd (\"subsection\", 1)", "^S^U", $1);
  definekey_reserved ("latex_cmd (\"subsubsection\", 1)", "sb", $1);
  definekey_reserved ("latex_cmd (\"subsubsection\", 1)", "^S^B", $1);
  definekey_reserved ("latex_cmd (\"paragraph\", 1)", "sp", $1);
  definekey_reserved ("latex_cmd (\"paragraph\", 1)", "^S^P", $1);
  definekey_reserved ("latex_cmd (\"subparagraph\", 1)", "sh", $1);
  definekey_reserved ("latex_cmd (\"subparagraph\", 1)", "^S^H", $1);
  definekey_reserved ("latex_cmd (\"part\", 1)", "sa", $1);
  definekey_reserved ("latex_cmd (\"part\", 1)", "^S^A", $1);
  % paragraphs - ^CP
  definekey_reserved ("latex_par_frame", "pr", $1);
  definekey_reserved ("latex_par_frame", "^P^R", $1);
  definekey_reserved ("latex_par_bgcolour", "pb", $1);
  definekey_reserved ("latex_par_bgcolour", "^P^B", $1);
  definekey_reserved ("latex_par_fgcolour", "pf", $1);
  definekey_reserved ("latex_par_fgcolour", "^P^F", $1);
  definekey_reserved ("insert (\"\\\\setlength{\\\\parindent}{0pt}\\n\")",
                      "pi", $1);
  definekey_reserved ("insert (\"\\\\setlength{\\\\parindent}{0pt}\\n\")",
                      "^P^I", $1);
  definekey_reserved ("insert (\"\\\\setlength{\\\\parskip}{3pt}\\n\")",
                      "ps", $1);
  definekey_reserved ("insert (\"\\\\setlength{\\\\parskip}{3pt}\\n\")",
                      "^P^S", $1);
  definekey_reserved ("latex_cmd (\"marginpar\", 1)", "pm", $1);
  definekey_reserved ("latex_cmd (\"marginpar\", 1)", "^P^M", $1);
  definekey_reserved ("latex_cmd (\"footnote\", 1)", "pn", $1);
  definekey_reserved ("latex_cmd (\"footnote\", 1)", "^P^N", $1);
  definekey_reserved ("latex_includegraphics", "pl", $1);
  definekey_reserved ("latex_includegraphics", "^P^L", $1);
  % links - ^CL
  definekey_reserved ("latex_cmd (\"label\", 1)", "ll", $1);
  definekey_reserved ("latex_cmd (\"label\", 1)", "^L^L", $1);
  definekey_reserved ("latex_cmd (\"ref\", 1)", "lr", $1);
  definekey_reserved ("latex_cmd (\"ref\", 1)", "^L^R", $1);
  definekey_reserved ("latex_cmd (\"cite\", 1)", "lc", $1);
  definekey_reserved ("latex_cmd (\"cite\", 1)", "^L^C", $1);
  definekey_reserved ("latex_cmd (\"nocite\", 1)", "ln", $1);
  definekey_reserved ("latex_cmd (\"nocite\", 1)", "^L^N", $1);
  definekey_reserved ("latex_cmd (\"pageref\", 1)", "lp", $1);
  definekey_reserved ("latex_cmd (\"pageref\", 1)", "^L^P", $1);
  definekey_reserved ("latex_url", "lu", $1);
  definekey_reserved ("latex_url", "^L^U", $1);
  definekey_reserved ("latex_index_word", "ii", $1);
  % math common stuff
  definekey_reserved ("latex_insert_tags (\"\\\\frac{\", \"}{}\", 1, 1)",
                      "Mf", $1);
  definekey_reserved ("latex_insert_tags (\"\\\\int_{\", \"}^{}\", 1, 1)",
                      "Mi", $1);
  definekey_reserved ("latex_insert_tags (\"\\\\lim_{\", \"}\", 1, 1)",
                      "Ml", $1);
  definekey_reserved ("latex_insert_tags (\"\\\\oint_{\", \"}^{}\", 1, 1)",
                      "Mo", $1);
  definekey_reserved ("latex_insert_tags (\"\\\\prod_{\", \"}^{}\", 1, 1)",
                      "Mp", $1);
  definekey_reserved ("latex_insert_tags (\"\\\\sum_{\", \"}^{}\", 1, 1)",
                      "Ms", $1);
  definekey_reserved ("latex_insert_tags (\"\\\\sqrt[]{\", \"}\", 1, 1)",
                      "Mq", $1);
  % math arrows - ^C + arrow
  definekey_reserved ("latex_insert (\"uparrow\")", Key_Up, $1);
  definekey_reserved ("latex_insert (\"downarrow\")", Key_Down, $1);
  definekey_reserved ("latex_insert (\"leftarrow\")", Key_Left, $1);
  definekey_reserved ("latex_insert (\"rightarrow\")", Key_Right, $1);
  % breaks - ^CK
  definekey_reserved ("latex_linebreak", "k*", $1);
  definekey_reserved ("latex_linebreak", "^K^*", $1);
  definekey_reserved ("insert (\"\\\\newline\\n\")", "kl", $1);
  definekey_reserved ("insert (\"\\\\newline\\n\")", "^K^L", $1);
  definekey_reserved ("insert (\"\\\\linebreak[1]\\n\")", "kb", $1);
  definekey_reserved ("insert (\"\\\\linebreak[1]\\n\")", "^K^B", $1);
  definekey_reserved ("insert (\"\\\\newpage\\n\")", "kp", $1);
  definekey_reserved ("insert (\"\\\\newpage\\n\")", "^K^P", $1);
  definekey_reserved ("insert (\"\\\\clearpage\\n\")", "kc", $1);
  definekey_reserved ("insert (\"\\\\clearpage\\n\")", "^K^C", $1);
  definekey_reserved ("insert (\"\\\\cleardoublepage\\n\")", "kd", $1);
  definekey_reserved ("insert (\"\\\\cleardoublepage\\n\")", "^K^D", $1);
  definekey_reserved ("insert (\"\\\\pagebreak\\n\")", "kr", $1);
  definekey_reserved ("insert (\"\\\\pagebreak\\n\")", "^K^R", $1);
  definekey_reserved ("insert (\"\\\\nolinebreak[1]\\n\")", "kn", $1);
  definekey_reserved ("insert (\"\\\\nolinebreak[1]\\n\")", "^K^N", $1);
  definekey_reserved ("insert (\"\\\\nopagebreak\\n\")", "ko", $1);
  definekey_reserved ("insert (\"\\\\nopagebreak\\n\")", "^K^O", $1);
  definekey_reserved ("insert (\"\\\\enlargethispage\\n\")", "ke", $1);
  definekey_reserved ("insert (\"\\\\enlargethispage\\n\")", "^K^E", $1);
  % misc
  definekey_reserved ("latex_insert_tags (\"{\", \"}\", 1, 1)", "{", $1);
  definekey_reserved ("latex_insert_math", "m", $1);
  % from tex.sl
  definekey_reserved ("latex_insert_tags (\"``\", \"''\", 1, 1)", "\"", $1);
  %definekey_reserved ("latex_insert_tags (\"`\", \"'\", 1, 1)", "'", $1);
  definekey ("tex_insert_quote", "\"", $1);
  definekey ("tex_insert_quote", "'",  $1);
  definekey ("tex_blink_dollar", "$",  $1);
  definekey ("tex_ldots",        ".",  $1);
  definekey ("latex_arrow", ">", $1);
  definekey ("latex_arrow", "-", $1);
  definekey ("latex_arrow", "=", $1);
  definekey ("tex_complete_symbol", "^[^I", $1); % from the old latex.sl
  definekey ("tex_complete_symbol", "^[v", $1);
  definekey ("tex_complete_symbol", "^[V", $1);
  definekey_reserved ("latex_open_env", "[", $1);
  definekey_reserved ("latex_close_env", "]", $1);
  definekey_reserved ("call (\"newline_and_indent\"); latex_env_item",
                      "^M", $1);
  % special characters
  undefinekey ("^I", $1);
  definekey ("latex_indent_line", "^I", $1);
  definekey_reserved (" \\$", "$", $1);
  definekey_reserved (" \\&", "&", $1);
  definekey_reserved (" \\%", "%", $1);
  definekey_reserved (" \\_", "_", $1);
  definekey_reserved (" \\#", "#", $1);
  definekey_reserved (" \\{", "(", $1);
  definekey_reserved (" \\}", ")", $1);
  definekey_reserved (" \\textless{}", "<", $1);
  definekey_reserved (" \\textgreater{}", ">", $1);
  definekey_reserved (" \\textbackslash{}", "\\", $1);
  definekey_reserved (" \\textbar{}", "|", $1);
  definekey_reserved (" \\textasciicircum{}", "^", $1);
  definekey_reserved (" \\textasciitilde{}", "~", $1);
  % final stuff
  definekey_reserved ("latex_customise",     "C", $1);
  definekey_reserved ("latex_customise",     "^C", $1);
  definekey_reserved ("latex_master_file",   "a", $1);
  definekey_reserved ("latex_master_file",   "^A", $1);
  definekey_reserved ("latex_select_output", "o", $1);
  definekey_reserved ("latex_select_output", "^O", $1);
  definekey_reserved ("latex_compose",       "c", $1);
  definekey_reserved ("latex_compose",       "^C", $1);
  definekey_reserved ("latex_view",          "v", $1);
  definekey_reserved ("latex_view",          "^V", $1);
  definekey_reserved ("latex_psprint",       "r", $1);
  definekey_reserved ("latex_psprint",       "^R", $1);
  definekey_reserved ("latex_bibtex",        "I", $1);
  definekey_reserved ("latex_bibtex",        "^I", $1);
  definekey_reserved ("latex_makeindex",     "x", $1);
  definekey_reserved ("latex_makeindex",     "^X", $1);
  definekey_reserved ("latex_browse_tree",   "d", $1);
  definekey_reserved ("latex_browse_tree",   "^D", $1);
  definekey_reserved ("latex_clearup",       "R", $1);
  % help
  definekey_reserved ("latex_info_help",     "h", $1);
  definekey_reserved ("latex_info_help",     "^H", $1);
  % compiling + errors
  local_unsetkey (Key_F9);
  local_setkey ("latex_compose", Key_F9);
  local_unsetkey (Key_F8);
  local_setkey ("latex_view", Key_F8);
  local_unsetkey (_Reserved_Key_Prefix + "'");
  definekey_reserved ("find_next_error",     "'", $1);
  % move by paragraphs
  definekey_reserved ("latex_goto_next_paragraph", Key_Right, $1);
  definekey_reserved ("latex_goto_prev_paragraph", Key_Left, $1);
}

% -----

$1 = "LaTeX-Mode";
create_syntax_table ($1);

define_syntax ("%", "", '%', $1);     % Comment Syntax
define_syntax ('\\', '\\', $1);       % Quote character
define_syntax ('$', '"', $1);         % string
define_syntax ("~^_&#", '+', $1);     % operators
define_syntax ("|&{}[]", ',', $1);    % delimiters
define_syntax ("a-zA-Z@", 'w', $1);
set_syntax_flags ($1, 8);

% Currently, DFA syntax highlighting doesn't span multiple lines.

#ifdef HAS_DFA_SYNTAX
%%% DFA_CACHE_BEGIN %%%
static define setup_dfa_callback (name)
{
  dfa_enable_highlight_cache ("latex.dfa", name);
  
  % comments:
  dfa_define_highlight_rule ("%.*$", "comment", name);

  % known keywords in curly braces
  dfa_define_highlight_rule ("{article}", "Qstring", name);
  dfa_define_highlight_rule ("{book}", "Qstring", name);
  dfa_define_highlight_rule ("{letter}", "Qstring", name);
  dfa_define_highlight_rule ("{report}", "Qstring", name);
  dfa_define_highlight_rule ("{slides}", "Qstring", name);
  dfa_define_highlight_rule ("{document}", "Qstring", name);
  % environments
  dfa_define_highlight_rule ("{abstract}", "Qstring", name);
  dfa_define_highlight_rule ("{array}", "Qstring", name);
  dfa_define_highlight_rule ("{center}", "Qstring", name);
  dfa_define_highlight_rule ("{description}", "Qstring", name);
  dfa_define_highlight_rule ("{displaymath}", "Qstring", name);
  dfa_define_highlight_rule ("{enumerate}", "Qstring", name);
  dfa_define_highlight_rule ("{eqnarray}", "Qstring", name);
  dfa_define_highlight_rule ("{equation}", "Qstring", name);
  dfa_define_highlight_rule ("{figure}", "Qstring", name);
  dfa_define_highlight_rule ("{flushleft}", "Qstring", name);
  dfa_define_highlight_rule ("{flushright}", "Qstring", name);
  dfa_define_highlight_rule ("{itemize}", "Qstring", name);
  dfa_define_highlight_rule ("{list}", "Qstring", name);
  dfa_define_highlight_rule ("{minipage}", "Qstring", name);
  dfa_define_highlight_rule ("{picture}", "Qstring", name);
  dfa_define_highlight_rule ("{quotation}", "Qstring", name);
  dfa_define_highlight_rule ("{quote}", "Qstring", name);
  dfa_define_highlight_rule ("{tabbing}", "Qstring", name);
  dfa_define_highlight_rule ("{table}", "Qstring", name);
  dfa_define_highlight_rule ("{tabular}", "Qstring", name);
  dfa_define_highlight_rule ("{thebibliography}", "Qstring", name);
  dfa_define_highlight_rule ("{theorem}", "Qstring", name);
  dfa_define_highlight_rule ("{titlepage}", "Qstring", name);
  dfa_define_highlight_rule ("{verbatim}", "Qstring", name);
  dfa_define_highlight_rule ("{verse}", "Qstring", name);
  % font family
  dfa_define_highlight_rule ("{rmfamily}", "Qkeyword2", name);
  dfa_define_highlight_rule ("{itshape}", "Qkeyword2", name);
  dfa_define_highlight_rule ("{mdseries}", "Qkeyword2", name);
  dfa_define_highlight_rule ("{bfseries}", "Qkeyword2", name);
  dfa_define_highlight_rule ("{upshape}", "Qkeyword2", name);
  dfa_define_highlight_rule ("{slshape}", "Qkeyword2", name);
  dfa_define_highlight_rule ("{sffamily}", "Qkeyword2", name);
  dfa_define_highlight_rule ("{scshape}", "Qkeyword2", name);
  dfa_define_highlight_rule ("{ttfamily}", "Qkeyword2", name);
  dfa_define_highlight_rule ("{normalfont}", "Qkeyword2", name);
  
  % everithing else between curly braces
  % !!! doesn't span multiple lines !!!
  dfa_define_highlight_rule ("{.*}", "Qkeyword1", name);
  dfa_define_highlight_rule("^([^{])*}", "Qkeyword1", name);
  dfa_define_highlight_rule("{.*", "keyword1", name);
  
  % short symbols that delimit math: $ \[ \] \( \)
  dfa_define_highlight_rule ("\\$|(\\\\[\\[\\]\\(\\)])", "string", name);

  % Fundamental delimiters in the TeX language: {}[]
  dfa_define_highlight_rule ("[{}\\[\\]]", "delimiter", name);

  % \leftX \rightY constructions where X and Y are
  % one of \| \{ \} [ ] ( ) / | .
  dfa_define_highlight_rule ("\\\\(left|right)(\\\\\\||\\\\{|\\\\}|" + 
                             "[\\[\\]\\(\\)/\\|\\.])",
                             "delimiter", name);

  % type 2 keywords: font definitions
  dfa_define_highlight_rule ("\\\\bfseries", "keyword2", name);
  dfa_define_highlight_rule ("\\\\emph", "keyword2", name);
  dfa_define_highlight_rule ("\\\\itshape", "keyword2", name);
  dfa_define_highlight_rule ("\\\\mathbf", "keyword2", name);
  dfa_define_highlight_rule ("\\\\mathcal", "keyword2", name);
  dfa_define_highlight_rule ("\\\\mathit", "keyword2", name);
  dfa_define_highlight_rule ("\\\\mathnormal", "keyword2", name);
  dfa_define_highlight_rule ("\\\\mathrm", "keyword2", name);
  dfa_define_highlight_rule ("\\\\mathsf", "keyword2", name);
  dfa_define_highlight_rule ("\\\\mathtt", "keyword2", name);
  dfa_define_highlight_rule ("\\\\mdseries", "keyword2", name);
  dfa_define_highlight_rule ("\\\\normalfont", "keyword2", name);
  dfa_define_highlight_rule ("\\\\rmfamily", "keyword2", name);
  dfa_define_highlight_rule ("\\\\scshape", "keyword2", name);
  dfa_define_highlight_rule ("\\\\sffamily", "keyword2", name);
  dfa_define_highlight_rule ("\\\\slshape", "keyword2", name);
  dfa_define_highlight_rule ("\\\\textbf", "keyword2", name);
  dfa_define_highlight_rule ("\\\\textit", "keyword2", name);
  dfa_define_highlight_rule ("\\\\textmd", "keyword2", name);
  dfa_define_highlight_rule ("\\\\textnormal", "keyword2", name);
  dfa_define_highlight_rule ("\\\\textrm", "keyword2", name);
  dfa_define_highlight_rule ("\\\\textsc", "keyword2", name);
  dfa_define_highlight_rule ("\\\\textsf", "keyword2", name);
  dfa_define_highlight_rule ("\\\\textsl", "keyword2", name);
  dfa_define_highlight_rule ("\\\\texttt", "keyword2", name);
  dfa_define_highlight_rule ("\\\\textup", "keyword2", name);
  dfa_define_highlight_rule ("\\\\ttfamily", "keyword2", name);
  dfa_define_highlight_rule ("\\\\upshape", "keyword2", name);
  % size
  dfa_define_highlight_rule ("\\\\tiny", "keyword2", name);
  dfa_define_highlight_rule ("\\\\scriptsize", "keyword2", name);
  dfa_define_highlight_rule ("\\\\footnotesize", "keyword2", name);
  dfa_define_highlight_rule ("\\\\small", "keyword2", name);
  dfa_define_highlight_rule ("\\\\normalsize", "keyword2", name);
  dfa_define_highlight_rule ("\\\\large", "keyword2", name);
  dfa_define_highlight_rule ("\\\\Large", "keyword2", name);
  dfa_define_highlight_rule ("\\\\LARGE", "keyword2", name);
  dfa_define_highlight_rule ("\\\\huge", "keyword2", name);
  dfa_define_highlight_rule ("\\\\Huge", "keyword2", name);
  
  % type 1 keywords: a backslash followed by 
  % one of -,:;!%$#&_ |\/{}~^´'``.=> :
  dfa_define_highlight_rule ("\\\\[\\-,:;!%\\$#&_ \\|\\\\/{}~\\^'`\\.=>]",
                             "keyword1", name);

  % type 0 keywords: a backslash followed by alpha characters
  dfa_define_highlight_rule ("\\\\[A-Za-z@]+", "keyword", name);
  
  % a backslash followed by a single char not covered by one of the
  % previous rules is probably an error
  dfa_define_highlight_rule ("\\\\.", "error", name);

  % The symbols ~ ^ _
  dfa_define_highlight_rule ("[~\\^_]", "operator", name);
  
  % numbers
  dfa_define_highlight_rule ("[0-9]", "number", name);
  dfa_define_highlight_rule ("\\.?[0-9]", "number", name);
  
  % macro parameters (#1 #2 etc)
  dfa_define_highlight_rule ("#[1-9]", "operator", name);

  % quoted strings
  dfa_define_highlight_rule ("``.*''", "Qstring", name);
  dfa_define_highlight_rule("^([^``])*''", "Qstring", name);
  dfa_define_highlight_rule("``.*", "string", name);
  % only one case with single quotes
  dfa_define_highlight_rule ("`.*'", "Qstring", name);
  
  % all the rest
  dfa_define_highlight_rule (".", "normal", name);
  % including fixes for common swedish UTF-8 chars
  dfa_define_highlight_rule("\xC3.", "normal", name);
  dfa_define_highlight_rule("\xC2.", "normal", name);
   
  dfa_build_highlight_table (name);
}
dfa_set_init_callback (&setup_dfa_callback, "LaTeX-Mode");
%%% DFA_CACHE_END %%%
#endif

% -----

%!%+
%\function{latex_mode}
%\synopsis{latex_mode}
%\usage{Void latex_mode ();}
%\description
% This mode is designed to facilitate the task of editing LaTeX files.
% It calls the function \var{latex_mode_hook} if it is defined. In addition,
% if the abbreviation table \var{"TeX"} is defined, that table is used.
%
% There are way too many key-bindings for this mode.
% Please have a look at the menus!
%!%-
public define latex_mode ()
{
  latex_keymap ();
  set_mode ("LaTeX", 0x1 | 0x20);
  set_buffer_hook ("par_sep", "tex_paragraph_separator");
  set_buffer_hook ("wrap_hook", "tex_wrap_hook");

  % latex math mode will map this to something else.
  local_unsetkey ("`");
  local_setkey ("quoted_insert", "`");
  
  mode_set_mode_info ("LaTeX", "init_mode_menu", &init_menu);
  use_syntax_table ("LaTeX-Mode");
  mode_set_mode_info ("LaTeX", "fold_info", "%{{{\r%}}}\r\r");
  run_mode_hooks ("latex_mode_hook");
  if (abbrev_table_p ("LaTeX"))
    use_abbrev_table ("LaTeX");
}

% -----

provide ("latex");

% --- End of file latex.sl
