. $PSScriptRoot\Shared.ps1

$ParamTypeMultiChoiceResult = @'
<parameter name="Options" type="multichoice" prompt="Select desired options" default="0,1,2" store="text"><choice label="&amp;Pester test support" help="Adds Tests directory and a starter Pester Tests file." value="Pester" /><choice label="P&amp;Sake build script" help="Adds a PSake build script that generates the module directory for publishing to the PSGallery." value="PSake" /><choice label="&amp;Git" help="Adds a .gitignore file." value="Git" /><choice label="&amp;None" help="No options specified." value="None" /></parameter>
'@

$ParamTypeChoiceResult = @'
<parameter name="License" type="choice" prompt="Select a license for your module" default="2" store="text"><choice label="&amp;Apache" help="Adds an Apache license file." value="Apache" /><choice label="&amp;MIT" help="Adds an MIT license file." value="MIT" /><choice label="&amp;None" help="No license specified." value="None" /></parameter>
'@

$ParamTypeTextResult = @'
<parameter name="Version" type="text" prompt="Enter the version number for the module" default="0.0.1" />
'@

$ParamTypeUserFullNameResult = @'
<parameter name="FullName" type="user-fullname" prompt="Enter your full name" store="text" />
'@

$ParamTypeUserEmailResult = @'
<parameter name="UserEmail" type="user-email" prompt="Enter your email address" store="text" />
'@

Describe 'Write-PlasterParameter Command Tests' {
    Context 'ParameterType of choice' {
        It 'Generates valid parameter XML.' {
          $Choices = @(
            @{
              label = '&Apache'
              help = 'Adds an Apache license file.'
              value = 'Apache'
            },
            @{
              label='&MIT'
              help="Adds an MIT license file."
              value="MIT"
            },
            @{
              label='&None'
              help="No license specified."
              value="None"
            }
          )
          Write-PlasterParameter -ParameterType 'choice' -ParameterName 'License' -ParameterDefault '2' -Store 'text' -ParameterPrompt 'Select a license for your module' -Choices $Choices | Should Be $ParamTypeChoiceResult
        }
    }
    Context 'ParameterType of multichoice' {
        It 'Generates valid parameter XML.' {
          $Choices = @(
            @{
              label='&Pester test support'
              help="Adds Tests directory and a starter Pester Tests file."
              value="Pester"
            },
            @{
              label='P&Sake build script'
              help="Adds a PSake build script that generates the module directory for publishing to the PSGallery."
              value="PSake"
            },
            @{
              label='&Git'
              help="Adds a .gitignore file."
              value="Git"
            },
            @{
              label='&None'
              help="No options specified."
              value="None"
            }
          )
          Write-PlasterParameter -ParameterType 'multichoice' -ParameterName 'Options' -ParameterDefault '0,1,2' -Store 'text' -ParameterPrompt 'Select desired options' -Choices $Choices | Should Be $ParamTypeMultiChoiceResult
        }
    }
    Context 'ParameterType of text' {
        It 'Generates valid parameter XML.' {
          Write-PlasterParameter -ParameterType 'text' -ParameterName 'Version' -ParameterPrompt 'Enter the version number for the module' -ParameterDefault '0.0.1' | Should BeExactly $ParamTypeTextResult
        }
    }
    Context 'ParameterType of user-fullname' {
        It 'Generates valid parameter XML.' {
          Write-PlasterParameter -ParameterType 'user-fullname' -ParameterName 'FullName' -ParameterPrompt 'Enter your full name' -Store 'text' | Should BeExactly $ParamTypeUserFullNameResult
        }
    }
    Context 'ParameterType of user-email' {
        It 'Generates valid parameter XML.' {
          Write-PlasterParameter -ParameterType 'user-email' -ParameterName 'UserEmail' -ParameterPrompt 'Enter your email address' -Store 'text' | Should BeExactly $ParamTypeUserEmailResult
        }
    }
}
