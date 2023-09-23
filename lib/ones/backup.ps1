function backup() {
	param (
		$parameters
	)

	# read sessings from file
	$settings = Get-Content -Path "$($parameters["--settings"])" -Encoding UTF8 | ConvertFrom-Json;

	$ibItems = ibItems -settings $settings;

	$ibListsFile = $settings;
	if ($null -ne $parameters["--ibListsFile"]) {
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
			
		backup_ibItem -ibItem $ibItem;

	}

}
function backup_validArguments {

	$validArguments = @{};
	makeArgument $validArguments '--settings' $false '';
	makeArgument $validArguments '--ibListName' $false '';
	makeArgument $validArguments '--ibListsFile' $false '';

	return $validArguments;
}
function backup_ibItem {
	param (
		$ibItem # Параметры информационной базы
	)

	$datestamp = Get-Date -Format 'yyyyMMddHHmmss';
	$backupFileName = '{0}/{1}/{2}-{1}' -f $ibItem.backupLocation, $ibItem.name, $datestamp;
	$log = '{0}/{1}.log' -f $ibItem.logLocation, $ibItem.name;
	$logtmp = '{0}.tmp' -f $log;

	# Создание файла для протокола
	if (-not (Test-Path -Path $log)) {
		New-Item -Path $log -ItemType 'File' -Force:$true | Out-Null;
	}

	# Подготовка каталога для резервных копий
	if ( -not (Test-Path -Path ('{0}/{1}' -f $ibItem.backupLocation, $ibItem.name))) {
		New-Item -Path ('{0}/{1}' -f $ibItem.backupLocation, $ibItem.name) -ItemType 'Directory' -Force:$true | Out-Null;
	}

	Write-Output '========================================================================' | Out-File -FilePath $logtmp -Append;
	Write-Output (('{0} Processing {1}...') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $ibItem.name) | Out-File -FilePath $logtmp -Append;

	switch ($ibItem.backupMethod) {
		"ones" {
			$backupFile = ("{0}.dt" -f $backupFileName);
			backup_ones_ibItem -ibItem $ibItem -backupFile $backupFile -log $logtmp;
		}
		"dbms" {
			$backupFile = ("{0}.{1}.bak" -f $backupFileName, $ibItem.dbms);
			backup_dbms_ibItem -ibItem $ibItem -backupFile $backupFile -log $logtmp;
		}
		"copy" { 
			$backupFile = ("{0}.1Cv8.1CD" -f $backupFileName, $ibItem.dbms);
			backup_copy_ibItem -ibItem $ibItem -backupFile $backupFile -log $logtmp;
		}
	}

	Write-Output (('{0} End processing...') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | Out-File -FilePath $logtmp -Append;

	$logtmpContent = Get-Content -Path $logtmp;
	Add-Content -Path $log -Value $logtmpContent;
	#TODO Send mail
	Remove-Item -Path $logtmp;

}
function backup_ones_ibItem {
	param (
		$ibItem,
		$backupFile,
		$log
	)
	
	# throw "$MyInvocation is not implemented";
	
	$onesThinClient = $OneSMT.ones.thinClientTemplate -f $ibItem.onesVersion;
	$onesDesigner = $OneSMT.ones.designerTemplate -f $ibItem.onesVersion;

	# Write-Output (('{0} Restart 1C Service') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | Out-File -FilePath $log -Append;
	# Restart-Service -Name '1C:Enterprise 8.3 Server Agent (x86-64)' | Out-File -FilePath $log -Append
	# 	(Get-Service -Name '1C:Enterprise 8.3 Server Agent (x86-64)').Status | Out-File -FilePath $log -Append

	switch ($ibItem.type) {
		'file' {
			$ibConnection = "/F`"{0}/{1}`"" -f $ibItem.location, $ibItem.name;
			break;
		}
		'server' { 
			$ibConnection = "/S`"{0}\{1}`"" -f $ibItem.location, $ibItem.name;
			break;
		}
		Default {}
	}

	$srcEncoding = [System.Text.Encoding]::GetEncoding("utf-8");
	$dstEncoding = [System.Text.Encoding]::GetEncoding("windows-1251");

	# Параметры запуска завершения работы пользователей
	[String[]]$argumentList = @(
		'ENTERPRISE',
		$ibConnection,
		("/N`"{0}`"" -f $ibItem.username),
		("/P`"{0}`"" -f $ibItem.password),
		'/WA-',
		'/DisableStartupMessages',
		'/DisableSplash',
		("/C`"{0}`"" -f $dstEncoding.GetString([System.Text.Encoding]::Convert($srcEncoding, $dstEncoding, $dstEncoding.GetBytes("ЗавершитьРаботуПользователей")))),
		("/UC`"{0}`"" -f $dstEncoding.GetString([System.Text.Encoding]::Convert($srcEncoding, $dstEncoding, $dstEncoding.GetBytes("КодРазрешения")))),
		("/Out`"{0}`"" -f $log),
		'-NoTruncate'
	);
	Write-Output (('{0} Disable users...') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | Out-File -FilePath $log -Append;
	executeProcess -filePath $onesThinClient -argumentList $argumentList -timeout 1200 -log $log -redirectStandartErrorOutput $true;
	Start-Sleep -Seconds 5
	
	# Параметры запуска выгрузки информационной базы
	[String[]]$argumentList = @(
		'DESIGNER',
		$ibConnection,
		("/N`"{0}`"" -f $ibItem.username),
		("/P`"{0}`"" -f $ibItem.password),
		'/WA-',
		'/DisableStartupMessages',
		'/DisableSplash',
		"/C`"`"",
		("/UC`"{0}`"" -f $dstEncoding.GetString([System.Text.Encoding]::Convert($srcEncoding, $dstEncoding, $dstEncoding.GetBytes("КодРазрешения")))),
		("/Out`"{0}`"" -f $log),
		'-NoTruncate',
		("/DumpIB`"{0}`"" -f $backupFile)
	);
	Write-Output (('{0} Backup database...') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | Out-File -FilePath $log -Append;
	executeProcess -filePath $onesDesigner -argumentList $argumentList -timeout $ibItem.backupTimeout -log $log -redirectStandartErrorOutput $true;
	Start-Sleep -Seconds 5
		
	# Параметры запуска разрешения работы пользователей
	[String[]]$argumentList = @(
		'ENTERPRISE',
		$ibConnection,
		("/N`"{0}`"" -f $ibItem.username),
		("/P`"{0}`"" -f $ibItem.password),
		'/WA-',
		'/DisableStartupMessages',
		'/DisableSplash',
		("/C`"{0}`"" -f $dstEncoding.GetString([System.Text.Encoding]::Convert($srcEncoding, $dstEncoding, $dstEncoding.GetBytes("РазрешитьРаботуПользователей")))),
		("/UC`"{0}`"" -f $dstEncoding.GetString([System.Text.Encoding]::Convert($srcEncoding, $dstEncoding, $dstEncoding.GetBytes("КодРазрешения")))),
		("/Out`"{0}`"" -f $logtmp),
		'-NoTruncate'
	);
	Write-Output (('{0} Enable users...') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | Out-File -FilePath $logtmp -Append;
	executeProcess -filePath $onesThinClient -argumentList $argumentList -timeout 60 -log $log -redirectStandartErrorOutput $true;
	Start-Sleep -Seconds 5

	# pmt_plugins_ones_enable($backup);
	
	return $false;
}
function backup_dbms_ibItem {
	param (
		$ibItem,
		$backupFile,
		$log
	)

	switch ($ibItem.dbms) {
		"PostgreSQL" {
			backup_dbms_PostgreSQL_ibItem -ibItem $ibItem -backupFile $backupFile -log $logtmp;
		}
	}
}
function backup_dbms_PostgreSQL_ibItem {
	param (
		$ibItem,
		$backupFile,
		$log
	)
	
	$env:PGPASSWORD = $ibItem.dbmsPassword;

	[String[]]$argumentList = @(
		'--format=custom',
		("--host={0}" -f $ibItem.dbmsLocation),
		("--dbname={0}" -f $ibItem.dbmsDBName),
		("--username={0}" -f $ibItem.dbmsUsername),
		("--file={0}" -f $backupFile)
	);
	Write-Output (('{0} Backup database...') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) | Out-File -FilePath $log -Append;

	executeProcess -filePath '/usr/bin/pg_dump' -argumentList $argumentList -timeout $ibItem.backupTimeout -log $log -redirectStandartErrorOutput $true;
	
	Start-Sleep -Seconds 2;

}
function backup_copy_ibItem {
	param (
		$ibItem,
		$backupFile,
		$log
	)
	
	if ($ibItem.backupToCompress -and (0 -ne $ibItem.backupCompressor.Length)) {
		Invoke-Expression -Command "& $($ibItem.backupCompressor -f $backupFile,("{0}/{1}/1Cv8.1CD" -f $ibItem.location,$ibItem.name)) 2>&1 1>>'$log'";
	}
	else {
		Copy-Item -Path ("{0}/{1}/1Cv8.1CD" -f $ibItem.location, $ibItem.name) -Destination $backupFile;
	}

}
function executeProcess {
	param (
		$filePath,
		$argumentList,
		$timeout,
		$log,
		[bool]$redirectStandardErrorOutput
	)

	$process = startProcess -filePath $filePath -argumentList $argumentList -redirectStandartErrorOutput $redirectStandardErrorOutput;
	if ($null -eq $process) {
		return;		
	} 
	Write-Output (('{0} Start-Process {1}...') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $process.Id) | Out-File -FilePath $log -Append;
	
	if ($redirectStandardErrorOutput) {
		$process.StandardError.ReadToEnd() | Out-File -FilePath $log -Append;
	}
	waitProcess -process $process -timeout $timeout;

	if (0 -eq $process.ExitCode) {
		Write-Output (('{0} Process {1} exited...') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $process.Id) | Out-File -FilePath $log -Append;
	}
	else {
		Write-Output (('{0} Process {1} terminated with code {2}...') -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $process.Id, $process.ExitCode) | Out-File -FilePath $log -Append;
	}
}
function startProcess {
	param (
		[String]$filePath,
		[String[]]$argumentList,
		[bool]$redirectStandartErrorOutput
	)

	#$process = New-Object -TypeName System.Diagnostics.Process;
	$processStartInfo = New-Object System.Diagnostics.ProcessStartInfo -Property @{
		FileName = $filePath;
		Arguments = $argumentList;
		CreateNoWindow = $true;
		RedirectStandardError = $redirectStandartErrorOutput;
		RedirectStandardOutput = $false;
		UseShellExecute = $false
	};

	return [System.Diagnostics.Process]::Start($processStartInfo);

}
function waitProcess {
	param (
		$process,
		[Int32]$timeout
	)

	if (-not $process.HasExited) {
		Wait-Process -InputObject $process -Timeout $timeout -ErrorAction SilentlyContinue;
	}

	if (-not $process.HasExited) {
		Stop-Process -InputObject $process -Force;
	}

}