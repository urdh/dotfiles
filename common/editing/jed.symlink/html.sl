% File:          html.sl      -*- SLang -*-
%
% Author:        Guido Gonzato, <guido dot gonzato at poste dot it>
% 
% Version:       1.0.1
% 
% Description:   this mode is designed to facilitate the editing of
%                HTML files. For Jed 0.99.18+.
%
% Last updated:	 5 December 2006

WRAP_INDENTS = 1; % you really want this

custom_variable ("HTML_INDENT", 2);
custom_variable ("Html_View_Cmd", "firefox");

static variable TRUE         = 1;
static variable FALSE        = 0;
static variable NO_PUSH_SPOT = FALSE;
static variable PUSH_SPOT    = TRUE;
static variable NO_POP_SPOT  = FALSE;
static variable POP_SPOT     = TRUE;
static variable NEWLINE      = TRUE;
static variable NO_NEWLINE   = FALSE;

% ----- %

% movement

define html_skip_tag ()
{
  go_right_1 ();
  () = fsearch_char ('<');
}

define html_bskip_tag ()
{
  () = bsearch_char ('<');
}  

static define html_paragraph_separator ()
{
  variable cs = CASE_SEARCH;
  bol_skip_white ();
  CASE_SEARCH = 0;
  eolp () or ffind ("<p>") or ffind ("</p>");
  CASE_SEARCH = cs;
}

% inserting stuff

static define html_insert_pair_around_region (tag1, tag2)
{
  check_region (1);
  exchange_point_and_mark ();
  insert (tag1);
  exchange_point_and_mark ();
  insert (tag2);
  pop_spot ();
  pop_mark_0 ();
}

% insert a pair of tags as a single line
static define html_insert_tags (tag, newline, do_push_spot, do_pop_spot)
{
  variable tag1, tag2;
  tag1 = sprintf ("<%s>", tag);
  if (TRUE == newline)
    tag2 = sprintf ("</%s>\n", tag);
  else
    tag2 = sprintf ("</%s>", tag);
  
  % if the current position is within a word, then select it
  if (0 == string_match (" \t\\\n", char (what_char ()), 1)) {
    % ok, the cursor is on a space
    () = right (1);
    bskip_word ();
    push_mark ();
    skip_word ();
  }
  % if a region is defined, insert the tags around it
  if (markp () ) {
    html_insert_pair_around_region (tag1, tag2);
    return;
  }
  insert (tag1);
  if (do_push_spot)
    push_spot ();
  insert (tag2);
  if (do_pop_spot)
    pop_spot ();
}

% insert a pair of tags as an 'environment'
static define html_insert_tags_env (tag, do_push_spot, do_pop_spot)
{
  variable tag1, tag2;
  tag1 = sprintf ("<%s>\n", tag);
  tag2 = sprintf ("</%s>\n", tag);
  
  variable col = what_column () - 1;
  if (markp () ) {
    html_insert_pair_around_region (tag1, tag2);
    return;
  }
  insert (tag1);
  insert_spaces (col + HTML_INDENT);
  if (do_push_spot)
    push_spot ();
  insert ("\n");
  insert_spaces (col);
  insert (tag2);
  if (do_pop_spot)
    pop_spot ();
}

% insert a pair of different tags as a single line
static define html_insert_different_tags
  (tag1, tag2, newline, do_push_spot, do_pop_spot)
{
  if (TRUE == newline)
    tag2 = tag2 + "\n";
  
  % if the current position is within a word, then select it
  if (0 == string_match (" \t\\\n", char (what_char ()), 1)) {
    % ok, the cursor is on a space
    () = right (1);
    bskip_word ();
    push_mark ();
    skip_word ();
  }
  % if a region is defined, insert the tags around it
  if (markp () ) {
    html_insert_pair_around_region (tag1, tag2);
    return;
  }
  insert (tag1);
  if (do_push_spot)
    push_spot ();
  insert (tag2);
  if (do_pop_spot)
    pop_spot ();
}

% ----- let's start: public functions

% paragraphs

define html_shortpara ()
{
  insert ("<p>\n");
}

define html_para ()
{
  html_insert_tags_env ("p", PUSH_SPOT, POP_SPOT);
}

define html_break ()
{
  insert ("<br>\n");
}

define html_hrule ()
{
  insert ("<hr size=1 width=\"80%\">\n");
}

define html_blockquote ()
{
  html_insert_tags_env ("blockquote", PUSH_SPOT, POP_SPOT);
}

define html_pre ()
{
  html_insert_tags_env ("pre", PUSH_SPOT, POP_SPOT);
}

define html_title (do_push_spot, do_pop_spot)
{
  html_insert_tags ("title", NEWLINE, do_push_spot, do_pop_spot);
}

% headings

define html_heading_1 ()
{
  html_insert_tags ("h1", NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_heading_2 ()
{
  html_insert_tags ("h2", NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_heading_3 ()
{
  html_insert_tags ("h3", NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_heading_4 ()
{
  html_insert_tags ("h4", NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_heading_5 ()
{
  html_insert_tags ("h5", NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_heading_6 ()
{
  html_insert_tags ("h6", NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_template ()
{
  variable col = what_column () - 1;
  insert ("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n\n");
  insert ("<html>\n\n<head>\n");
  insert_spaces (col + HTML_INDENT);
  html_title (PUSH_SPOT, NO_POP_SPOT);
  insert ("</head>\n\n<body bgcolor=white" +
          " text=\"#0000ff\">\n\n</body>\n\n</html>");
  pop_spot ();
}

define html_frameset (push_spot, pop_spot)
{
    html_insert_different_tags ("<frameset cols=\"20%, 80%\">\n\n",
                                "</frameset>\n",
                                NEWLINE, push_spot, pop_spot);
}

define html_frame (push_spot, pop_spot)
{
  html_insert_different_tags ("<frame src=\"",
                              "\">",
                              NEWLINE, push_spot, pop_spot);
}

define html_template_with_frames ()
{
  variable col = what_column () - 1;
  insert ("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Frameset//EN\"\n");
  insert ("  \"http://www.w3.org/TR/html4/frameset.dtd\">\n\n");
  insert ("<html>\n\n<head>\n");
  insert_spaces (col + HTML_INDENT);
  html_title (PUSH_SPOT, POP_SPOT);
  insert ("</head>\n\n");
  insert ("<frameset cols=\"20%, 80%\">\n");
  html_frame (NO_PUSH_SPOT, NO_POP_SPOT);
  html_frame (NO_PUSH_SPOT, NO_POP_SPOT);
  insert ("<noframes>\n</noframes>\n");
  insert ("</frameset>\n\n</html>\n");
}

% font

define html_font ()
{
  html_insert_different_tags ("<font size=\"",
                              "\" color=\"\" face=\"\">\n" + 
                              "\n</font>",
                              NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_address ()
{
  html_insert_tags ("address", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_big ()
{
  html_insert_tags ("big", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_small ()
{
  html_insert_tags ("small", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_sup ()
{
  html_insert_tags ("sub", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_sub ()
{
  html_insert_tags ("sup", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_bold ()
{
  html_insert_tags ("b", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_cite ()
{
  html_insert_tags ("cite", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_definition ()
{
  html_insert_tags ("dfn", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_emphasis ()
{
  html_insert_tags ("em", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_italics ()
{
  html_insert_tags ("i", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_keyboard ()
{
  html_insert_tags ("kbd", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_code ()
{
  html_insert_tags ("code", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_sample ()
{
  html_insert_tags ("samp", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_typewriter ()
{
  html_insert_tags ("tt", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_strong ()
{
  html_insert_tags ("strong", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_uline ()
{
  html_insert_tags ("u", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_var ()
{
  html_insert_tags ("var", NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

% anchors

define html_href ()
{
  html_insert_different_tags ("<a href=\"", "\"></a>",
                              NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_name ()
{
  html_insert_different_tags ("<a name=\"", "\"></a>",
                              NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

% lists

define html_dir ()
{
  html_insert_tags_env ("dir", PUSH_SPOT, POP_SPOT);
}

define html_li ()
{
  insert ("<li>");
}

define html_menu ()
{
  html_insert_tags_env ("menu", PUSH_SPOT, POP_SPOT);
}

define html_ol ()
{
  html_insert_tags_env ("ol", PUSH_SPOT, POP_SPOT);
}

define html_ul ()
{
  html_insert_tags_env ("ul", PUSH_SPOT, POP_SPOT);
}

define html_dl ()
{
  html_insert_different_tags ("<dl compact>\n", "</dl>",
                              NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

define html_dt ()
{
  variable col = what_column () - 1;
  insert ("<dt>");
  push_spot ();
  insert ("\n");
  insert_spaces (col + HTML_INDENT);
  insert ("<dd>");
  pop_spot ();
}

% alignments

define html_align_left ()
{
  insert (" align=left");
}

define html_align_centre ()
{
  insert (" align=center");
}

define html_align_right ()
{
  insert (" align=right");
}

define html_valign_top ()
{
  insert (" valign=top");
}

define html_valign_middle ()
{
  insert (" valign=middle");
}

define html_valign_bottom ()
{
  insert (" valign=bottom");
}

% tables

static variable table_columns = 3;

define html_ask_table_rows ()
{
  variable 
    ok = 0,
    col = what_column () - 1,
    i, table_col_str;
  
  while (0 == ok) {
    table_col_str = read_mini ("Columns?", Null_String, "3");
    table_columns = table_col_str [0] - '0';
    if ( (table_columns > 1) and (table_columns < 10) )
      ok = 1;
    !if (ok) {
      beep ();
      message ("Wrong value! ");
    }
  }
}

define html_table_row (tag, do_push_spot)
{
  variable i, col = what_column () - 1;
  insert ("<tr>\n");
  for (i = 0; i < table_columns; i++) {
    insert_spaces (col + HTML_INDENT);
    insert ("<" + tag + ">");
    if ( (do_push_spot) and (0 == i) )
      push_spot ();
    insert ("</" + tag + ">\n");
  }
  insert_spaces (col);
  insert ("</tr>\n");
}

define html_table ()
{
  html_ask_table_rows ();
  insert ("<table border=1 cellpadding=1 cellspacing=5>\n\n<caption>\n\n");
  push_spot ();
  insert ("</caption>\n\n<thead>\n\n<tfoot>\n\n<tbody>\n\n");
  html_table_row ("th", NO_PUSH_SPOT);
  html_table_row ("td", NO_PUSH_SPOT);
  insert ("\n</table>");
  pop_spot ();
}

% image

define html_image ()
{
  html_insert_different_tags ("<img src=\"", 
                              "\" alt=\"\" width=\"\" height=\"\" " + 
                              "hspace=\"\" vspace=\"\" border=\"\">",
                              NO_NEWLINE, PUSH_SPOT, POP_SPOT);
}

% misc

define html_view ()
{
  variable cmd, abc_file, abc_file_dir;
  
  (abc_file, abc_file_dir,,) = getbuf_info ();
  cmd = sprintf ("%s %s", Html_View_Cmd,
                 dircat (abc_file_dir, abc_file));
  if (0 != run_shell_cmd (cmd))
    error ("Could not start browser!");
}

% let's finish

% defining keywords is not necessary, since all the highlighting is
% done by the second and third define_syntax (). Rough, but fairly nice.

$1 = "html";
create_syntax_table ($1);
!if (keymap_p ($1)) 
  make_keymap ($1);
define_syntax ("\"([{<", "\")]}>", '(', $1);
define_syntax ('<', '\\', $1);
define_syntax ('&', '\\', $1);
define_syntax ("0-9A-Za-z>/!", 'w', $1);
define_syntax ("<>", '<', $1);

create_syntax_table ($1);
define_syntax ("<", ">", '(', $1);     %  make these guys blink match
define_syntax ("<>", '<', $1);
define_syntax ("<!-", "-->", '%', $1);
define_syntax ("A-Za-z&", 'w', $1);
define_syntax ('#', '#', $1);
set_syntax_flags ($1, 4);

#ifdef HAS_DFA_SYNTAX
% The highlighting copes with comments, "&eth;" type things, and <argh> type
% HTML tags. An unrecognised &..; construct or an incomplete <...> construct
% is flagged in delimiter colour.
%%% DFA_CACHE_BEGIN %%%
static define setup_dfa_callback (name)
{
  dfa_enable_highlight_cache ("html.dfa", name);
  dfa_define_highlight_rule ("<!.*-[ \t]*>", "Qcomment", name);
  dfa_define_highlight_rule ("^([^\\-]|-+[^>])*-+[ \t]*>", "Qcomment", name);
  dfa_define_highlight_rule ("<!.*", "comment", name);
  dfa_define_highlight_rule ("<([^>\"]|\"[^\"]*\")*>", "keyword", name);
  dfa_define_highlight_rule ("<([^>\"]|\"[^\"]*\")*(\"[^\"]*)?$", "delimiter", 
			     name);
  dfa_define_highlight_rule ("&#[0-9]+;", "keyword1", name);
  dfa_define_highlight_rule ("&[A-Za-z]+;", "Kdelimiter", name);
  dfa_define_highlight_rule (".", "normal", name);
  dfa_build_highlight_table (name);
}
dfa_set_init_callback (&setup_dfa_callback, "html");
%%% DFA_CACHE_END %%%
#endif

() = define_keywords ($1, "&gt&lt", 3);
() = define_keywords ($1, "&ETH&amp&eth", 4);
() = define_keywords ($1, "&Auml&Euml&Iuml&Ouml&Uuml" + 
                      "&auml&euml&iuml&nbsp&ouml&quot&uuml&yuml", 5);
() = define_keywords ($1,
  "&AElig&Acirc&Aring&Ecirc&Icirc&Ocirc&THORN&Ucirc&acirc" + 
  "&aelig&aring&ecirc&icirc&ocirc&szlig&thorn&ucirc", 6);
() = define_keywords ($1, 
  "&Aacute&Agrave&Atilde&Ccedil&Eacute&Egrave&Iacute&Igrave" + 
  "&Ntilde&Oacute&Ograve&Oslash&Otilde&Uacute&Ugrave&Yacute" + 
  "&aacute&agrave&atilde&ccedil&dollar&eacute&egrave&iacute&igrave" +
  "&ntilde&oacute&ograve&oslash&otilde&uacute&ugrave&yacute", 7);

define init_menu (menu)
{
  % header
  menu_append_popup (menu, "&Headings");
  $1 = sprintf ("%s.&Headings", menu);
  menu_append_item ($1, "&Template", "html_template");
  menu_append_item ($1, "&Frameset Template", "html_template_with_frames");
  menu_append_item ($1, "H&1", "html_heading_1");
  menu_append_item ($1, "H&2", "html_heading_2");
  menu_append_item ($1, "H&3", "html_heading_3");
  menu_append_item ($1, "H&4", "html_heading_4");
  menu_append_item ($1, "H&5", "html_heading_5");
  menu_append_item ($1, "H&6", "html_heading_6");
  menu_append_popup (menu, "&Paragraph Styles");
  $1 = sprintf ("%s.&Paragraph Styles", menu);
  menu_append_item ($1, "&Break", "html_break");
  menu_append_item ($1, "&Hrule", "html_hrule");
  menu_append_item ($1, "&Paragraph", "html_para");
  menu_append_item ($1, "&paragraph (short)", "html_shortpara");
  menu_append_item ($1, "Block&quote", "html_blockquote");
  menu_append_item ($1, "P&re", "html_pre");
  menu_append_popup (menu, "&Font Styles");
  $1 = sprintf ("%s.&Font Styles", menu);
  menu_append_item ($1, "&Address", "html_address");
  menu_append_item ($1, "&Bold", "html_bold");
  menu_append_item ($1, "Big", "html_big");
  menu_append_item ($1, "&Cite", "html_cite");
  menu_append_item ($1, "&Definition", "html_definition");
  menu_append_item ($1, "&Emphasis", "html_emphasis");
  menu_append_item ($1, "&Font...", "html_font");
  menu_append_item ($1, "&Italics", "html_italics");
  menu_append_item ($1, "&Keyboard", "html_keyboard");
  menu_append_item ($1, "C&ode", "html_code");
  menu_append_item ($1, "&Sample", "html_sample");
  menu_append_item ($1, "Small", "html_small");
  menu_append_item ($1, "Sub", "html_sub");
  menu_append_item ($1, "Sup", "html_sup");
  menu_append_item ($1, "&Typewriter", "html_typewriter");
  menu_append_item ($1, "St&rong", "html_strong");
  menu_append_item ($1, "&Uline", "html_uline");
  menu_append_item ($1, "&Variable", "html_var");
  menu_append_popup (menu, "Alig&n");
  $1 = sprintf ("%s.Alig&n", menu);
  menu_append_item ($1, "Align=&Left",    "html_align_left");
  menu_append_item ($1, "Align=&Center",  "html_align_centre");
  menu_append_item ($1, "Align=&Right",   "html_align_right");
  menu_append_item ($1, "Valign=&Top",    "html_valign_top");
  menu_append_item ($1, "Valign=&Middle", "html_valign_middle");
  menu_append_item ($1, "Valign=&Bottom", "html_valign_bottom");
  menu_append_popup (menu, "&Anchors");
  $1 = sprintf ("%s.&Anchors", menu);
  menu_append_item ($1, "&Href", "html_href");
  menu_append_item ($1, "&Name", "html_name");
  menu_append_popup (menu, "&Lists");
  $1 = sprintf ("%s.&Lists", menu);
  menu_append_item ($1, "&Dl", "html_dl");
  menu_append_item ($1, "D&t", "html_dt");
  menu_append_item ($1, "&Li",  "html_li");
  menu_append_item ($1, "&Menu","html_menu");
  menu_append_item ($1, "&Ordered", "html_ol");
  menu_append_item ($1, "&Unordered", "html_ul");
  menu_append_popup (menu, "&Table");
  $1 = sprintf ("%s.&Table", menu);
  menu_append_item ($1, "&Table", "html_table");
  menu_append_item ($1, "Table &Row", "html_table_row (\"TD\", 1)");
  menu_append_item ($1, "&Colspan", "insert (\"COLSPAN=\")");
  menu_append_item ($1, "Row&span", "insert (\"ROWSPAN=\")");
  menu_append_item ($1, "&Nowrap", "insert (\"NOWRAP=\")");
  menu_append_popup (menu, "F&rames");
  $1 = sprintf ("%s.F&rames", menu);
  menu_append_item ($1, "<frame&set>", "html_frameset (1, 1)");
  menu_append_item ($1, "<&frame>", "html_frame (1, 1)");
  menu_append_popup (menu, "&Image");
  $1 = sprintf ("%s.&Image", menu);
  menu_append_item ($1, "&Image", "html_image");
  menu_append_separator (menu);
  % convert to...
  menu_append_item (menu, "&View HTML", "html_view");
}

define html_keymap ()
{
  $1 = "html";
  !if (keymap_p ($1))
    make_keymap ($1);
  use_keymap ($1);

  % headings
  definekey_reserved ("html_bskip_tag", "^B", $1);
  definekey_reserved ("html_skip_tag", "^F", $1);
  % paragraph styles
  definekey_reserved ("html_break",       "pb", $1);
  definekey_reserved ("html_hrule",       "ph", $1);
  definekey_reserved ("html_shortpara",   "pp", $1);
  definekey_reserved ("html_para",        "pP", $1);
  definekey_reserved ("html_blockquote",  "pq", $1);
  definekey_reserved ("html_pre",         "pr", $1);
  % headings
  definekey_reserved ("html_heading_1", "h1", $1);
  definekey_reserved ("html_heading_2", "h2", $1);
  definekey_reserved ("html_heading_3", "h3", $1);
  definekey_reserved ("html_heading_4", "h4", $1);
  definekey_reserved ("html_heading_5", "h5", $1);
  definekey_reserved ("html_heading_6", "h6", $1);
  definekey_reserved ("html_template",  "ht", $1);
  definekey_reserved ("html_template_with_frames",  "hf", $1);
  % frames
  definekey_reserved ("html_frameset",   "rs", $1);
  definekey_reserved ("html_frame",      "rf", $1);
  % fonts
  definekey_reserved ("html_address",    "fa", $1);
  definekey_reserved ("html_bold",       "fb", $1);
  definekey_reserved ("html_cite",       "fc", $1);
  definekey_reserved ("html_definition", "fd", $1);
  definekey_reserved ("html_emphasis",   "fe", $1);
  definekey_reserved ("html_font",       "ff", $1);
  definekey_reserved ("html_italics",    "fi", $1);
  definekey_reserved ("html_keyboard",   "fk", $1);
  definekey_reserved ("html_code",       "fo", $1);
  definekey_reserved ("html_sample",     "fs", $1);
  definekey_reserved ("html_typewriter", "ft", $1);
  definekey_reserved ("html_strong",     "fr", $1);
  definekey_reserved ("html_uline",      "fu", $1);
  definekey_reserved ("html_var",        "fv", $1);
  % alignments
  definekey_reserved ("html_align_left",   "nl", $1);
  definekey_reserved ("html_align_centre", "nc", $1);
  definekey_reserved ("html_align_right",  "nr", $1);
  definekey_reserved ("html_valign_top",   "nt", $1);
  definekey_reserved ("html_valign_middle","nm", $1);
  definekey_reserved ("html_valign_bottom","nb", $1);
  % anchors
  definekey_reserved ("html_href",     "ah", $1);
  definekey_reserved ("html_name",     "an", $1);
  % lists
  definekey_reserved ("html_dl",       "ld", $1);
  definekey_reserved ("html_dt",       "lt", $1);
  definekey_reserved ("html_li",       "ll", $1);
  definekey_reserved ("html_menu",     "lm", $1);
  definekey_reserved ("html_ol",       "lo", $1);
  definekey_reserved ("html_ul",       "lu", $1);
  % table
  definekey_reserved ("html_table",    "tt", $1);
  definekey_reserved ("html_table_row (\"TD\", 1)","tr", $1);
  % image
  definekey_reserved ("html_image",    "i", $1);
  % view
  definekey_reserved ("html_view",     "v", $1);
  % special characters
% #ifdef WIN32
%   undefinekey ("�", $1); % prevent clash with arrow keys
% #endif
  local_setkey ("insert (\"&dollar;\")", "$");
  local_setkey ("insert (\"&amp;\")",    "&");
  local_setkey ("insert (\"&lt;\")",     "<");
  local_setkey ("insert (\"&gt;\")",     ">");
  % Unicode, see http://www.unicode.org/charts/
  local_setkey ("insert (\"&iexcl;\")", "¡");
  local_setkey ("insert (\"&cent;\")",   "¢");
  local_setkey ("insert (\"&pound;\")",  "£");
  local_setkey ("insert (\"&curren;\")", "¤");
  local_setkey ("insert (\"&yen;\")",    "¥");
  local_setkey ("insert (\"&brvbar;\")", "¦");
  local_setkey ("insert (\"&sect;\")",   "§");
  local_setkey ("insert (\"&uml;\")",    "¨");
  local_setkey ("insert (\"&copy;\")",   "©");
  local_setkey ("insert (\"&ordf;\")",   "ª");
  local_setkey ("insert (\"&laquo;\")",  "«");
  local_setkey ("insert (\"&not;\")",    "¬");
  local_setkey ("insert (\"&reg;\")",    "®");
  local_setkey ("insert (\"&macr;\")",   "¯");
  local_setkey ("insert (\"&deg;\")",    "°");
  local_setkey ("insert (\"&plusmn;\")", "±");
  local_setkey ("insert (\"&sup2;\")",   "²");
  local_setkey ("insert (\"&sup3;\")",   "³");
  local_setkey ("insert (\"&acute;\")",  "´");
  local_setkey ("insert (\"&micro;\")",  "µ");
  local_setkey ("insert (\"&para;\")",   "¶");
  local_setkey ("insert (\"&middot;\")", "·");
  local_setkey ("insert (\"&cedil;\")",  "¸");
  local_setkey ("insert (\"&sup1;\")",   "¹");
  local_setkey ("insert (\"&ordm;\")",   "º");
  local_setkey ("insert (\"&ranquo;\")", "»");
  local_setkey ("insert (\"&frac14;\")", "¼");
  local_setkey ("insert (\"&frac12;\")", "½");
  local_setkey ("insert (\"&frac34;\")", "¾");
  local_setkey ("insert (\"&iquest;\")", "¿");
  local_setkey ("insert (\"&Agrave;\")", "À");
  local_setkey ("insert (\"&Aacute;\")", "Á");
  local_setkey ("insert (\"&Acirc;\")",  "Â");
  local_setkey ("insert (\"&Atilde;\")", "Ã");
  local_setkey ("insert (\"&Auml;\")",   "Ä");
  local_setkey ("insert (\"&Aring;\")",  "Å");
  local_setkey ("insert (\"&AElig;\")",  "Æ");
  local_setkey ("insert (\"&Ccedil;\")", "Ç");
  local_setkey ("insert (\"&Egrave;\")", "È");
  local_setkey ("insert (\"&Eacute;\")", "É");
  local_setkey ("insert (\"&Ecirc;\")",  "Ê");
  local_setkey ("insert (\"&Euml;\")",   "Ë");
  local_setkey ("insert (\"&Igrave;\")", "Ì");
  local_setkey ("insert (\"&Iacute;\")", "Í");
  local_setkey ("insert (\"&Icirc;\")",  "Î");
  local_setkey ("insert (\"&Iuml;\")",   "Ï");
  local_setkey ("insert (\"&ETH;\")",    "Ð");
  local_setkey ("insert (\"&Ntilde;\")", "Ñ");
  local_setkey ("insert (\"&Ograve;\")", "Ò");
  local_setkey ("insert (\"&Oacute;\")", "Ó");
  local_setkey ("insert (\"&Ocirc;\")",  "Ô");
  local_setkey ("insert (\"&Otilde;\")", "Õ");
  local_setkey ("insert (\"&Ouml;\")",   "Ö");
  local_setkey ("insert (\"&Oslash;\")", "Ø");
  local_setkey ("insert (\"&Ugrave;\")", "Ù");
  local_setkey ("insert (\"&Uacute;\")", "Ú");
  local_setkey ("insert (\"&Ucirc;\")",  "Û");
  local_setkey ("insert (\"&Uuml;\")",   "Ü");
  local_setkey ("insert (\"&Yacute;\")", "Ý");
  local_setkey ("insert (\"&THORN;\")",  "Þ");
  local_setkey ("insert (\"&szlig;\")",  "ß");
  local_setkey ("insert (\"&agrave;\")", "à");
  local_setkey ("insert (\"&aacute;\")", "á");
  local_setkey ("insert (\"&acirc;\")",  "â");
  local_setkey ("insert (\"&atilde;\")", "ã");
  local_setkey ("insert (\"&auml;\")",   "ä");
  local_setkey ("insert (\"&aring;\")",  "å");
  local_setkey ("insert (\"&aelig;\")",  "æ");
  local_setkey ("insert (\"&ccedil;\")", "ç");
  local_setkey ("insert (\"&egrave;\")", "è");
  local_setkey ("insert (\"&eacute;\")", "é");
  local_setkey ("insert (\"&ecirc;\")",  "ê");
  local_setkey ("insert (\"&euml;\")",   "ë");
  local_setkey ("insert (\"&igrave;\")", "ì");
  local_setkey ("insert (\"&iacute;\")", "í");
  local_setkey ("insert (\"&icirc;\")",  "î");
  local_setkey ("insert (\"&iuml;\")",   "ï");
  local_setkey ("insert (\"&eth;\")",    "ð");
  local_setkey ("insert (\"&ntilde;\")", "ñ");
  local_setkey ("insert (\"&ograve;\")", "ò");
  local_setkey ("insert (\"&oacute;\")", "ó");
  local_setkey ("insert (\"&ocirc;\")",  "ô");
  local_setkey ("insert (\"&otilde;\")", "õ");
  local_setkey ("insert (\"&ouml;\")",   "ö");
  local_setkey ("insert (\"&oslash;\")", "ø");
  local_setkey ("insert (\"&ugrave;\")", "ù");
  local_setkey ("insert (\"&uacute;\")", "ú");
  local_setkey ("insert (\"&ucirc;\")",  "û");
  local_setkey ("insert (\"&uuml;\")",   "ü");
  local_setkey ("insert (\"&yacute;\")", "ý");
  local_setkey ("insert (\"&thorn;\")",  "þ");
  local_setkey ("insert (\"&yuml;\")",   "ÿ");
  % special characters, literally
  definekey_reserved (" &nbsp;", " ",  $1);
  definekey_reserved (" &",      "&",  $1);
  definekey_reserved (" >",      ">",  $1);
  definekey_reserved (" <",      "<",  $1);
  set_syntax_flags ($1, 8);
  use_syntax_table ($1);
}

%!%+
%\function{html_mode}
%\synopsis{html_mode}
%\usage{Void html_mode ();}
%\description
% This mode is designed to facilitate the editing of html files.
% If a region is defined (i.e., if a mark is set), many HTML tags will
% insert around the region; e.g. '<B>' and '</B>'. Tags are
% inserted either using the Mode menu, or with a key combination resembling 
% the menu entry, e.g. ^Cfb inserts <emphasis> (M&ode/&Fonts/<&B>).
% Variables affecting this mode include:
%#v+
%  Variable                  Default value
%
%  HTML_INDENT               2
%  Html_View_Cmd            "netscape"
%#v-
% To change the value of a variable, define that variable in .jedrc
% before loading html.sl. For example:
%#v+
%  variable HTML_INDENT = 3;
%#v-
% Hooks: \var{html_mode_hook}
%!%-
define html_mode ()
{
  variable mode = "html";

  set_mode (mode, 1); % wrap mode
  html_keymap ();
  set_buffer_hook ("par_sep", &html_paragraph_separator);
  mode_set_mode_info (mode, "init_mode_menu", &init_menu);
  run_mode_hooks ("html_mode_hook");
}

% --- End of file html.sl ---
