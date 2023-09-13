; Include CAL (this assumes it's located in the same folder)
#include chipys-ahk-library.ahk

; used to indicate how much you want to see in the logs (higher number = see less)
global LOG_LEVEL := 1  

; name in which to store your config data (stored in standard INI format)
cfg_filename := "test_config_tool.cfg" 

; Creates a manager object for your configurations
cfg :=  ConfigManagerTool(cfg_filename,"General","ahk_exe pathofexile.com")

; Create the entries that your script will be using
; HOTKEY
cfg.ini("demo_hotkey", 1, "F2", "hotkey", "This is what a Hotkey config variable looks like")
; TEXT
cfg.ini("demo_string", 0, "anything", "edit", "This is what a plain text string config variable looks like")

cfg.gui_open()
