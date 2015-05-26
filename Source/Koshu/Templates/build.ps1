properties {
	$product		= 'Product.Name'
	$version		= '1.0.0'
	$configuration	= 'release'
	$useVerbose		= $false

	$rootDir		= '.'
	$sourceDir		= "$rootDir\Source"
	$buildDir		= "$rootDir\Build"
	$artifactsDir	= "$buildDir\Artifacts"
	$artifactsName	= "$product-$version-$configuration" -replace "\.","_"
}

task default -depends Info, Deploy

task Info {
	Write-Host "Product:        $product" -fore Yellow
	Write-Host "Version:        $version" -fore Yellow
	Write-Host "Configuration:  $configuration" -fore Yellow
}

task Setup {

}

task Clean {
	delete_directory $artifactsDir
	create_directory $artifactsDir
}

task Compile -depends Setup, Clean {
	build_solution "$sourceDir\$product.sln"
}

task Test -depends Compile {

}

task Pack -depends Test {
	pack_solution "$sourceDir\$product.sln" $artifactsDir $artifactsName
}

task Deploy -depends Pack {

}

task ? -Description "Help" {
	Write-Documentation
}