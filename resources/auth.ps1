try {
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

    return $tokenstring
} catch {
    Write-Output "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    Write-Output "Exception:" $_.Exception
    exit 1
}
