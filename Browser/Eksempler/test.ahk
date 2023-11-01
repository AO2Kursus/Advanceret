﻿#Requires AutoHotkey v2.0
#SingleInstance force


#include BraveV2.ahk
F4::{
	page := Brave.GetPageByUrl("reddit.com")
	if !isobject(page){
		msgbox "Ikke connected"
		return
	}
	JS := "JSON.stringify([].slice.call(document.querySelectorAll('h3')).map(function(e) { return e.innerText; }))"
	;JS := "document.querySelectorAll('h3')"
	for ii, value in page.ValueArray(JS){
		msgbox "ii af er:`t" ii "`r`nValue er:`t" value
	}
	;msgbox page.value("document.querySelector('#head > div > div.h-tabs > ul > li:nth-child(3) > button').dataset['content']")
}


#HotIf WinActive(".ahk - Note")
~^s::reload
#HotIf

+esc::exitapp