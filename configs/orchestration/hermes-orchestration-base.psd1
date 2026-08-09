@{
    SchemaVersion            = '1.0'
    ProfilePath              = 'configs\profiles\hermes-workstation-base.psd1'
    StateDirectory           = 'exports\orchestration'
    StopOnRequiredFailure    = $true
    ContinueOptionalFailures = $true
    ReportFormats            = @('Json', 'Markdown')
}
