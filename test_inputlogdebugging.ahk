InstallMouseHook
InstallKeybdHook
Persistent
#SingleInstance


#Include chipys-ahk-library.ahk
LOG_LEVEL := 1
alert_up := true
prevent_mutli := true
block_duration := 500
LOG_PATH := "inputloggin.log"

; Double click // multi input detection
input_repetition_detect(input_to_watch := "RButton", repeat_delay_threshold := 500, log_fail_ratio := true) {
    break_signal := false
    last_tick := A_TickCount
    detected_single := 0
    detected_multi := 0

    msgbox "Starting repition detection for '" input_to_watch "' (<" repeat_delay_threshold "ms)"

    while not break_signal {
        ; tooltip "-"
        ; wait for input detection
        KeyWait input_to_watch, "D"
        ; wait for press to complete
        KeyWait input_to_watch

        if prevent_mutli {
            ; tooltip "+"
            BlockInput "Mouse"
            sleep repeat_delay_threshold
            BlockInput false
        }


        ; log time_since
        ms_since_last := A_TickCount - last_tick
        last_tick := A_TickCount
        ; log input
        if ms_since_last < repeat_delay_threshold {
            ; Log double click
            ; if alert_up
            ToolTip "(" ms_since_last ")"
            tooltip_timeout(500)
            Log("Multi-Input of '" input_to_watch "' (" ms_since_last "/" repeat_delay_threshold " ms  ||  " Floor(100 * (detected_multi / (detected_single + detected_multi))) "%" detected_single + detected_multi ")")
            detected_multi += 1
        } else {
            ; ToolTip ms_since_last
            detected_single += 1
        }


    }
}

; check for double clicks on mouse and report everything under 500ms apart
input_repetition_detect("RButton", block_duration)