function makeArgument {
    param (
        $arguments,
        $name,
        $isSwitch,
        $defaultValue
    )
    $arguments.Add($name, @{'isSwitch' = $isSwitch });
}

function parseArguments {
    param (
        $arguments,
        $validArguments,
        $result
    )

    $name = $null;

    foreach ($argument in $arguments) {
        if ($null -ne $name) {
            
            $result[$name] = $argument;
            $name = $null;
            continue;

        }
            
        $name = $argument;
        if (-not ($validArguments.ContainsKey($name))) {
            
            Write-Information "Invalid argument `"$name`"" -InformationAction:Continue;
            $result = $null;
            return $false;
    
        }
    
        $result.Add($name, $null);
        if ($validArguments[$name].isSwitch) {

            $result[$name] = $true;
            $name = $null;

        }
    }
    
    return $true;

}