Describe "Get-VersionsToUpdate" {
    BeforeAll {
        $script:mockDirectory = "$PSScriptRoot/mock-get-versionstoupdate"
        New-Item -ItemType Directory -Path $script:mockDirectory -Force -Confirm:$false | Out-Null
    }
    
    AfterAll {
        Remove-Item -Path $script:mockDirectory -Recurse -Force -Confirm:$false -ErrorAction Ignore
    }

    Context "When tags is not present, UpdateParentVersions is set to 'true' and Force is set to 'false'" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            '{"version": "1.0.0"}' | Out-File -FilePath "$script:mockDirectory/test-module/version.json"

            $param = @{
                RootPath             = $script:mockDirectory
                ModuleName           = "test-module"
                ExistingTags         = @()
                UpdateParentVersions = $true
                Force                = $false
            }
            $script:result = & $PSScriptRoot/../Get-VersionsToUpdate.ps1 @param
        }
        
        It "It should return an array of strings" {
            $script:result | Should -HaveCount 3
            $script:result[0] | Should -BeOfType [string]
            $script:result[1] | Should -BeOfType [string]
            $script:result[2] | Should -BeOfType [string]
        }
        It "It should contain versions '1.0.0', '1.0' and '1'" {
            $script:result | Should -Contain '1.0.0'
            $script:result | Should -Contain '1.0'
            $script:result | Should -Contain '1'
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }

    Context "When tags is present, UpdateParentVersions is set to 'true' and Force is set to 'false'" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            '{"version": "1.0.0"}' | Out-File -FilePath "$script:mockDirectory/test-module/version.json"
        }
        
        It "It should throw an error" {
            $script:param = @{
                RootPath             = $script:mockDirectory
                ModuleName           = "test-module"
                ExistingTags         = @("test-module/1.0.0")
                UpdateParentVersions = $true
                Force                = $false
            }
            
            { & $PSScriptRoot/../Get-VersionsToUpdate.ps1 @script:param} | Should -Throw `
                -ExceptionType ([System.Exception]) `
                -ErrorId "Version tag 'test-module/1.0.0' already exists. Force parameter set to 'false'. Not updating any tags or modules"
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }

    Context "When tags is present, UpdateParentVersions is set to 'true' and Force is set to 'true'" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            '{"version": "1.0.0"}' | Out-File -FilePath "$script:mockDirectory/test-module/version.json"

            $param = @{
                RootPath             = $script:mockDirectory
                ModuleName           = "test-module"
                ExistingTags         = @("test-module/1.0.0")
                UpdateParentVersions = $true
                Force                = $true
            }
            $script:warnings = "warningvariable"
            $script:result = & $PSScriptRoot/../Get-VersionsToUpdate.ps1 @param -WarningVariable script:warnings
        }
        
        It "It should return an array of strings" {
            $script:result | Should -HaveCount 3
            $script:result[0] | Should -BeOfType [string]
            $script:result[1] | Should -BeOfType [string]
            $script:result[2] | Should -BeOfType [string]
        }
        It "It should contain versions '1.0.0', '1.0' and '1'" {
            $script:result | Should -Contain '1.0.0'
            $script:result | Should -Contain '1.0'
            $script:result | Should -Contain '1'
        }
        It "It should have a warning about overwriting" {
            $script:warnings[0] | Should -Be "Version tag 'test-module/1.0.0' already exists. Force parameter set to 'true'. Overwriting tags and modules."
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }

    Context "When UpdateParentVersions is set to 'false'" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            '{"version": "1.0.0"}' | Out-File -FilePath "$script:mockDirectory/test-module/version.json"

            $param = @{
                RootPath             = $script:mockDirectory
                ModuleName           = "test-module"
                ExistingTags         = @()
                UpdateParentVersions = $false
                Force                = $false
            }
            $script:result = & $PSScriptRoot/../Get-VersionsToUpdate.ps1 @param
        }
        
        It "It should return an array of strings" {
            $script:result | Should -HaveCount 1
            $script:result[0] | Should -BeOfType [string]
        }
        It "It should contain versions '1.0.0', '1.0' and '1'" {
            $script:result | Should -Contain '1.0.0'
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }

    Context "When version.json is not present" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
        }
        
        It "It should throw an error" {
            $script:param = @{
                RootPath             = $script:mockDirectory
                ModuleName           = "test-module"
                ExistingTags         = @("test-module/1.0.0")
                UpdateParentVersions = $true
                Force                = $false
            }
            
            { & $PSScriptRoot/../Get-VersionsToUpdate.ps1 @script:param} | Should -Throw `
                -ExceptionType ([System.Management.Automation.ItemNotFoundException])
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }
}
