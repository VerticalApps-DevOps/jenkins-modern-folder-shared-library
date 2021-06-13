try {
    $auth = @{
        tenancyName = "Default"
        usernameOrEmailAddress = "Jenkins"
        password = "Password11"
        
        #tenancyName = $env:tenancy
        #usernameOrEmailAddress = $env:user
        #password = $env:pwd
    }

    Write-Host "Beginning UIPath Orchestrator Authentication"
    $authjson = $auth | ConvertTo-Json
    $authkey = Invoke-RestMethod -SkipCertificateCheck "https://ec2-52-91-158-128.compute-1.amazonaws.com/api/Account/Authenticate" -Method Post -Body $authjson -ContentType 'application/json'
    $authjson = $authkey | ConvertTo-Json
    $token = $authjson | ConvertFrom-Json
    Set-Variable -Name "ts" -Value $token.result

    $tokenstring = ConvertTo-SecureString $ts -AsPlainText -Force
    Write-Host "Successfully Authenticated"
    Invoke-Expression "`$PSScriptRoot\publish.ps1` -token $tokenString"
} catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    Write-Host "Exception:" $_.Exception
    exit 1
}
