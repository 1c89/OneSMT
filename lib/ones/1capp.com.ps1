function Applications_exchangesList {
    param (
        [string]$uri,
        [string]$applicationId
    )

    $headers = onesAppCom_headers;
    [string]$webRequestMethod = "GET";
    $result = Invoke-WebRequest -Uri ("{0}/applications/{1}/exchanges" -f $uri,$applicationId) -Headers $headers -Method $webRequestMethod;
    
    return $result;
 }
function Applications_exchangesUpload {
    param (
        [string]$uri,
        [string]$applicationId,
        [string]$filename,
        [string]$filepath
    )
    
    $ProgressPreference = 'SilentlyContinue';

    $headers = onesAppCom_headers;
    [string]$webRequestMethod = "POST";
    $result = Invoke-WebRequest -Uri ("{0}/applications/{1}/exchanges/upload?filename={2}" -f $uri,$applicationId,$filename) -Headers $headers -Method $webRequestMethod;
    
    if (200 -ne $result.StatusCode) {
        return $result;
    }
    
    $uploadUri = ($result.Content | ConvertFrom-Json).url;
    $webRequestMethod = "PUT"
    $result = Invoke-WebRequest -Uri "$uploadUri" -Headers @{} -Method $webRequestMethod -InFile $filepath;
        
    $ProgressPreference = 'Continue';

    return $result;
    
}

function Applications_exchangesInstall {
    param (
        [string]$uri,
        [string]$applicationId,
        [string]$filename,
        [string]$username,
        [string]$password
    )
    
    $ProgressPreference = 'SilentlyContinue';

    $headers = onesAppCom_headers;
    $body = @{
        username = $username;
        password = $password
    } | ConvertTo-Json;
    [string]$webRequestMethod = "POST";
    $result = Invoke-WebRequest -Uri ("{0}/applications/{1}/exchanges/install?filename={2}" -f $uri,$applicationId,$filename) -Headers $headers -Method $webRequestMethod -Body $body;

    $ProgressPreference = 'Continue';

    return $result;
    
}
function Customers_List {
    param (
    )

    $headers = onesAppCom_headers;

    [string]$webRequestMethod = "GET";
    $result = Invoke-WebRequest -Uri "$URI/customers" -Headers $headers -Method $webRequestMethod;
    
    return $result;
    
}

function onesAppCom_headers {
    param (
    )
    
    $headers = @{
        'Authorization' = 'Bearer XXX';
        'Content-Type' = 'application/json'
    };

    return $headers;

}
#$URI = 'https://service-api.1capp.com/partner-api/v2';

#$CUSTOMERID = 'e760b690-98ec-421b-86af-1e9021cf7d1a';
#$APPID = '44ca8c24-3956-4401-8a06-dcc717ec136c';

