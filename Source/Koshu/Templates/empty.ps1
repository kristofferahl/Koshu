properties {
	$product		= 'Product.Name'
	$version		= '1.0.0'
	$rootDir		= '.'
}

task default -depends Info, Execute

task Info {
	Write-Host "Product:        $product" -fore Yellow
	Write-Host "Version:        $version" -fore Yellow
}

task Execute {

}

task ? -Description "Help" {
	Write-Documentation
}