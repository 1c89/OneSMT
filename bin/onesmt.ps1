#!/usr/bin/pwsh
##################################################################################
# Usage:
# <path-to-PMT>\PMT.cmd <plugin> [<parameters>]
# & onesmt.ps1 OneS Configuration_ExportToCF
# & onesmt.ps1 project share http://kv-gitlab.1c89.ru/some-project-path
# Set configuration parameters
Set-StrictMode -Version Latest

Clear-Host;
(Get-Location).Path;
$item = Get-Item -Path $PSCommandPath;
if ((0 -ne $item.psobject.Properties.Match("LinkTarget").Count) -and ($null -ne $item.LinkTarget)) {
	$item = Get-Item -Path $item.LinkTarget;
}
$Root = $item.Directory.Parent.FullName;

$OneSMT = @{};
$OneSMT.root = "$Root";
$OneSMT.lib = $OneSMT.root + "/lib";
$OneSMT.core = $OneSMT.lib + "/core";
$OneSMT.cfg = $OneSMT.root + "/cfg";

# $args | format-list;
if (Test-Path -Path "$($OneSMT.lib)/$($args[0])") {
	Invoke-Expression -Command "& `"$($OneSMT.lib)/$($args[0])/main.ps1`" $($args[1..$($args.Count-1)] -join " ")";  # TODO: Добавить контроль необходимого количества аргументов
	# & "$($OneSMT.lib)/$($args[0])/main.ps1" $args.ForEach({$_});
}
else {
	# TODO: Print usage
	"Unknown $($args[0]) command";
}



if ($false) {
#     [ -s $PMT_PATH/defaults/configuration.sh ] && . $PMT_PATH/defaults/configuration.sh;
# #[ -s $PMT_CORE_CONFIGFILE ] && . $PMT_CORE_CONFIGFILE;
# [ -s $PMT_PATH/configuration.sh ] && . $PMT_PATH/configuration.sh;
# [ -s ./configuration.sh ] && . ./configuration.sh;

# [ -s $PMT_CORE_FUNCTIONS ] && . $PMT_CORE_FUNCTIONS;
# [ -s $PMT_CORE_STRINGS ] && . $PMT_CORE_STRINGS;
# [ -s $PMT_CORE_LOGGING ] && . $PMT_CORE_LOGGING;
# [ -s $PMT_CORE_PLUGINS ] && . $PMT_CORE_PLUGINS;

# pmt_core_LogMsg 4 "Start function ($(pmt_core_SubArrayToString 1 $@))";

# pmt_core_LogVar 5 PMT_PATH;
# pmt_core_LogVar 5 PMT_CORE_CONFIGFILE;
# pmt_core_LogVar 5 PMT_CORE_PATH;
# pmt_core_LogVar 5 PMT_CORE_FUNCTIONS;
# pmt_core_LogVar 5 PMT_CORE_LOGGING;
# pmt_core_LogVar 5 PMT_CORE_PLUGINS;

# pmt_core_LogMsg 4 "Plugin: $1";
# pmt_core_LogMsg 5 "Plugin params ($#): $(pmt_core_ArrayToString $@)";

# for plugin in $PMT_CORE_PLUGINS_PATH/*; do {
# 	. $plugin/${plugin##*/}.sh;
# } done;

# pmt_core_PluginExecute "$@";
# result=$?;

# pmt_core_LogVar 5 result;
# exit $result;

# #if [ -n "$STORE_SET" ]; then set > set.txt; fi;
# /

}
