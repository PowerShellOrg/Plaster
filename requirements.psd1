@{
  PSDepend = @{
    Version = '0.4.1'
  }
  PSDependOptions = @{
    Target = 'CurrentUser'
  }
  'Pester' = @{
    Version = '6.1.0'
    Parameters = @{
      SkipPublisherCheck = $true
    }
  }
  'psake' = @{
    Version = '5.0.0'
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
