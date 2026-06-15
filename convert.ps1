$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Open("d:\Project Code\KasirSantriAPK\PRD.docx")
$doc.SaveAs("d:\Project Code\KasirSantriAPK\PRD.txt", 2)
$doc.Close()
$word.Quit()
