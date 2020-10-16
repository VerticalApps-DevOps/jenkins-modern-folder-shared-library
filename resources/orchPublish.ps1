try {
   $project = Get-Content -Raw -Path $env:WORKSPACE\project.json | ConvertFrom-Json
   & "C:\Program Files (x86)\UiPath\Studio\UiRobot.exe" -pack "$env:WORKSPACE\project.json" --output "$env:WORKSPACE" -v $project.projectVersion

   $auth = @{
      tenancyName = $env:tenancy
      usernameOrEmailAddress = $env:user
      password = $env:pwd
   }

   Write-Output "Beginning UIPath Orchestrator Authentication"
   $authjson = $auth | ConvertTo-Json
   $authkey = Invoke-RestMethod -SkipCertificateCheck "$env:url/api/Account/Authenticate" -Method Post -Body $authjson -ContentType 'application/json'
   $authjson = $authkey | ConvertTo-Json
   $token = $authjson | ConvertFrom-Json
   Set-Variable -Name "ts" -Value $token.result

   $tokenstring = ConvertTo-SecureString $ts -AsPlainText -Force

   Write-Output "Beginning UIPath Orchestrator publish"
   # Replace spaces with underscores
   $project.name = $project.name.Replace(" ","_")
   $Package = $project.name + "." + $project.projectVersion + ".nupkg"
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

   if ($project.designOptions.outputType -eq "Library") {
      Write-Output "Publishing Library"
      Invoke-RestMethod -SkipCertificateCheck -Body $MultipartContent "$env:url/odata/Libraries/UiPath.Server.Configuration.OData.UploadPackage" -Method Post -Authentication Bearer -Token ($tokenstring)
      Write-Output "The library has been successfully published to Orchestrator and nexus"
   } else {
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
         Name = $project.name
         #EnvironmentId = $env:environmentId
         ProcessKey = $project.name
         ProcessVersion = $project.projectVersion
         packageVersion = $project.projectVersion
      }

      $specificPackageParameters = @{
         packageVersion = $project.projectVersion
      }

      $headers = @{
         'X-UIPATH-OrganizationUnitId' = $folderId
      }

      $updateparam = $specificPackageParameters | ConvertTo-Json

      Write-Output "Beginning call to read Releases"
      $rels = Invoke-RestMethod -SkipCertificateCheck -Headers $headers "$env:url/odata/Releases" -Method Get -Authentication Bearer -Token ($tokenstring)
      Write-Output "Releases returned and read"

      $updated = 0

      $releases = $rels | ConvertTo-Json
      $releasesjson = $releases | ConvertFrom-Json
      $processes = $releasesjson.value

      foreach($i in $processes) {
         if ($i.ProcessKey -eq $release.ProcessKey) {
            Write-Output "Beginning Process Update"
            $updateresponse = Invoke-RestMethod -SkipCertificateCheck -Headers $headers -ContentType 'application/json' -Body $updateparam "$env:url/odata/Releases($($i.Id))/UiPath.Server.Configuration.OData.UpdateToSpecificPackageVersion" -Method Post -Authentication Bearer -Token ($tokenstring)
            $updated  = 1
            Write-Output "Process Successfully Updated"
            break
         }
      }

      if (-Not $updated) {
         try {
            Write-Output "Beginning Process Creation"
            Invoke-RestMethod -SkipCertificateCheck -Headers $headers -Body $release "$env:url/odata/Releases" -Method Post -Authentication Bearer -Token ($tokenstring)
            Write-Output "Process Successfully Created"
         } catch {
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
         }
         
      }
   }
} catch {
   Write-Output "StatusCode:" $_.Exception.Response.StatusCode.value__ 
   Write-Output "Exception:" $_.Exception
   exit 1
}
