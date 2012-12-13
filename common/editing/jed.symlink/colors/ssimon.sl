$1 = "default"; $2 = "default";

set_color("normal",     $1,            $2);	       % default fg/bg
set_color("status",     "red"    ,   $2);   % status or mode line
set_color("region",     "yellow","black");   % for marking regions
set_color("operator",   $1,            $2);	       % +, -, etc..
set_color("number",     "brown" ,      $2);        % 10, 2.71,... TeX formulas
set_color("comment",    "blue",        $2);        % /* comment */
set_color("string",     "yellow"      ,$2);        % "string" or 'char'
set_color("keyword",    "magenta"  ,   $2);        % if, while, unsigned, ...
set_color("keyword1",   "green"    ,   $2);        % malloc, exit, etc...
set_color("delimiter",  $1,            $2);	       % {}[](),.;...
set_color("preprocess", "brightblue",  $2);        % #ifdef ....
set_color("message",    $1,            $2);        % color for messages
set_color("error",      "red"      ,   $2);        % color for errors
set_color("dollar",     "magenta"  ,   $2);        % color dollar sign continuat$
set_color("...",        "brightred",   $2);	       % folding indicator

set_color ("menu_char",          "lightgray", "gray" );
set_color ("menu",               "white"    , "gray" );
set_color ("menu_popup",         "white"    , "gray" );
set_color ("menu_shadow",        "gray" ,     "black"    );
set_color ("menu_selection",     "white"    , "blue"     );
set_color ("menu_selection_char","lightgray", "blue"     );

set_color ("cursor",    "magenta"  , "gray" );
set_color ("cursorovr", "magenta"  , "gray" );

%% The following have been automatically generated:
set_color("linenum", "gray"    , $2 );
set_color("trailing_whitespace", "brightcyan", $2);
set_color("tab", "brightcyan", $2);
set_color("url", "brightgreen", $2);
set_color("italic", $1, $2);
set_color("underline", "green"    , $2);
set_color("bold", "brightred", $2);
set_color("html", "brightred", $2);
set_color("keyword2", $1, $2);
set_color("keyword3", $1, $2);
set_color("keyword4", $1, $2);
set_color("keyword5", $1, $2);
set_color("keyword6", $1, $2);
set_color("keyword7", $1, $2);
set_color("keyword8", $1, $2);
set_color("keyword9", $1, $2);
