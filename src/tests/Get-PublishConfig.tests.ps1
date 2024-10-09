Describe "Get-PublishConfig" {
    BeforeAll {
        $script:mockDirectory = "$PSScriptRoot/mock-get-publishconfig"
        New-Item -ItemType Directory -Path $script:mockDirectory -Force -Confirm:$false | Out-Null
    }
    
    AfterAll {
        Remove-Item -Path $script:mockDirectory -Recurse -Force -Confirm:$false -ErrorAction Ignore
    }

    Context "When publishconfig is in the root directory" {
        BeforeAll {
            '{"bicepRegistryFqdn": "registrynameroot.azurecr.io"}' | Out-File -FilePath "$script:mockDirectory/publishconfig.json"
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            $script:result = & $PSScriptRoot/../Get-PublishConfig.ps1 -RootPath $script:mockDirectory -ModuleName "test-module"
        }
        
        It "It should return a hashtable" {
            $result | Should -BeOfType [hashtable]
        }
        It "It should contain bicepRegistryFqdn from root directory" {
            $result.bicepRegistryFqdn | Should -Be "registrynameroot.azurecr.io"
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
            Remove-Item -Path "$script:mockDirectory/publishconfig.json" -Confirm:$false -Force
        }
    }

    Context "When publishconfig is in the module directory" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            '{"bicepRegistryFqdn": "registrynamemodule.azurecr.io"}' | Out-File -FilePath "$script:mockDirectory/test-module/publishconfig.json"
            $script:result = & $PSScriptRoot/../Get-PublishConfig.ps1 -RootPath $script:mockDirectory -ModuleName "test-module"
        }
        
        It "It should return a hashtable" {
            $result | Should -BeOfType [hashtable]
        }
        It "It should contain bicepRegistryFqdn from module directory" {
            $result.bicepRegistryFqdn | Should -Be "registrynamemodule.azurecr.io"
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }

    Context "When publishconfig is in both the root and module directory" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            '{"bicepRegistryFqdn": "registrynameroot.azurecr.io"}' | Out-File -FilePath "$script:mockDirectory/publishconfig.json"
            '{"bicepRegistryFqdn": "registrynamemodule.azurecr.io"}' | Out-File -FilePath "$script:mockDirectory/test-module/publishconfig.json"
            $script:result = & $PSScriptRoot/../Get-PublishConfig.ps1 -RootPath $script:mockDirectory -ModuleName "test-module"
        }
        
        It "It should return a hashtable" {
            $result | Should -BeOfType [hashtable]
        }
        It "It should contain bicepRegistryFqdn from module directory" {
            $result.bicepRegistryFqdn | Should -Be "registrynamemodule.azurecr.io"
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
            Remove-Item -Path "$script:mockDirectory/publishconfig.json" -Confirm:$false -Force
        }
    }

    Context "When publishconfig is not present" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
        }
        
        It "It should throw an error" {
            { & $PSScriptRoot/../Get-PublishConfig.ps1 -RootPath $script:mockDirectory -ModuleName "test-module" } | Should -Throw `
                -ExceptionType ([System.IO.FileNotFoundException]) `
                -ErrorId "Cannot find 'publishconfig.json' configuration file. This file is required."
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }
}
