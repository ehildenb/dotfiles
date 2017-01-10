# maude
# =====

# Detection
# ---------

hook global BufSetOption mimetype=text/x-maude %{
    set buffer filetype maude
}

hook global BufCreate .*[.](maude) %{
    set buffer filetype maude
}

# Highlighters
# ------------

addhl -group / regions -default code maude \
    string   '"'     (?<!\\)(\\\\)*"      '' \
    comment ---\(   \)---              ---\( \
    comment  (---) $                      '' \
    macro   ^\h*?\K# (?<!\\)\n            ''

addhl -group /maude/string  fill string
addhl -group /maude/comment fill comment
addhl -group /maude/macro   fill meta

addhl -group /maude/code regex \b(load|quit|in|eof|popd|pwd|ls|cd|parse|reduce|rewrite|frewrite|erewrite|xmatch)\b 0:meta
addhl -group /maude/code regex \b(mod|endm|fmod|endfm|omod|endom|fth|endfth|th|endth|view|endv)\b 0:keyword
addhl -group /maude/code regex \b(is|protecting|including|extending)\b 0:keyword
addhl -group /maude/code regex \b(sort|sorts|subsort|subsorts|op|ops|var|vars|eq|ceq|rl|crl|md|cmb)\b 0:keyword
addhl -group /maude/code regex \b(Int|Integer|Char|Bool|Float|Double|IO|Void|Addr|Array|String)\b 0:type

# Markdown
# ========

# addhl -group / regions -default content markdown \
#     sh         ```maude   ```                    ''
