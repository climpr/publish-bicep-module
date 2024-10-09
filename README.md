# Publish Bicep Module

This action publishes a versioned Bicep template to an Azure Container Registry and creates tags in GitHub accordingly.

## How to use this action

This action can be used in multiple ways.

- Single workflow per Bicep module
- Part of a dynamic, multi-module publishing strategy using the `matrix` capabilities in Github.

You can call this step as follows:
The example above will look for the following module: `./bicep-modules/module-name/main.bicep`.
It will update parent versions. If the version is `1.0.0`, it will also update `1` and `1.0`.

```yaml
- name: publish
  uses: climpr/publish-bicep-module@main
  with:
    root-path: bicep-modules
    module-name: module-name
    update-parent-versions: true
    force: false
```

### Azure prerequisites

To use this action, you need:

- An Azure Container Registry
- AcrPush permissions on the container registry for the deployment principal
- AcrPull permissions on the container registry for all the potential consumers. This includes both users and all deployment principals.

### Workflow prerequisites

When using this action in a workflow, you must implement the following:

#### Workflow permissions

The job running the action must implement the following permissions:

```yaml
permissions:
  contents: read # Required for repo checkout
```

#### Workflow steps

The job running the action has to both checkout the repository and login to Azure before calling this action.

## Parameters

`root-path`: (Required.) The directory in the repo that contains the modules. Example: `bicep-modules`.

`module-name`: (Required.) The name of the module. This should include the full relative path below the root-path, not including any leading or trailing '/'. Example: 'subnet' or 'modules/subnet'.

`update-parent-versions`: (Optional. Default: `true`) Setting this parameter to 'true' will force updates of parent major and minor versions. Example: Updating '1.0.0' will create/update '1.0' and '1' as well.

`force`: (Optional. Default: `false`) Setting this parameter to 'true' will overwrite git tags and ACR modules for all relevant version tags (see update-parent-versions).

## Module requirements

To publish a module, the module must fulfill some requirements.

Each module must be located in a directory and only one module can be located in any given directory. Nesting module directories is supported.

### File requirements

All the files listed below must be present for this action to succeed.

- `main.bicep`: The template entry point. This must be named accordingly. Using submodules is supported. A good practice for submodules is to place them in a directory called `.bicep`.

- `version.json`: This file defines the version of the template. It must adhere to the [SemVer](https://semver.org/) format. And adhere to the following schema:

```json
{
  "version": "1.0.0"
}
```

- `README.md`: This file must be present. There are no requirements as to how this is formatted and what it contains.

## Examples

### Single-module workflow

```yaml
#* .github/workflows/publish-bicep-module-test-module.yaml
name: Publish Bicep module - test-module

on:
  push:
    branches:
      - main
    paths:
      - bicep-modules/test-module/version.json

  workflow_dispatch:
    inputs:
      force:
        type: boolean
        description: "Force: Setting this parameter to 'true' will overwrite git tags and ACR modules for all relevant version tags."
        required: false
        default: false

jobs:
  publish-bicep-modules:
    name: test-module - Publish
    environment: sandbox
    runs-on: ubuntu-22.04
    permissions:
      id-token: write # Required for the OIDC Login
      contents: write # Required for repo checkout and tag updates

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Azure login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ vars.APP_ID }}
          tenant-id: ${{ vars.TENANT_ID }}
          subscription-id: ${{ vars.SUBSCRIPTION_ID }}

      - name: publish
        uses: climpr/publish-bicep-module@main
        with:
          root-path: bicep-modules
          module-name: test-module
          update-parent-versions: true
          force: ${{ github.event_name == 'workflow_dispatch' && inputs.force || false }}
```

### Multi-module workflow

The example below monitors the directory `bicep-modules` for changes to `version.json` files and triggers a job per changed file.
Each job is the responsible for each module.

It also supports calling the workflow manually in Github, then requiring a `module-name` parameter to specify which module to publish.

```yaml
#* .github/workflows/publish-bicep-modules.yaml
name: Publish Bicep modules

on:
  push:
    branches:
      - main
    paths:
      - bicep-modules/**/version.json

  workflow_dispatch:
    inputs:
      module-name:
        type: string
        description: "Module name: This should include the full relative tree below the root path. Example: 'subnet' or 'modules/subnet'."
        required: true

      force:
        type: boolean
        description: "Force: Setting this parameter to 'true' will overwrite git tags and ACR modules for all relevant version tags."
        required: false
        default: false

env:
  root-path: bicep-modules

jobs:
  get-bicep-modules:
    runs-on: ubuntu-latest
    environment: sandbox
    permissions:
      contents: read # Required for repo checkout
    outputs:
      module-names: ${{ steps.get-module-names.outputs.module-names }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 2

      - name: Get Changed Files
        id: changed-files
        uses: tj-actions/changed-files@v44
        with:
          json: true
          escape_json: false
          files: |
            ${{ env.root-path }}/**/version.json
          separator: "|"

      - name: Get changed modules
        shell: pwsh
        id: get-module-names
        env:
          changedFiles: ${{ steps.changed-files.outputs.all_changed_files }}
          rootPath: ${{ env.root-path }}
          moduleName: ${{ inputs.module-name }}
          eventName: ${{ github.event_name }}
        run: |
          $moduleNames = @()  
          if ($env:eventName -eq "workflow_dispatch") {
            $moduleNames += $env:moduleName
          }
          else {
            $changedFiles = $env:changedFiles | ConvertFrom-Json -AsHashtable

            Push-Location $env:rootPath
            foreach ($changedFile in $changedFiles) {
              $moduleRelativePath = Resolve-Path -Relative (Get-Item $changedFile).Directory.FullName
              $moduleNames += $moduleRelativePath.Trim(".").Trim("/")
            }
          }

          #* Ensure well formed json array
          $json = $moduleNames.Count -gt 0 ? ($moduleNames | ConvertTo-Json -AsArray -Compress) : "[]"

          #* Write outputs
          Write-Output "module-names=$json" >> $env:GITHUB_OUTPUT

  publish-bicep-modules:
    name: "${{ matrix.module-name }} - Publish"
    if: ${{ needs.get-bicep-modules.outputs.module-names != '' && needs.get-bicep-modules.outputs.module-names != '[]' }}
    environment: sandbox
    runs-on: ubuntu-latest
    permissions:
      id-token: write # Required for the OIDC Login
      contents: write # Required for repo checkout and tag updates
    needs:
      - get-bicep-modules
    strategy:
      matrix:
        module-name: ${{ fromJson(needs.get-bicep-modules.outputs.module-names) }}
      max-parallel: 10
      fail-fast: false

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Azure login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ vars.APP_ID }}
          tenant-id: ${{ vars.TENANT_ID }}
          subscription-id: ${{ vars.SUBSCRIPTION_ID }}

      - name: publish
        uses: climpr/publish-bicep-module@main
        with:
          root-path: ${{ env.root-path }}
          module-name: ${{ matrix.module-name }}
          update-parent-versions: true
          force: ${{ github.event_name == 'workflow_dispatch' && inputs.force || false }}
```
