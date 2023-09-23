function ibItem() {
 
	$ibItem = [ordered]@{
	
		active = $false; # item activity switcher

		# 1cv8 binary parameters
		onesVersion = '';
		onesLocation = ''; # ones binary path or cloud http service URI
		
		# ones infobase parameters
		type = ''; # "file", "server", "cloud";
		location = ''; #Filesystem path or oneS server hostname, or web-server URI
		id = '';
		name = '';
		label = '';
		description = '';
		username = '';
		password = '';
		isModifiedCF = $false;
		hasExtension = $false;
		
		# backup parameters
		backupLocation = '';
		backupMethod = ''; # "ones" - OneS DumpIB, "dbms" - dbms full backup operation, "copy" - copy 1Cv8.1CD file
		backupToCompress = $false;
		backupCompressor = ""; # command line to compress with filename parameters. {0} - destination filename, {1} - source filename.
		backupTimeout = 60 * 120;

		# dbms database parameters
		dbms = ''; # "MSSQL", "PostgreSQL", "Oracle", "IBM"
		dbmsDBName = '';
		dbmsUsername = '';
		dbmsPassword = '';
		dbmsLocation = ''; # Filesystem path or dbms server hostname

		# logging parameters
		logType = 'file'; # "file", "syslog"
		logLevel = ''; # "DEBUG","INFO", etc
		logLocation = ''; # Log files path

	};

	return $ibItem;

}
function ibItemFromPSCustomObject() {
	param (
		$ibItem,
		$source
	)

	process { 
	
		foreach ($key in (ibItem).Keys) {
			
			$matchProperties = $source.psobject.Properties.Match($key);
			if (0 -ne $matchProperties.Count) {
				$ibItem[$key] = $matchProperties[0].Value;
			}
			
		}

		if (0 -eq $ibItem["name"].Length) {
			$ibItem["name"] = $ibItem["id"];
		} elseif (0 -eq $ibItem["id"].Length) {
			$ibItem["id"] = $ibItem["name"];
		};
		
	}

}
# Подготовка списка информационных баз
function ibItems() {
	param (
		$settings
	)
 	# Описание информационных баз
	$ibItems = @{};
	
	if (0 -eq $settings.psobject.Properties.Match('infobases').Count) {
		return $ibItems;
	}
	
	$ibItemDefault = ibItem;
	# Заполнение шаблона значениями из секции 'default' описания информационной базы
	if (0 -ne $settings.psobject.Properties.Match('default').Count) {
		ibItemFromPSCustomObject -ibItem $ibItemDefault -source $settings.default;
	}

	# Заполняем параметры информационной базы из файла настроек
	$infobases = "";
	$infobaseValue = { $null };
	if ($settings.infobases -is [System.Management.Automation.PSObject]) {
		$infobases = $settings.infobases.psobject.Properties;
		$infobaseValue = { $ibItem.name = $infobase.Name; $infobase.Value; };
	} else {
		$infobases = $settings.infobases;
		$infobaseValue = { $infobase; };
	}
	foreach ($infobase in $infobases) {

		$ibItem = ibItem;
		
		# Заполнение значениями из шаблона секции "default"
		foreach ($property in $ibItemDefault.GetEnumerator()) {
			$ibItem[$property.Key] = $property.Value;
		}
		
		# Заполнение значениями из секции описания информационной базы
		ibItemFromPSCustomObject -ibItem $ibItem -source (. $infobaseValue );

		$ibItems[$ibItem.id] = $ibItem;

	}

	return $ibItems;

}
