/************************************************************************
 * @description: Modify from G33kDude's Chrome.ahk v1
 * @author thqby
 * @date 2023/01/15
 * @version 1.0.1
 ***********************************************************************/

class Chrome {
	static _http := ComObject('WinHttp.WinHttpRequest.5.1')
	static FindInstance(exename := 'Chrome.exe', debugport := 0) {
		items := Map()
		filter_items := Map()
		for item in ComObjGet('winmgmts:').ExecQuery("SELECT CommandLine, ProcessID FROM Win32_Process WHERE Name = '" exename "' AND CommandLine LIKE '% --remote-debugging-port=%'"){
			If (parentPID := ProcessGetParent(item.ProcessID))
			{
			items[item.ProcessID] := [parentPID, item.CommandLine]
			msgbox items[item.ProcessID][1] "`r`n" items[item.ProcessID][2]
			}
		}
		for pid, item in items
			if !items.Has(item[1]) && (!debugport || InStr(item[2], ' --remote-debugging-port=' debugport))
				filter_items[pid] := item[2]
		for pid, cmd in filter_items
			if RegExMatch(cmd, 'i) --remote-debugging-port=(\d+)', &m)
				return { Base: this.Prototype, DebugPort: m[1], PID: pid }
	}

	/*
	 * @param ProfilePath - Path to the user profile directory to use. Will use the standard if left blank.
	 * @param URLs        - The page or array of pages for Chrome to load when it opens
	 * @param Flags       - Additional flags for Chrome when launching
	 * @param ChromePath  - Path to Chrome.exe, will detect from start menu when left blank
	 * @param DebugPort   - What port should Chrome's remote debugging server run on
	*/
	__New(URLs := "about:blank", Flags := "", ChromePath := "", DebugPort := 9222, ProfilePath := "") {
		; Verify ChromePath
		try ChromePath := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Chrome.exe")
		catch {
			throw Error('Chrome could not be found')
		}
		; Verify DebugPort
		if (!IsInteger(DebugPort) || (DebugPort <= 0))
			throw Error('DebugPort must be a positive integer')
		this.DebugPort := DebugPort, URLString := ''

		SplitPath(ChromePath, &exename)
		URLs := URLs is Array ? URLs : URLs && URLs is String ? [URLs] : []
		if instance := Chrome.FindInstance(exename, DebugPort) {
			this.PID := instance.PID
			http := Chrome._http
			for url in URLs
				http.Open('GET', 'http://127.0.0.1:' this.DebugPort '/json/new?' url), http.Send()
			return
		}

		; Verify ProfilePath
		if (ProfilePath && !FileExist(ProfilePath))
			DirCreate(ProfilePath)

		; Escape the URL(s)
		for url in URLs
			URLString .= ' ' CliEscape(url)

		hasother := ProcessExist(exename)
		Run(CliEscape(ChromePath) ' --remote-debugging-port=' this.DebugPort
			(ProfilePath ? ' --user-data-dir=' CliEscape(ProfilePath) : '')
			(Flags ? ' ' Flags : '') URLString, , , &PID)
		if (hasother && Sleep(600) || !instance := Chrome.FindInstance(exename, this.DebugPort))
			throw Error('Chrome is not running in debug mode. Try closing all chrome processes and try again')
		this.PID := PID

		CliEscape(Param) => '"' RegExReplace(Param, '(\\*)"', '$1$1\"') '"'
	}

	/*
	 * End Chrome by terminating the process.
	*/
	Kill() {
		ProcessClose(this.PID)
	}

	/*
	 * Queries Chrome for a list of pages that expose a debug interface.
	 * In addition to standard tabs, these include pages such as extension
	 * configuration pages.
	*/
	static GetPageList() {
		http := Chrome._http
		try {
			http.Open('GET', 'http://127.0.0.1:9222/json')
			http.Send()
			return JSON.parse(http.responseText)
		} catch
			return []
	}

	FindPages(opts, MatchMode := 'exact') {
		Pages := []
		for PageData in this.GetPageList() {
			fg := true
			for k, v in (opts is Map ? opts : opts.OwnProps())
				if !((MatchMode = 'exact' && PageData[k] = v) || (MatchMode = 'contains' && InStr(PageData[k], v))
					|| (MatchMode = 'startswith' && InStr(PageData[k], v) == 1) || (MatchMode = 'regex' && PageData[k] ~= v)) {
					fg := false
					break
				}
			if (fg)
				Pages.Push(PageData)
		}
		return Pages
	}

	NewTab(url := 'about:blank') {
		http := Chrome._http
		http.Open('GET', 'http://127.0.0.1:' this.DebugPort '/json/new?' url), http.Send()
		try if ((PageData := JSON.parse(http.responseText)).Has('webSocketDebuggerUrl'))
				return Chrome.Page(StrReplace(PageData['webSocketDebuggerUrl'], 'localhost', '127.0.0.1'), http)
	}

	ClosePage(opts, MatchMode := 'exact') {
		http := Chrome._http
		switch Type(opts) {
			case 'String':
				return (http.Open('GET', 'http://127.0.0.1:' this.DebugPort '/json/close/' opts), http.Send())
			case 'Map':
				if opts.Has('id')
					return (http.Open('GET', 'http://127.0.0.1:' this.DebugPort '/json/close/' opts['id']), http.Send())
			case 'Object':
				if opts.Has('id')
					return (http.Open('GET', 'http://127.0.0.1:' this.DebugPort '/json/close/' opts.id), http.Send())
		}
		for page in this.FindPages(opts, MatchMode)
			http.Open('GET', 'http://127.0.0.1:' this.DebugPort '/json/close/' page['id']), http.Send()
	}

	ActivatePage(opts, MatchMode := 'exact') {
		http := Chrome._http
		for page in this.FindPages(opts, MatchMode)
			return (http.Open('GET', 'http://127.0.0.1:' this.DebugPort '/json/activate/' page['id']), http.Send())
	}
	/*
	 * Returns a connection to the debug interface of a page that matches the
	 * provided criteria. When multiple pages match the criteria, they appear
	 * ordered by how recently the pages were opened.
	 *
	 * Key        - The key from the page list to search for, such as 'url' or 'title'
	 * Value      - The value to search for in the provided key
	 * MatchMode  - What kind of search to use, such as 'exact', 'contains', 'startswith', or 'regex'
	 * Index      - If multiple pages match the given criteria, which one of them to return
	 * fnCallback - A function to be called whenever message is received from the page, `msg => void`
	*/
	static GetPageBy(Key, Value, MatchMode := 'exact', Index := 1, fnCallback := '') {
		Count := 0
		for ii, PageData in this.GetPageList() {
			;msgbox "hej`t" PageData['url']
			if (((MatchMode = 'exact' && PageData[Key] = Value)	; Case insensitive
				|| (MatchMode = 'contains' && InStr(PageData[Key], Value))
				|| (MatchMode = 'startswith' && InStr(PageData[Key], Value) == 1)
				|| (MatchMode = 'regex' && PageData[Key] ~= Value))
				&& ++Count == Index)
				return Chrome.Page(PageData['webSocketDebuggerUrl'], fnCallback)
		}
	}

	; Shorthand for GetPageBy('url', Value, 'startswith')
	static GetPageByURL(Value, MatchMode := 'contains', Index := 1, fnCallback := '') {
		return this.GetPageBy('url', Value, MatchMode, Index, fnCallback)
	}

	; Shorthand for GetPageBy('title', Value, 'startswith')
	static GetPageByTitle(Value, MatchMode := 'contains', Index := 1, fnCallback := '') {
		return this.GetPageBy('title', Value, MatchMode, Index, fnCallback)
	}

	/**
	 * Shorthand for GetPageBy('type', Type, 'exact')
	 * 
	 * The default type to search for is 'page', which is the visible area of
	 * a normal Chrome tab.
	 */
	GetPage(Index := 1, Type := 'page', fnCallback := '') {
		return this.GetPageBy('type', Type, 'exact', Index, fnCallback)
	}

	; Connects to the debug interface of a page given its WebSocket URL.
	class Page extends WebSocket {
		ID := 0, responses := Map(), callback := 0
		/**
		 * @param url the url of webscoket
		 * @param events callback function, `(msg) => void`
		 */
		__New(url, events := 0) {
			super.__New(url)
			this.callback := events
			pthis := ObjPtr(this)
			SetTimer(this.KeepAlive := () => ObjFromPtrAddRef(pthis)('Browser.getVersion', , false), 25000)
		}
		__Delete() {
			if !this.KeepAlive
				return
			SetTimer(this.KeepAlive, 0), this.KeepAlive := 0
			super.__Delete()
		}

		Call(DomainAndMethod, Params?, WaitForResponse := true) {
			if (this.readyState != 1)
				throw Error('Not connected to tab')

			responseRepeat:	;	Christoffer
			; Use a temporary variable for ID in case more calls are made
			; before we receive a response.
			if !ID := this.ID += 1
				ID := this.ID += 1
			this.sendText(JSON.stringify(Map('id', ID, 'params', Params ?? {}, 'method', DomainAndMethod), 0))
			if (!WaitForResponse)
				return

			; Wait for the response
			this.responses[ID] := false
			while (this.readyState = 1 && !this.responses[ID]){
				Sleep(20)
				If(A_Index >= 200){
					GoTo responseRepeat
				}
			}

			; Get the response, check if it's an error
			if !response := this.responses.Delete(ID)
				throw Error('Not connected to tab')
			if !(response is Map)
				return response
			if (response.Has('error'))
				throw Error('Chrome indicated error in response', , JSON.stringify(response['error']))
			try return response['result']
		}
		Evaluate(JS) {
			response := this.Call('Runtime.evaluate', {
				expression: JS,
				objectGroup: 'console',
				includeCommandLineAPI: JSON.true,
				silent: JSON.false,
				returnByValue: JSON.false,
				userGesture: JSON.true,
				awaitPromise: JSON.false
			})
			if (response is Map) {
				if (response.Has('ErrorDetails'))
					throw Error(response['result']['description'], , JSON.stringify(response['ErrorDetails']))
				return response['result']
			}
		}

		Close() {
			RegExMatch(this.url, 'ws://[\d\.]+:(\d+)/devtools/page/(.+)$', &m)
			http := Chrome._http, http.Open('GET', 'http://127.0.0.1:' m[1] '/json/close/' m[2]), http.Send()
			this.__Delete()
		}

		Activate() {
			http := Chrome._http, RegExMatch(this.url, 'ws://[\d\.]+:(\d+)/devtools/page/(.+)$', &m)
			http.Open('GET', 'http://127.0.0.1:' m[1] '/json/activate/' m[2]), http.Send()
		}

		WaitForLoad(DesiredState := 'complete', Interval := 100) {
			while this.Evaluate('document.readyState')['value'] != DesiredState
				Sleep Interval
		}
		onClose(*) {
			try this.reconnect()
			catch WebSocket.Error
				this.__Delete()
		}
		onMessage(msg) {
			data := JSON.parse(msg)
			if this.responses.Has(id := data.Get('id', 0))
				this.responses[id] := data
			try (this.callback)(data)
		}
		NavigateAndWait(destination, DesiredState:="complete", Interval:=100)
		{
			fromUrl := ""
			Loop{
				try
				{
					fromUrl := this.evaluate("window.location.href")["value"]
				}
				catch Error as fromUrlError
				{
				}
			}Until fromUrl != ""
			destination := StrReplace(destination, "http://", "https://")
			if(!instr(destination, "https://")){
				destination := "https://" . destination
			}
			Loop{
				;this.Call("Page.navigate", Map("url", destination))
				this.Evaluate("window.location = '" destination "'")
				sleep 100
			}Until ( this.evaluate("window.location.href")["value"] != fromUrl)
			Loop{
				Sleep Interval
			}Until  (this.Evaluate("document.readyState")["value"] = DesiredState)
		}
		TestJS(JS){
			for ii, value in this.evaluate(JS){
				msgbox "ii er:`t" ii "`r`nvalue er:`t" value
			}
			return
		}
		Value(JS)
		{
			;return string af document.querySelector statement
			try return this.evaluate(JS)["value"]
			catch {
				msgbox "No Returnvalue for JS String, try TestJS(JS)"
				return
			}
		}
		innerTextArray_OLD(JS){
			return StrSplit(substr(this.evaluate("JSON.stringify([].slice.call(" JS ").map(function(e) { return e.innerText; }))")["value"],3,-2), '","')
		}
		innerTextArray(JS){
			return StrSplit(substr(this.evaluate("JSON.stringify([].slice.call(document.querySelectorAll(" '"' JS '"' ")).map(function(e) { return e.innerText; }))")["value"],3,-2), '","')
		}
		innerTextArrayRemoveChar(JS, char){	;Char := "£" : Fjerne forekomster af £
			return StrSplit(substr(this.evaluate("JSON.stringify([].slice.call(document.querySelectorAll(" '"' JS '"' ")).map(function(e) { return e.innerText.replace(" '"' char '", ""' "); }))")["value"],3,-2), '","')
		}
		hrefArray(JS){
			return StrSplit(substr(this.evaluate("JSON.stringify([].slice.call(document.querySelectorAll(" '"' JS '"' ")).map(function(e) { return e.href; }))")["value"],3,-2), '","')
		}
		ValueArray(JS)
		{
			;return et array med strings, indeholdende indhold fra JSON.stringify([].map.call(document.querySelectorAll(JS), e => e.*))	*innerText
			return JSON.parse(this.evaluate(JS)["value"])
		}
	}
}
class JSON {
	static null := ComValue(1, 0), true := ComValue(0xB, 1), false := ComValue(0xB, 0)
	
	/**
	 * Converts a AutoHotkey Object Notation JSON string into an object.
	 * @param text A valid JSON string.
	 * @param keepbooltype convert true/false/null to JSON.true / JSON.false / JSON.null where it's true, otherwise 1 / 0 / ''
	 * @param as_map object literals are converted to map, otherwise to object
	 */
	static parse(text, keepbooltype := false, as_map := true) {
		keepbooltype ? (_true := JSON.true, _false := JSON.false, _null := JSON.null) : (_true := true, _false := false, _null := "")
		as_map ? (map_set := (maptype := Map).Prototype.Set) : (map_set := (obj, key, val) => obj.%key% := val, maptype := Object)
		NQ := "", LF := "", LP := 0, P := "", R := ""
		D := [C := (A := InStr(text := LTrim(text, " `t`r`n"), "[") = 1) ? [] : maptype()], text := LTrim(SubStr(text, 2), " `t`r`n"), L := 1, N := 0, V := K := "", J := C, !(Q := InStr(text, '"') != 1) ? text := LTrim(text, '"') : ""
		Loop Parse text, '"' {
			Q := NQ ? 1 : !Q
			NQ := Q && (SubStr(A_LoopField, -3) = "\\\" || (SubStr(A_LoopField, -1) = "\" && SubStr(A_LoopField, -2) != "\\"))
			if !Q {
				if (t := Trim(A_LoopField, " `t`r`n")) = "," || (t = ":" && V := 1)
					continue
				else if t && (InStr("{[]},:", SubStr(t, 1, 1)) || RegExMatch(t, "^-?\d*(\.\d*)?\s*[,\]\}]")) {
					Loop Parse t {
						if N && N--
							continue
						if InStr("`n`r `t", A_LoopField)
							continue
						else if InStr("{[", A_LoopField) {
							if !A && !V
								throw Error("Malformed JSON - missing key.", 0, t)
							C := A_LoopField = "[" ? [] : maptype(), A ? D[L].Push(C) : D[L][K] := C, D.Has(++L) ? D[L] := C : D.Push(C), V := "", A := Type(C) = "Array"
							continue
						} else if InStr("]}", A_LoopField) {
							if !A && V
								throw Error("Malformed JSON - missing value.", 0, t)
							else if L = 0
								throw Error("Malformed JSON - to many closing brackets.", 0, t)
							else C := --L = 0 ? "" : D[L], A := Type(C) = "Array"
						} else if !(InStr(" `t`r,", A_LoopField) || (A_LoopField = ":" && V := 1)) {
							if RegExMatch(SubStr(t, A_Index), "m)^(null|false|true|-?\d+\.?\d*)\s*[,}\]\r\n]", &R) && (N := R.Len(0) - 2, R := R.1, 1) {
								if A
									C.Push(R = "null" ? _null : R = "true" ? _true : R = "false" ? _false : IsNumber(R) ? R + 0 : R)
								else if V
									map_set(C, K, R = "null" ? _null : R = "true" ? _true : R = "false" ? _false : IsNumber(R) ? R + 0 : R), K := V := ""
								else throw Error("Malformed JSON - missing key.", 0, t)
							} else {
								; Added support for comments without '"'
								if A_LoopField == '/' {
									nt := SubStr(t, A_Index + 1, 1), N := 0
									if nt == '/' {
										if nt := InStr(t, '`n', , A_Index + 2)
											N := nt - A_Index - 1
									} else if nt == '*' {
										if nt := InStr(t, '*/', , A_Index + 2)
											N := nt + 1 - A_Index
									} else nt := 0
									if N
										continue
								}
								throw Error("Malformed JSON - unrecognized character-", 0, A_LoopField " in " t)
							}
						}
					}
				} else if InStr(t, ':') > 1
					throw Error("Malformed JSON - unrecognized character-", 0, SubStr(t, 1, 1) " in " t)
			} else if NQ && (P .= A_LoopField '"', 1)
				continue
			else if A
				LF := P A_LoopField, C.Push(InStr(LF, "\") ? UC(LF) : LF), P := ""
			else if V
				LF := P A_LoopField, C[K] := InStr(LF, "\") ? UC(LF) : LF, K := V := P := ""
			else
				LF := P A_LoopField, K := InStr(LF, "\") ? UC(LF) : LF, P := ""
		}
		return J
		UC(S, e := 1) {
			static m := Map(Ord('"'), '"', Ord("a"), "`a", Ord("b"), "`b", Ord("t"), "`t", Ord("n"), "`n", Ord("v"), "`v", Ord("f"), "`f", Ord("r"), "`r")
			local v := ""
			Loop Parse S, "\"
				if !((e := !e) && A_LoopField = "" ? v .= "\" : !e ? (v .= A_LoopField, 1) : 0)
					v .= (t := InStr("ux", SubStr(A_LoopField, 1, 1)) ? SubStr(A_LoopField, 1, RegExMatch(A_LoopField, "i)^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K") - 1) : "") && RegexMatch(t, "i)^[ux][\da-f]+$") ? Chr(Abs("0x" SubStr(t, 2))) SubStr(A_LoopField, RegExMatch(A_LoopField, "i)^[ux]?([\dA-F]{4})?([\dA-F]{2})?\K")) : m.has(Ord(A_LoopField)) ? m[Ord(A_LoopField)] SubStr(A_LoopField, 2) : "\" A_LoopField, e := A_LoopField = "" ? e : !e
			return v
		}
	}
	
	/**
	 * Converts a AutoHotkey Array/Map/Object to a Object Notation JSON string.
	 * @param obj A AutoHotkey value, usually an object or array or map, to be converted.
	 * @param expandlevel The level of JSON string need to expand, by default expand all.
	 * @param space Adds indentation, white space, and line break characters to the return-value JSON text to make it easier to read.
	 */
	static stringify(S, expandlevel := unset, space := "  ") {
		expandlevel := IsSet(expandlevel) ? Abs(expandlevel) : 10000000
		return Trim(CO(S, expandlevel))
		CO(O, J := 0, R := 0, Q := 0) {
			static M1 := "{", M2 := "}", S1 := "[", S2 := "]", N := "`n", C := ",", S := "- ", E := "", K := ":"
			if (OT := Type(O)) = "Array" {
				D := !R ? S1 : ""
				for key, value in O {
					F := (VT := Type(value)) = "Array" ? "S" : InStr("Map,Object", VT) ? "M" : E
					Z := VT = "Array" && value.Length = 0 ? "[]" : ((VT = "Map" && value.count = 0) || (VT = "Object" && ObjOwnPropCount(value) = 0)) ? "{}" : ""
					D .= (J > R ? "`n" CL(R + 2) : "") (F ? (%F%1 (Z ? "" : CO(value, J, R + 1, F)) %F%2) : ES(value)) (OT = "Array" && O.Length = A_Index ? E : C)
				}
			} else {
				D := !R ? M1 : ""
				for key, value in (OT := Type(O)) = "Map" ? (Y := 1, O) : (Y := 0, O.OwnProps()) {
					F := (VT := Type(value)) = "Array" ? "S" : InStr("Map,Object", VT) ? "M" : E
					Z := VT = "Array" && value.Length = 0 ? "[]" : ((VT = "Map" && value.count = 0) || (VT = "Object" && ObjOwnPropCount(value) = 0)) ? "{}" : ""
					D .= (J > R ? "`n" CL(R + 2) : "") (Q = "S" && A_Index = 1 ? M1 : E) ES(key) K (F ? (%F%1 (Z ? "" : CO(value, J, R + 1, F)) %F%2) : ES(value)) (Q = "S" && A_Index = (Y ? O.count : ObjOwnPropCount(O)) ? M2 : E) (J != 0 || R ? (A_Index = (Y ? O.count : ObjOwnPropCount(O)) ? E : C) : E)
					if J = 0 && !R
						D .= (A_Index < (Y ? O.count : ObjOwnPropCount(O)) ? C : E)
				}
			}
			if J > R
				D .= "`n" CL(R + 1)
			if R = 0
				D := RegExReplace(D, "^\R+") (OT = "Array" ? S2 : M2)
			return D
		}
		ES(S) {
			switch Type(S) {
				case "Float":
					if (v := '', d := InStr(S, 'e'))
						v := SubStr(S, d), S := SubStr(S, 1, d - 1)
					if ((StrLen(S) > 17) && (d := RegExMatch(S, "(99999+|00000+)\d{0,3}$")))
						S := Round(S, Max(1, d - InStr(S, ".") - 1))
					return S v
				case "Integer":
					return S
				case "String":
					S := StrReplace(S, "\", "\\")
					S := StrReplace(S, "`t", "\t")
					S := StrReplace(S, "`r", "\r")
					S := StrReplace(S, "`n", "\n")
					S := StrReplace(S, "`b", "\b")
					S := StrReplace(S, "`f", "\f")
					S := StrReplace(S, "`v", "\v")
					S := StrReplace(S, '"', '\"')
					return '"' S '"'
				default:
					return S == JSON.true ? "true" : S == JSON.false ? "false" : "null"
			}
		}
		CL(i) {
			Loop (s := "", space ? i - 1 : 0)
				s .= space
			return s
		}
	}
}


#DllLoad winhttp.dll
class WebSocket {
	Ptr := 0, async := 0, readyState := 0, url := '', waiting := false
	HINTERNETs := [], cache := Buffer(0), recdata := Buffer(0)

	; onClose(status, reason) => void
	; onData(eBufferType, ptr, size) => void
	; onMessage(msg) => void

	/**
	 * @param Url the url of websocket
	 * @param Events an object of `{data:(this, eBufferType, ptr, size)=>void,message:(this, msg)=>void,close:(this, status, reason)=>void}`
	 */
	__New(Url, Events := 0, Async := true, Headers := '') {
		this.HINTERNETs := [], this.async := !!Async, this.cache.Size := 8192, this.url := Url
		if (!RegExMatch(Url, 'i)^((?<SCHEME>wss?)://)?((?<USERNAME>[^:]+):(?<PASSWORD>.+)@)?(?<HOST>[^/:]+)(:(?<PORT>\d+))?(?<PATH>/.*)?$', &m))
			throw WebSocket.Error('Invalid websocket url')
		if !hSession := DllCall('Winhttp\WinHttpOpen', 'ptr', 0, 'uint', 0, 'ptr', 0, 'ptr', 0, 'uint', Async ? 0x10000000 : 0, 'ptr')
			throw WebSocket.Error()
		this.HINTERNETs.Push(hSession), port := m.PORT ? Integer(m.PORT) : m.SCHEME = 'ws' ? 80 : 443, dwFlags := m.SCHEME = 'wss' ? 0x800000 : 0
		if !hConnect := DllCall('Winhttp\WinHttpConnect', 'ptr', hSession, 'wstr', m.HOST, 'ushort', port, 'uint', 0, 'ptr')
			throw WebSocket.Error()
		this.HINTERNETs.Push(hConnect)
		switch Type(Headers) {
			case 'Object', 'Map':
				s := ''
				for k, v in Headers is Map ? Headers : Headers.OwnProps()
					s .= '`r`n' k ': ' v
				Headers := LTrim(s, '`r`n')
			case 'String':
			default:
				Headers := ''
		}
		if (Events) {
			for k, v in Events.OwnProps()
				if (k ~= 'i)^(data|message|close)$')
					this.on%k% := v
		}
		connect(this)
		this.reconnect := connect

		connect(self) {
			static StatusCallback, msg_gui, wm_ahkmsg := DllCall('RegisterWindowMessage', 'str', 'AHK_WEBSOCKET_STATUSCHANGE', 'uint')
			static pSendMessageW := DllCall('GetProcAddress', 'ptr', DllCall('GetModuleHandle', 'str', 'user32', 'ptr'), 'astr', 'SendMessageW', 'ptr')
			if !self.HINTERNETs.Length
				throw WebSocket.Error('The connection is closed')
			self.shutdown()
			while (self.HINTERNETs.Length > 2)
				DllCall('Winhttp\WinHttpCloseHandle', 'ptr', self.HINTERNETs.Pop())
			if !hRequest := DllCall('Winhttp\WinHttpOpenRequest', 'ptr', hConnect, 'wstr', 'GET', 'wstr', m.PATH, 'ptr', 0, 'ptr', 0, 'ptr', 0, 'uint', dwFlags, 'ptr')
				throw WebSocket.Error()
			self.HINTERNETs.Push(hRequest)
			if (Headers)
				DllCall('Winhttp\WinHttpAddRequestHeaders', 'ptr', hRequest, 'wstr', Headers, 'uint', -1, 'uint', 0x20000000, 'int')
			if (!DllCall('Winhttp\WinHttpSetOption', 'ptr', hRequest, 'uint', 114, 'ptr', 0, 'uint', 0, 'int')
				|| !DllCall('Winhttp\WinHttpSendRequest', 'ptr', hRequest, 'ptr', 0, 'uint', 0, 'ptr', 0, 'uint', 0, 'uint', 0, 'uptr', 0, 'int')
				|| !DllCall('Winhttp\WinHttpReceiveResponse', 'ptr', hRequest, 'ptr', 0)
				|| !DllCall('Winhttp\WinHttpQueryHeaders', 'ptr', hRequest, 'uint', 19, 'ptr', 0, 'wstr', status := '00000', 'uint*', 10, 'ptr', 0, 'int')
				|| status != '101')
				throw IsSet(status) ? WebSocket.Error('Invalid status: ' status) : WebSocket.Error()
			if !self.Ptr := DllCall('Winhttp\WinHttpWebSocketCompleteUpgrade', 'ptr', hRequest, 'ptr', 0)
				throw WebSocket.Error()
			DllCall('Winhttp\WinHttpCloseHandle', 'ptr', self.HINTERNETs.Pop()), self.HINTERNETs.Push(self.Ptr), self.readyState := 1
			if (Async) {
				if !IsSet(StatusCallback) {
					StatusCallback := get_sync_StatusCallback()
					DllCall('SetParent', 'ptr', (msg_gui := Gui()).Hwnd, 'ptr', -3)
					OnMessage(wm_ahkmsg, WEBSOCKET_STATUSCHANGE)
				}
				NumPut('ptr', ObjPtr(self), 'ptr', msg_gui.Hwnd, 'ptr', pSendMessageW, 'uint', wm_ahkmsg, self.__context := Buffer(4 * A_PtrSize))
				DllCall('Winhttp\WinHttpSetOption', 'ptr', self, 'uint', 45, 'ptr*', self.__context.Ptr, 'uint', A_PtrSize)
				DllCall('Winhttp\WinHttpSetStatusCallback', 'ptr', self, 'ptr', StatusCallback, 'uint', 0xffffffff, 'uptr', 0, 'ptr')
				self.waiting := true
				DllCall('Winhttp\WinHttpWebSocketReceive', 'ptr', self, 'ptr', self.cache, 'uint', self.cache.Size, 'uint*', 0, 'uint*', 0)
			}

			get_sync_StatusCallback() {
				mcodes := ['i1QkDIPsDIH6AAAIAHQIgfoAAAAEdTWLTCQUiwGJBCSLRCQQiUQkBItEJByJRCQIM8CB+gAACAAPlMBQjUQkBFD/cQyLQQj/cQT/0IPEDMIUAA==',
					'SIPsSEyL0kGB+AAACAB0CUGB+AAAAAR1MEiLAotSGEyJTCQwRTPJQYH4AAAIAEiJTCQoSYtKCEyNRCQgQQ+UwUiJRCQgQf9SEEiDxEjD']
				DllCall('crypt32\CryptStringToBinary', 'str', hex := mcodes[A_PtrSize >> 2], 'uint', 0, 'uint', 1, 'ptr', 0, 'uint*', &s := 0, 'ptr', 0, 'ptr', 0) &&
					DllCall('crypt32\CryptStringToBinary', 'str', hex, 'uint', 0, 'uint', 1, 'ptr', code := Buffer(s), 'uint*', &s, 'ptr', 0, 'ptr', 0) &&
					DllCall('VirtualProtect', 'ptr', code, 'uint', s, 'uint', 0x40, 'uint*', 0)
				return code
				/*
				struct __CONTEXT {
					void *obj;
					HWND hwnd;
					decltype(&SendMessageW) pSendMessage;
					UINT msg;
				};
				void __stdcall WinhttpStatusCallback(
					void *hInternet,
					DWORD_PTR dwContext,
					DWORD dwInternetStatus,
					void *lpvStatusInformation,
					DWORD dwStatusInformationLength) {
					if (dwInternetStatus == 0x80000 || dwInternetStatus == 0x4000000) {
						__CONTEXT *context = (__CONTEXT *)dwContext;
						void *param[3] = { context->obj,hInternet,lpvStatusInformation };
						context->pSendMessage(context->hwnd, context->msg, (WPARAM)param, dwInternetStatus == 0x80000);
					}
				}*/
			}

			static WEBSOCKET_STATUSCHANGE(wp, lp, msg, hwnd) {
				ws := ObjFromPtrAddRef(NumGet(wp, 'ptr'))
				if lp {
					if (ws.readyState != 1)
						return
					hInternet := NumGet(wp, A_PtrSize, 'ptr')
					lpvStatusInformation := NumGet(wp, A_PtrSize * 2, 'ptr')
					dwBytesTransferred := NumGet(lpvStatusInformation, 'uint')
					eBufferType := NumGet(lpvStatusInformation, 4, 'uint')
					ws.waiting := false, rec := ws.recdata, offset := rec.Size
					switch eBufferType {
						case 0, 1:	; BINARY, BINARY_FRAGMENT
							try ws.onData(eBufferType, ws.cache.Ptr, dwBytesTransferred)
							wait()
						case 2:		; UTF8
							if (offset) {
								rec.Size += dwBytesTransferred, DllCall('RtlMoveMemory', 'ptr', rec.Ptr + offset, 'ptr', ws.cache, 'uint', dwBytesTransferred)
								msg := StrGet(rec, 'utf-8'), ws.recdata := Buffer(offset := 0), wait()
							} else msg := StrGet(ws.cache, dwBytesTransferred, 'utf-8'), wait()
							try ws.onMessage(msg)
						case 3:		; UTF8_FRAGMENT
							rec.Size += dwBytesTransferred, DllCall('RtlMoveMemory', 'ptr', rec.Ptr + offset, 'ptr', ws.cache, 'uint', dwBytesTransferred), offset += dwBytesTransferred
							wait()
						default:	; CLOSE
							ws.shutdown(), ws.readyState := 3
							rea := ws.QueryCloseStatus()
							try ws.onClose(rea.status, rea.reason)
					}
				} else ws.readyState := 3
				wait() {
					SetTimer(receive, -1, 2147483647)
					receive() {
						ws.waiting := true
						ret := DllCall('Winhttp\WinHttpWebSocketReceive', 'ptr', hInternet, 'ptr', ws.cache, 'uint', ws.cache.Size, 'uint*', 0, 'uint*', 0)
						if (ret && ret != 12030)
							throw WebSocket.Error(ret)
					}
				}
			}
		}
	}

	__Delete() {
		this.shutdown()
		while (this.HINTERNETs.Length)
			DllCall('Winhttp\WinHttpCloseHandle', 'ptr', this.HINTERNETs.Pop())
	}

	class Error extends Error {
		__New(err := A_LastError) {
			static module := DllCall('GetModuleHandle', 'str', 'winhttp', 'ptr')
			if err is Integer
				if (DllCall("FormatMessage", "uint", 0x900, "ptr", module, "uint", err, "uint", 0, "ptr*", &pstr := 0, "uint", 0, "ptr", 0), pstr)
					err := (msg := StrGet(pstr), DllCall('LocalFree', 'ptr', pstr), msg)
				else err := 'Error Code: ' err
			super.__New(err)
		}
	}

	queryCloseStatus() {
		if (!DllCall('Winhttp\WinHttpWebSocketQueryCloseStatus', 'ptr', this, 'ushort*', &usStatus := 0, 'ptr', vReason := Buffer(123), 'uint', 123, 'uint*', &len := 0))
			return { status: usStatus, reason: StrGet(vReason, len, 'utf-8') }
		else if (this.readyState > 1)
			return { status: 1006, reason: '' }
	}

	send(eBufferType, pvBuffer, dwBufferLength) {
		if (this.readyState != 1)
			throw WebSocket.Error('websocket is disconnected')
		ret := DllCall('Winhttp\WinHttpWebSocketSend', 'ptr', this, 'uint', eBufferType, 'ptr', pvBuffer, 'uint', dwBufferLength, 'uint')
		if (ret) {
			if (ret != 12030)
				throw WebSocket.Error(ret)
			this.shutdown()
			try this.onClose(1006, '')
		}
	}

	sendText(str) {
		if (size := StrPut(str, 'utf-8') - 1) {
			StrPut(str, buf := Buffer(size), 'utf-8')
			this.send(2, buf, size)
		} else
			this.send(2, 0, 0)
	}

	receive() {
		if (this.async)
			throw WebSocket.Error('Used only in synchronous mode')
		if (this.readyState != 1)
			throw WebSocket.Error('websocket is disconnected')
		cache := this.cache, size := this.cache.Size, rec := Buffer(0), offset := 0
		while (!ret := DllCall('Winhttp\WinHttpWebSocketReceive', 'ptr', this, 'ptr', cache, 'uint', size, 'uint*', &dwBytesRead := 0, 'uint*', &eBufferType := 0)) {
			switch eBufferType {
				case 0:
					if (offset)
						rec.Size += dwBytesRead, DllCall('RtlMoveMemory', 'ptr', rec.Ptr + offset, 'ptr', cache, 'uint', dwBytesRead)
					else
						rec := cache, rec.Size := dwBytesRead
					return rec
				case 1, 3:
					rec.Size += dwBytesRead, DllCall('RtlMoveMemory', 'ptr', rec.Ptr + offset, 'ptr', cache, 'uint', dwBytesRead), offset += dwBytesRead
				case 2:
					if (offset) {
						rec.Size += dwBytesRead, DllCall('RtlMoveMemory', 'ptr', rec.Ptr + offset, 'ptr', cache, 'uint', dwBytesRead)
						return StrGet(rec, 'utf-8')
					}
					return StrGet(cache, dwBytesRead, 'utf-8')
				default:
					this.shutdown()
					rea := this.QueryCloseStatus()
					try this.onClose(rea.status, rea.reason)
					return
			}
		}
		if (ret) {
			if (ret != 12030)
				throw WebSocket.Error(ret)
			this.readyState := 3
			try this.onClose(1006, '')
		}
	}

	shutdown() {
		if (this.readyState = 1) {
			this.readyState := 2
			if DllCall('Winhttp\WinHttpWebSocketShutdown', 'ptr', this, 'ushort', 1000, 'ptr', 0, 'uint', 0, 'uint')
				this.readyState := 3
		}
	}

	close() => this.shutdown()
}