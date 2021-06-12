try{   
    Write-Output "Beginning UIPath Orchestrator publish"
    $Package = "Test.1.2.7.nupkg"
    $FilePath = "delete\" + $Package
    Write-Output "File: " + $FilePath
    $FieldName = $Package.Replace(".nupkg","")
    $ContentType = 'multipart/form-data'

    $FileStream = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Open)
    $FileHeader = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new('form-data')
    $FileHeader.Name = $FieldName
    $FileHeader.FileName = Split-Path -leaf $FilePath
    $FileContent = [System.Net.Http.StreamContent]::new($FileStream)
    $FileContent.Headers.ContentDisposition = $FileHeader
    $FileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse($ContentType)

    $MultipartContent = [System.Net.Http.MultipartFormDataContent]::new()
    $MultipartContent.Add($FileContent)

    Invoke-RestMethod -SkipCertificateCheck -Body $MultipartContent "https://devrpa.verticalapps.com/odata/Processes/UiPath.Server.Configuration.OData.UploadPackage" -Method Post -Authentication Bearer -Token ($env:token)
    Write-Output "The package has been successfully published to Orchestrator"
} catch {
   Write-Output "StatusCode:" $_.Exception.Response.StatusCode.value__ 
   Write-Output "Exception:" $_.Exception
   exit 1
}
