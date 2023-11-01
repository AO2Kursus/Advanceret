run 'brave.exe --remote-debugging-port=9222 -incognito https://www.global.jdsports.com/search/nike+t-shirt/'
Sleep 500
page := Brave.GetPageByUrl("jdsports")
page.WaitforLoad()

;Nogen gange melder en hjemmeside, at den er indlæst, inden indholdet på siden er indlæst af javascriptet
;Så det kan nogen gange betale sig, at vente på at et bestemt element er indlæst, og indeholder en tekst
page.WaitFor('document.querySelector("#productListLeft > div.selected-filters-wrapper > h3").innerText', 'selected')

page.testJS('document.querySelector("#productListLeft > div.selected-filters-wrapper > h3").innerText')

Navn := "[data-e2e='product-listing-name']"
aNavn := page.innerTextArray(Navn)

Pris := "[data-e2e='product-listing-price']"
aPris := page.innerTextArrayRemoveChar(Pris,"£")

;UrlAdd := "JSON.stringify([].slice.call(document.querySelectorAll(" '"' "[data-e2e='product-listing-name']" '"' ")).map(function(e) { return e.href; }))"
;aUrlAdd := page.ValueArray(UrlAdd)
aUrlAdd := page.hrefArray(Navn)

nexthrefJS := "document.querySelector(" '"[title=' "'Next Page']" '").href'
vNexthrefJS := page.Value(nexthrefJS)
msgbox 'Next page href: `n' vNexthrefJS
page.NavigateAndWait(vNexthrefJS)

nextPageClickJS := "document.querySelector(" '"[title=' "'Next Page']" '").click()'
;page.Evaluate(nextPageClickJS)

For ii, value in aPris{
	msgbox aNavn[ii] '`n' value '`n' aUrlAdd[ii]
}

exitapp
