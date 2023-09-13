; Include CAL (this assumes it's located in the same folder)
#include chipys-ahk-library.ahk

; used to indicate how much you want to see in the logs (higher number = see less)
global LOG_LEVEL := 1  

; create update handler object
updater_obj := UpdateHandler("example.com","scriptname.ahk", "Script Title Name")

; check for a newer version
updater_obj.compare_versions_and_notify()