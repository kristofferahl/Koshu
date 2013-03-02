$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\test-helpers.ps1"
. "$here\..\Koshu\koshu-functions.ps1"

Describe "create_directory" {

    It "creates a directory called test1" {
		$expectedPath = "$TestDrive\Test1"
        
		create_directory $expectedPath
		
		$exists = test-path $expectedPath
        $exists.should.be($true)
    }
	
	It "creates a directory called test2" {
		$expectedPath = "$TestDrive\Test2"
        
		create_directory $expectedPath
		
		$exists = test-path $expectedPath
        $exists.should.be($true)
    }
	
	It "throws when path is null" {
		$exceptionOccured = $false
		
		try {
			create_directory $null
		} catch {
			$exceptionOccured = $true
		}
        
		$exceptionOccured.should.be($true)
    }

}

Describe "delete_directory" {

    It "deletes a directory called test1" {
		$expectedPath = "$TestDrive\Test1"
        create_directory $expectedPath
		
		delete_directory $expectedPath
        
		(test-path $expectedPath).should.be($false)
    }
	
	It "throws when path is null" {
		$exceptionOccured = $false
		
		try {
			delete_directory $null
		} catch {
			$exceptionOccured = $true
		}
        
		$exceptionOccured.should.be($true)
    }

}

Describe "delete_files" {

	Context "when 2 files exist in dirwithfiles" {
	
		$rootPath = "$TestDrive\dirwithfile"
		$file1 = "$rootPath\test1.txt"
		$file2 = "$rootPath\test2.jpg"
		
		function setup() {
			create_directory $rootPath
			new-item -type file -force $file1
			new-item -type file -force $file2
			
			$file1.should.exist()
			$file2.should.exist()
		}	

	    
		It "deletes all files in a directory called dirwithfiles" {
			setup
		
			delete_files $rootPath
			
			(test-path $file1).should.be($false)
			(test-path $file2).should.be($false)
		}
		
		It "deletes .txt files in a directory called dirwithfiles" {
			setup
		
			delete_files $rootPath "*.txt"
			
			(test-path $file1).should.be($false)
			(test-path $file2).should.be($true)
		}
		
		It "deletes .jpg files in a directory called dirwithfiles" {
			setup
		
			delete_files $rootPath "*.jpg"
			
			(test-path $file1).should.be($true)
			(test-path $file2).should.be($false)
		}
		
		It "deletes all files but .txt in a directory called dirwithfiles" {
			setup
		
			delete_files $rootPath "*.*" "*.txt"
			
			(test-path $file1).should.be($true)
			(test-path $file2).should.be($false)
		}
		
		It "deletes all files but .jpg in a directory called dirwithfiles" {
			setup
		
			delete_files $rootPath "*.*" "*.jpg"
			
			(test-path $file1).should.be($false)
			(test-path $file2).should.be($true)
		}

    }

}

Describe "find_down -file" {

	Context "when 3 matching files exists" {
	
		$rootDir = (testdir $TestDrive)
		
		$dir1 = "$rootDir\subdir\dir1"
		$dir2 = "$rootDir\subdir\dir2"
		
		$file1 = "$rootDir\nuget.exe"
		$file2 = "$dir1\nuget.exe"
		$file3 = "$dir2\nuget.exe"
		
		function setup() {
			create_directory $rootDir
			create_directory $dir1
			create_directory $dir2
			
			set-content $file1 "File1"
			set-content $file2 "File2"
			set-content $file3 "File3"
			
			$file1.should.exist()
			$file2.should.exist()
			$file3.should.exist()
		}
		
		setup
	
		It "finds file1 in root directory" {
			$file = find_down "nuget.exe" $rootDir -file
			
			$fileContent = (get-content (resolve-path $file))
			$expectedContent = (get-content (resolve-path $file1))
			
			$fileContent.should.be($expectedContent)
		}
		
		It "finds file2 in dir1 directory" {
			$file = find_down "nuget.exe" "$rootDir\subdir" -file
			
			$fileContent = (get-content (resolve-path $file))
			$expectedContent = (get-content (resolve-path $file2))
		
			$fileContent.should.be($expectedContent)
		}
		
		It "finds file3 in dir2 directory" {
			$file = find_down "nuget.exe" $dir2 -file
			
			$fileContent = (get-content (resolve-path $file))
			$expectedContent = (get-content (resolve-path $file3))
		
			$fileContent.should.be($expectedContent)
		}
		
		It "finds no files" {
			$file = find_down "abc.txt" $rootDir -file
		
			if ($file -ne $null) {
				throw "File was found"
			}
		}

	}

}

Describe "find_down -directory" {

	Context "when 3 matching directories exists" {
	
		$rootDir = (testdir $TestDrive)
		
		$dir1 = "$rootDir\nuget"
		$dir2 = "$rootDir\subdir1\nuget"
		$dir3 = "$rootDir\subdir2\nuget"
		$dir4 = "$rootDir\subdir3"
		
		function setup() {
			create_directory $rootDir
			create_directory $dir1
			create_directory $dir2
			create_directory $dir3
			create_directory $dir4
			
			$dir1.should.exist()
			$dir2.should.exist()
			$dir3.should.exist()
			$dir4.should.exist()
		}
		
		setup
	
		It "finds dir1 in root directory" {
			$dir = find_down "nuget" $rootDir -directory
			assert_path_equals $dir $dir1
		}
		
		It "finds dir2 in subdir1 directory" {
			$dir = find_down "nuget" "$rootDir\subdir1" -directory
			assert_path_equals $dir $dir2
		}
		
		It "finds dir3 in subdir2 directory" {
			$dir = find_down "nuget" "$rootDir\subdir2" -directory
			assert_path_equals $dir $dir3
		}
		
		It "finds no directories" {
			$dir = find_down "nuget" "$rootDir\subdir3" -directory
		
			if ($dir -ne $null) {
				throw "Directory was found"
			}
		}

	}

}

Describe "find_up -file" {

	Context "when 3 files exists" {
	
		$rootDir = (testdir $TestDrive)
		$dir1 = "$rootDir\dir1"
		$dir2 = "$rootDir\dir1\dir2"
		
		$file1 = "$rootDir\file1.txt"
		$file2 = "$dir1\file2.txt"
		$file3 = "$dir2\file3.txt"
		
		function setup() {
			create_directory $rootDir
			create_directory $dir1
			create_directory $dir2
			
			set-content $file1 "File1"
			set-content $file2 "File2"
			set-content $file3 "File3"
			
			$file1.should.exist()
			$file2.should.exist()
			$file3.should.exist()
		}
	
		It "finds file1 in root directory" {
			setup

			$file = find_up "file1.txt" $dir2 -file
			
			$fileContent = (get-content (resolve-path $file))
			$expectedContent = (get-content (resolve-path $file1))
			
			$fileContent.should.be($expectedContent)
		}
		
		It "finds file2 in dir1 directory" {
			setup

			$file = find_up "file2.txt" $dir2 -file
			
			$fileContent = (get-content (resolve-path $file))
			$expectedContent = (get-content (resolve-path $file2))
		
			$fileContent.should.be($expectedContent)
		}
		
		It "finds file3 in dir2 directory" {
			setup
		    
			$file = find_up "file3.txt" $dir2 -file
			
			$fileContent = (get-content (resolve-path $file))
			$expectedContent = (get-content (resolve-path $file3))
		
			$fileContent.should.be($expectedContent)
		}
		
		It "finds no files" {
			setup
		    
			$file = find_up "abc.txt" $dir2 -file
		
			if ($file -ne $null) {
				throw "File was found"
			}
		}

	}

}

Describe "find_up -directory" {

	Context "when 3 directories exists" {
	
		$rootDir = (testdir $TestDrive)
		
		$dir1 = "$rootDir\.nuget"
		$dir2 = "$rootDir\subdir\.nuget"
		$dir3 = "$rootDir\subdir\dir3\.nuget"
		$dir4 = "$rootDir\subdir\dir4"
		
		function setup() {
			create_directory $rootDir
			create_directory $dir1
			create_directory $dir2
			create_directory $dir3
			create_directory $dir4
			
			$dir1.should.exist()
			$dir2.should.exist()
			$dir3.should.exist()
			$dir4.should.exist()
		}
		
		setup
	
		It "finds dir1 in rootDir when starting in rootDir" {
			$dir = find_up ".nuget" $rootDir 0 -directory
			assert_path_equals $dir $dir1
		}
		
		It "finds dir2 in parent of dir4 when starting in dir4" {
			$dir = find_up ".nuget" $dir4 2 -directory
			assert_path_equals $dir $dir2
		}
		
		It "finds dir3 in parent of dir3 when starting in dir3" {
			$dir = find_up ".nuget" $dir3 1 -directory
			assert_path_equals $dir $dir3
		}
		
		It "finds no directories when starting in dir4" {
			$dir = find_up "nuget" $dir4 0 -directory
		
			if ($dir -ne $null) {
				throw "Directory was found"
			}
		}

	}

}

Describe "nuget_exe" {

	Context "invalid command" {
	
		$rootDir = (testdir $TestDrive)
		create_directory $rootDir
	
		It "throws" {
			$exceptionOccured = $false
			
			try {
				nuget_exe install psake -Version '4__.0.1' -OutputDirectory $rootDir
			} catch {
				$exceptionOccured = $true
			}
			
			$exceptionOccured.should.be($true)
		}

	}

	Context "install" {
	
		$rootDir = (testdir $TestDrive)
		create_directory $rootDir
	
		It "installs psake" {
			nuget_exe install psake -Version '4.2.0.1' -OutputDirectory $rootDir
			
			$exists = test-path "$rootDir\psake.4.2.0.1"
			$exists.should.be($true)
		}

	}

}