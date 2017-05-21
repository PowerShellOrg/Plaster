. $PSScriptRoot\Shared.ps1

$ExpectedResults = @{
    Message = @'
<message condition="$PLASTER_PARAM_Options -contains 'Pester'" noNewLine="true">

A message to the user

and other interesting information.</message>
'@
    Modify = @'
<Modify path=".vscode\tasks.json" condition="$PLASTER_PARAM_Editor -eq 'VSCode'" encoding="UTF8"><replace condition="$PLASTER_FileContent -notmatch '// Author:'"><original>(?s)^(.*)</original><substitute expand="true">// Author: $PLASTER_PARAM_FullName`r`n`$1</substitute></replace></Modify>
'@
    TemplateFile = @'
<templateFile source="test\Shared.ps1" destination="test\Shared.ps1" condition="$PLASTER_PARAM_Options -contains 'Pester'" />
'@
    File = @'
<file source="Tests\*.tests.ps1" destination="test\" condition="$PLASTER_PARAM_Options -contains 'Pester'" />
'@
    newModuleManifest = @'
<newModuleManifest copyright="Copyright 2017 (c) - $PLASTER_PARAM_FullName" description="$PLASTER_PARAM_ModuleDesc" destination="src\${PLASTER_PARAM_ModuleName}.psd1" tags="$PLASTER_PARAM_ModuleTags" author="$PLASTER_PARAM_FullName" rootModule="${PLASTER_PARAM_ModuleName}.psm1" companyName="$PLASTER_PARAM_FullName" projectUri="$PLASTER_PARAM_ModuleWebsite" encoding="UTF8-NoBOM" moduleVersion="$PLASTER_PARAM_Version" />
'@
    requireModule = @'
<requireModule condition="$PLASTER_PARAM_Options -contains 'Pester'" name="Pester" minimumVersion="3.4.0" message="Without Pester, you will not be able to run the provided Pester test to validate your module manifest file.`nWithout version 3.4.0, VS Code will not display Pester warnings and errors in the Problems panel." />
'@
}


Describe 'Write-PlasterManifestContent Command Tests' {
    Context 'Message content' {
        It 'Generates a valid message content XML block.' {
          Write-PlasterManifestContent -ContentType 'Message' -Message "`n`nA message to the user`n`nand other interesting information." -Condition "`$PLASTER_PARAM_Options -contains `'Pester`'" -NoNewLine $true | Should BeExactly $ExpectedResults['Message']
        }
    }
    Context 'Modify content' {
        It 'Generates a valid modify content XML block.' {
          Write-PlasterManifestContent -ContentType 'Modify' -Path '.vscode\tasks.json' -Encoding 'UTF8' -Condition "`$PLASTER_PARAM_Editor -eq 'VSCode'" -ReplaceCondition "`$PLASTER_FileContent -notmatch '// Author:'" -Original '(?s)^(.*)' -Substitute "// Author: `$PLASTER_PARAM_FullName``r``n```$1" -SubstituteExpand $true | Should BeExactly $ExpectedResults['Modify']
        }
    }
    Context 'TemplateFile content' {
        It 'Generates a valid TemplateFile content XML block.' {
          Write-PlasterManifestContent -ContentType 'TemplateFile' -Source "test\Shared.ps1" -Destination "test\Shared.ps1" -Condition "`$PLASTER_PARAM_Options -contains 'Pester'" | Should BeExactly $ExpectedResults['TemplateFile']
        }
    }
    Context 'File content' {
        It 'Generates a valid File content XML block.' {
          Write-PlasterManifestContent -ContentType 'File' -Source 'Tests\*.tests.ps1' -Destination 'test\' -Condition "`$PLASTER_PARAM_Options -contains 'Pester'" | Should BeExactly $ExpectedResults['File']
        }
    }
    Context 'newModuleManifest content' {
        It 'Generates a valid newModuleManifest content XML block.' {
          Write-PlasterManifestContent -ContentType 'newModuleManifest' -Destination 'src\${PLASTER_PARAM_ModuleName}.psd1' -moduleVersion '$PLASTER_PARAM_Version' -rootModule '${PLASTER_PARAM_ModuleName}.psm1' -author '$PLASTER_PARAM_FullName' -description '$PLASTER_PARAM_ModuleDesc' -Encoding 'UTF8-NoBOM' -tags '$PLASTER_PARAM_ModuleTags' -projectUri '$PLASTER_PARAM_ModuleWebsite' -copyright 'Copyright 2017 (c) - $PLASTER_PARAM_FullName' -companyName '$PLASTER_PARAM_FullName' | Should BeExactly $ExpectedResults['newModuleManifest']
        }
    }
    Context 'requireModule content' {
        It 'Generates a valid requireModule content XML block.' {
          Write-PlasterManifestContent -ContentType 'requireModule' -Name 'Pester' -Condition "`$PLASTER_PARAM_Options -contains 'Pester'" -MinimumVersion '3.4.0' -Message 'Without Pester, you will not be able to run the provided Pester test to validate your module manifest file.`nWithout version 3.4.0, VS Code will not display Pester warnings and errors in the Problems panel.' | Should BeExactly $ExpectedResults['requireModule']
        }
    }
}
