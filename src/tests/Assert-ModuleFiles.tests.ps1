Describe "Assert-ModuleFiles" {
    BeforeAll {
        $script:mockDirectory = "$PSScriptRoot/mock-assert-module-files"
        New-Item -ItemType Directory -Path $script:mockDirectory -Force -Confirm:$false | Out-Null
    }
    
    AfterAll {
        Remove-Item -Path $script:mockDirectory -Recurse -Force -Confirm:$false -ErrorAction Ignore
    }

    Context "When all files are present" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            '' | Out-File -FilePath "$script:mockDirectory/test-module/main.bicep"
            '{"version": "1.0.0"}' | Out-File -FilePath "$script:mockDirectory/test-module/version.json"
            '' | Out-File -FilePath "$script:mockDirectory/test-module/README.md"
        }
        
        It "It should not throw an error" {
            & $PSScriptRoot/../Assert-ModuleFiles.ps1 -Path "$script:mockDirectory/test-module"
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }

    Context "When README.md is missing" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            '' | Out-File -FilePath "$script:mockDirectory/test-module/main.bicep"
            '{"version": "1.0.0"}' | Out-File -FilePath "$script:mockDirectory/test-module/version.json"
        }
        
        It "It should throw an error" {
            { & $PSScriptRoot/../Assert-ModuleFiles.ps1 -Path "$script:mockDirectory/test-module" } | Should -Throw `
                -ExceptionType ([System.IO.FileNotFoundException]) `
                -ErrorId "'README.md' does not exist. This file is required."
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }

    Context "When version.json is missing" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            '' | Out-File -FilePath "$script:mockDirectory/test-module/main.bicep"
            '' | Out-File -FilePath "$script:mockDirectory/test-module/README.md"
        }
        
        It "It should throw an error" {
            { & $PSScriptRoot/../Assert-ModuleFiles.ps1 -Path "$script:mockDirectory/test-module" } | Should -Throw `
                -ExceptionType ([System.IO.FileNotFoundException]) `
                -ErrorId "'version.json' does not exist. This file is required."
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }

    Context "When main.bicep is missing" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            '' | Out-File -FilePath "$script:mockDirectory/test-module/README.md"
            '{"version": "1.0.0"}' | Out-File -FilePath "$script:mockDirectory/test-module/version.json"
        }
        
        It "It should throw an error" {
            { & $PSScriptRoot/../Assert-ModuleFiles.ps1 -Path "$script:mockDirectory/test-module" } | Should -Throw `
                -ExceptionType ([System.IO.FileNotFoundException]) `
                -ErrorId "'main.bicep' does not exist. This file is required."
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }

    Context "When multiple files are missing" {
        BeforeAll {
            New-Item -ItemType Directory -Path "$script:mockDirectory/test-module" -Force -Confirm:$false | Out-Null
            '{"version": "1.0.0"}' | Out-File -FilePath "$script:mockDirectory/test-module/version.json"
        }
        
        It "It should throw an error" {
            { & $PSScriptRoot/../Assert-ModuleFiles.ps1 -Path "$script:mockDirectory/test-module" } | Should -Throw `
                -ExceptionType ([System.IO.FileNotFoundException]) `
                -ErrorId "'main.bicep' does not exist. This file is required."
        }
        AfterAll {
            Remove-Item -Path "$script:mockDirectory/test-module" -Recurse -Confirm:$false -Force
        }
    }
}
