# Function to tokenize a message by splitting on whitespace
function ConvertTo-TokenizedMessage {
    param (
        [string]$Message
    )
    return $Message -split '\s+'
}

# Function to compare two tokenized messages
function Test-SimilarMessage {
    param (
        [array]$Tokens1,
        [array]$Tokens2,
        [float]$SimilarityThreshold = 0.7
    )
    
    $CommonTokens = 0
    $TokenCount = [Math]::Max($Tokens1.Length, $Tokens2.Length)
    
    for ($i = 0; $i -lt $TokenCount; $i++) {
        if ($Tokens1[$i] -eq $Tokens2[$i]) {
            $CommonTokens++
        }
    }
    
    $Similarity = $CommonTokens / $TokenCount
    return $Similarity -ge $SimilarityThreshold
}

# Function to process Error Reports CSV file
function Invoke-ErrorReportsProcessing {
    param (
        [string]$FilePath
    )
    
    $Data = Import-Csv -Path $FilePath | Sort-Object 'lastFailedRunErrorMsg'
    
    $PreviousTokens = $null
    $CurrentErrorGroup = @()
    $UniqueErrors = @{}

    foreach ($Row in $Data) {
        $Message = if ([string]::IsNullOrEmpty($Row.'lastFailedRunErrorMsg')) { "Empty error message" } else { $Row.'lastFailedRunErrorMsg' }
        $Tokens = ConvertTo-TokenizedMessage -Message $Message

        if (-not $PreviousTokens -or -not (Test-SimilarMessage -Tokens1 $PreviousTokens -Tokens2 $Tokens)) {
            if ($CurrentErrorGroup.Count -gt 0) {
                $UniqueErrors[$PreviousTokens -join " "] = $CurrentErrorGroup
            }
            $CurrentErrorGroup = @()
            $PreviousTokens = $Tokens
        }

        $CurrentErrorGroup += $Row.'objectName'
    }

    if ($CurrentErrorGroup.Count -gt 0) {
        $UniqueErrors[$PreviousTokens -join " "] = $CurrentErrorGroup
    }

    return $UniqueErrors
}

# Function to process Activity UI Export of Failures CSV file
function Invoke-ActivityExportProcessing {
    param (
        [string]$FilePath
    )
    
    $Data = Import-Csv -Path $FilePath | Sort-Object 'archivalRunParams.errorMessage'
    
    $PreviousTokens = $null
    $CurrentErrorGroup = @()
    $UniqueErrors = @{}

    foreach ($Row in $Data) {
        $Message = if ([string]::IsNullOrEmpty($Row.'archivalRunParams.errorMessage')) { "Empty error message" } else { $Row.'archivalRunParams.errorMessage' }
        $Tokens = ConvertTo-TokenizedMessage -Message $Message

        if (-not $PreviousTokens -or -not (Test-SimilarMessage -Tokens1 $PreviousTokens -Tokens2 $Tokens)) {
            if ($CurrentErrorGroup.Count -gt 0) {
                $UniqueErrors[$PreviousTokens -join " "] = $CurrentErrorGroup
            }
            $CurrentErrorGroup = @()
            $PreviousTokens = $Tokens
        }

        $CurrentErrorGroup += $Row.'object.name'
    }

    if ($CurrentErrorGroup.Count -gt 0) {
        $UniqueErrors[$PreviousTokens -join " "] = $CurrentErrorGroup
    }

    return $UniqueErrors
}

# Function to generate the report based on unique errors
function Export-ErrorReport {
    param (
        [hashtable]$UniqueErrors
    )
    
    $Report = ""

    foreach ($ErrorMessage in $UniqueErrors.Keys) {
        $ObjectNames = $UniqueErrors[$ErrorMessage]
        $Report += "Error: $ErrorMessage`n"
        $Report += "  Total Count: $($ObjectNames.Count)`n"
        $Report += "  Affected Objects: $($ObjectNames -join ', ')`n`n"
    }

    return $Report
}

# Main script execution
$FilePath = "/Users/fabian.sanchez/Library/CloudStorage/GoogleDrive-fabian.sanchez@cohesity.com/My Drive/Projects/Automation/IO Files/Input/activity_8_20_24_3_27 pm.csv"
$FileType = "ActivityExport"  # Change to "ErrorReports" if processing an Error Reports CSV

if ($FileType -eq "ErrorReports") {
    $UniqueErrors = Invoke-ErrorReportsProcessing -FilePath $FilePath
} elseif ($FileType -eq "ActivityExport") {
    $UniqueErrors = Invoke-ActivityExportProcessing -FilePath $FilePath
} else {
    Write-Error "Unknown file type. Please specify 'ErrorReports' or 'ActivityExport'."
    exit
}

$Report = Export-ErrorReport -UniqueErrors $UniqueErrors
$Report | Out-File -FilePath "/Users/fabian.sanchez/Library/CloudStorage/GoogleDrive-fabian.sanchez@cohesity.com/My Drive/Projects/Automation/IO Files/Output/ErrorReport.txt"

Write-Output "Report generated and saved to /Users/fabian.sanchez/Library/CloudStorage/GoogleDrive-fabian.sanchez@cohesity.com/My Drive/Projects/Automation/IO Files/Output/ErrorReport.txt"
