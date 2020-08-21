$nexusUrl = "http://ec2-54-196-97-102.compute-1.amazonaws.com:8081/repository/processes-verticalapps"
$package = Invoke-RestMethod "$nexusUrl/${env:PackageName}/${env:PackageVersion}" -Method Get -OutFile "${env:workspace}/${env:PackageName}.${env:PackageVersion}.nupkg"

$auth = @{
   tenancyName = $env:tenancy
   usernameOrEmailAddress = $env:user
   password = $env:pwd
}

$authjson = $auth | ConvertTo-Json
$authkey = Invoke-RestMethod "$env:url/api/Account/Authenticate" -Method Post -Body $authjson -ContentType 'application/json'
$authjson = $authkey | ConvertTo-Json
$token = $authjson | ConvertFrom-Json
Set-Variable -Name "ts" -Value $token.result

$tokenstring = ConvertTo-SecureString $ts -AsPlainText -Force

Write-Output "Beginning UIPath Orchestrator publish"
 
$Package = $env:PackageName + "." + $env:PackageVersion + ".nupkg"
$FilePath = $env:WORKSPACE + "\" + $Package
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


Invoke-RestMethod -SkipCertificateCheck -Body $MultipartContent "$env:url/odata/Processes/UiPath.Server.Configuration.OData.UploadPackage" -Method Post -Authentication Bearer -Token ($tokenstring)
Write-Output "The package has been successfully published to Orchestrator and nexus"

Write-Output "Reading folders for current tenant"
$folders = Invoke-RestMethod -SkipCertificateCheck -Headers $headers "$env:url/odata/Folders" -Method Get -Authentication Bearer -Token ($tokenstring)
Write-Output "Folders successfully retrieved"

$f = $folders | ConvertTo-Json
$foldersjson = $f | ConvertFrom-Json
$tenantfolders = $foldersjson.value

$folderId = $null

foreach($i in $tenantfolders) {
   if ($env:folderName -eq $i.DisplayName) {
      $folderId = $i.Id
      break
   }
}

$release = @{
   Name = $env:PackageName
   ProcessKey = $env:PackageName
   ProcessVersion = $env:PackageName
   packageVersion = $env:PackageVersion
}

$specificPackageParameters = @{
   packageVersion = $env:PackageVersion
}

Write-Output "Folder ID: " $folderId

$headers = @{
   'X-UIPATH-OrganizationUnitId' = $folderId
}

$updateparam = $specificPackageParameters | ConvertTo-Json

Write-Output "Beginning call to read Releases"
$rels = Invoke-RestMethod -Headers $headers "$env:url/odata/Releases" -Method Get -Authentication Bearer -Token ($tokenstring)
Write-Output "Releases returned and read"

$updated = 0

$releases = $rels | ConvertTo-Json
$releasesjson = $releases | ConvertFrom-Json
$processes = $releasesjson.value

foreach($i in $processes) {
   if ($i.ProcessKey -eq $release.ProcessKey) {
      Write-Output "Beginning Process Update"
      $updateresponse = Invoke-RestMethod -Headers $headers -ContentType 'application/json' -Body $updateparam "$env:url/odata/Releases($($i.Id))/UiPath.Server.Configuration.OData.UpdateToSpecificPackageVersion" -Method Post -Authentication Bearer -Token ($tokenstring)
      $updated  = 1
      Write-Output "Process Successfully Updated"
      break
   }
}

if (-Not $updated) {
   Write-Output "Beginning Process Creation"
   Invoke-RestMethod -Headers $headers -Body $release "$env:url/odata/Releases" -Method Post -Authentication Bearer -Token ($tokenstring)
   Write-Output "Process Successfully Created"
}
