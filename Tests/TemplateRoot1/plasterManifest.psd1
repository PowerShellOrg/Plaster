@{
    Metadata = @{
        Name = 'New Module Project'
        Version = '0.1.0'
        Tags = @('Module', 'Project')
    }
    Parameters = @{
        Parameter1 = @{
            Name = 'ModuleName'
            Type = 'string'
            Required = $true
        }
        Parameter2 = @{
            Name = 'ModuleVersion'
            Type = 'string'
            Required = $true
        }
    }
    Content = @{
        File0 = @{
            Source = '_gitignore'
            Destination = '.gitignore'
        }
        File1 = @{
            Source = 'Moodule.psd1'
            Destination = '$($Parameters.ModuleName).psd1'
        }
        File2 = @{
            Source = 'Moodule.psm1'
            Destination = '$($Parameters.ModuleName).psm1'
        }
    }
}