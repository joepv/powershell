<#
.Synopsis
    NCSC-NL Log4j Vulnerability (CVE-2021-44228) software information parser.
.DESCRIPTION
    This script parses the markdown tables to a PowerShell object provided by
    the Nationaal Cyber Security Centrum (NCSC-NL) GitHub page.
.EXAMPLE
    Just run and have fun!
.OUTPUTS
    A PowerShell Object with Supplier, Product, Version, Status and Notes columns. 
.NOTES
   Author:         Joep Verhaeg <info@joepverhaeg.nl>
   Creation Date:  December 2021
#>

function ConvertFrom-HtmlTableRow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $htmlTableRow
        ,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        $headers
        ,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [switch]$isHeader
    )
    process {
        $cols = $htmlTableRow | select -expandproperty td
        if($isHeader.IsPresent) {
            0..($cols.Count - 1) | %{$x=$cols[$_] | out-string; if(($x) -and ($x.Trim() -gt [string]::Empty)) {$x.Trim()} else {("Column_{0:0000}" -f $_)}} #clean the headers to ensure each col has a name        
        } else {
            $colCount = ($cols | Measure-Object).Count - 1
            $result = new-object -TypeName PSObject
            0..$colCount | %{
                $colName = if($headers[$_]){$headers[$_]}else{("Column_{0:00000} -f $_")} #in case we have more columns than headers 
                $colValue = $cols[$_]
                $result | Add-Member NoteProperty $colName $colValue
            } 
            Write-Output $result
        }
    }
}

function ConvertFrom-HtmlTable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $htmlTable
    )
    process {
        [xml]$cleanedHtml = ("<!DOCTYPE doctypeName [<!ENTITY nbsp ' '>]><root>{0}</root>" -f ($htmlTable | select -ExpandProperty innerHTML | %{(($_ | out-string) -replace '(</?t[rdh])[^>]*(/?>)|(?:<[^>]*>)','$1$2') -replace '(</?)(?:th)([^>]*/?>)','$1td$2'})) 
        
        [string[]]$headers = $cleanedHtml.root.td.tr | select -first 1 | ConvertFrom-HtmlTableRow -isHeader
        $cleanedHtml.root.tr | ConvertFrom-HtmlTableRow -Headers $headers | select $headers 
    }
}

$githubpage = (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/NCSC-NL/log4shell/main/software/README.md').Content
$source = ($githubpage | ConvertFrom-Markdown).Html
$dom = "<!DOCTYPE html><html><body>$($source)</body></html>" 
$html = New-Object -ComObject "HTMLFile";
try {
    # This works in PowerShell with Office installed
    $html.IHTMLDocument2_write($dom)
}
catch {
    # This works when Office is not installed    
    $src = [System.Text.Encoding]::Unicode.GetBytes($dom)
    $html.write($src)
}

$tables = $html.getElementsByTagName('table')

while ($i -ne $tables.Length) {
    $products += $tables[$i] | ConvertFrom-HtmlTable
    $i++
}

$products