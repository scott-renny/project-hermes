@{
    SchemaVersion = '1.0'
    ProfilePath   = 'configs\profiles\hermes-workstation-base.psd1'

    BackupPolicy = @{
        RootPath          = 'exports\backups'
        MaximumAgeDays    = 30
        MinimumPerModule  = 1
        ValidateDocuments = $true
    }

    Reporting = @{
        OutputDirectory = 'exports\maintenance'
        Formats         = @('Json', 'Markdown')
    }

    OperationalReferences = @{
        Repository = 'https://github.com/scott-renny/cyber-operations-center-engineering-program'
        Runbooks   = @(
            'RB-011-backup-job-failure'
            'RB-012-repository-integrity-validation'
            'RB-013-file-restore'
            'RB-014-full-system-restore'
        )
    }
}
