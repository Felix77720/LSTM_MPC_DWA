$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath('LSTM_MPC_DWA\paper')
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

function Export-DocxPdf([string]$docx, [string]$pdf) {
    $doc = $word.Documents.Open($docx, $false, $true)
    try {
        $doc.ExportAsFixedFormat($pdf, 17)
    }
    finally {
        $doc.Close($false)
        [Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
    }
}

$items = @(
    @([IO.Path]::Combine($root, 'target_sys_ele\system_engineering_electronics_manuscript_CN.docx'), [IO.Path]::Combine($root, 'target_sys_ele\system_engineering_electronics_manuscript_CN.pdf')),
    @([IO.Path]::Combine($root, 'jirs\jirs_manuscript_EN.docx'), [IO.Path]::Combine($root, 'jirs\jirs_manuscript_EN.pdf'))
)

foreach ($item in $items) {
    Export-DocxPdf $item[0] $item[1]
    Write-Output "PDF=$($item[1])"
}

$word.Quit()
[Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
