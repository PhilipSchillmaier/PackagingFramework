## Synopsis
ceterion Packaging Framework 

A PowerShell module based packaging framework.

This packaging framework contains parts of the PowerShell App Deployment Toolkit (Version 3.6.9) project from
http://psappdeploytoolkit.com/ with some modifications and custom extensions.
The modification includes a conversion from a simple included script into an PowerShell module and it's 
extended with some additional functions and variables we missed in the original implementation.

## Installation

Run PackagingFrameworkSetup.exe

## Usage

First make sure you start your PowerShell session with local admin permissions.
When UAC is enabled make sure to start you PowerShell session elevated.
Also make sure your PowerShell execution policy is configured to run scripts, i.e. you can configure it with this PowerShell command:
Set-ExecutionPolicy RemoteSigned

To import the module use the following PowerShell command:
Import-Module PackagingFramework 

To Initialize the runtime variables use the following PowerShell command:
Initialize-Script

The get a list of all included command use the following PowerShell command:
Get-Command -Module PackagingFramework

To get help for the individual PowerShell commands of the module use the following PowerShell command:
Get-Help <Command>

To get a full help of all included command use the following PowerShell command: 
Get-Command -Module PackagingFramework | Get-Help

To get a help console use this PowerShell command:
Show-HelpConsole

To get a list of all runtime variables use the following PowerShell command: 
Get-Variable | Out-GridView

To create your first own package use the following PowerShell command (example): 
New-Package -Path C:\Temp -Name 'Microsoft_Office_16.0_EN_01.00'

To customize the packaging framework to your needs please have a look at the module configuiration file at: 
'%ProgramFiles%\WindowsPowerShell\Modules\PackagingFramework\PackagingFramework.json'

When you have select the "Example Package" option while installing the setup, you will find the examples at:
'%MyDocuments%\Packaging Framework Examples'


## API Reference

Depending on the size of the project, if it is small and simple enough the reference docs can be added to the README. For medium size to larger projects it is important to at least provide a link to where the API reference docs live.

## Tests

Describe and show how to run the tests with code examples.

## Contributors

Let people know how they can dive into the project, include important links to things like issue trackers, irc, twitter accounts if applicable.

## License

A short snippet describing the license (MIT, Apache, etc.)