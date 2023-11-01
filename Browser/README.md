# Browser

### Åben browser der er modtagelig for javascript injection
Åben Brave med Run (Win+R)

	Brave.exe --remote-debugging-port=9222
	
Åben Brave med genvej; ændre destinationen

	"C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" --remote-debugging-port=9222

### Get Page
	page := Brave.GetPageByUrl("reddit.com")	;Matchmode er contains ;Brave browser
	page := Chrome.GetPageByUrl("reddit.com")	;Matchmode er contains ;Chrome browser
	if !isobject(page){
		msgbox "Ikke connected"
		return
	}

### Send kommando til page
	page.Evaluate(JS)
	
### Skift adresse på hjemmeside, og vent på at den er indlæst
	page.NavigateAndWait("www.google.com")

### Vent på at hjemmeside er indlæst
	page.WaitForLoad()

### Vent på at hjemmesiden indeholer
	page.WaitFor(JS, string)
	
### GetElement
	document.getElementById("")
	document.getElementsByTagName("p")
	document.getElementsByClassName("intro")
	document.getElementsByName("val")
	
### querySelector
	document.querySelector("")
	document.querySelectorAll("")

### querySelector for attribute
	tagName[attributeName='attributeValue']		;tagName ikke nødvendigt

### querySelector for class
	.className

### querySelector for id
	#idName
	
### Test indholdet af en Javascript String
	page.TestJS(JS)

### Få value som String af et javascript
	JS := "document.querySelector('h1').innerText"
	stringOutput := page.Value(JS)
	
### Få innerText som Array af en querySelectorAll
	JS := "h3"	;Find innerText af alle <h3>'ere
	arrayOutput := page.innerTextArray(JS)
	
### Få innerText som Array af en querySelectorAll, men slet alle forekomster af f.eks. "£"
	JS := "h3"	;Find innerText af alle <h3>'ere
	arrayOutput := page.innerTextArrayRemoveChar(JS, "£")
	
### Få href som Array af en querySelectorAll
	JS := "h3"	;Find innerText af alle <h3>'ere
	arrayOutput := page.hrefArray(JS)
	
### Få noget andet en innerText af en querySelectorAll
	;Ændre indeholdet i querySelectorAll
	JS := 'JSON.stringify([].slice.call(document.querySelectorAll("h3")).map(function(e) { return e.innerText; }))'	;indsæt noget andet en e.innerText
	arrayOutput := page.ValueArray(JS)
	
### Click
	JS := document.querySelector('div:nth-child(2) a').click()
	page.Evaluate(JS)
	
### Click Event
    JS = document.querySelector('svg > g.highcharts-exporting-group > g').dispatchEvent(new Event('click'))
