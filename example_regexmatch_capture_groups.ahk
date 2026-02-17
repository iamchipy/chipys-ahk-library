text := "
(
This is a test line
Another line with {
One more: line with colon
Yet another (line with paren)
)"

/*
Match Object (RegExMatchInfo) properties:
This(RegExMatch) function returns the position of the leftmost occurrence of NeedleRegEx in the string Haystack. Position 1 is the first character. Zero is returned if the pattern is not found.

Match.Pos, Match.Pos[N] or Match.Pos(N): Returns the position of the overall match or a captured subpattern.
Match.Len, Match.Len[N] or Match.Len(N): Returns the length of the overall match or a captured subpattern.
Match.Name[N] or Match.Name(N): Returns the name of the given subpattern, if it has one.
Match.Count: Returns the overall number of subpatterns (capturing groups), which is also the maximum value for N.
Match.Mark: Returns the NAME of the last encountered (*MARK:NAME), when applicable.
Match[] or Match[N]: Returns the overall match or a captured subpattern.

All of the above allow N to be any of the following:

0 for the overall match.
The number of a subpattern, even one that also has a name.
The name of a subpattern.
Match.N: Shorthand for Match["N"], where N is any unquoted name or number which does not conflict with a defined property (listed above). For example, match.1 or match.Year.

The object also supports enumeration; that is, the for-loop is supported. Alternatively, use Loop Match.Count.
*/

loop parse text, "`n" {
    ; Use RegExMatch with alternation to capture which pattern appears first
    if RegExMatch(A_LoopField, "m:^(?P<colon>.*?:)|^(?P<brace>.*?{)|^(?P<paren>.*?\()", &match) {
        for k, v in match.OwnProps() {
            MsgBox A_Index "`nkey:`t" k "`nvalue:`t" v "`n"
        }

        ; if match.has("colon")
        ;     MsgBox "First match is a line with ':'"
        ; else if match.has("brace")
        ;     MsgBox "First match is a line with '{'"
        ; else if match.has("paren")
        ;     MsgBox "First match is a line with '('"
    } else {
        MsgBox "No matching lines found in:`n" A_LoopField
    }
}