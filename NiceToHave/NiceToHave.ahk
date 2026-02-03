#SingleInstance force
SetTitleMatchMode 2
SetDefaultMouseSpeed 0
SetNumLockState "AlwaysOn"
CoordMode "Mouse"
CoordMode "Pixel"
CoordMode "Tooltip"


/*

^ Control
! Alt
+ Shift
# Windows

*/

;-DIV-
;-CAPSLOCK-
;-NOTEPAD-
;-AHK-
;-F1MENU-

#Include Temp.ahk
#Include BraveV2.ahk

;-----------------------DIV-----------------------

#A::WinSetAlwaysOnTop -1, "A"

^Numpad9::Run('brave.exe https://www.autohotkey.com/docs/v2/')

F14::Send('!{tab}')
F15::Send('^#{left}')
F16::Send('^#{right}')

;----------------------/DIV-----------------------

;-----------------------CAPSLOCK------------------

Capslock::{
	capsSearch := Inputbox( , "Search", "w180 h69")
	If(capsSearch.value = "" or capsSearch.result != "OK"){
		return
	}else if(InStr(capsSearch.value, ".") and !InStr(capsSearch.value, " ")){
		run 'https://' capsSearch.value
	}else{
		run "https://www.google.com/search?udm=14&q=" StrReplace(capsSearch.value,"&","%26")
	}
}
^Capslock::{
	A_Clipboard := ""
	Send "^c"
	If(!ClipWait(1))
		return
	Run('https://google.com/search?udm=14&q=' A_Clipboard)
}

;----------------------/CAPSLOCK------------------

;-----------------------NOTEPAD-------------------

#HotIf WinActive(".ahk – Note")

~$^s::Reload
^!+::Send '{{}{}}{left}'

#HotIf

;----------------------/NOTEPAD-------------------

;-----------------------AHK-----------------------

+F4::ExitApp
+F5::Reload
+F13::Reload

+F14::
Insert::{
	If(!WinExist("Temp.ahk – Note")){
		Run "Notepad " A_ScriptDir "\Temp.ahk"
		WinWait "Temp.ahk – Note"
		WinActivate "ahk_exe Notepad.exe"
		WinSetAlwaysOnTop 1 , "ahk_exe Notepad.exe"

	}else{
		If (!WinActive('Temp.ahk – Note')){
			WinActivate "ahk_exe Notepad.exe"
		}
		Send '^w'
	}
}

^+F14::
^+Insert::{
	If(!WinExist("NiceToHave.ahk – Note")){
		Edit
		WinWait "NiceToHave.ahk – Note"
		WinActivate "ahk_exe Notepad.exe"
		WinSetAlwaysOnTop 1 , "ahk_exe Notepad.exe"
	}else{
		If (!WinActive('NiceToHave.ahk – Note')){
			WinActivate "ahk_exe Notepad.exe"
		}
		Send '^w'
	}
}
^F14::
^Insert::{
	If(!WinExist("Window Spy")){
		Run "C:\Program Files\AutoHotkey\WindowSpy.ahk"
	}else{
		WinClose "Window Spy"
	}
}

;-----------------------F1MENU-----------------------

#HotIf WinActive(".ahk – Note") and not ((IsSet(SendRecording) and SendRecording) or (IsSet(SendMouseRecording) and SendMouseRecording))
F1::{
	F1Menu := Menu()

	F1Menu.Add('&New Hotkey',F1MenuHotkey)
	F1Menu.Add()
	F1Menu.Add('&A_Clipboard', F1MenuClipboard)
	F1Menu.Add('&ClipboardWait', F1MenuClipboardWait)
		ForMenu := Menu()
		ForMenu.Add('&For{ }',F1MenuFor)
		ForMenu.Add('For{ strSpli&t }',(*) => F1MenuForSplit(0))
		ForMenu.Add('For{ strSplit te&xt }',(*) => F1MenuForSplit(1))
	F1Menu.Add('&For { }', ForMenu)
		F1MenuGui := Menu()
		F1MenuGui.Add('Declare GUI',(*) => Send("global testGUI := GUI('border -caption')"))
		F1MenuGui.Add('&Show',F1MenuGuiShow)
		F1MenuGui.Add()
		F1MenuGui.Add('&Button',F1MenuGuiButton)
		F1MenuGui.Add('&CheckBox',(*) => Send("Global testGuiCheck := testGUI.Add('CheckBox','',''){left 2}"))
		F1MenuGui.Add('C&omboBox',(*) => Send("Global testGuiCB := testGUI.Add('ComboBox','',){left}"))
		F1MenuGui.Add('&DropDownList',(*) => Send("Global testGuiDDL := testGUI.Add('DropDownList','',){left}"))
		F1MenuGui.Add('&Edit',(*) => Send("Global testGuiEdit := testGUI.Add('Edit','',''){left 5}"))
		F1MenuGui.Add('&GroupBox',(*) => Send("testGUI.Add('GroupBox','',''){left 2}"))
		F1MenuGui.Add('&Pic',(*) => Send("testGUI.Add('Pic','',''){left 2}"))
		F1MenuGui.Add('&Radio',(*) => Send("Global testGuiRadio := testGUI.Add('Radio','',''){left 2}"))
		F1MenuGui.Add('Tab&3',(*) => Send("testGUI.Add('Tab3','',){left}"))
		F1MenuGui.Add('&Text',(*) => Send("testGUI.Add('Text','',''){left 2}"))
	F1Menu.Add('&GUI',F1MenuGui)
	F1Menu.Add('&Inputbox',F1MenuInputBox)
	F1Menu.Add('ImageSearc&h', F1MenuImageSearch)
	F1Menu.Add('&Loop { }', F1MenuLoop)
		MouseMenu := Menu()
		MouseMenu.Add('&Click',MouseMenuClicks)
		MouseMenu.Add('Mouse&GetPos',(*) => SendText('MouseGetPos &Xpos, &Ypos'))
		MouseMenu.Add('Mouse&Move',(*) => SendText('MouseMove Xpos, Ypos'))
	F1Menu.Add('&Mus',MouseMenu)
	F1Menu.Add('MsgBo&x', F1MenuMsgBox)
		RegExMenu := Menu()
		RegExMenu.Add('&Match', (*) => Send("RegExMatch(,''){left 4}"))
		RegExMenu.Add('Match(&var)', (*) => Send("RegExMatch(,'',&vRegEx){left 12}"))
		RegExMenu.Add('&Replace', (*) => Send("RegExReplace(A_Clipboard, '', ''){left 6}"))
	F1Menu.Add('&RegEx', RegexMenu)
	F1Menu.Add("&Send ' '",F1MenuSend)
	F1Menu.Add("Send(Rec&ord)",F1MenuSendRecord)
	F1Menu.Add('Sl&eep 150', F1MenuSleep)
	F1Menu.Add('StringSpli&t', F1MenuStringSplit)
		WinMenu := Menu()
		WinMenu.Add('#&HotIf', WinMenuHotIf)
		WinMenu.Add('Win&Activate', (*) => WinMenuFunc('Activate') WinMenuFunc('WaitActive'))
		WinMenu.Add('Win&Close', (*) => WinMenuFunc('Close') WinMenuFunc('WaitClose'))
		WinLogicMenu := Menu()
		WinLogicMenu.Add('Win&Active', (*) => WinMenuFunc('Active'))
		WinLogicMenu.Add('Win&Exist', (*) => WinMenuFunc('Exist'))
		WinWaitMenu := Menu()
		WinWaitMenu.Add('WinWait&Active', (*) => WinMenuFunc('WaitActive'))
		WinWaitMenu.Add('WinWait&Close', (*) => WinMenuFunc('WaitClose'))
		WinWaitMenu.Add('WinWait(&Exist)', (*) => WinMenuFunc('Wait'))
		WinMenu.Add('Win&Logic', WinLogicMenu)
		WinMenu.Add('&WinWait', WinWaitMenu)
	F1Menu.Add('&Win', WinMenu)

	F1Menu.Show(0,0)
}
#HotIf
F1MenuGuiButton(*){
	tempClip := ClipboardAll()
	A_Clipboard := ""
	Send "+{home}^c{end}"
	ClipWait(0.3)
	RegExReplace(A_Clipboard, '`t',,&vRegCount)
	Send("testButton := testGUI.Add('Button','',''){enter}")
	Send '{tab ' vRegCount "}testButton.OnEvent('Click', (*) => ){up}{end}{left 2}"
	A_Clipboard := tempClip
}
F1MenuGuiShow(*){
	tempClip := ClipboardAll()
	A_Clipboard := ""
	Send "+{home}^c{end}"
	ClipWait(0.3)
	RegExReplace(A_Clipboard, '`t',,&vRegCount)
	Send "testGUI.OnEvent('Close', testGui.Destroy){enter}"
	Send '{tab ' vRegCount '}' "testGUI.OnEvent('Escape', testGui.Destroy){enter}"
	Send '{tab ' vRegCount '}testGUI.Show(){left}'
	A_Clipboard := tempClip
}
F1MenuHotkey(*){
	Send "F::{{}{enter}"
	Send "{tab}{enter}"
	Send "{}}{up 2}"
}
F1MenuClipboard(*){
	Send 'A_Clipboard'
}
F1MenuClipboardWait(*){
	tempClip := ClipboardAll()
	A_Clipboard := ""
	Send "+{home}^c{end}"
	ClipWait(0.3)
	RegExReplace(A_Clipboard, '`t',,&vRegCount)
	Send 'A_Clipboard := ""{enter}'
	Send '{tab ' vRegCount '}Send "{^}c"{enter}'
	Send '{tab ' vRegCount '}If({!}ClipWait(1)){enter}'
	Send '{tab ' vRegCount+1 '}return{enter}'
	Send '{tab ' vRegCount '}'
	A_Clipboard := tempClip
}
F1MenuInputBox(*){
	tempClip := ClipboardAll()
	A_Clipboard := ""
	Send "+{home}^c{end}"
	ClipWait(0.3)
	RegExReplace(A_Clipboard, '`t',,&vRegCount)
	Send 'vIB := InputBox("Tekst", "Title", "w180 h100"){enter}'
	Send '{tab ' vRegCount '}If(vIB.value = "" or vIB.result {!}= "Ok"){enter}'
	Send '{tab ' vRegCount+1 '}return{enter}'
	Send '{up 3}{end}^{left 3}{left 3}'
	A_Clipboard := tempClip
}
F1MenuImageSearch(*){
	Send '+#s'
	Loop {
		Sleep 100	
	}until GetKeyState('LButton') or GetKeyState('esc') ;Loop
	If(GetKeyState('esc')){
		return
	}
	MouseGetPos &X0, &Y0
	KeyWait 'LButton'
	MouseGetPos &X1, &Y1
	run 'mspaint'
	WinWait('ahk_exe mspaint.exe')
	WinActivate('ahk_exe mspaint.exe')
	WinWaitActive('ahk_exe mspaint.exe')
	Send '{alt}ie'
	Sleep 250
	Send '+{tab}{space}{tab}'
	Sleep 150
	Send '1{tab}{space}{tab}'
	Sleep 150
	Send '1{enter}'	
	Sleep 250
	Send '^v'
	Send '^s'
	If(!DirExist(A_ScriptDir '\ImgSearchPic'))
		DirCreate A_ScriptDir '\ImgSearchPic'

	picName := ''
	Loop {
		If(!FileExist(A_ScriptDir '\ImgSearchPic\pic' A_index '.png')){
			picName := 'pic' A_index '.png'
		}		
	}until picName ;Loop
	
	
	If(SubStr(A_Language,3) = '09'){ ;Eng
		WinWaitActive('Save As')
	}else If(SubStr(A_Language,3) = '06'){ ;DK
		WinWaitActive('Gem som')
	}

	Send picName
	Send '^l' A_ScriptDir '\ImgSearchPic+{enter}'
	Sleep 150

	If(SubStr(A_Language,3) = '09'){ ;Eng
		Send '!s'
		WinWaitNotActive('Save As')
	}else If(SubStr(A_Language,3) = '06'){ ;DK
		Send '!g'
		WinWaitNotActive('Gem som')
	}

	WinClose('ahk_exe mspaint.exe')

	WinActivate('.ahk – Note')
	WinWaitActive('.ahk – Note')
	Send "If(ImageSearch(&x,&y," X0 - 100 "," Y0 - 100 "," X1 + 100 "," Y1 + 100 ",'" A_ScriptDir '\ImgSearchPic\' picName "')){{}{}}{left}{enter 2}{tab}{up}{tab 2}"
}
F1MenuFor(*){
	tempClip := ClipboardAll()
	A_Clipboard := ""
	Send "+{home}^c{end}"
	ClipWait(0.3)
	RegExReplace(A_Clipboard, '`t',,&vRegCount)
	Send 'For ii, value in StrSplit(A_Clipboard, "``n", "``r"){{}{enter}'
	Send '{tab ' vRegCount+1 '}if(value = ""){enter}'
	Send '{tab ' vRegCount+2 '}continue{enter}'
	Send '{tab ' vRegCount+1 '}{enter}'
	Send '{tab ' vRegCount+1 '}Sleep 1000{enter}'
	Send '{tab ' vRegCount '}{}} {;}For{up 2}{end}'
	A_Clipboard := tempClip
}
F1MenuForSplit(vText := 0){
	tempClip := ClipboardAll()
	A_Clipboard := ""
	Send "+{home}^c"
	ClipWait(0.3)
	RegExReplace(A_Clipboard, '`t',,&vRegCount)
	Send (vText ? '{end}text := ""{enter}' : '{bs}')
	Send '{tab ' vRegCount '}For ii, value in StrSplit(A_Clipboard, "``n", "``r"){{}{enter}'
	Send '{tab ' vRegCount+1 '}if(value = ""){enter}'
	Send '{tab ' vRegCount+2 '}continue{enter}'
	Send '{tab ' vRegCount+1 '}item := StrSplit(value, ""``{bs}t"){enter 2}'
	Send '{tab ' vRegCount '}{}} {;}For{enter}'
	Send (vText ? '{tab ' vRegCount '}A_Clipboard := text{up 2}{tab ' vRegCount+1 '}' : '{up 2}{tab ' vRegCount+1 '}')
	A_Clipboard := tempClip
}
F1MenuLoop(*){
	tempClip := ClipboardAll()
	A_Clipboard := ""
	Send "+{home}^c{end}"
	ClipWait(0.3)
	RegExReplace(A_Clipboard, '`t',,&vRegCount)
	Send 'Loop {{}{enter}'
	Send '{tab ' vRegCount+1 '}{enter}'
	Send '{tab ' vRegCount '}{}} {;}Loop{up 2}{end}{left}'
	A_Clipboard := tempClip
}
MouseMenuClicks(*){
	MouseGetPos &xposO, &yposO
	tooltip 'Tryk {F1} for at afslutte',0,0
	WinMinimize('.ahk – Note')
	Global SendMouseRecording := 1
	Global strMouseClicks := ''
	Loop {
		Sleep 10
	}until !SendMouseRecording
	winrestore '.ahk – Note'
	WinWaitActive '.ahk – Note'
	tempClip := ClipboardAll()
	A_Clipboard := ""
	Send "+{home}^c{end}"
	ClipWait(0.2)
	RegExReplace(A_Clipboard, '`t',,&vRegCount)
	For ii, value in StrSplit(strMouseClicks, "`n", "`r"){
		if(value = "")
			continue
		SendText value
		Send '{enter}{tab ' vRegCount '}'
		Sleep 1
	} ;For
	mousemove xposO, yposO
	tooltip
	Global strMouseClicks := ''
	A_Clipboard := tempClip
}
#HotIf IsSet(SendMouseRecording) and SendMouseRecording
F1::{
	Global SendMouseRecording := 0
}
*~LButton::{
	mousegetpos &xpos, &ypos
	If(GetKeyState('ctrl','p')){
		Global strMouseClicks .= "Send '^{Click " xpos " " ypos "}'`n"
	}else If(GetKeyState('alt','p')){
		Global strMouseClicks .= "Send '!{Click " xpos " " ypos "}'`n"
	}else If(GetKeyState('shift','p')){
		Global strMouseClicks .= "Send '+{Click " xpos " " ypos "}'`n"
	}else If(GetKeyState('lwin','p')){
		Global strMouseClicks .= "Send '#{Click " xpos " " ypos "}'`n"
	}else{
		Global strMouseClicks .= 'Click ' xpos ',' ypos '`n'
	}
}
*~MButton::{
	mousegetpos &xpos, &ypos
	If(GetKeyState('ctrl','p')){
		Global strMouseClicks .= "Send '^{Click " xpos " " ypos " Middle}'`n"
	}else If(GetKeyState('alt','p')){
		Global strMouseClicks .= "Send '!{Click " xpos " " ypos " Middle}'`n"
	}else If(GetKeyState('shift','p')){
		Global strMouseClicks .= "Send '+{Click " xpos " " ypos " Middle}'`n"
	}else If(GetKeyState('lwin','p')){
		Global strMouseClicks .= "Send '#{Click " xpos " " ypos " Middle}'`n"
	}else{
		Global strMouseClicks .= 'Click ' xpos ',' ypos ',' "'Middle'`n"
	}
}
*~RButton::{
	mousegetpos &xpos, &ypos
	If(GetKeyState('ctrl','p')){
		Global strMouseClicks .= "Send '^{Click " xpos " " ypos " Right}'`n"
	}else If(GetKeyState('alt','p')){
		Global strMouseClicks .= "Send '!{Click " xpos " " ypos " Right}'`n"
	}else If(GetKeyState('shift','p')){
		Global strMouseClicks .= "Send '+{Click " xpos " " ypos " Right}'`n"
	}else If(GetKeyState('lwin','p')){
		Global strMouseClicks .= "Send '#{Click " xpos " " ypos " Right}'`n"
	}else{
		Global strMouseClicks .= 'Click ' xpos ',' ypos ',' "'Right'`n"
	}
}
#HotIf
F1MenuMsgBox(*){
	Send "MsgBox ''{left}"
}
F1MenuSend(*){
	Send "Send ''{left}"
}
F1MenuSendRecord(*){
	WinMinimize('.ahk – Note')
	Global SendRecording := 1
	Global aSRText := []
	Tooltip 'Tryk {F1} for at afslutte Send(Record)`nTryk {F2} for at oprette WinWaitActive',0,0,20
	Global ih := InputHook('V L1','{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{a}{b}{c}{d}{e}{f}{g}{h}{i}{j}{k}{l}{m}{n}{o}{p}{q}{r}{s}{t}{u}{v}{w}{x}{y}{z}{æ}{ø}{å}{1}{2}{3}{4}{5}{6}{7}{8}{9}{0}{Numpad1}{Numpad2}{Numpad3}{Numpad4}{Numpad5}{Numpad6}{Numpad7}{Numpad8}{Numpad9}{Numpad0}{space}{tab}{enter}{esc}{bs}{del}{ins}{home}{end}{PgUp}{PgDn}{up}{down}{left}{right}{AppsKey}{¨}{^}{~}{´}{`}{!}{"}{#}{¤}{%}{&}{/}{(}{)}{=}{?}')
	Loop {
		ih.Start()
		ih.Wait()

		If(!SendRecording){
			break
		}
		SRPrefix := ''
		If(GetKeyState('Ctrl')){
			SRPrefix .= '^'
		}
		If(GetKeyState('Alt')){
			SRPrefix .= '!'
		}
		If(GetKeyState('Shift')){
			SRPrefix .= '+'
		}
		If(GetKeyState('LWin')){
			SRPrefix .= '#'
		}
		If(GetKeyState('RWin')){
			SRPrefix .= '#'
		}
		
		If((ih.EndKey = 'c') and (SRPrefix = '^')){
			aSRText.Push('||CBW||')
		}else If(StrLen(ih.EndKey)){
			aSRText.Push(SRPrefix '{' ih.EndKey '}')
		}else{
			aSRText.Push(SRPrefix '{' ih.Input '}')
		}
	}
}
F1MenuSleep(*){
	Send 'Sleep 150'
}
F1MenuStringReplace(*){
	Send "StrReplace(A_Clipboard, ''){left 2}"
}
F1MenuStringSplit(*){
	Send "StrSplit(A_Clipboard,''){left 2}"
}
WinMenuHotIf(*){
	Send "{#}HotIf WinActive('')"
	Send '{enter 2}'
	Send '{#}HotIf'
	Send '{up 2}{end}{left 2}'
	MouseGetPos(,,&mWin)
	SendText WinGetTitle(mWin)
	Send '{down}'
}
WinMenuFunc(name := ''){
	If(name = '')
		return
	ClipBSaved := ClipboardAll()
	A_Clipboard := ""
	Send "+{home}^c{end}"
	ClipWait(0.3)
	RegExReplace(A_Clipboard, '`t',, &vRegCount)
	Send "Win" name "(''){left 2}"
	MouseGetPos(,,&mWin)
	SendText WinGetTitle(mWin)
	Send '{end}{enter}{tab ' vRegCount '}'
	A_Clipboard := ClipBSaved
}

#HotIf IsSet(SendRecording) and SendRecording
F1::{
	tooltip '',,,20
	WinRestore('.ahk – Note')
	WinActivate('.ahk – Note')
	Global SendRecording := 0
	ih.Stop()
	SRText := ''
	repeatCount := 0
	For ii, value in aSRText{
		If(InStr(value,'WinGetTitle') = 1){
			SRText .= '||WWA' SubStr(value,12) '||'
		}else If(value = '^{v}'){
			SRText .= '^{v}||SLEEP||'
		}else If(value = '!{tab}'){
			SRText .= '!{tab}||SLEEP||'
		}else If((A_index = aSRText.length) and (repeatCount > 0)){
			SRText .= RegExReplace(value, '}$', ' ' repeatCount+1 '}')
		}else If((A_index = aSRText.length) and (repeatCount = 0)){
			SRText .= value
		}else If(aSRText[A_index] = aSRText[A_index+1]){
			repeatCount += 1
			continue
		}else if(repeatCount > 0){
			SRText .= RegExReplace(value, '}$', ' ' repeatCount+1 '}')
			repeatCount := 0
		}else{
			SRText .= value
		}
	}
	SRText := RegExReplace(SRText, "{'", '{' "' " '"' "'" '" ' "'")
	WinWaitActive('.ahk – Note')
	Send '+{home}'
	A_Clipboard := ""
	Send "^c{end}"
	ClipWait(0.3)
	RegExReplace(A_Clipboard, '`t',,&vRegCount)
	For ii, value in StrSplit(SRText, "||"){
		If(InStr(value,'WWA') = 1){
			Send '{enter}{tab ' vRegCount "}WinWaitActive('" SubStr(value,4) "'){enter}{tab " vRegCount "}"
		}else If(value = 'CBW'){
			Send '{enter}{tab ' vRegCount '}'
			Send '{end}A_Clipboard := ""{enter}'
			Send '{tab ' vRegCount '}Send "{^}c"{enter}'
			Send '{tab ' vRegCount '}If({!}ClipWait(1)){enter}'
			Send '{tab ' vRegCount+1 '}return'
			Send '{tab ' vRegCount '}'
			Send '{enter}{tab ' vRegCount '}'
		}else If(value = 'SLEEP'){
			Send '{enter}{tab ' vRegCount '}Sleep 150{enter}{tab ' vRegCount '}'
		}else If(value != ''){
			SendText "Send '" value "'"
		}
		Sleep 100
	} ;For
}
F2::{
	aSRText.Push('WinGetTitle' WinGetTitle('A'))
}
~Lwin::
~Rwin::
~LAlt::
~RAlt::{
	global aSRTextlengthPre := aSRText.length
}
~Lwin Up::{
	If(aSRTextlengthPre  = aSRText.length)
		aSRText.Push('{LWin}')
}
~RWin up::{
	If(aSRTextlengthPre  = aSRText.length)
		aSRText.Push('{RWin}')
}
~LAlt up::{
	If(aSRTextlengthPre  = aSRText.length)
		aSRText.Push('{LAlt}')
}
~RAlt up::{
	If(aSRTextlengthPre  = aSRText.length)
		aSRText.Push('{RAlt}')
}
#HotIf
;----------------------/F1MENU-----------------------