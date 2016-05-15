# This is a sample of what a Plaster manifest might look like as nested hashtables.
# But there is no schema capability for hashtables.
@{
    Metadata = @{
        Name = 'New Module Project'
        Version = '0.1.0'
        Tags = @('Module', 'Project')
    }
    Parameters = @(
        @{
            Name = 'ModuleName'
            Type = 'string'
            Required = $true
        }
        @{
            Name = 'ModuleVersion'
            Type = 'string'
            Required = $true
        }
    )
    Content = @(
        @{
            Type = 'File'
            Source = '_gitignore'
            Destination = '.gitignore'
        }
        @{
            Type = 'File'
            Source = 'Moodule.psd1'
            Destination = '$($Parameters.ModuleName).psd1'
        }
        @{
            Type = 'File'
            Source = 'Moodule.psm1'
            Destination = '$($Parameters.ModuleName).psm1'
        }
    )
}