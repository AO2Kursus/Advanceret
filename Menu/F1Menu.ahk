#SingleInstance force
#Requires AutoHotkey v2.0
SetTitleMatchMode 2
CoordMode "Tooltip"

F1MenuInit()

+F4::ExitApp

/*************************************************
		F1Menu	
**************************************************/
#HotIf WinActive(".ahk - Note")

F1::{
	F1Menu := Menu()

	F1Menu.Add('&New Hotkey',F1MenuHotkey)
	F1Menu.Add()
	F1Menu.Add('&A_Clipboard', F1MenuClipboard)
	F1Menu.Add('&ClipboardWait', F1MenuClipboardWait)
	F1Menu.Add('&For { }', F1MenuFor)
	F1Menu.Add('&For {StrSplit}', F1MenuForSplit)
	F1Menu.Add('&Inputbox',F1MenuInputBox)
	F1Menu.Add('&Loop { }', F1MenuLoop)
	F1Menu.Add('&MouseClicks',F1MenuMouseClicks)
	F1Menu.Add('MsgBo&x', F1MenuMsgBox)
	F1Menu.Add("&Send ' '",F1MenuSend)
	F1Menu.Add('Sl&eep 150', F1MenuSleep)
	F1Menu.Add('String&Replace', F1MenuStringReplace)
	F1Menu.Add('StringSpli&t', F1MenuStringSplit)
		WinMenu := Menu()
		WinMenu.Add('Win&Activate', WinMenuWinActivate)
		WinMenu.Add('Win&WaitActive', WinMenuWinWaitActive)
		WinMenu.Add('Win&Close', WinMenuWinClose)
	F1Menu.Add('&Win', WinMenu)

	F1Menu.Show(0,0)
}

#HotIf

F1MenuHotkey(*){
	Send "F::{{}{enter}"
	Send "{tab}{enter}"
	Send "{}}{up 2}{right}"
}
F1MenuClipboard(*){
	Send 'A_Clipboard'
}
F1MenuClipboardWait(*){
	Send 'A_Clipboard := ""{enter}'
	Send '{tab}Send "{^}c"{enter}'
	Send "{tab}If({!}ClipWait(1)){enter}"
	Send "{tab 2}return{enter}"
	Send "{tab}"
}
F1MenuInputBox(*){
	Send 'vIB := InputBox("Tekst", "Title", "w180 h100"){enter}'
	Send '{tab}If(vIB.value = "" or vIB.result {!}= "Ok"){enter}'
	Send "{tab 2}return{enter}"
	Send "{up 3}{end}^{left 3}{left 3}"
}
F1MenuFor(*){
	Send 'For ii, value in StrSplit(A_Clipboard, "``n", "``r"){{}{enter}'
	Send '{tab 2}if(value = ""){enter}'
	Send '{tab 3}continue{enter}'
	Send '{tab 2}{enter}'
	Send "{tab 2}Sleep 1000{enter}"
	Send "{tab}{}} {;}For{up 2}{end}"
}
F1MenuForSplit(*){
	Send 'text := ""{enter}'
	Send '{tab}For ii, value in StrSplit(A_Clipboard, "``n", "``r"){{}{enter}'
	Send '{tab 2}if(value = ""){enter}'
	Send '{tab 3}continue{enter}'
	Send '{tab 2}item := StrSplit(value, ""``{bs}t"){enter 2}'
	Send "{tab}{}} {;}For{enter}"
	Send "{tab}A_Clipboard := text{up 2}{tab 2}"
}
F1MenuLoop(*){
	Send "Loop {{}{enter}"
	Send "{tab 2}{enter}"
	Send "{tab}{}} {;}Loop{up 2}^{right}"
}
F1MenuMouseClicks(*){
	mousegetpos &xposO, &yposO
	tooltip '[esc] for at afslutte',0,0
	winminimize '.ahk - Note'
	amc := []
	Loop {
		Loop {
			Sleep 10
		}until GetKeyState('LButton','p') or GetKeyState('esc','p')
		If(GetKeyState('esc','p'))
			break
		keywait 'LButton'
		mousegetpos &xpos, &ypos
		amc.push([xpos, ypos])
	}until GetKeyState('esc','p')
	winrestore '.ahk - Note'
	WinWaitActive '.ahk - Note'
	For ii, value in amc{
		Send "Click " value[1] ", " value[2] "{enter}{tab}"
	}
	mousemove xposO, yposO
	tooltip
}
F1MenuMsgBox(*){
	Send "MsgBox ''{left}"
}
F1MenuSend(*){
	Send "Send ''{left}"
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
WinMenuWinActivate(*){
	Send "WinActivate(''){left 2}"
}
WinMenuWinWaitActive(*){
	Send "WinWaitActive(''){left 2}"
}
WinMenuWinClose(*){
	Send "WinClose(''){left 2}"
}