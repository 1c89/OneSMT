. "$($OneSMT.lib)/ones/1capp.com.ps1";
function updateCfg() {
	param (
		$parameters
	)

	# read settings file
	$settings = Get-Content -Path "$($parameters["--settings"])" -Encoding UTF8 | ConvertFrom-Json;
	
	$ibItems = ibItems -settings $settings;
	
	$ibListsFile = $settings;
	if (0 -ne $parameters["--ibListsFile"]) {
		$ibListsFile = Get-Content -Path "$($parameters["--ibListsFile"])" -Encoding UTF8 | ConvertFrom-Json;
	};

	$ibItemsList = @();
	if (0 -ne $ibListsFile.psobject.Properties.Match('lists').Count) {
		
		$ibListName = $parameters["--ibListName"];
		if (0 -ne $ibListsFile.lists.psobject.Properties.Match($ibListName).Count) {
			$ibItemsList = $ibListsFile.lists.$ibListName;
		}
	}
	
	$ibItemsProcessList = @();
	foreach ($item in $ibItemsList) {

		$ibItem = $ibItems[$item];
		if (($null -ne $ibItem) -and ($ibItem.active)) { $ibItemsProcessList += $ibItem; }

	}
	foreach ($ibItem in $ibItemsProcessList) {

		if (-not $ibItem.active) {
			continue;
		}
		
		updateCfg_ibItem -ibItem $ibItem -updateFile $parameters["--updateFile"];

	}

}
function updateCfg_validArguments() {

	$validArguments = @{};
	makeArgument $validArguments '--settings' $false '';
	makeArgument $validArguments '--ibListName' $false '';
	makeArgument $validArguments '--ibListsFile' $false '';
	makeArgument $validArguments '--updateFile' $false '';

	return $validArguments;
}
function updateCfg_ibItem {
	param (
		$ibItem, # Параметры информационной базы
		[string]$updateFile
	)

	$datestamp = Get-Date -Format 'yyyyMMddHHmmss';
	$log = '{0}/{1}.log' -f $ibItem.logLocation, $ibItem.name;
	$logtmp = '{0}.tmp' -f $log;

	# Создание файла для протокола
	if (-not (Test-Path -Path $log)) {
		New-Item -Path $log -ItemType 'File' -Force:$true | Out-Null;
	}

	Write-Output '========================================================================' | Out-File -FilePath $logtmp -Append;
	Write-Output (('{0} Processing {1}...') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $ibItem.name) | Out-File -FilePath $logtmp -Append;

	switch ($ibItem.type) {
		"file" {
		}
		"server" {
		}
		"cloud" { 
			updateCfg_cloud_ibItem -ibItem $ibItem -updateFile $updateFile;
		}
	}

	Write-Output (('{0} End processing...') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | Out-File -FilePath $logtmp -Append;

	$logtmpContent = Get-Content -Path $logtmp;
	Add-Content -Path $log -Value $logtmpContent;
	#TODO Send mail
	Remove-Item -Path $logtmp;

}

function updateCfg_cloud_ibItem {
	param (
		$ibItem, # Параметры информационной базы
		[string]$updateFile
	)
	
	$updateFileItem = Get-Item -Path $updateFile;

	$result = Applications_exchangesUpload -uri $ibItem.onesLocation -applicationId $ibItem.id -filename $updateFileItem.Name -filepath $updateFile;
	if (200 -ne $result.StatusCode) {
		return $result;
	};

	$result = Applications_exchangesInstall -uri $ibItem.onesLocation -applicationId $ibItem.id -filename $updateFileItem.Name -username $ibItem.username -password $ibItem.password;

	$result;
	
}