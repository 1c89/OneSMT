# INCLUDES
. ("$($OneSMT.core)/arguments.ps1");
. ("$($OneSMT.lib)/ones/ibItem.ps1");

$OneSMT.ones = @{
	thinClientTemplate = "C:/Program Files/1cv8/{0}/bin/1cv8c.exe";
	designerTemplate = "C:/Program Files/1cv8/{0}/bin/1cv8.exe";
	backup = @{"--settings" = "$($OneSMT.cfg)/backup.default.json"}
	updateCfg = @{"--settings" = "$($OneSMT.cfg)/updateCfg.default.json"}
};

$command,$arguments = $args;
switch ($command) {
	'backup'
	{
	}
	'updateCfg'
	{
	}
	Default {
		"Unknown OneS command $command)";
		return;
	}
}

. ("$($OneSMT.lib)/ones/{0}.ps1" -f $command);

# Parse input arguments
$validArguments = . ("{0}_validArguments" -f $command);
$parameters = @{};
if (-not (parseArguments $arguments $validArguments $parameters)) {	return;	};

# Формирование параметров команды
foreach ($key in $parameters.Keys) {
	$OneSMT.ones[$command][$key] = $parameters[$key];
}

# process command
. $command $OneSMT.ones[$command];
