Describe '<%= $PLASTER_PARAM_ModuleName %>' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../<%= $PLASTER_PARAM_ModuleName %>.psd1" -Force
    }
    It 'reports its own name' {
        (Get-<%= $PLASTER_PARAM_ModuleName %>Info).Module | Should -Be '<%= $PLASTER_PARAM_ModuleName %>'
    }
}
