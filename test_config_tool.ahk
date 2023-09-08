#include chipys-ahk-library.ahk

cfg_filename := "ahk.cfg"

cfg :=  ConfigManagerTool(cfg_filename,"General","ahk_exe pathofexile.com")
cfg.gui_add("TestHotkey")

cfg.gui_open()

; new remote from laptop
; added from desktop
; offline from latop