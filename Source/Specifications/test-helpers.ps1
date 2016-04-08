function testdir($path) {
	$guid = ([guid]::NewGuid()).ToString().Substring(0,8)
	$testDir = "$path\$guid"
	return "$testDir"
}

function assert_path_equals($path1, $path2) {
	if ($path1 -eq $null) { throw "Path 1 is null" }
	if ($path2 -eq $null) { throw "Path 2 is null" }

	$relPath1 = (resolve-path -path "$path1" -relative).ToString()
	$relPath2 = (resolve-path -path "$path2" -relative).ToString()

	write-host "Asserting paths are equal"
	write-host "Path1: $relPath1"
	write-host "Path2: $relPath2"

	"$relPath1" | Should Be "$relPath2"
}

function nuget_configfile() {
	return (resolve-path '.\.nuget\NuGet.Config')
}
