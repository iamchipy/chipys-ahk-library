; constructed for AHKv2 Alpha (2.0-a106-4a6b3ff1)
; 7/1/21 updated for v2.0-134-d3d43350
;should be able to find it in (autohotkey.com/download/2.0/)
if A_AhkVersion != "2.0.2" and !A_IsCompiled  ;no longer logical here: and silent_mode!=True
	msgbox "You are running AHK v" A_AhkVersion "`n`rHowever CAL was written for v2.0.2`n`nYou may need to download that exact version from autohotkey.com/download/2.0/ if you experince issue in the code"

;=======================================================
; CONSTANTS
;=======================================================
global CAL_VERSION := "3.02"
global ROAMING := A_AppData "\Chipys-AHK-Library"
; if (!FileExist(INI_FILE_NAME) ) FileAppend("",INI_FILE_NAME)
; global DEPS := DependencyManager()
global GUI_FONT_SIZE := "20"		;scaled of base of 20 
global NATO_UI_FONT := "Share Tech Mono.ttf"

;=======================================================
; CONSTANTS with defaults, expected to be overwritten by scripts
;=======================================================

global SCRIPT_NAME := "DefaultChipysUtilityLibraryName"
global LOG_LEVEL := 5  ; scale of 0-10 higher value = more important to see AKA 9/10 = critical
global CFG_PATH := SCRIPT_NAME ".cfg"
global LOG_PATH := SCRIPT_NAME ".log"

global DEBUG := LOG_LEVEL  ; to be discontinued in favour of LOG_LEVEL
global INI_FILE_NAME := LOG_PATH ; to be discontinued in favour of CFG_FILE_NAME

APP_VERSION := "0.0.1", unused := "custom var"
;@Ahk2Exe-Let U_version = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%
;@Ahk2Exe-SetCopyright    Freeware written by Chipy
;@Ahk2Exe-SetCompanyName  Chipy.dev
;@Ahk2Exe-SetFileVersion  %U_version%
;@Ahk2Exe-SetName         Chipy's AHK Library
;@Ahk2Exe-SetDescription  If you are seeing you have used the chipys-ahk-library without seettings your own ahk2exe instructions
;@Ahk2Exe-SetOrigFilename chipys-ahk-library.ahk
;@Ahk2Exe-SetMainIcon     chipys-ahk-library.ico
;@Ahk2Exe-Base 			  Unicode 64-bit.bin


;=======================================================
; variables for predefined HUD objects
;=======================================================
global global_hud_obj1 := HUD(".",1)
global global_hud_obj2 := HUD(". .",2)
global global_hud_obj3 := HUD(". . .",3)
global blocking_user_input := "off"						;used as a global to know if BlockInput is on or off
global ticker := "-"

;=======================================================
; built-in icon
;=======================================================


; OnError("CUL_err_to_file")


class UpdateHandler {
	__new(download_url, script_name:="DefaultScriptName", display_name:="DefaultDisplayName"){
		; build variables and set defaults
		version_file_url := download_url "_version.txt"
		this.script_name := script_name
		this.download_url := download_url
		this.display_name := display_name

		; start the query for cloud version
		this._query_latest_version_then_callback(version_file_url, (*)=>this.compare_versions_and_notify())
	}

	_query_latest_version_then_callback(version_file_url, callback_function){
		; send a GET request to version_file_url then sets a callback
		this.com_obj := ComObject("Msxml2.XMLHTTP")  ; used to make URL requests
		this.com_obj.open("GET", version_file_url, true)
		this.com_obj.onreadystatechange := callback_function
		this.com_obj.send()
	}

	compare_versions_and_notify(){
		; global APP_VERSION, bumper_active
		; Receives the GET callback and compares versions

		; check if callback has a completed state
	    if (this.com_obj.readyState != 4){  ; Not done yet.
	        return
	    }
	    ; check if http code is a success (200)
	    if (this.com_obj.status == 200){
	    	; skim off and line returns
	    	cloud_version := strsplit(this.com_obj.responseText,"`r")[1]
	    	; create a log
	    	;log append_log("DEBUG: prompt_update -> comparing " cloud_version "(cloud) to " app_version "(current)")

	    	; pass cloud version info to c
	        if this._is_newer_version(cloud_version, app_version) == 1{
	        	this.prompt_update(cloud_version)
		    }else{
		        TrayTip("UpdateCheck(" cloud_version ")`nYou are on the latest version. (" app_version ")", this.display_name,"Mute")
	        	; prompt_update(cloud_version,True)
		    }
		}else (
			msgbox("Unknown error when checking version")
		)
	}


	_is_newer_version(v_one, v_two){
		; receives version strings 1 & 2
		; returns whichever is newer or 0/FALSE for neither

		; clean strings
		v_one := StrReplace(v_one, "`r", "")
		v_one := StrReplace(v_one, "`n", "")
		v_two := StrReplace(v_two, "`r", "")
		v_two := StrReplace(v_two, "`n", "")

		; split the variables into arrays for easy testing
		v_one_array := StrSplit(v_one , ".")
		v_two_array := StrSplit(v_two , ".")

		; Check version lengths match
		if v_one_array.Length != v_two_array.Length 
			return -1

		; compare arrays until we find a larger one
		loop v_one_array.Length {
			if Integer(v_one_array[A_Index]) > Integer(v_two_array[A_Index])
				return 1
			if Integer(v_one_array[A_Index]) < Integer(v_two_array[A_Index])
				return 2				
		}
		; if we make it this far that v_two must be larger
		return 0
	}

	prompt_update(cloud_version:=0, force_redownload:= False){
		; writes a powershell string the terminate itself for update

		undate_ps1_str := 'Stop-Process -Name "' this.script_name '"`n'
		undate_ps1_str .= 'if(Test-Path -Path ".\' this.script_name '.old") {Remove-Item ".\' this.script_name '.old"}`n' 
		undate_ps1_str .= 'Rename-Item -Path ".\' this.script_name '.exe" -NewName ".\' this.script_name '.old" -force`n'
		undate_ps1_str .= 'if(Test-Path -Path ".\' this.script_name '.exe"){ Remove-Item ".\' this.script_name '.exe"}`n'
		undate_ps1_str .= 'Rename-Item -Path ".\' this.script_name '.new" -NewName ".\' this.script_name '.exe" -force`n'
		undate_ps1_str .= '& ".\' this.script_name '.exe"'

		if !force_redownload
			answer := msgbox("NEWER version (" cloud_version ") available`n`nhttps://chipy.dev",,"y/n")
		if force_redownload or answer = "yes"{
			download this.download_url, this.script_name ".new"
			download this.download_url "_img.zip", script_name ".exe_img.zip"
			this._unzip(A_WorkingDir "\" script_name ".exe_img.zip", A_WorkingDir "\img")  ;TODO possible dynamic file path inconsistancy
			FileDelete("update.ps1")
			FileAppend(undate_ps1_str, "update.ps1")

			Run( "PowerShell.exe .\update.ps1")
		}
	}

	; pulled from https://www.autohotkey.com/boards/viewtopic.php?t=103864
	_unzip(source, destination){
	    DirCreate(destination)
		;https://www.autohotkey.com/boards/viewtopic.php?t=59016
		; errors := RunWait( "PowerShell.exe -Command Expand-Archive -LiteralPath '" A_WorkingDir "\" source "' -DestinationPath " A_WorkingDir "\" destination,,"hide" )
		errors := RunWait( "PowerShell.exe -Command Expand-Archive -LiteralPath '"  source "' -DestinationPath " destination)
		;log if errors 
			; pin( "WARN:error " errors " unzipping '" source "' to '" destination "'",True)
	}	
}

class NatoDict {
	__init(){

		; setup statics for NatoDict
		this.nato_dict := map()

		this.nato_dict["a"] := "alpha" 
		this.nato_dict["b"] := "bravo" 
		this.nato_dict["c"] := "charlie" 
		this.nato_dict["d"] := "delta" 
		this.nato_dict["e"] := "echo" 
		this.nato_dict["f"] := "foxtrot" 
		this.nato_dict["g"] := "golf" 
		this.nato_dict["h"] := "hotel" 
		this.nato_dict["i"] := "india" 
		this.nato_dict["j"] := "juliet" 
		this.nato_dict["k"] := "kilo" 
		this.nato_dict["l"] := "lima" 
		this.nato_dict["m"] := "mike" 
		this.nato_dict["n"] := "november" 
		this.nato_dict["o"] := "oscar" 
		this.nato_dict["p"] := "papa" 
		this.nato_dict["q"] := "quebec" 
		this.nato_dict["r"] := "romeo" 
		this.nato_dict["s"] := "sierra" 
		this.nato_dict["t"] := "tango" 
		this.nato_dict["u"] := "uniform" 
		this.nato_dict["v"] := "victor" 
		this.nato_dict["w"] := "whiskey" 
		this.nato_dict["x"] := "xray" 
		this.nato_dict["y"] := "yankee" 
		this.nato_dict["z"] := "zulu" 
		this.nato_dict[" "] := " " 

		this.nato_dict["A"] := "Alpha"
		this.nato_dict["B"] := "Bravo"
		this.nato_dict["C"] := "Charlie"
		this.nato_dict["D"] := "Delta"
		this.nato_dict["E"] := "Echo"
		this.nato_dict["F"] := "Foxtrot"
		this.nato_dict["G"] := "Golf"
		this.nato_dict["H"] := "Hotel"
		this.nato_dict["I"] := "India"
		this.nato_dict["J"] := "Juliet"
		this.nato_dict["K"] := "Kilo"
		this.nato_dict["L"] := "Lima"
		this.nato_dict["M"] := "Mike"
		this.nato_dict["N"] := "November"
		this.nato_dict["O"] := "Oscar"
		this.nato_dict["P"] := "Papa"
		this.nato_dict["Q"] := "Quebec"
		this.nato_dict["R"] := "Romeo"
		this.nato_dict["S"] := "Sierra"
		this.nato_dict["T"] := "Tango"
		this.nato_dict["U"] := "Uniform"
		this.nato_dict["V"] := "Victor"
		this.nato_dict["W"] := "Whiskey"
		this.nato_dict["X"] := "Xray"
		this.nato_dict["Y"] := "Yankee"
		this.nato_dict["Z"] := "Zulu"	

		this.nato_dict["0"] := "Zero"
		this.nato_dict["1"] := "Wun"
		this.nato_dict["2"] := "Too"
		this.nato_dict["3"] := "Tree"
		this.nato_dict["4"] := "Fow-er"
		this.nato_dict["5"] := "Fife"
		this.nato_dict["6"] := "Six"
		this.nato_dict["7"] := "Sev-en"
		this.nato_dict["8"] := "Ait"
		this.nato_dict["9"] := "Nin-er"

		this.nato_dict["``"] := "Grave/Accent"
		this.nato_dict["~"] := "Tilde"
		this.nato_dict["!"] := "Exclamation"
		this.nato_dict["@"] := "At Symbol"
		this.nato_dict["#"] := "Pound/Hash"
		this.nato_dict["$"] := "Dollar Sign"
		this.nato_dict["%"] := "Percent Sign"
		this.nato_dict["^"] := "Carrot"
		this.nato_dict["&"] := "Ampersand"
		this.nato_dict["*"] := "Asterisk"
		this.nato_dict["("] := "Open Parentheses"	
		this.nato_dict[")"] := "Close Parentheses"
		this.nato_dict["["] := "Open Bracket"
		this.nato_dict["]"] := "Close Bracket"		
		this.nato_dict["{"] := "Open Brace/Curly Bracket"
		this.nato_dict["}"] := "Close Brace/Curly Bracket"		
		this.nato_dict["\"] := "Backslash"	
		this.nato_dict["/"] := "Forward Slash"	
		this.nato_dict["`""] := "Quotation Marks"
		this.nato_dict["`'"] := "Apostrophe"		
		this.nato_dict["_"] := "Underscore"	
		this.nato_dict["="] := "Equals"
		this.nato_dict[":"] := "Colon"			
		this.nato_dict[";"] := "Semicolon"			
		this.nato_dict["."] := "Period/Dot"
		this.nato_dict[","] := "Comma"	
		this.nato_dict["?"] := "Question Mark"	
		this.nato_dict["+"] := "Plus Sign"	
		this.nato_dict["-"] := "Hyphen/Dash/Minus Sign"	
	}

	__new(d){
		if instr(d,"`n") or instr(d,"`r") or instr(d,"`t"){
			this.sound := this.digit := ""
			Return
		}

		try{
			this.digit := d
			this.uppercase := isUpper(d)
			if this.uppercase 
				this.sound := strupper(this.nato_dict[d])
			else
				this.sound := this.nato_dict[d] 

		}catch any as e{
			clog(e, "NatoDict(" this.digit ")")
			msgbox e.message "`n" e.what "`ndigit:" this.digit 
			Return 0
		}
	}
}

Class NatoOfString {
	__init(){
		; blank vars	
		this.nato_string_array := []
	}	

	__new(s,anchor_coords:=0){
		this.raw_str := s
		this.escaped_str := StrReplace(this.raw_str, "&" , "&&")
		this.anchor_coords := anchor_coords

		this._build_nato_string()
		this.build_gui(this.anchor_coords)
	}

	_build_nato_string(){
		for char in StrSplit(this.raw_str){
			this.nato_string_array.push(NatoDict(char))
		}
	}

	build_gui(custom_coords){
		global nato_ui_font
		if type(nato_ui_font) != String
			nato_ui_font := "Share Tech Mono.ttf"

		nato_gui := gui("+AlwaysOnTop -MaximizeBox -MinimizeBox")
		nato_gui.BackColor := "333333"
		nato_gui.SetFont("s20 q5 cSilver", substr(nato_ui_font,1,-4))

		; check for "Share Tech Mono"
		; https://fonts.google.com/specimen/Share+Tech+Mono?category=Monospace
		note := "GUI designed for a MonoSpaced font like: " nato_ui_font ". Please download and install from below sites (or change desired font in CFG)`nhttps://fonts.google.com/specimen/Share+Tech+Mono?category=Monospace `nor`nhttps://chipy.dev/fonts/Share Tech Mono.ttf"
		if !FileExist("c:\users\" A_UserName "\Appdata\Local\Microsoft\Windows\Fonts\" nato_ui_font){
			nato_gui.SetFont("s8 q5 w100") 
			nato_gui.addtext("xm+10", note)	
			nato_gui.addbutton("xm","Donwload Now").onevent("Click",(*)=>this.nato_gui_dl_font(nato_gui))
		}

		; fonts.google.com/download?family=Ubuntu%20   &

		; build easy read display
		nato_gui.SetFont("s22 q5 w900")
		nato_gui.addtext("xm ", this.escaped_str)

		; build spacer
		spacer := ""
		loop strlen(this.raw_str)
			spacer .= "-"
		nato_gui.addtext("xm ", spacer )

		; list string for easy reading
		loop this.nato_string_array.length{
			; build Digit column
			raster_str := this.nato_string_array[A_Index].digit
			if InStr(raster_str, "`&")
				raster_str := "&" raster_str
			nato_gui.SetFont("s22 q5 w900")
			nato_gui.addtext("xm yp+28", raster_str)

			; build sound column
			nato_gui.SetFont("s16 q5 w100") 
			nato_gui.addtext("xp+35 yp+7", this.nato_string_array[A_Index].sound)

			; build case column
			; nato_gui.SetFont("s18 q5 w100") 
			;nato_gui.addtext("xp+55 yp",this.nato_string_array[A_Index].uppercase)
		}

		; build spacer
		spacer := ""
		loop strlen(this.raw_str)
			spacer .= "-"
		nato_gui.addtext("xm ", spacer )

		; build a copy to clipboard button
		nato_gui.SetFont("s22 q5 w900") 
		this.c2c := nato_gui.add("text","xm", "Copy to Clipboard")
		this.c2c.OnEvent("Click",(*)=> this.nato_gui_copy_to_clipboard(this.c2c, this.raw_str))

		; handle custom GUI locations
		if custom_coords {
			nato_gui.show("x" custom_coords[1] " y" custom_coords[2])
		}else{
			nato_gui.show()
		}
		
	}

	nato_gui_dl_font(nato_gui, *){
		; downloads the current font from chipy.dev
		; pass through on nato_gui via params due to "this" referencing this button obj in current scope

		nato_gui.Minimize()
		a := MsgBox( "Do you wish to download " nato_ui_font "?", "Download missing font?" , "YesNo")
		if a = "yes"{
			msgbox "Once downloaded and saved to file pleast right-click and 'install font' to allow the script to access the font from the Windows Font Library"
			run("https://chipy.dev/fonts/" nato_ui_font )
		}
		
	}

	nato_gui_copy_to_clipboard(label_obj, s){
		; since this references the button object as self we need to pass through the str
		label_obj.SetFont("cWhite")
		a_Clipboard := s
		sleep 100
		label_obj.SetFont("cSilver")
	}

	nato_gui_auto_hide(nato_gui){
		; MouseGetPos OutputVarX
		; if abs(mouse_x_was-OutputVarX) < 10{
			; SetTimer nato_gui_auto_hide.bind(OutputVarX) , -1000
		; }else{
			nato_gui.Destroy()
		; }
	}
}

class RealTimeAlgoGUI {
	;this is a class that helps convert GUI algos for ARK variables and inf like Element ratios
	class EleGen extends RealTimeAlgoGUI {
		__new(){
			this.element := 0
			this.shards := 0
			this.radius := 0
			this.time := 0
		
			this.open()
		}	

		gui_close(){
			this.gui_obj.hide()
		}

		open(){
			try{
				this.gui_obj.show()
				Return
			}
			this.gui_obj := gui("+AlwaysOnTop -caption +ToolWindow +LastFound -DPIScale", "Tek Gen Calculator") ;
			this.gui_obj.setfont("c00cccc s" round(GUI_FONT_SIZE*0.95) " w400 q3", "Terminal")
			this.gui_obj.BackColor := "666666"

			this.gui_obj.add("text","w120 xm", "Element")
			this.element := This.gui_obj.add("edit","w" round(GUI_FONT_SIZE*3.5) " yp vElement RIGHT 0x2000 Background666666", 1)
			this.element.onevent("change", (obj_of_event,*)=> this.calculate(obj_of_event))
			this.gui_obj.add("picture","yp w-1 h" GUI_FONT_SIZE " BackgroundTrans ", A_WorkingDir "\img\tek_gen_cal_element.png")

			this.gui_obj.add("text","w120 xm", "Shards")
			this.shards := This.gui_obj.add("edit","w" round(GUI_FONT_SIZE*3.5) " yp vShards RIGHT 0x2000 Background666666", 1)
			this.shards.onevent("change", (obj_of_event,*)=> this.calculate(obj_of_event))
			this.gui_obj.add("picture","yp w-1 h" GUI_FONT_SIZE " BackgroundTrans ", A_WorkingDir "\img\tek_gen_cal_shards.png")

			this.gui_obj.add("text","w120 xm", "Radius")
			this.radius := This.gui_obj.add("edit","w" round(GUI_FONT_SIZE*3.5) " yp vRadius RIGHT Background666666", 1)
			this.radius.onevent("change", (obj_of_event,*)=> this.calculate(obj_of_event))
			this.gui_obj.add("picture","yp w-1 h" GUI_FONT_SIZE " BackgroundTrans ", A_WorkingDir "\img\tek_gen_cal_gen.png")
			
			this.gui_obj.add("text","w" GUI_FONT_SIZE*3.5 " xm", "Time")
			this.time := This.gui_obj.add("edit","w" round(GUI_FONT_SIZE*10) " yp vTime Background666666", "18h 11m")
			this.time.onevent("change", (obj_of_event,*)=> this.calculate(obj_of_event))


			this.gui_obj.add("button","c666666", "Close").OnEvent("click", (*)=> this.gui_close())
			this.gui_obj.OnEvent("Escape", (*)=> this.gui_close())
			this.gui_obj.OnEvent("Close", (*)=> this.gui_close()) 
			this.gui_obj.show()
		}

		calculate(obj_of_event){
			try{
				if obj_of_event.name = "time"{
					if InStr(obj_of_event.value, "m"){
						min := strreplace(this.time.value, "m", "")
						radius := this.radius.value
						shards := ((100+((radius-1)*33))/60)*(min/18) 
						this.shards.value := ceil(shards)
					}
					if InStr(obj_of_event.value, "h"){
						hour := strreplace(this.time.value, "h", "")
						radius := this.radius.value
						shards := ((100+((radius-1)*33))/60)*((hour*60)/18) 
						this.shards.value := ceil(shards)
					}
					if InStr(obj_of_event.value, "d"){
						day := strreplace(this.time.value, "d", "")
						radius := this.radius.value
						shards := ((100+((radius-1)*33))/60)*((day*1440)/18) 
						this.shards.value := ceil(shards)
					}								
					Return
				}
			
				shards := this.element.value*100 + this.shards.value
				radius := this.radius.value
				min :=(shards/((100+((radius-1)*33))/60))*18
				this.time.value := floor(min/1440) "d " mod(floor(min/60),24) "h " round(mod(min, 60)) "m"
			}
		}		
	}

	class InGameTime extends RealTimeAlgoGUI {
		;https://ark-days.herokuapp.com/
		;ingame default 1day = 50.675 IRL mins
		;  = > 1h is 126.7 sec 

		;https://steamcommunity.com/app/346110/discussions/0/1470840994966637222/
		;wiki agrees with 2.5 sec to one 1 IG minute
		; 1day = 60 IRL mins

		;testing shows 
		;10m IG  =>  23sec IRL 
		;30m IG  =>  1:10
		;1h 	 =>  2:20.3 IRL
		__new(ig_min_to_irl_sec:=2.5){
			this.event := 0
			this.current := 0
			this.time := 0
		
			this.ratio := ig_min_to_irl_sec
			this.open()
		}

		_convert_to_minutes(time_string){
			t := StrSplit( time_string , [":",","])
			if t.length < 3	{	; assume that this is down to minute accuracy and have no punc
				disp("d=" SubStr(t[1], 1, -4),1)
				disp("h=" SubStr(t[1], -4 ,2),2)	
				disp("m=" SubStr(t[1], -2 ,2),3)	

				t:=[SubStr(t[1], 1, -4),
					SubStr(t[1], -4 ,2),
					SubStr(t[1], -2 ,2)]
			}	

			time_in_minutes := 0
			; time_in_minutes += round(t[4]/60)
			time_in_minutes += t[3]
			time_in_minutes += t[2]*60
			time_in_minutes += t[1]*1440

			;ToolTip  t[1] "d " t[2] "h " t[3] "m " t[4] "s "
			Return time_in_minutes
		}	

		_convert_to_format(time_minutes){
			time_string := floor(time_minutes/1440) "d " mod(floor(time_minutes/60),24) "h " round(mod(time_minutes, 60)) "m"
			Return time_string
		}			

		gui_close(){
			this.gui_obj.hide()
		}

		open(){
			try{
				this.gui_obj.show()
				Return
			}
			this.gui_obj := gui("+AlwaysOnTop -caption +ToolWindow +LastFound -DPIScale", "Tek Gen Calculator") ;
			this.gui_obj.setfont("c00cccc s" round(GUI_FONT_SIZE*0.8) " w400 q3", "Terminal")
			this.gui_obj.BackColor := "666666"

			this.gui_obj.add("text","xm+90 CENTER", "format:`n'days,HH:MM:SS'`n 0000,12:55:12 ")

			this.gui_obj.add("text","w" round(GUI_FONT_SIZE*8) " xm", "IG Event Time")
			this.event := This.gui_obj.add("edit","w" round(GUI_FONT_SIZE*0.8)*round(GUI_FONT_SIZE/2) " yp vEvent RIGHT  Background666666", "0000,00:00:00")
			this.event.onevent("change", (obj_of_event,*)=> this.calculate(obj_of_event))			

			this.gui_obj.add("text","w" round(GUI_FONT_SIZE*8) " xm", "IG Current Time")
			this.current := This.gui_obj.add("edit","w" round(GUI_FONT_SIZE*0.8)*round(GUI_FONT_SIZE/2) " yp vCurrent RIGHT Background666666", "0000,00:00:00")
			this.current.onevent("change", (obj_of_event,*)=> this.calculate(obj_of_event))

			this.gui_obj.add("text","w" round(GUI_FONT_SIZE*8) " xm", "IRL time since event")
			this.time := This.gui_obj.add("edit","w" round(GUI_FONT_SIZE*12) " yp vTime Background666666", "18h 11m")
			;this.time.onevent("change", (obj_of_event,*)=> this.calculate(obj_of_event))

			this.gui_obj.add("button","xm+130 c666666", "Close").OnEvent("click", (*)=> this.gui_close())
			this.gui_obj.OnEvent("Escape", (*)=> this.gui_close())
			this.gui_obj.OnEvent("Close", (*)=> this.gui_close()) 
			this.gui_obj.show()
		}

		calculate(obj_of_event){
			try{
				duration := abs(this._convert_to_minutes(this.event.value) - this._convert_to_minutes(this.current.value))
				this.time.value := this._convert_to_format(  round(   (duration*this.ratio)/60   ,2)   )
			}
		}		
	}
}

class ThreeButtonMenu {
	__new(list_of_items, display_time:=5000){
	;__new(display_time:=5000){
		;create blank vars 
		this.function_map := map()		;this will be the 'list' of functions to cycle through
		this.index := []
		this.current_index := 2
		this.previous_index:= 1
		this.next_index:= 1
		list_of_items := list_of_items		; COULD help to fix STATIC frrom CARKA 2

		;fill vars
		this.hide_timer := objbindmethod(this, "hide")
		this.save_timer := objbindmethod(this, "_save_last")
		this.display_time := display_time
		try
			this.current_index:=integer(IniRead(INI_FILE_NAME, "TBM", "last_selected"))

		;run setup
		this._gui_build()
	}

	_gui_build(){
		txt := "sample"
		this.gui_obj := gui("+LastFound +AlwaysOnTop -caption +disabled +ToolWindow -DPIScale") ;
		this.gui_obj.BackColor := "000000"
		WinSetTransColor("000000")
		
		this.gui_obj.setfont("ccccc00 s" GUI_FONT_SIZE*.8 " w400 q3", "Terminal")			;incase of missing font
		this.ctr_p := this.gui_obj.add("text","ym right h" GUI_FONT_SIZE*2, txt)				;add 0x1000 for sunken
		
		this.gui_obj.setfont("c00FF00 s" GUI_FONT_SIZE*1.2 " w700 q3", "Terminal")			;incase of missing font
		this.ctr_c := this.gui_obj.add("text","ym CENTER h" GUI_FONT_SIZE*3 , txt)
		
		this.gui_obj.setfont("ccccc00 s" GUI_FONT_SIZE*.8 " w400 q3", "Terminal")			;incase of missing font
		this.ctr_n := this.gui_obj.add("text","ym left h" GUI_FONT_SIZE*2, txt)
	}

	_gui_update(items:=0, display_time:=5000){
		
		;update font size scaler
		this.ctr_p.setfont("s" GUI_FONT_SIZE*.8)
		this.ctr_c.setfont("s" GUI_FONT_SIZE*1.2)
		this.ctr_n.setfont("s" GUI_FONT_SIZE*.8)
		if(items != 0){
			if type(items) != "array"{ 	;error catch					
				MsgBox "array of previous, current, and next item is required"
				Return
			}
			
			p_width := This._calc_width(items[1],GUI_FONT_SIZE)
			c_width := This._calc_width(items[2],GUI_FONT_SIZE*1.5)
			n_width := This._calc_width(items[3],GUI_FONT_SIZE)
			margins := 10

			new_width := max(p_width,c_width,n_width) + margins
			new_p_anchor := 0
			new_c_anchor := round(0 + new_width)
			new_n_anchor := round(0 + new_width + c_width)

			; msg_str := "new_width:" new_width "`n"
			; msg_str .= "new_p_anchor:" new_p_anchor "|" p_width "`n"
			; msg_str .= "new_c_anchor:" new_c_anchor "|" c_width "`n"
			; msg_str .= "new_n_anchor:" new_n_anchor "|" n_width "`n"
			; msg_str .= "margins:" margins "`n"
			; msgbox msg_str

			this.ctr_p.visible := 0
			this.ctr_p.value := items[1]
			this.ctr_p.move(new_p_anchor,, new_width,)
			this.ctr_p.visible := 1

			this.ctr_c.visible := 0
			this.ctr_c.value := items[2]
			this.ctr_c.move(new_c_anchor,, c_width,)
			this.ctr_c.visible := 1
			
			this.ctr_n.visible := 0
			this.ctr_n.value := items[3]
			this.ctr_n.move(new_n_anchor,, new_width,)
			this.ctr_n.visible := 1

			; caluclate position of the GUI
			screen_center := A_ScreenWidth/2
			gui_width := (new_width*2+c_width)
			gui_X := screen_center - (gui_width/2)
			gui_Y:=0

			;msgbox "update:" "`n" this.ctr_p.value this.ctr_c.value this.ctr_n.value "`n"
			this.gui_obj.show("NoActivate h-1 w" new_width*3 " x" gui_X " y" gui_Y " AutoSize")

		}else {
			this.gui_obj.show()
		}

		;allows for adjustment of display time for every update or defaults to time given when instantiated 
		if display_time != 5000{
			SetTimer this.hide_timer, display_time
		}else {
			SetTimer this.hide_timer, this.display_time
		}		
	}

	_calc_width(sample_str, size){
		LMargin := 1
		Return (StrLen(sample_str) * size + LMargin)
	}	

	_save_last(){
		IniWrite this.current_index, INI_FILE_NAME, "TBM", "last_selected"
		if DEBUG 
			tooltip "_save_last()" A_TickCount
	}

	cycle(direction:=1){
		if type(direction) = "string"
			if direction = "left"
				direction := -1
			else if direction = "right"
				direction := 1

		;shift along indexes using modulo and zero checks
		this.current_index := mod(this.current_index+direction,this.function_map.count)
		if this.current_index <= 0
			this.current_index := this.function_map.count -  abs(this.current_index)

		this.next_index := mod(this.current_index+1,this.function_map.count)
		if this.next_index <= 0
			this.next_index := this.function_map.count - abs(this.next_index)

		this.previous_index:= mod(this.current_index-1,this.function_map.count)
		if this.previous_index <= 0
			this.previous_index := this.function_map.count - abs(this.previous_index)



		; this.index_str := ""
		; for item in this.index
		; 	this.index_str .= "," item
		; debug_str := "DEBUG:`n"
		; debug_str .= "direction: " direction "`n"
		; ; debug_str .= "index: " this.index_str "`n"
		; debug_str .= this.previous_index " " this.index[this.previous_index]  "`n"
		; debug_str .= this.current_index " " this.index[this.current_index]  "`n"
		; debug_str .= this.next_index " " this.index[this.next_index]  "`n"
		; msgbox debug_str

		; ;STATIC call to binds_obj in CARKA 2
		; p := "(" this.list_of_items.c["tbm_previous"].value ") " strUpper(StrReplace(this.index[this.previous_index], "_" , " ")) " < "
		; c :=  strUpper(StrReplace(this.index[this.current_index], "_" , " ")) 
		; n := " > " strUpper(StrReplace(this.index[this.next_index], "_" , " ")) " (" this.list_of_items.c["tbm_next"].value ")" 
		; this._gui_update(  [p, c, n])

		p := "(" this.index[this.previous_index] ") " " < "
		c :=  strUpper(StrReplace(this.index[this.current_index], "_" , " ")) 
		n := " > " " (" this.index[this.next_index] ")" 
		this._gui_update(  [p, c, n])

		SetTimer(this.save_timer, -2000)
	}

	activate(){
		; if DEBUG
			;disp("you selected " this.index[this.current_index])

		; debug_str:= "DEBUG:" "`n"
		; debug_str.= "index:" this.current_index "`n"
		; debug_str.= "value:" this.index[this.current_index] "`n"
		; ; debug_str.= "func:" this.function_map[this.index[this.current_index]] "`n"
		; msgbox debug_str

		this.function_map[this.index[this.current_index]]()
	}

	add_to_map(func_label, func_obj:=0){
		if !func_obj
			func_obj := (*)=> %func_label%()
		this.function_map[func_label] := func_obj
		this.index.push(func_label)
	}

	hide(){
		this.gui_obj.hide()
	}	
}

class ConfigEntry {
	; data-structures/Objectsfor complex configuration entries allowing each entry to handle it's own save/load
	__new(key,c_section,fn,c_type:=0,accessories:=0,default_value:=0,delete_if_blank:=0,info:=''){
		;value = base entry's value 
		;section = ini section 
		;type = main entry's value/input type 
		;accessories = array of flags for assisting options [checkbox/toggle]

		;defaults
		this.value := 0
		this.toggle := 0
		this.pipelist:= ["none"]						;creates an array and init with "none"

		;load values
		this.key := key
		this.section := c_section 								;ini section 
		this.fn := fn 											;file name of config ini
		((c_type)?(this.type:=c_type):(this.type:="edit"))
		this.default := default_value
		this.to_clean := delete_if_blank
		this.info := info

		this.acc := accessories
		this.has_toggle := 0		
		if type(this.acc) = "array"	{						;check if it's an array
			; MsgBox(this.acc[1] "`n is an array for " key)  
			if this.type = "DropDownList" {					;if this entry is a list, the accessory is the data
				loop this.acc.Length{							;loop for all items in the list
					this.pipelist.push(this.acc[A_Index])			;adds item
				}		
			}else if this.acc[1] = "DropDownList" {
				; MsgBox key " has an array `n" this.acc[2] "`n" this.acc[3]
				loop this.acc.Length -1 {			;loop for all  remaining entries in array
					this.pipelist.push(this.acc[A_Index+1])  ; adds item
				}
			}else{ 											;all other types get default system
				loop this.acc.Length{							;loop for all accessories in array
					if instr(this.acc[A_Index],"*") 			;check if this item has '*' mean it's a default for the previous item
						this.has_%this.acc[A_Index-1]%_default := SubStr(this.acc[A_Index], 2 )
					else
						this.has_%this.acc[A_Index]% := 1
				}
			}
		}else if type(this.acc) = "string"{				;assumes it's to be used as is in list prop 
			this.pipelist:= this.acc					;creates a pipe-separated-list
		}
		this._load()
	}

	_save(new_value:=0){
		if new_value
			this.value := new_value
		if this.value = this.default{						;if we have a value stored and it isn't the default
			if this.to_clean{								;if this is one to delete when it's the default value
				IniDelete this.fn, this.section, this.Key 	;clears ini value and key out 
				if type(this.acc) = "array"					;if accessories prop is array AKA multiple items
					for item in this.acc 					;loops for items in map
						IniDelete this.fn, this.section, this.Key "_" item	;clears ini for each item
				else 										;else just use as is
					IniDelete this.fn, this.section, this.Key "_" this.acc	;clears ini value and key out 
				Return 										;escapes and doesn't save a the value
			}
		}	

		; build array into string for storing
		if type(this.value) = "array" {
			; msgbox this.key "   being saved"
			this.save_string := ""
			for item in this.value 
				this.save_string .= item "\," 

			; clean up the last trailing comma
			this.save_string := SubStr(this.save_string, 1 ,-2)
			; msgbox this.save_string

			; if we got this far then this should be a normal scenario and we should save the value
			IniWrite this.save_string, this.fn, this.section, this.key			
		}else{
			; if we got this far then this should be a normal scenario and we should save the value
			IniWrite this.value, this.fn, this.section, this.key
		}
		
		; handles toggle options
		if this.hasprop("has_toggle_default")
			IniWrite this.toggle, this.fn, this.section, this.key "_toggle"
	}

	_load(){
		this.value := iniread(this.fn, this.section, this.key, "NO_DATA")		;load key's value from ini
		; building manual default check to make sure array's can be loaded as defaults
		if this.value := "NO_DATA"
			this.value := this.default
		; checks for array and builds that if needed
		if type(this.value) = "string" and instr(this.value, "\,")
			this.value := StrSplit(this.value, "\,")
		;check if there is a default present for for the toggle accessory
		if this.hasprop("has_toggle_default")
			this.toggle := iniread(this.fn, this.section, this.key "_toggle", this.has_toggle_default )		;load key's toggle state from ini
	}	

	ToString(){
		try
			Return "ConfigEntry(k:" this.key  ")(v:" this.value ")"
		catch
			return "ConfigEntry(ERROR key type =" type(this.key) " v=" type(this.value) ")"
	}
} 

class ConfigManagerTool {
	__new(file_name:=0, custom_section:=0, client_name:=0){

		;sets default for custom section is != 0
		((file_name)?(this.fn:=file_name):(this.fn:=INI_FILE_NAME))					;accepts custom name or uses normal
		((custom_section)?(this.section:=custom_section):(this.section:="ConfigManager"))
		((client_name)?(this.client_name:=client_name):(MsgBox(custom_section " MISSING client name")))
		this.gui_size_limit_height := 20

		this.c := map()		;map of settings in dict/map form for easy of saving, loading, and recall
		this.c2 := map()	;secondary map of settings in dict/map form for easy of saving, loading, and recall
		this._protected_keys := []	;list of currently used keys
		this.section_alt := this.section "_alt"

		this.load_all()
	}

	info(gui_obj, assist:=""){
		try{
			MsgBox this.c%assist%[substr(gui_obj.Name,5)].info, "About " gui_obj.Name 	;simple wrapper for info popup with key's info map data
		}catch any as e{
			;any exeption will result in default no-info-msgbox
			MsgBox "Sorry, no info avaliable for " substr(gui_obj.Name,5), "Missing Info"
		}
	}	

	_unbind(key_name,func_name:=""){
		try{
			; if DEBUG
			; 	ToolTip "unbind " key_name " from doing " func_name
			Hotkey key_name, "off"
		}
	}
	
	_bind(key_name, func_name, always_on:= 0){
		; This method is called to bind keys in general 
		; INPUT:
		; - key_name (STRING) containing name of desired hotkey
		; - func_name (STRING) containing name of function
		; - always_on (BOOL) used to enable this hotkey outside of normal application context		
		try{
			; MsgBox "func: " func_name "`nkey: " key_name "`nclient: " this.client_name "`n" always_on
			if key_name = ""{	;if keyname is non it means disable 
				hotif  ;new was to turn of context sensitivity https://lexikos.github.io/v2/docs/commands/HotIf.htm
				Hotkey "$~!#1", (*)=> func_name, "off"
				Return 1	;return success as unbound
			}
			if DEBUG 
				tooltip "binding " key_name " to " func_name " always: " always_on,,4
			;if always_on hotkey trigger only in app else set to always

			HotIfWinActive this.client_name		;make all hotkeys only work IN-CLIENT only by default
			if always_on 								;if we indicate to always work, only then do we clear the inf
				hotif 							        ; set hotkey to always work

			;MsgBox "binding:`nfunc: " func_name "`nkey: " key_name "`nclient: " this.client_name "`nalways:" always_on
			Hotkey key_name, (*)=> %func_name%()
			Return 1		;return success as bound
		}catch any as e{   ;ValueError
			MsgBox "read:`nfunc: " func_name "`nkey: " key_name
    		MsgBox Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n`n`n{6}",
    					  type(e), e.Message, e.File, e.Line, e.What, e.Stack)
		}catch TargetError {
			msgbox "Invalid target (method/function) for hotkey to assign`r`n`r`n" Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}",
    					  type(e), e.Message, e.File, e.Line, e.What, e.Stack) 
		}catch any as e{

			if e.Message == "Parameter #2 invalid."{
				MsgBox "Could not bind '" func_name "' to the [" key_name "] key.`r`n'" func_name "()' does not exist.", "Keybinding error!", 48
				Return 0
			}
			/* section taken out in favor of proper catch statments (and learning them)
			else if ErrorLevel == 2{
				MsgBox key_name " is not a valid hotkey recognized by this system", "Keybinding error!", 48
				Return 0
			}
			*/ 
			;Exception(Message , What, Extra) {file\line}
			MsgBox("err: " e.Message, "Keybinding error!", 48)
		}
	}

	bind_all_keys(){ ;discontinuted
		for key, obj in this.c{
			try{
				if obj.type = "hotkey"
					this._bind(obj.value, key, obj.toggle)
			}catch any as e{
				CULErrorHandler(e,"Encounterd possible faulty/old ini keybind entry: `n'" key "' -> '" obj.value "' `Will now attempt to heal/clean the error")
				IniDelete this.fn, this.section , key
			}
		}
	}

	unbind_all(){
		for key, obj in this.c{
			try{
				if obj.type = "hotkey" and key != "reload"    ;this is to allow reload to always work
					this._unbind(obj.value)
			}catch any as e{
				CULErrorHandler(e,"unbinding error 332")
				IniDelete this.fn, this.section , key
			}
		}
	}

	gui_add(custom_section:=0){
		;create a large window with all possible settings
		this.gui := gui(" -MinimizeBox -DPIScale","Settings Manager")
		this.gui.setfont("c00cccc s" round(GUI_FONT_SIZE*0.8) " q3", "Terminal")				; new gui style with gray and teal	
		this.gui.BackColor := "666666"								; gray bg for gui
		this.gui.Add("edit", "xm w" round(GUI_FONT_SIZE*4.8) " vnewkey" ,"key")
		this.gui.Add("edit", "xp+" round(GUI_FONT_SIZE*5) " w" round(GUI_FONT_SIZE*10) " vnewvalue", "value")
		this.gui_button_save := this.gui.add("button","xm","Save").OnEvent("click",(*)=> this.gui_save_one(custom_section))
		this.gui.show()
	}

	gui_open(*){	

		Suspend 1
		try			;checks if gui object exists and closes incase double opening
			this.gui.Destroy()

		;highmargin var for page FileSystem
		height_margin_modifier := (2.5*GUI_FONT_SIZE)
		height_margin_increment := GUI_FONT_SIZE*1.5

		; try{
			;create a large window with all possible settings
			this.gui := gui(" -MinimizeBox -DPIScale",this.section)
			this.gui.setfont("c00cccc s" round(GUI_FONT_SIZE*0.5) " q5", "Terminal")				; new gui style with gray and teal	
			this.gui.BackColor := "666666"								; gray bg for gui

			;special "pre-settings" loop for settings to be left separately grouped
			for key, obj in this.c2{				;loop for each setting in the obj map[]
				;if i'm in this loop it means that i would need to bump other tab content down so 
				height_margin_modifier += height_margin_increment

				;title
				this.gui.Add("text", "xm", strUpper(StrReplace(key, "_" , " ")))

				;help/discription buttons
				this.gui.Addbutton("xp+180 vinfo" key,"?").onEvent("click", (gui_obj,*)=>this.info(gui_obj,"2"))
				
				;main value item 
				if obj.type = "checkbox"
					this.gui.Add(obj.type, "xp+30 w" round(GUI_FONT_SIZE*10) " v" key " checked" obj.value, "default: " obj.default)
				if obj.type = "edit" or obj.type = "hotkey"
					this.gui.Add(obj.type, "xp+30 w" round(GUI_FONT_SIZE*10) " v" key, obj.value)
				if obj.type = "DropDownList"{

					if DEBUG
						tooltip key "`n" obj.value "`n`n" obj.pipelist
					temp:= this.gui.Add(obj.type, "lowercase altsubmit xp+30 w200 v" key " choose" obj.value, obj.pipelist)
					temp.OnEvent("change",(obj_of_event,*)=> this.gui_apply_preset(obj_of_event))
				}

				;add ons 
				if obj.has_toggle
					this.gui.Add("Checkbox", "xp+230 v" key "_toggle checked" obj.toggle, "Enabled")
			}


			;system for handling incresing number of settings on new pages
			row_count := 15
			page_count := (this.c.count//row_count)+1
			row_current := -1
			row_extra := 0 								;value used for multi line entries to bump others down
			page_current := 0
			tab_names_array := []
			loop page_count{								;for each page loop
				tab_names_array.push("Page " A_Index )			;add label with page #
			}

			this.tabs := this.gui.add("Tab3","xm",tab_names_array)

			;now add normal items
			for key, obj in this.c{				;loop for each setting in the obj map[]

				;pagte system cont. in loop
				row_current += 1
				page_current := ((row_current+row_extra)//row_count)+1
				row_y := mod((row_current+row_extra), row_count)
				this.tabs.UseTab(page_current)

				;checks if entry in ini is something we know whwat to do with our how to handle
				if type(obj) != "ConfigEntry"{	;no longer treating as an error by just a text field
					; msgbox "Encounterd possible faulty/old ini setting entry: '" key "' and will now attempt to self-correct"
					; IniDelete this.fn, this.section , key
					if DEBUG 
						msgbox "Encounterd possible faulty/old ini setting entry: '" key "' NEEDS TO BE REMOVED FROM config.ini"
					Continue
				}

				;title
				this.gui.Add("text", "xm+" height_margin_increment " y" (height_margin_increment*row_y)+height_margin_modifier, strUpper(StrReplace(key, "_" , " ")))			

				if DEBUG 
					tooltip "gui_open`nkey: " string(key) "`nobj: " string(obj)

				;help/discription buttons
				this.gui.Addbutton("xp+" 8*height_margin_increment " vinfo" key,"?").onEvent("click", (gui_obj,*)=>this.info(gui_obj))
				; if key = "debugmode"
				; 	msgbox key

				;main value item 
				if obj.type = "edit" {
					if strlen(obj.value)>25{
						if type(obj.acc) = "array" and obj.acc[1] = "DropDownList"
							this.gui.Add(obj.type, "xp+" height_margin_increment " w" round(GUI_FONT_SIZE*10) " r3 v" key, obj.value)	
						else
							this.gui.Add(obj.type, "xp+" height_margin_increment " w" round(GUI_FONT_SIZE*20) " r3 v" key, obj.value)	
						row_extra += 1
					}
					else{
						if DEBUG
							tooltip key "`n" obj.value "`n`n" obj.type
						this.gui.Add(obj.type, "xp+" height_margin_increment " w" round(GUI_FONT_SIZE*10) " v" key, obj.value)			
					}
				}
				if obj.type = "checkbox"
					this.gui.Add(obj.type, "xp+" height_margin_increment " w" round(GUI_FONT_SIZE*10) " v" key " checked" obj.value, "default: " obj.default)
				if obj.type = "hotkey"
					this.gui.Add(obj.type, "xp+" height_margin_increment " w" round(GUI_FONT_SIZE*10) " v" key, obj.value).OnEvent("change",(obj_of_event,*)=> this.on_change(obj_of_event))
				if obj.type = "Slider"
					this.gui.Add(obj.type, "xp+" height_margin_increment " w" round(GUI_FONT_SIZE*10) " v" key, obj.value)

				;add ons 
				if obj.has_toggle
					this.gui.Add("Checkbox", "xp+" 7.1*height_margin_increment " v" key "_toggle checked" obj.toggle, "Enabled")
				if type(obj.acc) = "array" and obj.acc[1] = "DropDownList"{
					;                                                                                                                         [acc_value]? no idea what this was
					acc_value := ""																						; assigned to help with #warn
					temp:= this.gui.Add("DropDownList","lowercase altsubmit xp+" 7.1*height_margin_increment " w" round(GUI_FONT_SIZE*10) " v" acc_value, obj.pipelist)
					t := key 	; variable can't have changed between time of use and PHATarrow obj method so store value it it's own var
					temp.OnEvent("change",(obj_of_event,*)=> this.gui_apply_action_wheel_value(obj_of_event, t))
				}

			}

			this.tabs.UseTab() ;pops back out of tabs placement
			this.gui_button_save := this.gui.add("button","xm","Save").OnEvent("click",(*)=> this.gui_save())
			this.gui_button_reset := this.gui.add("button","xp+" height_margin_increment*5 ,"Reset").OnEvent("click",(*)=> this.gui_reset())		
			this.Gui.OnEvent("Escape", (*)=> this.gui_close())
			this.gui.OnEvent("Close", (*)=> this.gui_close()) 
			this.gui.show()
		; }catch any as e{
		; 	CULErrorHandler(e,"UNKNOWN gui error opening '" this.section "' section ' (key is at bottom of this msg)")
		; }
	}

	gui_save(args*){
		Suspend 0
		this.gui_data := this.gui.submit()					;dumps current state of GUI to an object
		for key, value in this.gui_data.OwnProps(){			;enumerates the entire dict as an easy way of not missing anything

			;skips toggle accessories
			if instr(key,"_toggle")
				Continue

			;case special cases in map "c2"
			if this.c2.has(key){
				this.c2[key].value := value 
				disp("gui_save() skipping gui element: " key)
				Continue
			}
			
			;hotkey unbind before assigning a new value to be bound
			if this.c[key].type = "hotkey" {								;if this is a hotkey
				if this.c[key].value != value or this.c[key].toggle != this.gui_data.%key%_toggle{
					this._unbind(this.c[key].value)								;unbind previous value(key)
					if value {													;if there is a new value from gui, bind it
						this._bind(value, key, this.gui_data.%key%_toggle)			
					}
				}
			}

			;checks if there is an accessories that needs updating
			if this.c[key].has_toggle								
				this.c[key].toggle := this.gui_data.%key%_toggle 
			;base functionality of applying variable's value
			this.c[key].value := value
		}

		this.save_all()
		; this.bind_all_keys()
	}

	gui_save_one(custom_section:=0){
		this.gui_data := this.gui.submit()	;dumps current state of GUI to an object
		; this.value[this.gui_data.newkey] := this.gui_data.newvalue
		; this.save_all()
		this._save(this.gui_data.newkey,this.gui_data.newvalue,custom_section)
	}

	gui_close(){
		Suspend 0
		this.gui.Destroy()
	}

	gui_reset(){
		if MsgBox( "Are you sure you want to reset ALL saved data?",,1+48+256) != "OK"
			Return
		this.gui_close()
		for key, obj in this.c
			obj.value := ""
		This.gui_open()
	}

	gui_apply_action_wheel_value(obj_of_event,key,args*){
		; TODO infuture build this into some kind of direct gui change rather than reloading entire gui
		this.c[key].value := iniread( this.fn, "action_wheel_presets", obj_of_event.Text)

		this.gui_close()
		this.gui_open()
	}

	gui_apply_preset(obj_of_event){
		if DEBUG
			MsgBox this.c2["preset"].value "->" obj_of_event.value "(" obj_of_event.Text ")"

		;sets preset map entry's value
		this.c2["preset"].value := obj_of_event.value

		for key, obj in this.c{				;loop for all options
			obj.value := 0					;start by making all unchecked as a base
			if obj_of_event.value = 1		;handles the 'none' preset
				Continue
			if key != obj_of_event.Text 	;then if text isn't the preset item's match 
				obj.value := 1				;check all items not matching
		}

		;new reboot the gui for an easy way to apply preset
		this.gui_close()
		this.gui_open()		
	}

	on_change(obj_of_event){
		if this.does_conflict(obj_of_event.value){
			if DEBUG
				ToolTip obj_of_event.value " conflicts with "  this.does_conflict(obj_of_event.value)
		}
	}

	does_conflict(key_to_check){
		;checks for conflicts in existing keybinds or reserved hotkeys 
		;returns 0 if no conflicts
		;returns INT of coflicting index in the this.functions[] List
		;retunrn STRING if conflicting with reserved key
		if key_to_check == ""
			Return 0

		loop this._protected_keys.Length{
			if key_to_check == this._protected_keys[A_Index]{
				MsgBox key_to_check " is a reserved/protected key"
				Return this._protected_keys[A_Index]
			}
		}

		for key, obj in this.c{
			if key_to_check == obj.value{
				MsgBox key_to_check " is already assigned to " key "`n`nBe careful with overlapping hotkeys"
				Return A_Index
			}
		}
		Return 0
	}

	wrong_type_handler(key, value := 0, alt_map:=""){
		log("INFO:wrong_type_handler(||has: " this.c%alt_map%.has(key) " ||key: " string(key) "(" type(key) ")||value: " string(value) "(" type(value) "))")
		
		; checks if this needs to be part of the primary map "c" or the supplementary map "c2" 
		if !alt_map{
			; checks to see if value already exists
			if !this.c.has(key){
				this.c[key] := ConfigEntry(key, this.section, this.fn)
				log("INFO:wrong_type_handler(NEW: " this.c.has(key) " ||key: " string(key) "(" type(key) ")||value: " string(value) "(" type(value) ")")
			}
		}else{
			if !this.c2.has(key){
				this.c2[key] := ConfigEntry(key, this.section, this.fn)
				log("INFO:wrong_type_handler(NEW-alt: " this.c2.has(key) " ||key: " string(key) "(" type(key) ")||value: " string(value) "(" type(value) ")")
			}			
		}
	}

	; stores data enties in C/C2 maps of this obj
	ini(key, delete_if_blank:=0, default_value:=0, ctr_type:="edit", info:='',accessories:=0){
		if ctr_type = "DropDownList"{
			this.c2[key]:=ConfigEntry(	key,
										this.section_alt,
										this.fn,
										ctr_type,
										accessories,
										default_value,
										delete_if_blank,
										info)
		}else{
			this.c[key]:=ConfigEntry(	key,
										this.section,
										this.fn,
										ctr_type,
										accessories,
										default_value,
										delete_if_blank,
										info)
		}
	}

	load_all(){
		; checks if the file exits
		if !FileExist(this.fn){
			;if it doesn't
			;leave a log
			log("WARN: CfgMgr: Could not locate '" this.fn "' to load config data")
			;exit load process
			return
		}
		; msgbox a_workingdir "\" this.fn "`n" FileExist(a_workingdir "\" this.fn ) "`n" this.section

		Try{
			;reads section from ini
			temp_read := iniread(this.fn, this.section)	
			;now build map with values from string 
			lines_array := StrSplit(temp_read, ["`n"])			;split each line in string 
			for l in lines_array{								;loop for each line
				pairs_array := StrSplit(l, "=")					;split pair
				if instr(pairs_array[1], "_toggle")				;checks if it's an accessory and skips it
					Continue
				; sets correct types for values
				this.wrong_type_handler(pairs_array[1], pairs_array[2])
				; stores the data in the "c" map
				this.c[pairs_array[1]].value := pairs_array[2]
				log("INFO:Load_ALL(line:" l "||" pairs_array[1] " +> " pairs_array[2] )
			}

		}catch OSError as e{
			MsgBox "Unable to find file or section:  [" this.section "] in:`n" this.fn "`n`nYou might need to setup this section's settings"	
		}catch any as e{
			temp := CULErrorHandler(e,"Error loading settings from section[" this.section "] of " this.fn " (if this is the first time you are seeing this it should be safe to ignore this message)`n`n")
		}
	}

	save_all(){
		for key, obj in this.c{			; loop through enitre map and tell each to save it's self
			obj._save()
		}
		for key, obj in this.c2{			; loop through enitre map and tell each to save it's self	
			obj._save()
		}		
	}

	_save(key, value, custom_section:=0){
		this.wrong_type_handler(key, value)
		this.c[key].value := value	
		this.c[key]._save()
	}

	_load(){
		;not used yet
		MsgBox "not using _LOAD please update "
	}
}

class HUD {
	hud_index_array := []

	; allows for display of single lines of text on screen bot-right
	__New(txt:="sample of text to display", index:=1, display_time:=5000){
		this.hide_timer := objbindmethod(this, "hide")
		if display_time > 0
			display_time := 0-display_time
		this.display_time:= display_time
		; hud_index_array.push() incomplete idea
		this._create(index)
		if txt
			this.display(txt)
	}

	_create(index){
		this.i := Integer(index)
		this.gui_obj := gui("+LastFound `+AlwaysOnTop -caption +disabled +ToolWindow -DPIScale",this.i)
		this.gui_obj.setfont("c00FF00 s" round(GUI_FONT_SIZE*1.2) " W700 q3", "Verdana")	    ;incase of missing font
		this.gui_obj.BackColor := "000000"
		WinSetTransColor("000000")
		this.txt_obj := this.gui_obj.add("text","xm ym RIGHT", "")
	}

	display(text_to_display, display_time:=5000){
		LocalWidth := This._calc_width(text_to_display)
		LX:=A_ScreenWidth - LocalWidth - 100
		LY:=A_ScreenHeight  - 100 - (50*this.i)
		
		this.txt_obj.Visible := 0 
		this.txt_obj.value := text_to_display
		this.txt_obj.move(,,LocalWidth,)
		this.txt_obj.Visible := 1

		this.gui_obj.show("NoActivate autosize" " x" LX " y" LY)
	

		;allows for adjustment of display time for every update or defaults to time given when instantiated 
		if display_time != 5000{
			SetTimer this.hide_timer, -display_time
		}else {
			SetTimer this.hide_timer, -this.display_time
		}
	}

	_calc_width(sample_str){
		FontWidth := round(GUI_FONT_SIZE*2)
		LMargin := 2
		Return (StrLen(sample_str) * FontWidth + LMargin)
	}	

	hide(){
		this.gui_obj.setfont("s" round(GUI_FONT_SIZE*1.2))   ; here for the sake of updating gui size somehow since only create 1x
		this.gui_obj.hide()
	}

	class Image extends HUD {
		__init(display_time:=0){
			this.current_image := "demo.png"
			this.scale := 100
			this.image_size_array := []
			this.gui_coords := []
			if display_time > 0 {
				this.display_time := display_time
			}

			this._create(99)  ; picking a high index to not disrupt text displays
		}

		_build_gui(){
			this.gui_obj := gui()
			; this.gui_image := this.gui_obj.add("pic", "xm ym " this.current_image)  
		}

		_calculate_gui_size(){
			; gets images size from ifrv image dimentions output
			this.imagetool := ImageTool()
			this.image_size_array := this.ImageTool.get_image_size(this.current_image)
			; gets center of screen and subtracts the half image size to get top left coords of where GUI should start to center image on screen
			this.gui_coords := [round((A_ScreenWidth/2) - (this.image_size_array[1]/2)), round((A_ScreenHeight/2) - (this.image_size_array[2]/2))]
		}

		_update_image(new_path){
			if !FileExist(new_path)
				throw Error("Image file not found","_update_image(" new_path ")", new_path)
			if new_path != this.current_image {
				this.current_image := new_path
				this._calculate_gui_size()
			}

			this.txt_obj.Visible := 0 ; hide text from base
			this.gui_image := this.gui_obj.add("pic") 
			this.gui_image.Value := Format("*w{1} *h{2} {3}", this.image_size_array[1], this.image_size_array[2], this.current_image)  ; Load the image.
		}

		show(desired_image:="", timeout:=0){
			if desired_image != "" {
				this._update_image(desired_image)
			}

			; this.gui_obj.Opt("+AlwaysOnTop +Disabled -SysMenu +Owner")
			this.gui_obj.BackColor := "white"
			WinSetTransColor("white")
			; this.gui_obj.show("x" this.gui_coords[1] " y" this.gui_coords[1])
			this.gui_obj.show("xCenter yCenter AutoSize")

			if timeout> 0
				SetTimer this.hide_timer, -timeout						
		}
	}
}

class Tool {
	class Mouse {
		__init(){
			;sets basic vars so that the obj has those prop later
		    this.x1 := 0
		    this.y1 := 0
		    this.x2 := 0
		    this.y2 := 0	
		    this.color:=""
		    this.coord_mode_to_use:=""
		}

		_capture_next(key_press, function){
			;allows you to capture the next click
			Hotkey(key_press, function, "on")
		}

		_screen_to_prop(coords){ 	;copies coords into client's properties
		    this.sx1 := coords[1] 	;fill prop info from results for partent caller to use
		    this.sy1 := coords[2] 	;fill prop info from results for partent caller to use
			if coords.length == 2 	;returns if only 2 coords are needed
				Return			    
		    this.sx2 := coords[3] 	;fill prop info from results for partent caller to use
		    this.sy2 := coords[4]	;fill prop info from results for partent caller to use   
		}	
		_screen_to_client(coords){	;take current screen/window info and converts to client coodemode from screen
			WinGetClientPos &X, &Y, &Width, &Height, "A"	;use active window, assuming it's the right one
			this.x := x
			this.y := y
			this.w := width
			this.h := height

			ToolTip "client " x ":" y "   " width "x" height "`n" coords[1] ":" coords[2] "`n" coords[1]-x ":" coords[2]-y

		    this.cx1 := coords[1]-x 	;fill prop info from results for partent caller to use
		    this.cy1 := coords[2]-y 	;fill prop info from results for partent caller to use
			if coords.length == 2 	;returns if only 2 coords are needed
				Return			    
		    this.cx2 := coords[3]-x 	;fill prop info from results for partent caller to use
		    this.cy2 := coords[4]-y	;fill prop info from results for partent caller to use   
		}

		class Pixel extends Tool.Mouse {
			__new(target_window){
				this._capture_next("LButton",(*)=>this.get())
				WinActivate target_window						;set client window (what ever app you are wroking in active)	
				this.done:=0
			}

			get(){
				; ToolTip "STARTING pixel"

				MouseGetPos &x1, &y1
				this.color := PixelGetColor(x1, y1, "alt")
				; ToolTip this.color 
				this.info := Tool.highlight("temp_pixel", [x1,y1], this.color,,1)
				this.info.show()
			    this.x1 := x1
			    this.y1 := y1
			    this.done := 1
				Hotkey("Lbutton", (*)=> this.drag(), "off")
				Return this.color
			}
		}

		class Area extends Tool.Mouse {
			__new(target_window){
				this._capture_next("LButton",(*)=>this.drag())
				WinActivate target_window						;set client window (what ever app you are wroking in active)
				this.done:=0
			}

			drag(){
				;displays and records info about the area "drug" on screen
			    MouseGetPos &x1, &y1 	;get starting click
			    this.display_obj := tool.highlight("dragzone", [x1, y1 ,x1+2, y1+2 ],"EEEEEE",0)

			    try{
				    while GetKeyState("LButton", "p"){	;while mouse is clicked keep updating the gui for drag effect
				        MouseGetPos &x2, &y2
				        ToolTip x1 ", " y1 "`n" Abs(x1-x2) " x " Abs(y1-y2)
				        this.display_obj.move([x1,y1,x2,y2])
				        Sleep 10
				    }
				    ToolTip
			    
				    this._screen_to_prop([x1,y1,x2,y2])
				    this._screen_to_client([x1,y1,x2,y2])
			    }catch any as e {
				    this.display_obj.hide()		;hide the live display so the confirm SHOW_COORDS can take over
				    Hotkey("Lbutton", (*)=> this.drag(), "off")
			    	return false
			    }	
			    this.done := 1	;confirm that the process has finished

			    this.display_obj.hide()		;hide the live display so the confirm SHOW_COORDS can take over
			    Hotkey("Lbutton", (*)=> this.drag(), "off")
			}
		}
	}

	class Highlight {
		__New(_id, coords, colour:=0, duration:=1500, show_tile:=0, crosshair_size:=2){
			; a general tool to simplify debugging and display of locations on the screen
			; with either a point or an area as acceptable in puts
			;
			; id STRNG - is the unique name for this highlight
			; coords ARRAY - can be either 1 or 2 coordinate pairs in [array] form THESE MUST BE SCREEN COORDMODE
			; *colour STRNG - of hex 6digit type or ARRAY which would be first colour of tile and then gui crosshair color
			; *duration INT - length in MS to display 
			; *show_tile BOOL - 1/0 true/false if you want to see tile of the color at the coords for point
			; *coordmode STRING - a string of AHK's CoordMode options (window/screen/other)

			;handling of defaults and variations
			if coords.Length == 2{
				this.type := "point"
			}else if coords.Length == 4{
				this.type := "area"		
			}else{
				MsgBox "The highlight tool only accepts coordinate pairs (1-point or 2-area) in array form "
				Return 0
			}

			;handles colour's options    [blank need to have a default]
			if !colour{
				this.target_color := 0		;set to ZERO so that it selects the colour tile of visible
				this.gui_color := "00ff00"	;set a default color for the gui elements
			}else if type(colour) == "Array" {		;if it's of array type, we've been given both colors so jsut plug in
				this.target_color := colour[1]
				this.gui_color := colour[2]	
			}else{								;to handle a single color being fed in and gives a default gui color, unless gui is AREA
				
				this.target_color := colour
				; if DEBUG
				; 	disp(_id " is color=" this.target_color,2)
				this.gui_color := "00ff00"
				if this.Type == "area"
					this.gui_color := colour
			}


			; dumping params
			this.trans_amount:= 20
			this.id := _id
			this.hrid := _id
			this.coords := coords
			this.duration := duration
			this.show_tile := show_tile

			;static vars for now (possible add to params)
			this.ch_b := crosshair_size					;buffer size around pixel
			this.ch_b2 := this.ch_b*3						
			this.ch_p := 1						;pixel size should stay 1 but just for calc
			this.ch_s := this.ch_b*2+this.ch_p  ; giving you "dot" number of pixels on either side of the clicked pixel
			this.ch_l := this.ch_b2*4

			;props for guis and deletions
			this.color_tile := ""
			this.gui_handles := [1,2,3,4,5,6]
			this.moving := 0			;used to tell contructer if it should creat a gui or just use old handles
			; this.gui_ids := []
			this.hide_timer := objbindmethod(this, "hide")
		}

		_start_timer(){
			if this.duration == 0
				Return  ; meaning permanent display or manual hiding
			;handles positive timer number so it never activates twice
			if this.duration > 0
				this.duration := 0-this.duration

			; if DEBUG
			; 	tooltip "setting timer for '" this.hrid "' of type [" this.type "]`n" this.coords[1] ":" this.coords[2] 				
			;handles timer start and resets(TODO add reset somehow/ refresh timer)
			SetTimer this.hide_timer, this.duration
		}

		_construct_crosshair_element(i,x,y,w,h,is_tile:=0){
			if !this.moving					;checks if it needs to create gui or if we are moving AKA been created before
				this.gui_handles[i] := gui("+toolwindow +AlwaysOnTop -Caption +Disabled +LastFound -DPIScale")
			
			if is_tile{						;handles colours for tiles, non-tiles(gui) and auto color pick from point if no color
				;TODO create border on tile indicating if correct color is present
				; current_pix_color := PixelGetColor(this.coords[1], this.coords[2])	
				; if 
				if this.target_color		;if target color defined (AKA not defaulted to 0)
					this.gui_handles[i].BackColor := this.target_color
				else
					this.gui_handles[i].BackColor := PixelGetColor(this.coords[1], this.coords[2])				
			}else{							; if not tile then use GUI color
				this.gui_handles[i].BackColor := this.gui_color
			}

				
			this.gui_handles[i].show(" x" x " y" y " w" w " h" h   " NoActivate")
			;check if it's an area type and then make it transparent ish
			if this.type == "area"
				WinSetTransparent(this.trans_amount, this.gui_handles[i])
		}

		move(new_coords,duration:=-1){
			this.coords := new_coords
			this.show(duration)		
			this.moving := 1
		}

		show(duration:=-1){
			if duration != -1
				this.duration := duration
			if duration != 0
				this._start_timer()	
			; process display of coords for a point
			if this.type == "point"{
				;a debugging dot for crosshair precision 
				; i,x,y,w,h,is_tile:=0
				this._construct_crosshair_element(1,this.coords[1]-this.ch_b, this.coords[2]-this.ch_b2-this.ch_l, this.ch_s,this.ch_l)
				this._construct_crosshair_element(2,this.coords[1]+this.ch_b2+this.ch_p, this.coords[2]-this.ch_b, this.ch_l,this.ch_s)
				this._construct_crosshair_element(3,this.coords[1]-this.ch_b, this.coords[2]+this.ch_b2+this.ch_p, this.ch_s,this.ch_l)
				this._construct_crosshair_element(4,this.coords[1]-this.ch_b2-this.ch_l, this.coords[2]-this.ch_b, this.ch_l,this.ch_s)

				if this.show_tile
					this._construct_crosshair_element(5,this.coords[1]+this.ch_l+this.ch_b, this.coords[2]-this.ch_l*2, this.ch_l, this.ch_l, this.show_tile)
			}
			if this.type == "area"{
				this._construct_crosshair_element(6,this.coords[1], this.coords[2], this.coords[3]-this.coords[1], this.coords[4]-this.coords[2])
			}

			this.moving := 0
		}

		hide(){
			; if debug
			; 	tooltip "hiding ->" this.id,,, 2
			;handles issues of many timers being called on the smae gui
			if this.type == "area" {
				this.gui_handles[6].Destroy()
				Return
			}
			if this.show_tile
				this.gui_handles[5].Destroy()
			this.gui_handles[1].Destroy()
			this.gui_handles[2].Destroy()
			this.gui_handles[3].Destroy()
			this.gui_handles[4].Destroy()
		}
	}

	class CrossHair {
		__New(scale_factor:=1, window_id:=0){
			this.gui_obj := 0
			this.image_size := 256
			this.img_path := 0
			this.img_name := ""
			this.img_index := 1
			this.scale := scale_factor//100
			
			this.img_folder := A_WorkingDir "\img\crosshairs\"

			this.cycle()
		}

		_create(custom_window_origin:=0){

			h := round(this.image_size*this.scale)+2
			w := round(this.image_size*this.scale)+2			
			if custom_window_origin != 0 {
				win_width:=win_height:=0
				WinGetClientPos(&win_x, &win_y,&win_width,&win_height)
				x := round((win_width/2 - w/2)+win_x)
				y := round((win_height/2 - h/2)+win_y)
			}else{
				x := round(A_ScreenWidth/2 - w/2)
				y := round(A_ScreenHeight/2 - h/2)
			}

			if !this.gui_obj
				this.gui_obj := gui("+LastFound `+AlwaysOnTop -caption +disabled +ToolWindow -DPIScale")
			this.gui_obj.BackColor := "000000"
			WinSetTransColor("000000")
			try
				this.img := this.gui_obj.Add("Picture", "AltSubmit x0 y0 w" w " h-1", this.img_path)
			catch as e
				disp( type(e) "(Invalid File)  >>  " this.img_name)

			this.gui_obj.show("x" x " y" y " h" h " w" w " NA")
			if DEBUG
				MsgBox "x" x " y" y " h" h " w" w "`n" 
		}

		show(new_scale_factor:=0, custom_window_origin:=0){

			this._create(custom_window_origin)
		}

		hide(){
			if this.gui_obj
				this.gui_obj.Destroy()
			this.gui_obj :=0
		}

		toggle(new_scale_factor:=0, custom_window_origin:=0){
			if new_scale_factor
				this.scale := new_scale_factor/100
			((this.gui_obj)?(this.hide()):(this.show(new_scale_factor, custom_window_origin)))
		}

		cycle(new_scale_factor:=0, custom_window_origin:=0){
			if new_scale_factor
				this.scale := new_scale_factor/100

			Loop files, this.img_folder "*.*"
			{
				if A_Index = this.img_index{
					this.img_path := this.img_folder "\" A_LoopFileName
					this.img_name := A_LoopFileName
					if DEBUG
						disp(A_LoopFileName )
					if this.gui_obj{
						this.hide()
						this.show(new_scale_factor, custom_window_origin)
					}
					; disp(this.img_path " applied",2)
					this.img_index +=1
					Return
				}
			}
			this.img_index := 1
		}
	}
}

class Action {
	__New(frequency:=1000, key_to_press:="1") {
		if frequency == 0
			this.disabled := 1
		else
			this.disabled := 0

		if frequency < 200
			this.freq:= frequency*1000
		else
			this.freq := frequency

		this.last_tick := 0	
		this.key := key_to_press
		this.x := 0
		this.y := 0			
		Return this
	}

	is_due() {
		if this.disabled
			Return 0
		If(this.last_tick+this.freq <a_tickcount)
			return 1
		Return 0
	}

	payload() {
		send this.key
	}

	update_last_tick(){
		this.last_tick := a_tickcount	
	}

	do() {
		if(this.is_due())
		{
			this.payload()
			this.update_last_tick()
			disp(this.key)
			return 1
		}
		return 0
	}

	class Moose extends Action{
		bump(min:=5, max:=50){
			disp("bumping mouse " )
			;determin direction of movment
			x_change := random(min,max)
			y_change := random(min,max)
			if this.x>0
				x_change := 0 - x_change
			if this.y>0
				y_change := 0 - y_change
			this.x += x_change
			this.y += y_change

			MouseMove(x_change, y_change, 100, "Relative")
		}
	}
}

class ScenarioDetector {
	__init(){
		;define variables that will get saved or need defaults
		this.coord_mode_to_use := "Screen"
		this.prop := Map()							;all saved properties are now in this map for easy of saving
		this.prop["x_ref"] := 1920					;resolution client at time of search-area setup
		this.prop["y_ref"] := 1080 					;resolution client at time of search-area setup
		this.prop["x_win"] := A_ScreenWidth			;width of client (default assumes fullscreen)
		this.prop["y_win"] := A_ScreenHeight 		;hieght of client (default assumes fullscreen)		
		this.prop["x_off"] := 0					;coordinate representing the origin of the client window (offset + coord should = screen pixel)
		this.prop["y_off"] := 0					;coordinate representing the origin of the client window (offset + coord should = screen pixel)
		this.prop["ui_compensate"] := false 		;for telling if this pixel should have it's coord adjusted accounting to ui scaler

		this.prop["x"] := 0		;x of (last) found location of scenario
		this.prop["y"] := 0		;y of (last) found location of scenario
		this.prop["x1"] := 0	;x of first (upper left) coord for area to search [based on client coordmode]
		this.prop["y1"] := 0	;y of first (upper left) coord for area to search [based on client coordmode]
		this.prop["x2"] := 0 	;x of second (lower right) coord for area to search [based on client coordmode]
		this.prop["y2"] := 0	;x of second (lower right) coord for area to search [based on client coordmode]

		;live properties used for manipulation and based on SCREEN for gui/hud accuracy
		this.x := 0		;x of (last) found location of scenario
		this.y := 0		;y of (last) found location of scenario
		this.x1 := 0	;x of first (upper left) coord for area to search [based on SCREEN coordmode]
		this.y1 := 0	;y of first (upper left) coord for area to search [based on SCREEN coordmode]
		this.x2 := 0 	;x of second (lower right) coord for area to search [based on SCREEN coordmode]
		this.y2 := 0	;x of second (lower right) coord for area to search [based on SCREEN coordmode]		

		;define blank variable that might be used by class or child classes 
		this.color_mark := "00FF00"
		this.prop["color_target"] := "FFFFFF"
		this.hide_timer := objbindmethod(this, "hide_coords")
		this.display_time := 500					;default time for search box to show
		this.last_coords := 0
		this.coords:=0
		this.showing_search_area := 0
		this.mode := "base"
		this.tile_flag := 0
		this.area_flag := 0
		this.last_seen := 0
		this.age_ms := 0
		this.sub_count := 0
		this.force_reselection := 0

		;init blank values for GUI ids/obj so that we don't doup guis
		this.m_n_id := 0
		this.m_s_id := 0
		this.m_e_id := 0
		this.m_w_id := 0
		this.tile_id := 0
		this.search_area_gui_obj_id:=0
		this.m_n := 0
		this.m_s := 0
		this.m_e := 0
		this.m_w := 0
		this.tile := 0
	}

	_refine_coords(refine_array:=0){ ;update offset/win(refine_array) & 'live' with prop[]ratios+offset
		if !WinExist(this.client_name){
			disp(this.hrid " could not find ARK window")			;STATIC
			Return
		}
		; refine_array -> [[win-x,win-y],[win-w,win-h]]
		if !refine_array{					;if we weren't info try get it from client window
			WinGetClientPos &X, &Y, &Width, &Height, this.client_name	
			refine_array := [[X,Y],[Width,height]]	
		}

		this.update_offset(refine_array[1])		;update the object's current offset prop (to be saved)
		this.update_win(refine_array[2])		;update the object's current window dimentions prop (to be saved)

		; MsgBox  this.prop["x1"] ":" this.prop["y1"] "`n" this.prop["x2"] ":" this.prop["y2"]
		;new system (scaler for ark ui)
		;converts client coords (sample) to client coords current res
		temp_coords :=[this.prop["x1"],this.prop["y1"],this.prop["x2"],this.prop["y2"]]
		if this.prop["ui_compensate"]
			temp_coords :=[this.prop["x1"],this.prop["y1"],this.prop["x2"],this.prop["y2"],this.prop["ui_compensate"]]
		normalized_array := coords_normalize_array(	temp_coords,
													[this.prop["x_ref"],this.prop["y_ref"]],
													refine_array[2])
		this.x1 := normalized_array[1] + this.prop["x_off"]
		this.y1 := normalized_array[2] + this.prop["y_off"]
		this.x2 := normalized_array[3] + this.prop["x_off"]
		this.y2 := normalized_array[4] + this.prop["y_off"]	
	}

	_client_to_screen(coord_pair){
		if coord_pair.Length == 2
			Return [coord_pair[1]+this.prop["x_off"],coord_pair[2]+this.prop["y_off"]] 
		if coord_pair.Length == 4
			Return [coord_pair[1]+this.prop["x_off"],coord_pair[2]+this.prop["y_off"],coord_pair[3]+this.prop["x_off"],coord_pair[4]+this.prop["y_off"]] 			
	}

	_wipe(){
		;wipe entire save section, likely to force reselections of stuff
		Inidelete(A_WorkingDir "/" INI_FILE_NAME, this.id)
		sleep 100
	}

	_save_prop(prop_name){
		IniWrite(this.prop[prop_name], A_WorkingDir "/" INI_FILE_NAME, this.id, prop_name)
		; if DEBUG 
		; 	ToolTip "ScenarioDetector " this.type " saving " this.%prop_name% " to:`n" A_WorkingDir "/" INI_FILE_NAME
	}

	_load_prop(prop_name){
		
		temp := iniread(INI_FILE_NAME, this.id, prop_name, "KEY_ERROR")
		; if "ui_hurt_A" = this.hrid{
		; 	MsgBox INI_FILE_NAME " " this.id " " prop_name " attempting"
		; 	run INI_FILE_NAME
		; 	ToolTip "_load_prop('" this.hrid "')`n" temp " of type " type(temp) " into " prop_name
		; }
		if DEBUG
			ToolTip "_load_prop('" this.hrid "')`n" temp " of type " type(temp) " into " prop_name
		if temp == "KEY_ERROR" or temp == "FFFFFF"{
			; msgbox "errors here"
			throw { message: "KEY_ERROR", what:  A_WorkingDir "/" prop_name, extra: "_load_prop('" prop_name "') for '" this.hrid "' not found in ini file"}
		}
		this.prop[prop_name] := temp
	}

	show_coords(length_to_show:=1000, live_mode:=0){
		; if debug 
		; 	ToolTip "show_coords: " this.hrid "`nLastSeen: " this.x ":" this.y "`nin: " 

		if live_mode			;not the case by default only an option for specifically shows what is live with direct call by
		    this.last_coords := this.is_present() 	;forcing it to run, is present check first to fill the data of current screen 

		if this.type == "pixel" or this.last_coords{				;if visible show crosshair or if pixel show where should be
			send_coords := [this.x, this.y]
			send_color := this.prop["color_target"]			
		}else if this.type == "image" or this.type == "pixel_ext" { ;show area searched 
			send_coords := [this.x1, this.y1, this.x2, this.y2]
			send_color := this.color_mark			
		}else if this.type == "cluster" {  							;if type is cluster we gotta feed it subpixel1's coords for search area
			send_coords := [this.sub_pixel[1].x1, this.sub_pixel[1].y1, this.sub_pixel[1].x2, this.sub_pixel[1].y2]
			send_color := this.color_mark		
		}

		if debug {
			str := ""
			loop send_coords.Length
				str .= send_coords[A_Index] " "
			ToolTip "show_coords: " this.hrid "`nLastSeen: " this.x ":" this.y "`nin: " str
		}

		;now make highlight with above 'dynamic' flexie vars
		this.hud_obj := tool.highlight(	this.id, 
											send_coords, 
											send_color, 
											length_to_show,
											this.tile_flag)
		this.hud_obj.show()		
	}

	is_present(variation:=-1, visual:=1, length_to_show:=250, refine_array:=0){
		this.last_coords := 0  ; reset to avoid false positive
		if variation <0
			variation := this.tol

		; if refine_array  ;refine_array if you want to make changes -> [[win-x,win-y],[win-w,win-h]]
			this._refine_coords(refine_array)

		if this.type = "image" {	
			this.last_coords := find_image(this.file_name,
										   this.x1,
										   this.y1,
										   this.x2,
										   this.y2,
										   variation,
										   this.scale)
			if this.last_coords != 0
			{
				this.x := this.last_coords[1]
				this.y := this.last_coords[2]
				this.update_last_seen()
				if DEBUG or visual
					this.show_coords(length_to_show)	
				Return 1
			}
			if DEBUG and visual
				this.show_coords(length_to_show)				
			Return 0
		}

		if this.type = "pixel_ext" {
			this.mode := "pixel_ext"
			if(PixelSearch(&x, &y, this.x1, this.y1, this.x2,this.y2, this.prop["color_target"], variation)) {
				this.last_coords := [x, y]
				this.x := x
				this.y := y
				this.update_last_seen()
				if DEBUG or visual
					this.show_coords(length_to_show)					
				Return 1
			}
			if DEBUG and visual
				this.show_coords(length_to_show)				
			Return 0
		}

		if this.type = "pixel"{
			r := 2
			if(PixelSearch(&x,&y,this.x-r,this.y-r,this.x+r,this.y+r,this.prop["color_target"],variation)){
				this.last_coords := [x, y]
				this.x := x
				this.y := y	
				this.update_last_seen()			
				if DEBUG or visual
					this.show_coords(length_to_show)					
				Return 1
			}
			if DEBUG and visual
				this.show_coords(length_to_show)				
			Return 0		
		}

		if this.type = "cluster"{
			loop this.sub_count{															;loop for each sub pixel in cluster
				i:= A_Index
				if this.sub_pixel[i].is_present(){											;if current pixel is present
					this.sub_pixel[i].show_coords()											; show it's location
					if this.mode == 1
						this.sub_pixel[i+1].update_coords(	[this.sub_pixel[1].x-this.range,	; update the search area for next pixel (mode=1)
															 this.sub_pixel[1].y-this.range,
															 this.sub_pixel[1].y+this.range,
															 this.sub_pixel[1].y+this.range])
					if this.mode == 2
						this.sub_pixel[i+1].update_coords(	[this.sub_pixel[i].x-this.range,	; update the search area for next pixel (mode=2)
															 this.sub_pixel[i].y-this.range,
															 this.sub_pixel[i].y+this.range,
															 this.sub_pixel[i].y+this.range])
				}else{
					if DEBUG and visual
						this.show_coords(length_to_show)	
					Return 0 ; sub_pixel i isn't present we failed to see full cluster so exit 
				}
			}
			Return 1	;if we made it this far, we must have found all cluster pixels and thus scenario is present
		}
	}	

	save_all(){
		;alias for save to be consistant with other objs 
		this.save()
	}

	save(){
		this._save_prop("color_target")
		; this._save_prop("sub_count") not needed
		this._save_prop("x")
		this._save_prop("y")
		this._save_prop("x1")
		this._save_prop("y1")
		this._save_prop("x2")
		this._save_prop("y2")	

		this._save_prop("x_ref")
		this._save_prop("y_ref")
		this._save_prop("x_win")
		this._save_prop("y_win")
		this._save_prop("x_off")
		this._save_prop("y_off")	
	}	

	load(use_static_coords:=0){
		if DEBUG
			ToolTip this.hrid " loading..." this.hrid
		;try load search area
		if !use_static_coords{						;use_static_coords is for a hardcoded area or pixel (not recommended)
			try{									;try block with silent catch for option properties
				; if "ui_hurt_A" = this.hrid
					; MsgBox "hi"
				this._load_prop("color_target")
				this._load_prop("x_ref")
				this._load_prop("y_ref")
				this._load_prop("x_win")
				this._load_prop("y_win")
				this._load_prop("x_off")
				this._load_prop("y_off")
				this._load_prop("x")
				this._load_prop("y")
				this._load_prop("ui_compensate")
			}catch any{
				; if "ui_hurt_A" = this.hrid{
				; 	MsgBox this.hrid " failed to load everything" 
				; 	MsgBox e.message "`n" e.what
				; }
				; msgbox "caught correctly by parent"
			}
			try{	;try block for values that aren't optional 
				if this.force_reselection{
					this.force_reselection :=0 
					; MsgBox this.hrid " forced reselections"
					throw ValueError("Custom Error to hide when hotkeys are deassigned", this.hrid "force_reselection image", " ")
				}
				if this.prop["x2"]	 	;if have info for secondary coord (aka part of area) then we must be good
					Return
				if this.prop["x"] and this.type == "pixel"	;;if have info for pixel's coord then we are good
					Return					
				this._load_prop("x1")			;load x1 -used in pixel/ext/img
				this._load_prop("y1")			;load y1 -used in pixel/ext/img
				if this.area_flag{				;if this.area_flag we know it's ext/img only
					this._load_prop("x2")		;load x2 -used in ext/img to define zone end
					this._load_prop("y2")		;load y2 -used in ext/img to define zone end
				}
				if this.type == "ext"{			;for pix.ext we are interested in loading last seen
					;load last seen TODO
				}	
			}catch any as e{
				; msgbox "catching: " e.message
				if e.message == "KEY_ERROR"{	;KEY_ERROR is a custom err thrown when no value found for key
					if DEBUG 
						ToolTip e.extra " => " e.message
					if this.type == "pixel" or this.type == "pixel_ext"{
						disp("No config detected, please select a pixel for '" this.hrid "' now.",,,0)
						this.picker("pixel")
					}
					if this.area_flag and !this.prop["x2"]{
						disp("No config detected, please drag-select an area for '" this.hrid "' now.",,,0)
						this.picker("area")
					}
				}
			}
		}
	}	

	update_last_seen(){
		this.last_seen := A_TickCount
		this.save()
	}

	update_coords(coords:=0){		;used to update the search range of this(instance) manually (or [prop+offset]->live)
		if !coords{
			this.x1 := this.prop["x1"] + this.prop["x_off"]
			this.y1 := this.prop["y1"] + this.prop["y_off"]
			this.x2 := this.prop["x2"] + this.prop["x_off"]
			this.y2 := this.prop["y2"] + this.prop["y_off"]
			Return
		}
		this.prop["x1"] := coords[1]
		this.prop["y1"] := coords[2]
		if coords.Length < 4
			Return
		this.prop["x2"] := coords[3]
		this.prop["y2"] := coords[4]
	}

	update_offset(coords){ 		;used to update the offset/origin of client window
		this.prop["x_off"] := coords[1]
		this.prop["y_off"] := coords[2]
	}

	update_win(dimentions){		;used to update client window dimentions 
		this.prop["x_win"] := dimentions[1]
		this.prop["y_win"] := dimentions[2]
	}

	get_age_in_ms(){
		this.age_ms := a_tickcount - this.last_seen
		Return this.age_ms
	}

	picker(mode:="pixel"){	
		; try;NO idea what this was
			; temp := Man(this.hrid)  

		if mode == "pixel"{
			this._grab_pixel_info()
		}
		if mode == "area"{
			this._grab_area_info()
		}			
	}

	_grab_area_info(){
		temp := tool.mouse.area(this.client_name) 	
		while !temp.done
			sleep 100
		this.update_coords([temp.cx1,temp.cy1,temp.cx2,temp.cy2]) ;copy results into props (client mode)
		this.prop["x_ref"] := temp.w 		;copy in the results from screen drag 	window info
		this.prop["y_ref"] := temp.h 		;copy in the results from screen drag 	window info

		this._refine_coords([[temp.x,temp.y],[temp.w,temp.h]])	;feed getclientpos stuff from temp so we don't do it twice

		disp("'" this.hrid "' area selected")
		this.show_coords()
		this.save_all()

		; if DEBUG
		; 	ToolTip "received " temp.x1 ":" temp.y1 " to " temp.x2 ":" temp.y2
	}

	_grab_pixel_info(){
		temp := tool.mouse.pixel(this.client_name)
		while !temp.done
			sleep 100
		this.prop["x"] := temp.x1
		this.prop["y"] := temp.y1
		this.prop["color_target"] := temp.color

		disp("'" this.hrid "' pixel selected")
		this.save_all()
		; if DEBUG
		; 	ToolTip "received " temp.x1 ":" temp.y1 " -> " temp.color
	}

	class Img extends ScenarioDetector{
		__New(file_name, coords:=0, LocalTol:=50, client_name:=0) {
			;handles defaults
			if type(coords) == "String"
				coords := this._translate_zone(coords)
			if type(coords) == "Array"{
				this.prop["x1"] := coords[1]
				this.prop["y1"] := coords[2]
				this.prop["x2"] := coords[3]
				this.prop["y2"] := coords[4]
			}	

			if client_name{
				this.client_name:=client_name
			}else{
				this.client_name:= "AHK_exe " WinGetProcessName("A")
			}

			this.file_name := file_name
			this.id := StrSplit(file_name , ".")[1]
			this.hrid := this.id
			this.tol := LocalTol
			this.type := "image"
			this.area_flag := 1


			this.load()		;load info from ini file
			this._refine_coords()	;take loaded info and translate into coords used for SCREEN based stuff

			; try{
				; TODO remove IMFV and use GUI creation https://www.autohotkey.com/boards/viewtopic.php?f=6&t=3806
				
				; if DEBUG
				; 	MsgBox "File: " a_workingdir this.file_name "`nExist: " FileExist( a_workingdir this.file_name) "(letters for Attributes = yes)"
				; to get dimentions
				if !FileExist(a_workingdir this.file_name)
					MsgBox "Image file appear to be missing from path below. You might need to reinstall CARKA or ask for info in Discord `n`n" a_workingdir this.file_name
					; throw TargetError("Missing image file", a_workingdir this.file_name " (NOT FOUND) ", a_workingdir this.file_name)

				this.imagetool := imagetool()									;build obj for image tool

				this.dimentions := this.imagetool.get_image_size(this.file_name)	;gets the x and y size of the image for scaling 

				this.scale := this.imagetool.rescaler( 	this.dimentions,	; rescale(img_dimentions, ref_dimentions, win_dimentions)
														[this.prop["x_ref"],this.prop["y_ref"]],
														[this.prop["x_win"],this.prop["y_win"]]) 
			; }catch any as e{
			; 	temp := CULErrorHandler(e,"Error trying to get dimentions. `n`nPlease try reinstalling to get images in the right folder.`n(discont.)Please try menu>dev-mode>verify_all to redownload possible missing files.")
			; }
								
		}

		capture_new_sample(){
			capture_image_region(this.file_name)
		}
	}
	
	class Pix extends ScenarioDetector{
		__New(identifier, coords:=False, tol := 2, force_reselection:=0, client_name:=0, known_info:=0, target_color:=0){
			;handles defaults not in use
			if type(coords) == "String"
				msgbox(identifier " was given " coords "(str:coords) which is no longer a valid option please give an array pretranslated")
			if type(coords) == "Array"{
				this.prop["x"] := coords[1]
				this.prop["y"] := coords[2]		
				this.x := coords[1]			;to allow fo display of what pixels are expected we load into the "lastfound" vars expected coords
				this.y := coords[2]			;to allow fo display of what pixels are expected we load into the "lastfound" vars expected coords
				if coords.Length = 3
					this.prop["ui_compensate"] := coords[3]		
			}

			((client_name)?(this.client_name:=client_name):(this.client_name:= "AHK_exe " WinGetProcessName("A")))

			if target_color
				this.prop["color_target"] := target_color

			this.id := identifier
			this.hrid := identifier
			this.type := "pixel"
			this.mode := "tile"
			this.tile_flag := 1
			this.tol := tol
			this.load()

			if DEBUG 
				disp(identifier " has loaded [" this.prop["x"] ":" this.prop["y"] "," this.prop["ui_compensate"] "] c=" this.prop["color_target"],3)
		}

 		class Ext extends ScenarioDetector.Pix {
			__New(identifier, coords:=0, LocalTol:=5, force_reselection:=0, client_name:=0, target_color:=0) {
				if type(coords) == "String"
					coords := this._translate_zone(coords)
				if type(coords) == "Array"{
					if coords.length = 3							;handles ui compensation requests
						this.prop["ui_compensate"] := coords[3]
					if coords.Length < 4{							;handles pixels as input options
						this.prop["x1"] := coords[1]-LocalTol
						this.prop["y1"] := coords[2]-LocalTol
						this.prop["x2"] := coords[1]+LocalTol	
						this.prop["y2"] := coords[2]+LocalTol
					}else{
						this.prop["x1"] := coords[1]
						this.prop["y1"] := coords[2]
						this.prop["x2"] := coords[3]
						this.prop["y2"] := coords[4]		
					}			
				}
				
				if client_name{
					this.client_name:=client_name
				}else{
					this.client_name:= "AHK_exe " WinGetProcessName("A")
				}
				((target_color)?(this.prop["color_target"] := target_color):(this.prop["color_target"] := "FFFFFF"))			

				this.id := identifier
				this.hrid := identifier
				this.tol := LocalTol
				this.area_flag := 1
				this.tile_flag := 1
				this.mode := "tile"
				this.type := "pixel_ext"
				this.showing_search_area := 0
				
				if force_reselection{
					this.force_reselection := 1
					this._wipe()				
				}

				this.load()
				;defines coords for this with this.prop map info like offset and win-size
				this._refine_coords()				
			}		
		}

		class Cluster extends ScenarioDetector.Pix{
			__New(id_list, coords:=0, range:=100, LocalTol:=100, mode:=1, force_reselection:=0, client_name:=0) {
				;a scenario detector that runs pixel_ext and then check for subsequent pixel_ext in RANGE distance from first 
				;pixel detection to allow for more sophisticated detection of situations
				;
				;id_list array with [name, n_of_subpixels]
				;coords is where to look for the first Pixel
				;range is how far from the first pixel to look for others
				;mode(2 will) allow for pixels to be check in chain-distance rather than cluster/origin distance from first pixel

				; if type(coords) == "Array"{
				; 	this.prop["x1"] := coords[1]
				; 	this.prop["y1"] := coords[2]
				; 	this.prop["x2"] := coords[3]
				; 	this.prop["y2"] := coords[4]
				; }
				if type(id_list) = "string"{
					MsgBox id_list ".pix.cluster requires an array containing [ID, count] for it's ID"
					Return
				}

				this.id := id_list[1]
				this.hrid := this.id "_cluster_head"
				this.sub_count := id_list[2]
				this.tol := LocalTol
				this.mode := "tile"
				this.type := "cluster"

				;builds cluster from id_list
				this.sub_pixel := []													;blank list to push to
				this.sub_pixel.push(ScenarioDetector.pix.ext(this.id, coords))	;creates primary pixel
				loop id_list[2] - 1{												;loops for all secondary pixels
					this.sub_pixel.push(ScenarioDetector.pix.ext(this.id A_Index,[1,1,2,2]))	;coords will be updated before check time
				}
				; if DEBUG
				; 	MsgBox this.hrid " done"
			}
		}	
	}
}

class UpdateTool{
	__new(current_version, remote_version_url, remote_installer_url, change_log_url:="", tray_icons:=0){
		this.change_log_url:=change_log_url
		this.current_version := current_version
		this.v_url := remote_version_url
		this.installer_url := remote_installer_url
		SplitPath remote_installer_url , &n, , &e
		this.installer_name := n  ;"." e    ;concat filename + extention for downloading
		this.last_known_remote_version := "2.00"
		this.icons:=tray_icons

		this.populated := 0						;info check to allow early calls to know if we've fetched remote info yet
		this.is_update_available := 0 			;bool telling up if remote is newer		
	}

	_populate_info(is_forced:=0){ ;this method allows for the obj creation without 'hanging' while GET-requests go on
		this.is_update_available := this.is_remote_newer()
		this.populated := 1
		disp("Checking for updates . . .", 3) 
		if !is_forced && this.is_remote_newer()
			this.prompt()
	}

	_get_remote_version(){
		try{
			ldata := url_get(this.v_url)
		}catch any as e{
			CULErrorHandler(e, "update-tool-")
		}
		if(!ldata){
			;TODO reduce msgbox interupts
			MsgBox "Could not connect to remote server!`r`nUnable to update.`r`nerror 433: while trying to check remote version "
			Return 0
		}
		this.last_known_remote_version := round(float(ldata),2)		;round to .00
		Return ldata
	}

	is_remote_newer(){
		if this._get_remote_version() > this.current_version{
			if this.icons
				TraySetIcon(this.icons[1],,1)
			Return 1
		}
		Return 0
	}

	prompt(check_latest_version:=1){
		if !this.populated
			this._populate_info(1)
		if check_latest_version
			this._get_remote_version()
		version_report:="Update to v" round(this.last_known_remote_version,2) " (from v" this.current_version ")"
		changes_txt:="No changelog found"
		if this.change_log_url
			changes_txt := url_get(this.change_log_url)

		temp := UITool.UpdatePrompt((*)=>this.update_now(),"Do you wish to update?",version_report, changes_txt)
	}

	update_now(){
		GENERIC_MISSING_ELEMENT_MSGBOX("Self Update Discontinuted")
		Return
		/*
		; Download "https://raw.githubusercontent.com/sgmsm/CARKA/master/CARKA_Installer.exe", "CARKA_Installer.exe"	
		temp:=UITool.ProgressBar("Downloading . . .")
		download this.installer_url, a_workingdir "\" this.installer_name	
		if DEBUG
			tooltip "setting to 50% progress"
		temp.update(50)
		while !FileExist(a_workingdir "\" this.installer_name){
			sleep 500
		}	

		if DEBUG 
			tooltip "wd: " a_workingdir "`nname: " this.installer_name "`n`n" a_workingdir "\" this.installer_name " has been found"

		;building run commands string into a single var for simplicity and debugging
		run_str := '"' a_workingdir '\' this.installer_name '" ' 	;file to run followed by args
		run_str .= DllCall("GetCurrentProcessId") " " 				;arg1 carka process id for killing
		run_str .= this.current_version " " 						;arg2 curent var for backing up name
		run_str .= round(this.last_known_remote_version,2) " " 		;arg3 remote version for showing what is downloading
		run_str .= '"' A_ScriptFullPath '"'							;arg4 exact name to replace with new download

		if DEBUG
			msgbox run_str

		Run(run_str)
		temp.Destroy()
		;exits the app to allow for update to replace it
		ExitApp "updating..."	
		*/
	}
}

class LicenseTool{
	; tool used to get a unique identifier code for hardware and mix with username then compare to web url presence
	__new(user_name, custom_url, icon_path:=0, consequence_method:=0, unconsequence_method:=0){

  		;check for default UserName (type = ConfigEntry obj)
  		; if user_name = "dem0#1234"
  		; 	this.prompt_user_name()


       	if !icon_path{ 	;sets default icon (in the "img" subfolder)
       		this.icon_path_unauth := "img\tray_unregistered.ico"
       		this.icon_path_auth := "img\tray_loaded.ico"
       	}else{
       		
       		this.icon_path_unauth := icon_path[1]
       		this.icon_path_auth := icon_path[2]
       	}
       	this.discord_webhook := DiscordWebhook(this.decode("aAB0AHQAcABzADoALwAvAGQAaQBzAGMAbwByAGQAYQBwAHAALgBjAG8AbQAvAGEAcABpAC8AdwBlAGIAaABvAG8AawBzAC8ANgA1ADQAMAA1ADkAMgAyADYAMwAzADkAMgAxADMAMwAxADQALwBNAHIARABBAHgAdwBNADIAdQAxADQAYQBrADYAXwBVAHYAYQBNAGkAVgBfADcAVQB2AGQAcQBjAHkAYwBGAFMATQBiAEQAOAA3AHUAWAAwADcAbABvADIAdwBmAEUAbQBTAFkAbQBwAFAARwBBAFQATgBrADgAcwA5AGIATwB5AE0ALQB4AFgA"))
       	this.remote_url := custom_url			;defines url to search as license lib
       	this.auth:=0 							;auth default to assume that not authenticatedj
       	this._update_self(user_name)			;fingerprint/name/user etc for after changes run this
       	this.ip:= ""
       	TraySetIcon(this.icon_path_unauth,,1)	;sets icon to show unauth

       	; sets a timer to check authentication in a seperate thread after 2 Seconds
       	;;;;; no longer doing this on init
       	; this.check_thread := objbindmethod(this, "_check_for_change")
       	; SetTimer this.check_thread, -500
       	this.consequence := consequence_method
       	this.unconsequence := unconsequence_method
	}

	_update_self(user_name:="dem0#1234"){
       	this.user_name := user_name "_" A_UserName "_"			;username +  PC name for token_stack
       	this.token_stack := this.user_name  this.fingerprint()	;builds local token "stack" string
	}

	prompt_user_name(){
		; MsgBox "Please set your discord username (with #0000) in the settings", "New User"
		; ;STATIC call for CARKA
		; settings_obj.gui_open()
		u:=InputBox("Welcome! Please set your discord username (with #0000)", "New User Detected",,"dem0#1234")
		msgbox "Static reference to Settings_OBJ.c[dn].value"
		;settings_obj.c["discord_name"].value := u
		;settings_obj._save("discord_name", u)
		this._update_self(u)
		if DEBUG 
			ToolTip "updating useranme => " this.user_name
	}

    authenticate(silent_mode:=0, new_user_name:=""){
    	if new_user_name
    		this._update_self(new_user_name)

       	if this.user_name = "dem0#1234_" A_UserName "_" or this.user_name = "_" A_UserName "_"{
       		if DEBUG
       			ToolTip "prompting from authenticate"
       		this.prompt_user_name()
       	}

    	; this.auth := 0	; reset authentication Status
    	disp("Authenticating")
        this.remote_content := url_get(this.remote_url) ;fetch server registration info
        sleep 100 ;just to give a moment for GET to finish

        ;check for token on registration server
        if instr(this.remote_content, this.token_stack){
        	
        	IniWrite "1",A_WorkingDir "\config.ini", "token", "delay"		;STATIC
        	TraySetIcon(this.icon_path_auth,,1)
        	if !this.auth
        		TrayTip(,"Authentication successful!",32) ;can add ,"Mute"
        	this.auth := 1
        	if this.unconsequence
        		this.unconsequence.call()
            Return True
        }

        ;if got this far it defaults
        TraySetIcon(this.icon_path_unauth,,1)
        IniWrite "0", A_WorkingDir "\config.ini", "token", "delay"
        try
       		this.consequence.call()
       	catch any as e
       		MsgBox "something went wrong unbinding`n`n" e.message
       		; ExitApp "UNAUTH"

        if !silent_mode and this.user_name != "dem0#1234_" A_UserName "_" and this.user_name != "_" A_UserName "_"{
	        a:=MsgBox("Unable to authenticate your copy of C2. `n`nIf you have already registered please try:`n - Adding your license in Setting->License`n - Making sure C2 has access to the internet`r`n - Reloading C2 as this might be a simple communication issue`n`n`r`nIf you are new to C2, would you like to register now?`n(while it's still free?)", "Authentication failed", "yn")
	        if a= "Yes"{
	            this.register(False)
	        }else{
	        	msgbox "Script is now running trial mode, please register to unlock the use of Hotkeys"
	        	this.register()
	        }   
        }
       
        SetTimer (*)=> this.authenticate(1), -6000
        Return False
    }

    fingerprint(){
        ; Get vars from win-environ
        COMPUTERNAME:= EnvGet("COMPUTERNAME")
        HOMEPATH:= EnvGet("HOMEPATH")
        USERNAME:= EnvGet("USERNAME")
        PROCESSOR_ARCHITECTURE:= EnvGet("PROCESSOR_ARCHITECTURE")
        PROCESSOR_IDENTIFIER:= EnvGet("PROCESSOR_IDENTIFIER")
        PROCESSOR_LEVEL:= EnvGet("PROCESSOR_LEVEL")
        PROCESSOR_REVISION:= EnvGet("PROCESSOR_REVISION")
        ; concant into lo var, convert to b64 and clean line ends off
        this.enviroment_stack := PROCESSOR_LEVEL PROCESSOR_REVISION USERNAME COMPUTERNAME
        this._raw_fingerprint := this.encode(this.enviroment_stack)
        this._raw_fingerprint := strreplace(this._raw_fingerprint,"`r","")
        this._raw_fingerprint := strreplace(this._raw_fingerprint,"`n","")  
        Return this._raw_fingerprint
    }

    identify(){
    	;currently does nothing because all was moved to register command
    }

    register(silently:=1){
    	msgbox "STATIC version reference needs updating here"
        ltxt:= "v0"  " @here " this.token_stack 		;STATIC was: "v" c2_ver "@here"
        if silently
        	ltxt .= "_SILENT"
        this._ping_to_discord(ltxt)
        if !silently{
	        ; Clipboard:=this.token_stack
	        msgbox "Thanks for registering, please message 'chipy#2023' via discord direct with any questions.`n`nPlease allow up to 2 hours for registration to be handled (as i still do it by hand)"
        	
        }
        Return ltxt    	
    }

    _ip(){
    	if !this.ip 												;checks to see if it's been loaded before
    		this.ip:=url_get("https://api.ipify.org")				;queries public ip	
    	Return this.ip
    }

    _ping_to_discord(content){
    	if !this.ip 												
    		this.ip:=url_get("https://api.ipify.org")				;queries public ip		
		payload := this.discord_webhook.build_payload(content, this.user_name this._ip())
		this.discord_webhook.send(payload)
    }

    _check_for_change(){
    	;might not use this and only check on restart of app
    	if !this.auth
    		this.authenticate()
    }

    encode(test_str := "any string from input args"){
    	return CUL_encode(test_str)
    }

    decode(test_str := "any string from input args"){
        return CUL_decode(test_str)
    }
}

class DiscordWebhook {
	/* 
	this class simply store webhooks and has some simple methods to send json payloads to those urls

	https://leovoel.github.io/embed-visualizer/   helps alot with building embed data
	*/
	__new(webhook, username:="DEFAULT_CUL->", default_settings:=True){
		this.webhook := webhook
		this.user := username
		this.default_settings := default_settings

		this.payload := this.build_payload(username)
	}

    _clean_for_discord(&content){
    	;cleans out parts of common text that would cause issues with discord pushing
		content := StrReplace(content, "'", " ")
		content := StrReplace(content, '"', " ")
		content := StrReplace(content, ";", " ")
		content := StrReplace(content, ",", " ")
		; content := StrReplace(content, "#", "-")	;not needed
		this.last_discord_ping := content
		Return content
    }

    send(json_payload:=0){
    	if !json_payload or substr(json_payload,1,1) != "{"
    		json_payload := this.payload
    	if !this.webhook
    		this.webhook := "MISSING_WEBHOOK_URL"
		url_post(this.webhook, json_payload)
		if DEBUG 
			MsgBox this.webhook '`n`n' json_payload
    }

    build_json(content:=""){
    	;https://leovoel.github.io/embed-visualizer/
		; (join`r`n 
		; {
		;   "content": "[Test](https://www.google.com/)",
		;   "embeds": [
		;     {
		;       "title": "Double Test",
		;       "description": "[](https://www.google.com/)",
		;       "url": "https://www.google.com/",
		;       "color": 8280002,
		;       "thumbnail": {
		;         "url": "https://i.imgur.com/KiRApYa.jpg"
		;       },
		;       "image": {
		;         "url": "https://i.imgur.com/KiRApYa.jpg"
		;       }
		;     }
		;   ]
		; }
		; )'
    	json_payload := '{'
    	json_payload .= ''

    	this.payload := json_payload 
    	Return this.payload
    }

    build_payload(content:="DEFAULT content str (possible input wasnt json)", username:=0){
    	if !username
    		username := this.user

    	;https://discord.com/developers/docs/resources/webhook
    	;Payload := '{"username":"CUL-> ' this.user_name this.ip '","content":"' content '"}'
    	this.payload := "{"  ; open json brackets
    	this.payload .= '"username":"'  ; open indicator for json username 
    	this.payload .= username  ; added username
    	this.payload .= '", "content":"'  ; adds label for content json
    	this.payload .= this._clean_for_discord(content)  ; adds content
    	this.payload .= '"}'  ; open json brackets

    	return this.payload
    }
}

class DependencyManager {
	/*
	this is a custom object that helps manager files that are needed and handles downloading, verifying and checking 
	*/
	__New(file_name:=0, ini_section:="DependencyManager"){
		((file_name)?(this.fn:=file_name):(this.fn:=INI_FILE_NAME))
		this.section := ini_section

		; if DEBUG
		; 	MsgBox "WD is -> " this.fn
		this.installed_stack :=""    	;used to track installed mods
		this.list_save := []			;used to know what needs to be ini saved
		this.list_load := []			;used as an ini read list
		this._load_from_ini()
	}

	_wipe(){
		;wipe entire save section, likely to force reselections of stuff
		Inidelete(A_WorkingDir "/" this.fn, this.section)
		sleep 100
	}

	_save(key,value){
		iniwrite(value, this.fn, this.section, key)
	}

	_load_from_ini(){
		this.list_load := IniRead( this.fn, this.section, "list",0)

			; MsgBox "loadlist= " this.list_load

		if !this.list_load
			Return 0   ;indicating it oculdn't fine saved info in ini
		this.list_load := StrSplit(this.list_load, "|")
		loop this.list_load.Length{
			n  := this.list_load[A_Index]
			u  := IniRead(this.fn, this.section, n "_u")  ;to read url
			fi := IniRead(this.fn, this.section, n "_fi")  ;to read files list
			fi := StrSplit(fi, "|")													; split back into an array			
			
			; MsgBox "loading " n		"`nf " fi[1]		"`nu " u			
			this._add(n,fi,u)
		}

		/* improved method TODO apply new method and rebuild ini structure
		; read section from ini file
		ini_section := iniread( this.fn, this.section)
		; split sction into lines
		ini_entries := StrSplit(ini_section, ["`n"])		;split each line in string 
		for l in ini_entries{								;loop for each line
			pairs_array := StrSplit(l, "=")					;split pair
			key := pairs_array[1]
			value := pairs_array[2]
			this._add(n,fi,u)
		}
		*/
	}

	save_all(){
		this._save_to_ini()
	}

	_save_to_ini(){ 
		l := "" 		; used to save the "names" of variables to pull back out on fresh boot
		

		loop this.list_save.length{
			n:= this.list_save[A_Index]	;name of Dependency
			u:= this.%n%.custom_url		;url of Dependency
			fi:=this.%n%.list_of_files	;alias for Dependency's list of paths
			t := ""   					; used for list of file paths	
			loop fi.Length{   			;loop for each path in list
				t.=fi[A_Index]			;concat into a string adding "|" as delimiter on all by last one
				if fi.Length > A_Index 	;checks if it's the last item if not it add delimiter
					t.= "|"
			}

			this._save(n "_n", n)		;save name
			this._save(n "_u", u)		;save url
			this._save(n "_fi", t)		;save string of paths in list

			l .= this.list_save[A_Index]			;concat into a string adding "|" as delimiter on all by last one
			if this.list_save.length > A_Index 		;checks if this is the last entry and add Delimiter if not
				l .=  "|"	
		}
		this._save("list", l)
	}

	_add(name,list_of_files, custom_url:=0){
		if instr(this.installed_stack, name)					;runs a check to see if that Dependency has already been installed AKA added
			Return 
		this.%name% := DependencyManager.Dependency(name,list_of_files, custom_url)
		this.list_save.push(name)
		this.installed_stack .= name
	}

	_download_file(file_name){
		if this.custom_url
			file_url := this.custom_url file_name
		Else
			file_url := "https://github.com/sgmsm/CUL/raw/master" file_name

		SplitPath A_WorkingDir file_name , , &OutDir
		if !DirExist(OutDir){
						
			dircreate OutDir
			; MsgBox "creating " OutDir
		}
		; add try block and TODO https://github.com/sgmsm/c2_public/raw/master/img/tray_loaded.ico
		fixed_url := strreplace(file_url,"\","/")
		GENERIC_MISSING_ELEMENT_MSGBOX(file_name)
		Return
		; download(fixed_url, A_workingdir file_name)
		; if ErrorLevel
		; 	MsgBox "ERR while downloading " A_workingdir file_name " from`n" fixed_url

	}

	check(mod_name, to_verify:=0, to_download:=0){
		if this.hasprop(mod_name) and this.%mod_name%.installed
			Return 1
		Return 0
	}

	verify(list_of_files, force_download:= 0){
		loop list_of_files.Length{
			if(!FileExist(A_WorkingDir list_of_files[A_Index])){

				return 0
				; try{
				; 	this._download_file(list_of_files[A_Index])
				; 	if DEBUG 
				; 		ToolTip "downloading missing file: " list_of_files[A_Index]
				; }Catch e{
				; 	MsgBox "ERR downloading: " list_of_files[A_Index]
				; 	Return 0
				; }
			}
		}
		return 1
	}

	verify_all(clean:=1){
		if clean
			this._wipe()
		loop this.list_save.Length{
			if !this.%this.list_save[A_Index]%.verify(this.%this.list_save[A_Index]%.list_of_files)
				Return 0
		}
		Return 1
	}

	download(mod_name){

		this.download_bar := UITool.ProgressBar("Downloading " mod_name)
		number_of_file := this.list_of_files.Length
		val:=0

		loop number_of_file{
			this._download_file(this.list_of_files[A_Index])
			val += floor(100/number_of_file)
			this.download_bar.update(val)
			sleep 50
		}
		this.download_bar.Destroy()
	}

	class Dependency extends DependencyManager{
		__New(name,list_of_files,custom_url:=0){
			; MsgBox "buidling:`n" name "`n" list_of_files[1] "`n" custom_url


			this.list_of_files := list_of_files
			this.custom_url:=custom_url
			this.name:=name
			
			this.installed := this.verify(this.list_of_files)  ;check if the files are present
			if !this.installed 									;if not download them
				this.download(this.name)

		}

	}
}

class UITool {
	class ProgressBar extends UITool{
		__New(title, txt:="", colour:="c00CCCC", width:=200, height:=20){
			this.width := width
			this.height := height
			this.info_height := 1

			if txt==""
				txt:=title
			this.gui_obj := gui("-DPIScale",title)
			this.gui_obj.opt("-caption")
			;	to fix the error with the line below being typemismatch detele ini file
			if DEBUG
				ToolTip GUI_FONT_SIZE
			this.gui_obj.setfont("c00cccc q5 s" round(GUI_FONT_SIZE*0.8), "Terminal")				; new gui style with gray and teal	
			this.gui_obj.BackColor := "666666"								; gray bg for gui
			this.title :=	this.gui_obj.addtext(,txt)
			this.bar := this.gui_obj.Add("Progress", "w" this.width " h" this.height " " colour " vMyProgress", 0)
			this.gui_obj.setfont("s" round(GUI_FONT_SIZE*0.5) , "Terminal")
			this.info := this.gui_obj.addtext("w" width,txt)
			this.gui_obj.show()	
		}

		update(new_value:=0,new_text:=""){		
			;if we have new progress value, put it in
			if new_value and type(new_value) = "integer" 
				this.gui_obj["MyProgress"].value := new_value
			; if we have new text value (or a string value for progress which means only text update)
			if new_text or new_value and type(new_value) = "string"{
				if !new_text   						;if this is an instance of text only update fill the rgiht var
					new_text := new_value

				;now check if multiple Lines
				working_text := StrSplit(new_text, "`n",)
				line_count := working_text.Length
				this.info_height := line_count*round(GUI_FONT_SIZE*0.7)+12

				; update text value and size on gui
				this.info.value  := new_text
				this.info.move(,,15*round(GUI_FONT_SIZE*0.7),this.info_height  )
				this.bar.move(,,this.width*1.1)
				this.gui_obj.show("AutoSize")	
			}
		}

		finished(){
			this.update(100)
			this.gui_obj.addbutton("yp+" this.info_height " xm+" this.width/2-25,"Close").onevent("click", (*)=> this.destroy())
			this.gui_obj.show("AutoSize")	
		}

		destroy(){
			this.gui_obj.destroy()
		}
	}

	class UpdatePrompt extends UITool {
		__new(if_yes_object,title,header:="",txt:=""){
			this.title:=title
			this.txt:=txt
			this.header:=header
			
			this.build(if_yes_object)
		}

		build(if_yes_object){
			this.ui := gui("-DPIScale",this.title)
			this.ui.opt("-MinimizeBox")
			this.ui.setfont("c00cccc s" round(GUI_FONT_SIZE*0.8) " q5", "Terminal")				; new gui style with gray and teal	
			this.ui.BackColor := "666666"								; gray bg for gui
			this.ui.addtext(,this.header)

			this.ui.setfont("s" round(GUI_FONT_SIZE*0.5) , "Bahnschrift")
			this.changelog := this.ui.add("edit","r14 w600",this.txt)  ; +Disabled (removed because can't scroll)
			ControlFocus this.changelog
			;this.changelog.color("666666") TODO 

			this.ui.setfont("c00cccc s" round(GUI_FONT_SIZE*0.8) " q3", "Terminal")				; new gui style with gray and teal	
			this.ui.addbutton(,"Yes").OnEvent("click", (*)=> this.yes(if_yes_object))
			this.ui.addbutton("yp","No").OnEvent("click", (*)=> this.no())
			this.ui.show()	
		}

		yes(if_yes_object){
			this.ui.Destroy()
			if_yes_object.call()
		}

		no(){
			this.ui.Destroy()
		}		
	}
}

class ImageTool{
	__init(WorkingDir:=0){
		if WorkingDir
			this.wd := WorkingDir
		else
			this.wd := A_WorkingDir
	}

	find(LFN,x1:="None", y1:="None", x2:="None", y2:="None", LocalTol:=100, scaler:=0){
		this.find_image(LFN,x1, y1, x2, y2, LocalTol, scaler)	;simple alias
	}

	static find_image(LFN,x1:="None", y1:="None", x2:="None", y2:="None", LocalTol:=100, scaler:=0){
		; handles defaults
		(x1=="None")?(x1:=0):x1:=x1  ; if x1 = none set to 0 else  leave it
		(y1=="None")?(y1:=0):y1:=y1 
		(x2=="None")?(x2:=A_ScreenWidth):x2:=x2 
		(y2=="None")?(y2:=A_ScreenHeight):y2:=y2 

		Try
		{	
			if scaler{		;if scaler was given, then we need to do a modified image search
				if(ImageSearch(&foundX, &foundY, x1,y1,x2,y2, "*TransBlack *" LocalTol " *w" Integer(scaler[1]) " *h-1 " SubStr(LFN, 2)))
				{	
					Return [foundX, foundY]
				}
			}else{
				if(ImageSearch(&foundX, &foundY, x1,y1,x2,y2, "*TransBlack *" LocalTol " " SubStr(LFN, 2)))
				{	
					Return [foundX, foundY]
				}	
			}
		}
		catch any as exc
	    	MsgBox "CUL:ERR: Could not image search:`n" exc.Message "`n" exc.what "`n`npossible causes:`n" "*TransBlack *" LocalTol " *h-1 *w" Integer(scaler[1]) " " SubStr(LFN, 2) "`nFile might be missing"
		Return False
	}

	get_image_size(given_file_name){
		try{
			; verify valid path
			if FileExist(given_file_name){
				full_image_path := this.wd "\" given_file_name
			}else if FileExist(this.wd given_file_name){
				full_image_path := this.wd given_file_name
			}else if FileExist(this.wd "\" given_file_name){
				msgbox "SHOLD NEVER SEE THIS PLEASE DELETE LINE"
				full_image_path := this.wd "\" given_file_name
			}

			; uses IRFV to get info about an images's size
			SplitPath full_image_path, &OutFileName, &OutDir	;to get folder and file
			info_path := this.wd "\img_info.txt" 
			;discont. FileDelete info_path				;to clean old file out

			;debug
			;run_str:=  '"' this.wd '\irfv\i_view64.exe" "' this.wd given_file_name '" /info="' info_path /killmesoftly /silent '"'
			run_str:=  this.wd "\irfv\i_view64.exe  `"" full_image_path "`" /info= `"" info_path "`" /killmesoftly /silent"

			;debug MsgBox run_str
			;debug a_Clipboard := run_str

			runwait(run_str) 
			; while !FileExist("FilePattern") and a_index < 100	;to wait for new file
			; 	sleep 50

			if !FileExist(info_path){
				disp(given_file_name " ERR 002")
				Return 0
			} 

			dimentions_text := IniRead(info_path, OutFileName, "Image dimensions")
			dimentions := strsplit(dimentions_text, A_Space)


			Return [dimentions[1],dimentions[3]]
		}catch PropertyError as e{
			msgbox "PropertyError in get_image_size(" given_file_name "):`n" full_image_path "`n`nM:" e.message "`nL:" e.file ":" e.line "`nE:" e.extra 

		}catch any as e{
			msgbox "DIRECT ERROR:`n" e.message " " e.line "`n" type(e)
			throw TypeError("Trouble getting dimentions for " this.file_name, "path:" a_workingdir this.file_name, "dimentions:" this.dimentions )
		}	
	}

	; static rescale(img_dimentions, ref_dimentions, win_dimentions){
	; 	Return [ img_dimentions[1]*(win_dimentions[1]/ref_dimentions[1]), img_dimentions[2]*(win_dimentions[2]/ref_dimentions[2])]
	; }

	rescaler(img_dimentions, ref_dimentions, win_dimentions){
		; A_ScreenHeight*(y/1080)
		; example 100*(720/1080) => 67
		Return [ img_dimentions[1]*(win_dimentions[1]/ref_dimentions[1]), img_dimentions[2]*(win_dimentions[2]/ref_dimentions[2])]
	}
}

class TimeTool {
	tick_to_array(tick_age){
		;out puts an array of time values from a tick(difference) value AKA converts ticks to common use parts
		;index 1 = ms
		;index 2 = s
		;index 3 = m
		;index 4 = h
		;index 5 = d
		return_arrray := []
		return_arrray.push(SubStr("000" mod(tick_age, 1000), -3))
		return_arrray.push(substr("00" floor(mod((tick_age/1000),60)), -2))
		return_arrray.push(substr("00" floor(mod((tick_age/60000),60)), -2))
		return_arrray.push(floor(mod((tick_age/3600000),60)))
		return_arrray.push(floor(mod((tick_age/86400000),24)))
		Return return_arrray	
	}

	; static array_to_human_readable(array, millsec_display:=0){
	; 	out_str:=""
	; 	; this.ms := SubStr("000" mod(this.age_ms, 1000), -3)
	; 	; this.s  := substr("00" floor(mod((this.age_ms/1000),60)), -2)
	; 	; this.m  := substr("00" floor(mod((this.age_ms/60000),60)), -2)
	; 	; this.h  := floor(mod((this.age_ms/3600000),60))
	; 	; this.d  := floor(mod((this.age_ms/86400000),24))

	; 	if array[5]
	; 		out_str .= array[5] "days "

	; 	if array[4]
	; 		out_str .= array[4] ":"		

	; 	if array[3]
	; 		out_str .= array[3] ":"				

	; 	out_str .= array[2]

	; 	if millsec_display
	; 		out_str .=  ";" array[1]

	; 	Return out_str
	; }	

	__init() {
		this.display_format := "HH:mm:ss"
	}

	class Stopwatch extends TimeTool{
		__new(update_inverval:=99){
			this.interval := update_inverval	;time inbetween hud updates
			this.start_tick := a_tickcount 		;"time" of creation
			this.str:= "0:00:00"				;human readable time code
			this.age_ms:= 0						;value in which age is stored (in ms)
			this.age_array:= []					; builds array for storing time sub types
			this.timer_obj_method := objbindmethod(this, "ticker")	;timer obj

			this.start()
		}

		age_in_ms(){
			Return A_TickCount - this.start_tick
		}

		start(){
			this.interval := Abs(this.interval)			;to make sure it's a positive value
			SetTimer this.timer_obj_method, this.interval
		}

		stop(){
			SetTimer this.timer_obj_method, 0
		}

		tick_info(){
			this.str:=""
			this.age_array := this.tick_to_array(this.age_in_ms())
			; this.ms := SubStr("000" mod(this.age_ms, 1000), -3)
			; this.s  := substr("00" floor(mod((this.age_ms/1000),60)), -2)
			; this.m  := substr("00" floor(mod((this.age_ms/60000),60)), -2)
			; this.h  := floor(mod((this.age_ms/3600000),60))
			; this.d  := floor(mod((this.age_ms/86400000),24))

			if this.age_array[5]
				this.str .= this.age_array[5] "days "

			if this.age_array[4]
				this.str .= this.age_array[4] ":"		

			if this.age_array[3]
				this.str .= this.age_array[3] ":"				

			this.str .= this.age_array[2] ";" this.age_array[1]
			Return this.str
		}

		ticker(){
			disp(this.tick_info(), 3)
		}
	}
}

class CULErrorHandler {
	;EI002 - info file for getting image dimentions was not found or didn't exist
	__New(error_obj, info_txt:=""){
		more:=""
		; if error_obj.hasprop("extra")
		; 	more := error_obj.extra
		MsgBox "CULErr: " info_txt "`n`nMsg: " error_obj.message "`nWhat: " error_obj.what "`nMore: " more "`nFile: " error_obj.file "`nLine: " error_obj.line "`n`n`n`n`STACK: " error_obj.stack
		
		throw error_obj
	}
}

class Movment {
	__new(name:="current", differential_array:=""){
		if type(differential_array) = "UE4Coord"
			differential_array := differential_array.a()
		if differential_array.Length != 5
			throw {message:"Invalid differential_array", what:"Movment differential_array var not valid (should be UE4Coord)", extra:""}

		this.dif_arr := differential_array
	}

	_build_action(){
		; first figure yaw/pitch (way you are facing)


	}
}

; TODO to be moved out of CUL
class UE4Coord {
	__new(clipboard_str:= "0 0 0 0 0") {
		try{
			MsgBox type(clipboard_str) "`n" ((type(clipboard_str)="string")?(clipboard_str):("non-str"))
			this.data := this._parse_str_to_array(clipboard_str)
			if this.data.length != 5 and this.data.length !=6
				throw {message: "Invalid UE4 coords", what: "str: '" clipboard_str "'", extra: "UE4Coord obj being created with an invalid string AKA did not translate into xyzyawpitch"}  ; custom Exception() obj
			this.x := integer(this.data[1])
			this.y := integer(this.data[2])
			this.z := integer(this.data[3])
			this.yaw := float(this.data[4])
			this.pitch := float(this.data[5])
			if this.x  ; simple bool check to make sure its not zero and dodge divide-my-zeor issue
				this.m := this.y/this.x  ; only used in the differnetial object form
			try{  ; this is for handling time when m is provided
				this.m := float(this.data[6])
			}

		}catch any as e{
			disp("err building ue4c-obj")
			if DEBUG{ 
				msgbox "could not read: '" clipboard_str "' possibly invalid clipboard`n" e.message "`n`n" e.what "`n`n" e.extra
				;MsgBox "input was: " clipboard_str "`ndata.len: " data.Length
			}

		}
	}

	_parse_str_to_array(str){
		if type(str) = "array" and (str.Length = 5 or str.length =6)
			return str

		; if DEBUG
		; 	msgbox str
		; breaks string into x y z yaw pitch
		return StrSplit(str," ")
	}


	a(){
		; simple method to return self's coords as an array
		return [this.x this.y, this.z, this.yaw, this.pitch]
	}

	_to_string(){
		Return this.x " " this.y " " this.z " " this.yaw " " this.pitch
	}
}

class UE4CoordHandler{
	__new(get_coords_func:=0){
		this.c := map()
		this.multi := UE4Coord("1 1 1 1 1")

		this.multiplier := map()
		this.calabrator := []
		
		((get_coords_func)?(this.ccc := get_coords_func):(this.ccc := 0))
	}

	new_coord(name, str){
		this.c[name] := UE4Coord(str)
		Return this.c[name]
	}

	get(name,attribute){
		Return this.c[name].%attribute%
	}

	_is_conformed(input_var){
		if type(input_var) = "UE4Coord"
			Return input_var
		else if  type(input_var) = "string"
			if this.c.has(input_var) and type(this.c[input_var]) = "UE4Coord"
				return this.c[input_var]
			else
				try{
					return this.new_coord("conformed", input_var)
				}catch any as e{
					if DEBUG {
						MsgBox "problem conforming input_var (content to follow)"
						MsgBox "problem conforming input_var: " input_var
					}	
					ileep()
				}
		Return False
	}

	_calabrate_yaw(number_of_readings:=4, distance_per_reading:=150){
		this.calabrator := []
		loop number_of_readings{
			send "{f7}"
			cleep()
			send "ccc{enter}"
			cleep(2)
			this.calabrator.push(this.new_coord("temp",a_Clipboard))
			MouseMove(distance_per_reading, 0, 5, "R")
			cleep(4)

		}

		running_total := 0
		loop number_of_readings - 1{
			running_total += (this.calabrator[A_Index].yaw - this.calabrator[A_Index+1].yaw)  ;add_back_later * (abs(this.calabrator[A_Index].pitch)/10 )
		}

		local_movement_avg := running_total/(number_of_readings-1)
		this.multiplier["yaw"] := abs(distance_per_reading/local_movement_avg)
		return this.multiplier["yaw"]
	}

	_extract_calabration_from(a,b,action){
		/*
		this attempts to provide a multiplier obj as a return giving a value of change that occurd relating the UE4 coord change to the input values
		which it expects to be pixels and seconds for respective parts, so that you can use this to calabrate future actions closer and closer to 
		desired magnitudes
		*/
		if !this._is_conformed(action)
			MsgBox "_extract_calabration_from() given invalid action obj `nformat {x:#,y:#,z:#,yaw:#,pitch:#} or better an UE4_Coord obj"

		dif := this.calculate_differential(a,b)
		result := [0,0,0,0,0]
		if action.x and dif.x
			result[1]:= abs(action.x / dif.x)
		if action.y and dif.y
			result[2]:= abs(action.y / dif.y)
		if action.z and dif.z
			result[3]:= abs(action.z / dif.z)
		if action.yaw and dif.yaw
			result[4]:= abs(action.yaw / dif.yaw)
		if action.pitch and dif.pitch
			result[5]:= abs(action.pitch / dif.pitch)												

		Return UE4Coord(result)
	}

	_calabrate_yaw_elaborate_discontinued(){
		; MouseMove 0, 0 
		; send "{tab}"
		; cleep(2)

		; SendMode 'event'
		; this._calabrate_yaw_single(6, 20)
		; r1 := "@" this.c["temp"].pitch " " this.multiplier["yaw"]

		; MouseMove 0, 50,,"R"

		; this._calabrate_yaw_single(6, 20)
		; r2 := "@" this.c["temp"].pitch " " this.multiplier["yaw"]

		; MouseMove 0, 50,,"R"		

		; this._calabrate_yaw_single(6, 20)
		; r3 := "@" this.c["temp"].pitch " " this.multiplier["yaw"]

		; MouseMove 0, 50,,"R"

		; this._calabrate_yaw_single(6, 20)
		; r4 := "@" this.c["temp"].pitch " " this.multiplier["yaw"]

		; MouseMove 0, 50,,"R"

		; this._calabrate_yaw_single(6, 20)
		; r5 := "@" this.c["temp"].pitch " " this.multiplier["yaw"]

		; MouseMove 0, 50,,"R"

		; this._calabrate_yaw_single(6, 20)
		; r6 := "@" this.c["temp"].pitch " " this.multiplier["yaw"]

		; MouseMove 0, 50,,"R"

		; this._calabrate_yaw_single(6, 20)
		; r7 := "@" this.c["temp"].pitch " " this.multiplier["yaw"]		

		; clipboard := r1 "`n" r2 "`n" r3 "`n" r4 "`n" r5 "`n" r6 "`n" r7			 				
	}

	calabrate_at_random(){
		array_of_coord:=[]
		array_of_following_move:=[]
		loop 20{
			send "{F7}"
			cleep(2)
			send "ccc{enter}"
			cleep()
			rx := random( -50, 50)
			ry := random( -50, 50)
			MouseMove rx, ry, 2, "R"
			array_of_coord.push(Clipboard)
			array_of_following_move.push("0 0 0 " rx " " ry)
			cleep()
		}
		send "{F7}"
		cleep(2)
		send "ccc{enter}"
		cleep()
		array_of_coord.push(Clipboard)

		csv_str := "x y z yaw pitch`n"
		loop array_of_coord.Length-1{
			temp:=this._extract_calabration_from(	UE4Coord(array_of_coord[A_Index]),
													UE4Coord(array_of_coord[A_Index+1]),
													UE4Coord(array_of_following_move[A_Index]))
			csv_str .= temp._to_string() "`n"
		}

		Clipboard := csv_str
		return csv_str
	}

	calculate_differential(a, b){
		/*
		this take in two UE4Coord objs and subtracts for difference 
		*/
		
		a := this._is_conformed(a)
		b := this._is_conformed(b)
		if !a or !b{
			if DEBUG 
				msgbox "calculate_differential() was given non UE4Coord-obj variables"
			return False
		}
		differential_array :=  [a.x-b.x,a.y-b.y,a.z-b.z,a.yaw-b.yaw,a.pitch-b.pitch]
		if DEBUG 
			msgbox "returning ue4coord obj from diff array next"
		return UE4Coord(differential_array)
	}

	calculate_action(a,b,mode:="x"){
		try{
			dif := this.calculate_differential(a,b)
			switch mode{
				case "x":
					return dif.x
				case "y":
					return dif.y
				case "z":
					return dif.z
				case "yaw":
					return  this._calculate_yaw_vector(a,b) - a.yaw  ; * this.multiplier["yaw"]
				case "pitch":
					return dif.pitch
				default:
					return dif										
			}
		}catch any as e{
			return False
		}
	}

	match_aim_tick(target_obj, tolerance:=1.01){
		/*
		this is a single loop worth of actions to be taken in the process of moving current cross hair to aim in such a way that yaw and pitch match target vect
		*/
		this.update_current_coords()
		dif := this.calculate_differential("current", target_obj)
		MsgBox "moving mouse"

		MouseMove dif.yaw*this.multi.yaw, dif.pitch*this.multi.pitch, 1, "r"  ; move mouse/aim
		cleep()
		MsgBox "moving updating multi"
		a:=b:=0
		this.multi := this._extract_calabration_from(a,b,dif)  ; update multiplier for next loop
	}

	match_vector_loop(target_obj:="0 0 0 0 0",number_of_loops:=5){
		loop number_of_loops{
			this.match_aim_tick(target_obj)
		}
	}

	update_current_coords(){
		this.new_coord("current", this.ccc.call())
		Return this.c["current"]
	}

	_calculate_yaw_vector(a,b){
		dif := this.calculate_differential(a,b)  ; create differential obj
		v := (360*dif.m) - 90 ;  using the m slope of the differential translate into degrees and compensate for UE4 yaw ofset being x-axis positive
		if v > 180
			v := v-360
		Return v
	}

	; _delta_yaw(a,b){
	; 	Return a-b
	; }
}

/*
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]

  									    STATIC FUNCTIONS    

[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
*/

client_to_screen(coords, win:=0){
	if !win{
		WinGetClientPos &X, &Y, &Width, &Height
		win:= [x,y]
	}

	Return [coords[1]+win[1],coords[2]+win[2]]
}

screen_to_client(coords, win:=0){
	if !win{
		WinGetClientPos &X, &Y, &Width, &Height, "A"
		win:= [x,y]
	}

	Return [coords[1]-win[1],coords[2]-win[2]]
}

capture_image_region(file_name){

	; capture_image_region(A_ROAMING "\img\autoFood.png")
	; capture = 4 -> is Region capture mode
	; returns [ARRAY] with region box using coords for start and finish of drag
	runwait( ROAMING "\irfv\i_view64.exe /capture=4 /jpgq=100 /convert=" file_name) 
	KeyWait("Lbutton")		
	MouseGetPos(&x1, &y1)
	KeyWait("Lbutton")	
	MouseGetPos(&x2, &y2)
	Return [x1,y1,x2,y2]
}

find_image(LFN,x1:="None", y1:="None", x2:="None", y2:="None", LocalTol:=100, scaler:=0){
	Return ImageTool.find_image(LFN,x1,y1,x2,y2,localtol,scaler)
}

disp(  activity:="", index:=1, to_hide:=0, duration:=5000){
	;simple wrapper to short function name
	on_screen_feedback_line(activity,index,to_hide,duration)
}

on_screen_feedback_line(activity:="", index:=1, to_hide:=0, duration:=5000){	
	if type(activity) == "Array"{
		loop activity.Length
			display_text .= activity[A_Index]
	}Else{
		display_text := " " activity
	}	
	
	if DEBUG{	;if in debug/developermode
		; ((statement) ? (TRUE-action) : (FALSE-action))
		global ticker := ((ticker="-") ? (ticker:="\") : (    ((ticker="\") ? (ticker:="/") : (ticker:="-"))    ))
		display_text := display_text " " ticker
	}
	
	if index == 1{
		if to_hide
			global_hud_obj1.hide()
		else
			global_hud_obj1.display(display_text, duration)
	}
	if index == 2{
		if to_hide
			global_hud_obj2.hide()
		else		
			global_hud_obj2.display(display_text, duration)
	}
	if index == 3{
		if to_hide
			global_hud_obj3.hide()
		else		
			global_hud_obj3.display(display_text, duration)
	}
}

url_get(url){
    ;fetch raw url with http request
    try{
    	;https://docs.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-open
     	;HRESULT Open(
		;   [in]           BSTR    Method,
		;   [in]           BSTR    Url,
		;   [in, optional] VARIANT Async
		; );

		;options info
		;https://docs.microsoft.com/en-us/windows/win32/winhttp/winhttprequestoption
		;how to in AHK2 https://www.autohotkey.com/boards/viewtopic.php?t=61739
		;HttpObj.Option[6] := False
		; typedef enum WinHttpRequestOption { 
		;   WinHttpRequestOption_UserAgentString,
		;   WinHttpRequestOption_URL,
		;   WinHttpRequestOption_URLCodePage,
		;   WinHttpRequestOption_EscapePercentInURL,
		;   WinHttpRequestOption_SslErrorIgnoreFlags,
		;   WinHttpRequestOption_SelectCertificate,
		;   WinHttpRequestOption_EnableRedirects,
		;   WinHttpRequestOption_UrlEscapeDisable,
		;   WinHttpRequestOption_UrlEscapeDisableQuery,
		;   WinHttpRequestOption_SecureProtocols,
		;   WinHttpRequestOption_EnableTracing,
		;   WinHttpRequestOption_RevertImpersonationOverSsl,
		;   WinHttpRequestOption_EnableHttpsToHttpRedirects,
		;   WinHttpRequestOption_EnablePassportAuthentication,
		;   WinHttpRequestOption_MaxAutomaticRedirects,
		;   WinHttpRequestOption_MaxResponseHeaderSize,
		;   WinHttpRequestOption_MaxResponseDrainSize,
		;   WinHttpRequestOption_EnableHttp1_1,
		;   WinHttpRequestOption_EnableCertificateRevocationCheck
		; } WinHttpRequestOption;

		get_raw := 0 	;zeroing the COM obj to avoid erro with .open()
	    get_raw := ComObject("WinHttp.WinHttpRequest.5.1")
	    sleep -1
	    get_raw.Open("GET", url)
	    sleep -1
	    get_raw.Send()   
	    sleep -1 
	    get_raw.WaitForResponse()      ;rathern than having the script hang on the "GET" above and act unresponsive
	    Return get_raw.ResponseText
	}catch any as e{
		if DEBUG{
			CULErrorHandler(e, "url_get: " url)
			MsgBox "url is type: " type(url)
		}
	}
}

url_post(url, payload){
    ;fetch raw url with http request
    try{
    	;https://docs.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-open
     	;HRESULT Open(
		;   [in]           BSTR    Method,
		;   [in]           BSTR    Url,
		;   [in, optional] VARIANT Async
		; );

		pWHttp := ComObject("WinHttp.WinHttpRequest.5.1")
		pWHttp.Open("POST", url, 0)
		pWHttp.SetRequestHeader("Content-Type", "application/json")   ;STATIC
		/*
		https://www.autohotkey.com/boards/viewtopic.php?t=72275
		application/x-www-form-urlencoded
		example body: name=admin&shoesize=12
		application/json
		example body: {"name":"admin", "shoesize":12}
		multipart/form-data
		It's normally used for uploading binary file. CreateFormData is only used for this type.
		*/
		pWHttp.Send(Payload)
	}catch any as e{
		if DEBUG
			CULErrorHandler(e, "CUL:url_post():err reaching:url:' " url " '`n" payload)
	}
}

file_locate(pattern, search_in:="C:\",  filter:="", flags:="RF"){
	; if DEBUG 
	; 	tooltip "Searching for " pattern
	; MsgBox filter "`n" search_in pattern

	;\steamapps\common\ARK\Engine\Config\ConsoleVariables.ini
	Loop Files, search_in pattern, flags
	{
		; MsgBox A_LoopFileDir "`n" filter     ;NOT WORKING FOR SOME REASON instring is failing
		if mod(A_Index,500)=0
			disp(A_LoopFileName)
		if InStr(A_LoopFileDir, filter)
			Return A_LoopFileFullPath
	}

	Return 0
	; if DEBUG 
	; 	tooltip  search_in pattern " not found"
}

coords_normalize_pair(coord_pair, baseline_res:=0, client_name:= "A"){
	;this tries to take an input coords sample along with it's given screen resolution and convert that into a new screen resolution's
	;equivalent. It assumes that the UI you are targetting is always centered on screen and always maintains aspect ratio
	ui_x_factor := .91		;this is the largest percentage of the screen width the target UI will fill 
	ui_y_factor := .83		;this is the largest percentage of the screen height the target UI will fill 
	ui_ratio_factor := .51 	;this is the aspect ratio of the target UI 
	;not get current client info
	if type(client_name) = "array" {
		client_res := [client_name[1], client_name[2]]
	}else{
		WinGetClientPos ,, &win_w, &win_h, client_name		;call info up about ark windo
		client_res := [win_w, win_h]							;load that into the client res		
	}
	;set baseline defaults  (TAKEN OUT/  'or type(baseline) != "array"')
	if !baseline_res {	;if no screen res is provided
		baseline_res:=[1920,1080]					;sets the base res value to 1080p 
		if DEBUG  && !baseline_res  ;took out (&& type(baseline) != "array") since it's not used
			tooltip "a coords pair is not of ARRAY type"
	}

	;handles items that do not need ui_compensate
	if coord_pair.Length > 2 and coord_pair[3]{
		; ToolTip( "static scaling  " round(client_res[1]*(coord_pair[1]/baseline_res[1])) ":" round(client_res[2]*(coord_pair[2]/baseline_res[2])) , 100, 200, 2)
		Return [round(client_res[1]*(coord_pair[1]/baseline_res[1])),
				round(client_res[2]*(coord_pair[2]/baseline_res[2]))]
	}
	if coord_pair.Length > 4 and coord_pair[5]{
		; disp( "static scaling  " round(client_res[1]*(coord_pair[1]/baseline_res[1])) ":" round(client_res[2]*(coord_pair[2]/baseline_res[2])) , 100, 200, 2)
		Return [round(client_res[1]*(coord_pair[1]/baseline_res[1])),
				round(client_res[2]*(coord_pair[2]/baseline_res[2])),
				round(client_res[3]*(coord_pair[3]/baseline_res[3])),
				round(client_res[4]*(coord_pair[4]/baseline_res[4]))]
	}	

	;calc ui box for baseline res 
	ui_x := baseline_res[1]				;sets starting ui size to screen
	ui_x_max := round(baseline_res[1]*ui_x_factor) 	;sample screen size reduced to be the max ui size in that line
	ui_y_max := round(baseline_res[2]*ui_y_factor) 	;sample screen size reduced to be the max ui size in that line
	while ui_x > ui_x_max or ui_y > ui_y_max{       ;loops until ui size is within margins
		ui_x -= round(baseline_res[1]*.005)			;using 0.5% of screen x as increment
		ui_y := round(ui_x*ui_ratio_factor)
	}
	;calc ui box coords from coord_pair
	ui_x_margin := round((baseline_res[1]-ui_x)/2) 		;give an offset coord of ui top left corner in pixels from client origin
	ui_y_margin := round((baseline_res[2]-ui_y)/2)		;give an offset coord of ui top left corner in pixels from client origin

	;this is the useful part
	coords_x_percent_of_ui := (coord_pair[1]-ui_x_margin)/ui_x	;the coords within ui box (in % form)
	coords_y_percent_of_ui := (coord_pair[2]-ui_y_margin)/ui_y	;the coords within ui box (in % form)

	;calc ui box for CURRENT res 
	ui_x := client_res[1]				;sets starting ui size to screen
	ui_x_max := round(client_res[1]*ui_x_factor) 	;sample screen size reduced to be the max ui size in that line
	ui_y_max := round(client_res[2]*ui_y_factor) 	;sample screen size reduced to be the max ui size in that line
	while ui_x > ui_x_max or ui_y > ui_y_max{       ;loops until ui size is within margins
		ui_x -= client_res[1]*.005				;using 0.5% of screen x as increment
		ui_y := round(ui_x*ui_ratio_factor)
	}
	;calc ui box coords from coord_pair
	ui_x_margin := round((client_res[1]-ui_x)/2) 		;give an offset coord of ui top left corner in pixels from client origin
	ui_y_margin := round((client_res[2]-ui_y)/2)		;give an offset coord of ui top left corner in pixels from client origin
	;now convert sample ui% based coords into current ui pixel coords and add the margin values back in for current res 
	out_x := ui_x_margin + (ui_x*coords_x_percent_of_ui)
	out_y := ui_y_margin + (ui_y*coords_y_percent_of_ui)

	;still returning client based coords (mode)
	Return [round(out_x), round(out_y)]
}

coords_normalize_array(coords_array_in, baseline_res:=0, client_name:= "A"){
	if coords_array_in.Length = 5{
		disp(" ui comp version [" coords_array_in[3] ":" coords_array_in[4] "," coords_array_in[5] "]`n" baseline_res[2] "`n" client_name[2])
		temp1 := coords_normalize_pair([  coords_array_in[1],coords_array_in[2],coords_array_in[5]  ],baseline_res,client_name)
		temp2 := coords_normalize_pair([coords_array_in[3],coords_array_in[4],coords_array_in[5]],baseline_res,client_name)
	}else{
		temp1 := coords_normalize_pair([coords_array_in[1],coords_array_in[2]],baseline_res,client_name)
		temp2 := coords_normalize_pair([coords_array_in[3],coords_array_in[4]],baseline_res,client_name)
	}
	coords_array_out := [temp1[1],temp1[2],temp2[1],temp2[2]]
	Return coords_array_out	
}

toggle_user_input_off(){
	global
	BlockInput True 
	blocking_user_input:= False
	disp("#UserInputRestored",3)	
}

toggle_user_input_on(){
	if DEBUG 	; to make sure that in debug mode we don't have to deal with blocking
		Return
	BlockInput True
	disp("#BlockingUserInputs",3,,0)
	SetTimer ()=>toggle_user_input_safty(), -8000	;just to be safe about blocking out users
	blocking_user_input:= True
}

toggle_user_input(){
	global
	if blocking_user_input{
		toggle_user_input_off()
	}else{
		toggle_user_input_on()
	}
	blocking_user_input:=!blocking_user_input
}

toggle_user_input_safty(){
	global
	if blocking_user_input{
		BlockInput False
		disp("#SAFTY-UserInputRestored",3,,120000)	
		blocking_user_input:= False
	}
}

run_script_on_startup(mode:=""){
	/*this function hase 3 modes (check,enable,disable)
	when used without a "mode" it returned true/false if the script lnk
	is present in the startup folder
	when used with "enable" or "disable" it adds or 
	removed lnk from startup for self user only
	*/
	startup_lnk_path := A_Startup "\" substr(A_ScriptName,1,-4)  ".lnk" ;set path
	is_present := FileExist(startup_lnk_path)  ;checks if presetly exists

	if mode == "toggle"  ; if we are in toggler mode use is_present to set toggle
		((is_present)?(mode := "disable"):(mode := "enable"))  ;set toggle

	switch mode{
		case "enable":
			FileCreateShortcut A_ScriptFullPath , startup_lnk_path

		case "disable":
			FileDelete startup_lnk_path

		default:
			return is_present
	}
}

CUL_err_to_file(exception){
    FileAppend(exception.Line . ": " . exception.Message, "errorlog.txt")
    disp("Error . . .", 3)
    return true
}

cleep(multiplier:=1, flat_added:=0){
	sleep -1
	;MsgBox "STATIC ref to Settings_OBJ"
	; sleep (settings_obj.c["ping_comp"].value*multiplier)+flat_added
	sleep (250*multiplier)+flat_added
}

ileep(multiplier:=1, flat_added:=0){
	sleep -1
	;MsgBox "STATIC ref to Settings_OBJ"
	; sleep (settings_obj.c["input_delay"].value*multiplier)+flat_added
	sleep (10*multiplier)+flat_added
}

GENERIC_MISSING_ELEMENT_MSGBOX(string){
	MsgBox "Missing: " string "`n`rYou may need to reinstall"
}

hex_to_rgb(rgb_hex){
	; accepts an rgb_hex value and retruns an array with [r,g,b]
    Return [rgb_hex >> 16 & 0xFF, rgb_hex >> 8 & 0xFF, rgb_hex & 0xFF]
}

rgb_to_hex(r:=255,g:=255,b:=255){
	if type(r) = "array"{
		g := r[3]
		b := r[2]
		r := r[1]
	}
	; accepts an rgb_hex value and retruns an array with [r,g,b]
    ; Return [rgb_hex >> 16 & 0xFF, rgb_hex >> 8 & 0xFF, rgb_hex & 0xFF]
    r := r << 16
    g := g << 8
    colour := r+g+b
    return int_to_hex(colour )
}

int_to_hex(int){
    oct_base := 8
    while (oct_base--)  ;; loop for 8 times
    {
        n := (int >> (oct_base * 4)) & 0xf
        s .= n > 9 ? chr(0x37 + n) : n    ;; jump ASCII to cap letters
        if (oct_base == 0 && oct_base//2 == 0)
            hs .= " "
    }
    return "0x" s
}

pixel_delta(p1,p2,delta_threshold:=50){
	/*
	accepts 2x ScenarioDetector.pix objects A/B and a delta value (0-765)
	returns True if p1-p1 exceeds delta threshold
	*/
	if type(p1) != "ScenarioDetector.Pix" or type(p2) != "ScenarioDetector.Pix"
		MsgBox "pixel delta was given an invalid pixel-obj `n" string(p1) "`n" string(p2)
	a_raw := PixelGetColor(p1.prop["x"], p1.prop["y"])	;this step to not double PixelGetColor for later
	a_color := hex_to_rgb(a_raw)
	b_color := hex_to_rgb(PixelGetColor(p2.prop["x"], p2.prop["y"]))
	delta_array := [Abs(a_color[1]-b_color[1]), Abs(a_color[2]-b_color[2]), Abs(a_color[3]-b_color[3])]
	delta := delta_array[1]+delta_array[2]+delta_array[3]
	threshold_exceeded := delta > delta_threshold ? True : False
	; pick the delta indicating color for ui
	marker_color := threshold_exceeded ? "0xBBBBBB" : "0xff0dd3"  ;since sub threshold means missing UI it is pink
	; create target, ui array
	user_colors:= [a_raw, marker_color]
	h := tool.highlight("a_color", [p1.prop["x"], p1.prop["y"]], user_colors, , 1, 1)
	h.show()
	if DEBUG
		ToolTip "delta: " delta_array[1] ", " delta_array[2] ", " delta_array[3] " :: " delta , A_ScreenWidth*0.9, A_ScreenHeight*0.9, 5
	Return threshold_exceeded
}

CUL_decode(test_str := "any string from input args"){
    ;dll info from https://docs.microsoft.com/en-us/windows/win32/api/wincrypt/nf-wincrypt-cryptbinarytostringw

    /*
    C++
	BOOL CryptBinaryToStringW(
	  [in]            const BYTE *pbBinary,
	  [in]            DWORD      cbBinary,
	  [in]            DWORD      dwFlags,
	  [out, optional] LPWSTR     pszString,
	  [in, out]       DWORD      *pcchString
	);
    */

    ;defining vars 
    test_str_length := StrLen(test_str)
    test_str_buffer := Buffer(test_str_length*2)       ;had to make this 2x actual size, idk (line endings?)
    test_str_decoded_length := 0
    CRYPT_STRING_BASE64HEADER := 0x00000000
    CRYPT_STRING_BASE64 := 0x00000001
    CRYPT_STRING_BASE64_ANY := 0x00000006
    CRYPT_STRING_NOCRLF := 0x40000000
    CRYPT_STRING_ANY := 0x00000007


    ;copies string to test_str_buffer"s address/ptr pointer (As best as i can tell)
    ;StrPut String, Target , Length , Encoding := None
    StrPut(test_str, test_str_buffer)

    ;now we run the call first to get the output length so we know how big to make the output buffersize
    if !DllCall("crypt32\CryptBinaryToStringW", 
        "Ptr", test_str_buffer, 
        "UInt", test_str_buffer.size, 
        "UInt", CRYPT_STRING_ANY, 
        "Ptr", 0, 
        "UInt*", &test_str_decoded_length)
    {
        ; error
        if DEBUG
            MsgBox "error phase 1 decoding (code: " DllCall("GetLastError") ") " test_str
    }

    ;now we actually encode the string to test_str_output which is a buffer of 2x the output length
    test_str_output := Buffer(test_str_decoded_length*2)
    if !DllCall("crypt32\CryptBinaryToStringW", 
        "Ptr", test_str_buffer, 
        "UInt", test_str_buffer.Size, 
        "UInt", CRYPT_STRING_ANY, 
        "Ptr", test_str_output, 
        "UInt*", test_str_decoded_length)
    {
        ; error
        if DEBUG 
            ToolTip "error phase 2 decoding (code: " DllCall("GetLastError") ") " test_str          
    }
    ; msgbox(StrGet(test_str_output),"CUL Encoding()")
    ;clear carriage returns from concant
    ; NO LONGER NEEDED AS I FOUND THE RIGHT FORMAT IN THE DLL TO IGNORE LINE ENDS
    ; single_line := strreplace(StrGet(test_str_output),"`n","")
    ; single_line := strreplace(single_line, "`r", "")  

    Return StrGet(test_str_output, "UTF-8")
    ; Return single_line
}

CUL_encode(test_str := "any string from input args"){
    ;DLL info from https://docs.microsoft.com/en-us/windows/win32/api/wincrypt/nf-wincrypt-cryptstringtobinaryw
    /*
    BOOL CryptStringToBinaryW(
        LPCWSTR pszString,   A pointer to a string that contains the formatted string to be converted.
        DWORD   cchString, 0 - meaning psz will be null terminated or LENGTH of convertion
        DWORD   dwFlags,  CRYPT_STRING_BASE64
        BYTE    *pbBinary, input or 0 for length calc
        DWORD   *pcbBinary, size of str incomeing in bytes and outgoing?
        DWORD   *pdwSkip,   optional
        DWORD   *pdwFlags   optional
        );
    */

    ;defining vars 
    test_str_length := StrLen(test_str)
    test_str_buffer := Buffer(test_str_length*2)       ;had to make this 2x actual size, idk (line endings?)
    test_str_encoded_length := 0    ; define as null but Integer
    CRYPT_STRING_BASE64HEADER := 0x00000000
    CRYPT_STRING_BASE64 := 0x00000001
    CRYPT_STRING_BASE64_ANY := 0x00000006
    CRYPT_STRING_ANY := 0x00000007

    ;copies string to test_str_buffer"s address/ptr pointer (As best as i can tell)
    ;StrPut String, Target , Length , Encoding := None
    StrPut(test_str, test_str_buffer)
    ; msgbox "Str: " test_str "`nptr: " test_str_buffer.ptr "`nsize: " test_str_buffer.Size

    ;now we run the call first to get the output length so we know how big to make the output buffersize
    return_value := DllCall("crypt32\CryptStringToBinaryW", 
			                "Ptr", test_str_buffer, 
			                "UInt", 0, 
			                "UInt", CRYPT_STRING_ANY, 
			                "Ptr", 0, 
			                "UInt*", &test_str_encoded_length,
			                "Ptr",0,
			                "Ptr",0)
    if !return_value{
        ; error
        if DEBUG
            ToolTip "error phase 1 encoding " test_str                
    }

    ;MsgBox "encodeing length = " test_str_encoded_length
    ;now we actually encode the string to test_str_output which is length return above
    test_str_output := Buffer(test_str_encoded_length)
    return_value := DllCall("crypt32\CryptStringToBinaryW", 
			                "Ptr", test_str_buffer, 
			                "UInt", 0, 
			                "UInt", CRYPT_STRING_ANY, 
			                "Ptr", test_str_output, 
			                "UInt*", &test_str_encoded_length,
			                "Ptr",0,
			                "Ptr",0)
    if !return_value{
        ; error
        if DEBUG
            ToolTip "error phase 2 encoding (code: " DllCall("GetLastError") ") " test_str '`n`nINFO:`n234(0xEA) = ERROR_MORE_DATA (input str longer than buffer)`n13(0xD) = ERROR_INVALID_DATA The input data is invalid`n87(0x57) = ERROR_INVALID_PARAMETER'
    }
    ; tooltip "test_str_encoded_length: " test_str_encoded_length
    Return StrGet(test_str_output, "UTF-8")
}

CUL_encrypt(plain_str := "any string from input args", key:="shortfillerstringtouse"){
	; set var
	encrypted_str := ""
	current_char := 0
	validated_key := string_validation(key)
	; loop for each character
	loop StrLen(plain_str){
		; select char from string 
		current_char := SubStr(plain_str, A_Index, 1)
		; convert string to CP ordinal number
		current_ordinal := Ord(current_char)
		; normalize ordinals to assist with controled loop range by removing the first 32 CP
		normalized_ordinal := current_ordinal-32
		; select char from key_string looping for length of key
		next_key_char := SubStr(validated_key, Mod(A_Index,StrLen(validated_key)), 1)
		; convert string to CP ordinal number (no need to normalize this one)
		next_key_ordinal := Ord(next_key_char)
		; combind the key and the letter to encrypt then loop by 92 to keep within savable ASCII range
		new_char := Mod(normalized_ordinal + next_key_ordinal,92)

		; convert int into HEX for storage
		current_hex := Format("{:X}", new_char)
		; make sure the leading "0" isn't omitted to help with decoding consistancy
		if StrLen(current_hex) == 1 
			encrypted_str .= "0" current_hex 
		else
			encrypted_str .= current_hex
		

		; DEBUG info
		debug_str :="current_char	'" current_char "'"
		debug_str .="`ncurrent_ordinal	" current_ordinal  " ('" chr(current_ordinal) "')"
		debug_str .="`nnorm_ordinal:	" normalized_ordinal " ('" chr(normalized_ordinal) "')"
		debug_str .="`nnew_char	" new_char " ('" chr(new_char) "')"
		debug_str .="`n`nkey:		'" SubStr(validated_key, Mod(A_Index,StrLen(validated_key)), 1)  "'"
		debug_str .="`nkey_ord:		" ord(SubStr(validated_key, Mod(A_Index,StrLen(validated_key)), 1))
		debug_str .="`n`nencrypted_str`n" encrypted_str   " (" current_hex ")"
		; MsgBox debug_str, "CUL Encrypt()"
	}
	return encrypted_str
}

CUL_decrypt(encrypted_str := "any string from input args", key:="shortfillerstringtouse"){
	; set var
	plain_str := ""
	current_char := 0
	validated_key := string_validation(key)
	manual_key_index :=0
	; loop for each character
	loop StrLen(encrypted_str){
		; skip every other line to read hex values 
		if Mod(A_Index,2) == 1 {
			; extract current char 
			current_hex := "0x" SubStr(encrypted_str, A_Index, 2)
			; skip on line ending
			if instr(current_hex, "`n") or instr(current_hex, "`r")
				Continue
			; tooltip current_hex " " type(current_hex)
			current_ordinal := Format("{:u}", current_hex )
			; decrement that number by the equal index of the key (looped reverse later)
			manual_key_index +=1
			next_key_char := SubStr(validated_key, Mod(manual_key_index,StrLen(validated_key)), 1)
			next_key_ordinal := Ord(next_key_char)
			adj_char := current_ordinal - next_key_ordinal
			; tooltip current_hex " " type(current_hex) "`ncurrent_ordinal: " current_ordinal " " Type(current_ordinal)
			; msgbox "current_hex: " current_char "`nnew_char: " new_char "`ncurrent_ordinal: " current_ordinal "(" chr(current_ordinal) ")"

			; check if we ended up with a negative CP Char after decryption
			if adj_char < 0 {
				new_char := 92 + adj_char +32
			}else{
				new_char := adj_char +32
			}
			; append to output string
			plain_str .= Chr(new_char)
			; DEBUG info
			debug_str :="current_hex	'" current_hex "'" " ('" chr(current_hex) "')"
			debug_str .="`ncurrent_ordinal	" current_ordinal  " ('" chr(current_ordinal) "')"
			; debug_str .="`nnorm_ordinal:	" normalized_ordinal " ('" chr(normalized_ordinal) "')"
			debug_str .="`nadj_char		" adj_char " ('" type(adj_char) "')"
			debug_str .="`nnew_char	" new_char " ('" chr(new_char) "')`n"
			debug_str .="`nkey:		'" SubStr(validated_key, Mod(A_Index,StrLen(validated_key)), 1)  "'"
			debug_str .="`nvalue:		" ord(SubStr(validated_key, Mod(A_Index,StrLen(validated_key)), 1))
			debug_str .="`n`nplain_str (" new_char ")"		
			debug_str .="`n" plain_str		
			; MsgBox debug_str, "CUL Derypt()"
		}
	}
	return plain_str
}

string_validation(in_string, black_list:="", ordial_range_start:=33, ordinal_range_end:=126){
	out_string:=""
	loop StrLen(in_string){
		currtent_char := SubStr(in_string, A_Index, 1)
		; if InStr(black_list, currtent_char, "On")
		; 	continue
		if Ord(currtent_char) > ordinal_range_end or Ord(currtent_char) < ordial_range_start
			continue
		out_string .= currtent_char
	}
	return out_string
}

/*
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]

  									    Tooltips SECTION

[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
*/

tooltip_timeout(time_before_clearing:= 2000){
	SetTimer (*)=> clear_tooltips(), time_before_clearing
}

clear_tooltips(tooltip_index_to_clear:=-1){
	if tooltip_index_to_clear{
		tooltip(,,tooltip_index_to_clear)
		Return True
	}
	loop 9 {
		tooltip ,,A_Index
	}
}



/*
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]

  									    TIMING SECTION

[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
*/

fancy_sleep(ms_to_sleep_for, halting_flag:=false){
	; sleepin in 200ms chunks until remaining sleep time is less than 200 and sets a final timer
	wake_target_in_system_ticks := A_TickCount+ms_to_sleep_for
	loop{
		if mod((wake_target_in_system_ticks-A_TickCount),200)>1{
			sleep 200
		}else{
			sleep(wake_target_in_system_ticks-A_TickCount)
		}
	}until((wake_target_in_system_ticks-A_TickCount)<1 or halting_flag)	
}

baseline_sleep_time(ms_to_sleep_for:=1, halting_flag:=false, base_delay_time:=100){
	; function for quick sleep that allows "mutlitasking" with micro variation when imprecise sleep is acceptible
	; accepts values smaller than base_delay_time as shorthand for multiple baseline periods ask bst(10)=sleep(1000+random)
	if ms_to_sleep_for < base_delay_time{
		; shortcut case for multiples of base delay
		sleep ms_to_sleep_for*Random(.9*base_delay_time,1.1*base_delay_time)
		return
	}

	roughened_time_to_sleep := Random(.9*ms_to_sleep_for,1.1*ms_to_sleep_for)
	if roughened_time_to_sleep > 400{
		fancy_sleep(roughened_time_to_sleep, halting_flag)
	}else{
		sleep(roughened_time_to_sleep)
	}
}

bst(ms_to_sleep_for:=1, &halting_flag:=false, base_delay_time:=100){
	; alias for baseline_sleep_time(ms_to_sleep_for:=1, halting_flag:=false, base_delay_time:=100)
	baseline_sleep_time(ms_to_sleep_for:=1, halting_flag:=false, base_delay_time:=100)
}

/*
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]

  									    ERROR SECTION

[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
*/

clog(ErrClass, f:="SourceFunc") {
	; this allows for simple logging of desired text
	If type(ErrClass) = "String" {
		t := A_Now ">" ErrClass "`n=*=*=*=*=*=*=*=*=*=*=*=*=*=*=`n"
	    FileAppend t , "log.txt"	
		return True
	}

	l := "LineNumber"
	try 
		l := ErrClass.Line	

	m := "WhatMessage"
	try 
		m := ErrClass.what

	s := "Stack"
	try 
		s := ErrClass.stack		

	c := "ErrClass"
	try 
		c := type(ErrClass)			


	t := A_Now "_LINE#" l ":" f ">" c ">>> " m "`n- - - - STACK - - - -`n" s "`n===========================`n"
    FileAppend t , "log.txt"
    return true
}

log(in_str) {
	global LOG_LEVEL, LOG_PATH
	; ; check log levels and filter
	if ((inStr(in_str,"SPAM") and LOG_LEVEL <= 0) or 
		(!inStr(in_str,"SPAM") and LOG_LEVEL <= 1) or 
		(inStr(in_str,"DEBUG") and LOG_LEVEL <= 2) or 
		(inStr(in_str,"INFO") and LOG_LEVEL <= 4) or 
		(inStr(in_str,"WARN") and LOG_LEVEL <= 6) or 
		(inStr(in_str,"ALERT") and LOG_LEVEL <= 8) or 
		(inStr(in_str,"ERR") and LOG_LEVEL <= 9) or 
		(inStr(in_str,"REPORT"))){
			in_str := String(in_str)
			try{
				FileAppend(FormatTime(A_Now,"yyyyMMdd HH:mm:ss") "|: " in_str "`n", LOG_PATH)
			}catch{
				sleep 10
				FileAppend(FormatTime(A_Now,"yyyyMMdd HH:mm:ss") "|: " in_str "`n", LOG_PATH)
			}
	}
}







; OnError (*)=> CULErrorHandler()




;http://www.autohotkey.com/board/topic/18670-converting-numbers-to-any-base-radix-using-msvcrtdll/
; base_to_dec(n, Base) {
; 	static U := A_IsUnicode ? "wcstoui64_l" : "strtoui64"
; 	return DllCall("msvcrt\_" U, "Str",n, "Uint",0, "Int",Base, "CDECL Int64")
; }


; DecToBase(n, Base) {
; 	static U := A_IsUnicode ? "w" : "a"
; 	VarSetCapacity(S,65,0)
; 	DllCall("msvcrt\_i64to" U, "Int64",n, "Str",S, "Int",Base)
; 	return, S
; }




































/*
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]

  									    ONLINE EXAMPLES   

[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
*/
/*
mouse intercept from 
https://www.autohotkey.com/boards/viewtopic.php?t=35703

#IfWinNotActive, ahk_class #32770
$LButton::
CoordMode, Mouse, Window
Loop
{
	WinGet, AktivID, ID, A
	MouseGetPos, Xm, Ym, MID
	If (AktivID = MID)
		Break
	WinActivate, ahk_id %MID%
}
WinGetPos,,, Width,,A
If (Xm > Width-25) And (Ym < 25)
{
	MsgBox, 4, reminder, close out of program on a remote session before closing the remote session
	IfMsgBox Yes
		WinClose, ahk_id %MID%
}
Else
{
	SendInput, {LButton Down}
	KeyWait, LButton
	SendInput, {LButton Up}
}
Return
/*





/*
sinkfaze
http://www.autohotkey.com/forum/post-430865.html#430865
WinGet, id, list, ahk_class GxWindowClass
PostClick(x=188,y=81,msg=1,win="id") {   ; Single click is 1, Double is 2, D is Down and U is Up

   if msg not in D,U,1,2
   {
      MsgBox, 48, Warning, The WM Message is not valid, please double-check your entry
      return   False
   }
   lParam :=   x & 0xFFFF | (y & 0xFFFF) << 16   ; converts the coordinates to be used with PostMessage
   if msg=1
   {
      PostMessage, 0x201, , %lParam%, , %id%   ; WM_LBUTTONDOWN
      PostMessage, 0x202, , %lParam%, ,  %id%   ; WM_LBUTTONUP
      return   True
   }
PostMessage, (msg="D") ? 0x201 : (msg="U") ? 0x202 : 0x203, , %lParam%, , %id%
   return   True
 
}



*/



/* 
inline included icon for CAL
	IconDataHex := "
	( Join
	000001000100101010000100040028010000160000002800000010000000200000000100040000000000C00000
	0000000000000000000000000000000000C6080800CE101000CE181800D6212100D6292900E13F3F00E7525200
	EF5A5A00EF636300F76B6B00F7737300FF7B7B00FFC6C600FFCEC600FFDEDE00FFFFFF00CCCCCCCCCCCCCCCCC0
	0000000000000CC11111111111111CC22222CFFE22222CC33333CFFE33333CC44444CFFE44444CC55555CFFE55
	555CC55555CFFE55555CC55555CFFE55555CC66666CFFE66666CC77777777777777CC88888CFFC88888CC99999
	CFFC99999CCAAAAAAAAAAAAAACCBBBBBBBBBBBBBBCCCCCCCCCCCCCCCCC00000000000000000000000000000000
	000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
	000000
	)"

	nSize:=StrLen(IconDataHex)//2

	new_size := VarSetStrCapacity( &IconData, (nSize) )
	data_test := Buffer(new_size)
	; MCode by Laszlo Hars: http://www.autohotkey.com/forum/viewtopic.php?t=21172
	
	Loop nSize {
		tooltip "0x" . SubStr(IconDataHex,2*A_Index-1,2) "`n" type(IconData) IconData "`n" A_Index-1
		NumPut( "Char", "0x" SubStr(IconDataHex,2*A_Index-1,2), data_test)
		; NumPut( "Char", "0x" . SubStr(IconDataHex,2*A_Index-1,2), IconData, A_Index-1)
	}
	IconDataHex := ""                                          ; Hex contents needed no more
	
	hICon := DllCall( "CreateIconFromResourceEx", 
						"UInt",numget(data_test,"Char"), 
						"UInt",nSize, 
						"Int",1, 
						"UInt",0x30000, 
						"Int",16, 
						"Int",16, 
						"UInt",0 )

	TraySetIcon(hICon)

	*/