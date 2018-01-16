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

add-highlighter shared/ regions -default code maude \
    string   '"'     (?<!\\)(\\\\)*"      '' \
    comment ---\(   \)---              ---\( \
    comment ---\(   ---\)              ---\( \
    comment  (---) $                      '' \
    macro   ^\h*?\K# (?<!\\)\n            ''

add-highlighter shared/maude/string  fill string
add-highlighter shared/maude/comment fill comment
add-highlighter shared/maude/macro   fill meta

add-highlighter shared/maude/code regex \b(load|quit|in|eof|popd|pwd|ls|cd|parse|reduce|red|rewrite|rew|frewrite|erewrite|xmatch|search)\b 0:meta
add-highlighter shared/maude/code regex \b(mod|endm|fmod|endfm|omod|endom|fth|endfth|th|endth|view|endv)\b 0:keyword
add-highlighter shared/maude/code regex \b(is|protecting|including|extending)\b 0:keyword
add-highlighter shared/maude/code regex \b(sort|sorts|subsort|subsorts|op|ops|var|vars|eq|ceq|rl|crl|md|cmb)\b 0:keyword
add-highlighter shared/maude/code regex \b(assoc|comm|left|right|id|idem|iter|memo|ditto|config|obj|msg|metadata|strat|poly|frozen|prec|gather|format|special|nonexec|otherwise|owise|variant|label|print|id-hook|op-hook|term-hook)\b 0:attribute
add-highlighter shared/maude/code regex \b(QID|CONVERSION|STRING|RAT|FLOAT|COUNTER|INT|RANDOM|NAT|EXT-BOOL|BOOL|TRUTH|BOOL-OPS|TRUTH-VALUE)\b 0:type

# Markdown
# ========

# add-highlighter / regions -default content markdown \
#     sh         ```maude   ```                    ''

# Initialization
# ==============

hook global WinSetOption filetype=maude %[
    add-highlighter ref maude
]

hook global WinSetOption filetype=(?!maude).* %{
    rmhl maude
}
