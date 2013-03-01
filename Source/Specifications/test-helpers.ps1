function testdir($path) {
	$guid = ([guid]::NewGuid()).ToString().Substring(0,8)
	$testDir = "$path\$guid"
	return "$testDir"
}