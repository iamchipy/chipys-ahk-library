; >> >>  >>   >>    >>     >>      ||  VARS  ||      <<     <<    <<   <<  << <<
; >> >>  >>   >>    >>     >>      ||  VARS  ||      <<     <<    <<   <<  << <<
; vv vv  vv   vv    vv     vv      vv        vv      vv     vv    vv   vv  vv vv
run_count := 100000
paste := "
(
Item Class: Amulets
Rarity: Rare
Sol Gorget
Simplex Amulet
--------
Quality (Attribute Modifiers): +20% (augmented)
--------
Requirements:
Level: 64
--------
Item Level: 86
--------
Allocates Primal Spirit (enchant)
--------
{ Implicit Modifier }
-2 Prefix Modifiers allowed (implicit)
-1 Suffix Modifier allowed (implicit)
Implicit Modifiers Cannot Be Changed — Unscalable Value (implicit)
100% increased Explicit Modifier magnitudes — Unscalable Value (implicit)
--------
{ Prefix Modifier "The Shaper's" (Tier: 1) — Damage  — 100% Increased }
1% increased Damage per 15 Intelligence
{ Suffix Modifier "of the Crusade" (Tier: 1) — Attribute  — 120% Increased }
11(9-12)% increased Intelligence
{ Suffix Modifier "of Shaping" (Tier: 1) — Attribute  — 120% Increased }
9(6-9)% increased Attributes
(Attributes are Strength, Dexterity, and Intelligence)
--------
Split
--------
Shaper Item
Crusader Item
)"

; ^^ ^^  ^^   ^^    ^^     ^^      ^^        ^^      ^^     ^^    ^^   ^^  ^^ ^^
; >> >>  >>   >>    >>     >>      ||  VARS  ||      <<     <<    <<   <<  << <<
; >> >>  >>   >>    >>     >>      ||  VARS  ||      <<     <<    <<   <<  << <<

; >> >>  >>   >>    >>     >>      ||  EXEC  ||      <<     <<    <<   <<  << <<
; >> >>  >>   >>    >>     >>      ||  EXEC  ||      <<     <<    <<   <<  << <<
; vv vv  vv   vv    vv     vv      vv        vv      vv     vv    vv   vv  vv vv
function_to_speed_test_a(in_str, filter := "") {
    RegExMatch(in_str, "im){ Prefix Modifier", &m)
    MsgBox m.count " " m.Pos[0] " " m.len[0] " "
    out_string := RegExReplace(in_str, filter, "adds flat ", &repaced_count)
    return repaced_count
}

function_to_speed_test_b(in_str, filter := "") {
    match := {}
    out_string := RegExMatch(in_str, filter, &match)
    if out_string
        return SubStr(in_str, match.pos + match.len)
    return False
}

function_to_speed_test_c(in_str, filter := "") {

}
; ^^ ^^  ^^   ^^    ^^     ^^      ^^        ^^      ^^     ^^    ^^   ^^  ^^ ^^
; >> >>  >>   >>    >>     >>      ||  EXEC  ||      <<     <<    <<   <<  << <<
; >> >>  >>   >>    >>     >>      ||  EXEC  ||      <<     <<    <<   <<  << <<

; runs run_count number of test on each of provided functions to test
; then reports on execustion speed
run_test_on(func_reff_array) {
    if Type(func_reff_array) != "Array"
        MsgBox "Invalid Input, please supply Array[Function_References]"

    report_array := []
    for func_reff in func_reff_array {
        run_times := []
        full_start_tick := A_TickCount
        loop run_count {
            start_tick := A_TickCount
            ; ---------------------- FUNC REFF
            func_reff(paste, "im)^adds.*to.*\)")
            end_tick := A_TickCount
            run_times.push([start_tick, end_tick, end_tick - start_tick])
        }
        full_end_tick := A_TickCount
        avg := 0
        for r in run_times {
            ; avg all run durations
            ; MsgBox r[1] "`n" r[2] "`n" r[3] "`n"
            avg += r[3]
        }
        avg := avg / run_count
        report_array.push([A_Index, avg, full_end_tick - full_start_tick])
    }
    report := ""
    for r in report_array
        report .= "[i:" r[1] "]: ~" r[2] "ms (dur: " r[3] "ms)`n"
    report := "Results for " run_count "x loops of each:`n" report
    A_Clipboard := "/*`n" report "`n*/"
    MsgBox report, "Speed Test Report"

}

run_test_on(
    [
        function_to_speed_test_a,
        function_to_speed_test_b,
        ; function_to_speed_test_c,
    ]
)


/*
Results for 100000x loops of each:
[i:1]: ~0.0032799999999999999ms (dur: 359ms)
[i:2]: ~0.0035899999999999999ms (dur: 375ms)

function_to_speed_test_a(in_str, filter := "") {
    out_string := RegExReplace(in_str, filter, "adds flat ", &repaced_count)
    return repaced_count
}

function_to_speed_test_b(in_str, filter := "") {
    match := {}
    out_string := RegExMatch(in_str, filter, &match)
    if out_string
        return SubStr(in_str, match.pos + match.len)
    return False
}
*/


/*
Results for 100000x loops of each:
[i:1]: ~0.00093000000000000005ms ( total125ms)
[i:2]: ~0.00156ms ( total172ms)
[i:3]: ~0.0011000000000000001ms ( total141ms)

function_to_speed_test_a(in_str) {

    split := StrSplit(in_str, ":")
    if split.Length > 0
        return False
    key := split[1]
    value := split[2]
    return [key, value]
}

function_to_speed_test_b(in_str) {
    i := InStr(in_str, ":")
    if !i
        return False
    split := StrSplit(in_str, ":")
    key := split[1]
    value := split[2]
    return [key, value]
}

function_to_speed_test_c(in_str) {
    i := RegExMatch(in_str, "im):")
    if !i
        return False
    key := SubStr(in_str, 1, i)
    value := SubStr(in_str, i, StrLen(in_str) - i)
    return [key, value]

}
*/
