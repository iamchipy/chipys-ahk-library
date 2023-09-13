; Include CAL (this assumes it's located in the same folder)
#include chipys-ahk-library.ahk

; used to indicate how much you want to see in the logs (higher number = see less)
global LOG_LEVEL := 1  

; create update handler object
updater_obj := UpdateHandler("https://chipy.dev/res/Chipys_Mouse_Bumper.exe","1.0.0","Chipys_Mouse_Bumper.exe", "Chipy's Mouse Bumper")

