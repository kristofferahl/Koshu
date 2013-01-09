$here = Split-Path -Parent $MyInvocation.MyCommand.Path
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