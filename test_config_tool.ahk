#include chipys-ahk-library.ahk

cfg_filename := "test_config_tool.cfg"

cfg :=  ConfigManagerTool(cfg_filename,"General","ahk_exe pathofexile.com")
cfg.ini("demo_hotkey", 1, "F2", "hotkey", "This is what a Hotkey config variable looks like")

cfg.gui_open()
