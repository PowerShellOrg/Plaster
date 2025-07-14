@{
  PSDepend = @{
    Version = '0.3.8'
  }
  PSDependOptions = @{
    Target = 'CurrentUser'
  }
  'Pester' = @{
    Version = '5.7.1'
    Parameters = @{
      SkipPublisherCheck = $true
    }
  }
  'psake' = @{
    Version = '4.9.1'
  }
  'BuildHelpers' = @{
    Version = '2.0.16'
  }
  'PowerShellBuild' = @{
    Version = '0.7.2'
  }
  'PSScriptAnalyzer' = @{
    Version = '1.24.0'
  }
}