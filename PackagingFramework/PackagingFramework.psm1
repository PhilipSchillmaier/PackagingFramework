<#
.SYNOPSIS
	This modul contains the functions and logic engine for the Packaging Framework.
.DESCRIPTION
	This modul contains the functions and logic engine for the Packaging Framework.
	Please check release notes and documentation for more details.

    To import the module use the following PowerShell command:
    Import-Module PackagingFramework

    The get a list of all included command use the following PowerShell command:
    Get-Command -Module PackagingFramework

    To get help for the individual PowerShell commands of the module use the following PowerShell command:
    Get-Help <Command>

    To get a full help of all included command use the following PowerShell command:
    Get-Command -Module PackagingFramework | Get-Help
.LINK
	http://www.ceterion.com
#>

## Set Execution Policy & Error Action
Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

# Buil-in defaults to make the log file work even when Initialize-Script is not called, will be read later from config file
$Global:ConfigLogWriteToHost = $true
$Global:ConfigLogDebugMessage =$false
$Global:LogDir = "$env:WinDir\Logs\Software"

##*=============================================
##* FUNCTION LISTINGS (sorted from A - Z)
##*=============================================

#region Function Add-Font
Function Add-Font {
<#
.SYNOPSIS
	Installs fonts
.DESCRIPTION
	Installs and register a font to the Windows Font folder
.PARAMETER FilePath
	File path to the font file. i.e. "$Files\Arial.ttf"
.EXAMPLE
	Add-Font "$Files\Arial.ttf"
.NOTES
    Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True)]
		[ValidateNotNullorEmpty()]
		[string]$FilePath
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
                Write-Log "Installing [$FilePath]" -Source ${CmdletName}
                
                ##############
                
                # Define constants
                set-variable CSIDL_FONTS 0x14

                # Create hashtable containing valid font file extensions and text to append to Registry entry name.
                $hashFontFileTypes = @{}
                $hashFontFileTypes.Add(".fon", "")
                $hashFontFileTypes.Add(".fnt", "")
                $hashFontFileTypes.Add(".ttf", " (TrueType)")
                $hashFontFileTypes.Add(".ttc", " (TrueType)")
                $hashFontFileTypes.Add(".otf", " (OpenType)")

                # Initialize variables
                $invocation = (Get-Variable MyInvocation -Scope 0).Value
                #$scriptPath = Split-Path $Invocation.MyCommand.Path
                $fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

                # Load C# code
$fontCSharpCode = @'
using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.Runtime.InteropServices;

namespace FontResource
{
    public class AddRemoveFonts
    {
        private static IntPtr HWND_BROADCAST = new IntPtr(0xffff);
        private static IntPtr HWND_TOP = new IntPtr(0);
        private static IntPtr HWND_BOTTOM = new IntPtr(1);
        private static IntPtr HWND_TOPMOST = new IntPtr(-1);
        private static IntPtr HWND_NOTOPMOST = new IntPtr(-2);
        private static IntPtr HWND_MESSAGE = new IntPtr(-3);

        [DllImport("gdi32.dll")]
        static extern int AddFontResource(string lpFilename);

        [DllImport("gdi32.dll")]
        static extern int RemoveFontResource(string lpFileName);

        [DllImport("user32.dll",CharSet=CharSet.Auto)]
        private static extern int SendMessage(IntPtr hWnd, WM wMsg, IntPtr wParam, IntPtr lParam);

        [return: MarshalAs(UnmanagedType.Bool)]
        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool PostMessage(IntPtr hWnd, WM Msg, IntPtr wParam, IntPtr lParam);

        public static int AddFont(string fontFilePath) {
            FileInfo fontFile = new FileInfo(fontFilePath);
            if (!fontFile.Exists) 
            {
                return 0; 
            }
            try 
            {
                int retVal = AddFontResource(fontFilePath);

                //This version of SendMessage is a blocking call until all windows respond.
                //long result = SendMessage(HWND_BROADCAST, WM.FONTCHANGE, IntPtr.Zero, IntPtr.Zero);

                //Alternatively PostMessage instead of SendMessage to prevent application hang
                bool posted = PostMessage(HWND_BROADCAST, WM.FONTCHANGE, IntPtr.Zero, IntPtr.Zero);

                return retVal;
            }
            catch
            {
                return 0;
            }
        }

        public static int RemoveFont(string fontFileName) {
            //FileInfo fontFile = new FileInfo(fontFileName);
            //if (!fontFile.Exists) 
            //{
            //    return false; 
            //}
            try 
            {
                int retVal = RemoveFontResource(fontFileName);

                //This version of SendMessage is a blocking call until all windows respond.
                //long result = SendMessage(HWND_BROADCAST, WM.FONTCHANGE, IntPtr.Zero, IntPtr.Zero);

                //Alternatively PostMessage instead of SendMessage to prevent application hang
                bool posted = PostMessage(HWND_BROADCAST, WM.FONTCHANGE, IntPtr.Zero, IntPtr.Zero);

                return retVal;
            }
            catch
            {
                return 0;
            }
        }

        public enum WM : uint
        {
            NULL = 0x0000,
            CREATE = 0x0001,
            DESTROY = 0x0002,
            MOVE = 0x0003,
            SIZE = 0x0005,
            ACTIVATE = 0x0006,
            SETFOCUS = 0x0007,
            KILLFOCUS = 0x0008,
            ENABLE = 0x000A,
            SETREDRAW = 0x000B,
            SETTEXT = 0x000C,
            GETTEXT = 0x000D,
            GETTEXTLENGTH = 0x000E,
            PAINT = 0x000F,
            CLOSE = 0x0010,
            QUERYENDSESSION = 0x0011,
            QUERYOPEN = 0x0013,
            ENDSESSION = 0x0016,
            QUIT = 0x0012,
            ERASEBKGND = 0x0014,
            SYSCOLORCHANGE = 0x0015,
            SHOWWINDOW = 0x0018,
            WININICHANGE = 0x001A,
            SETTINGCHANGE = WM.WININICHANGE,
            DEVMODECHANGE = 0x001B,
            ACTIVATEAPP = 0x001C,
            FONTCHANGE = 0x001D,
            TIMECHANGE = 0x001E,
            CANCELMODE = 0x001F,
            SETCURSOR = 0x0020,
            MOUSEACTIVATE = 0x0021,
            CHILDACTIVATE = 0x0022,
            QUEUESYNC = 0x0023,
            GETMINMAXINFO = 0x0024,
            PAINTICON = 0x0026,
            ICONERASEBKGND = 0x0027,
            NEXTDLGCTL = 0x0028,
            SPOOLERSTATUS = 0x002A,
            DRAWITEM = 0x002B,
            MEASUREITEM = 0x002C,
            DELETEITEM = 0x002D,
            VKEYTOITEM = 0x002E,
            CHARTOITEM = 0x002F,
            SETFONT = 0x0030,
            GETFONT = 0x0031,
            SETHOTKEY = 0x0032,
            GETHOTKEY = 0x0033,
            QUERYDRAGICON = 0x0037,
            COMPAREITEM = 0x0039,
            GETOBJECT = 0x003D,
            COMPACTING = 0x0041,
            COMMNOTIFY = 0x0044,
            WINDOWPOSCHANGING = 0x0046,
            WINDOWPOSCHANGED = 0x0047,
            POWER = 0x0048,
            COPYDATA = 0x004A,
            CANCELJOURNAL = 0x004B,
            NOTIFY = 0x004E,
            INPUTLANGCHANGEREQUEST = 0x0050,
            INPUTLANGCHANGE = 0x0051,
            TCARD = 0x0052,
            HELP = 0x0053,
            USERCHANGED = 0x0054,
            NOTIFYFORMAT = 0x0055,
            CONTEXTMENU = 0x007B,
            STYLECHANGING = 0x007C,
            STYLECHANGED = 0x007D,
            DISPLAYCHANGE = 0x007E,
            GETICON = 0x007F,
            SETICON = 0x0080,
            NCCREATE = 0x0081,
            NCDESTROY = 0x0082,
            NCCALCSIZE = 0x0083,
            NCHITTEST = 0x0084,
            NCPAINT = 0x0085,
            NCACTIVATE = 0x0086,
            GETDLGCODE = 0x0087,
            SYNCPAINT = 0x0088,
            NCMOUSEMOVE = 0x00A0,
            NCLBUTTONDOWN = 0x00A1,
            NCLBUTTONUP = 0x00A2,
            NCLBUTTONDBLCLK = 0x00A3,
            NCRBUTTONDOWN = 0x00A4,
            NCRBUTTONUP = 0x00A5,
            NCRBUTTONDBLCLK = 0x00A6,
            NCMBUTTONDOWN = 0x00A7,
            NCMBUTTONUP = 0x00A8,
            NCMBUTTONDBLCLK = 0x00A9,
            NCXBUTTONDOWN = 0x00AB,
            NCXBUTTONUP = 0x00AC,
            NCXBUTTONDBLCLK = 0x00AD,
            INPUT_DEVICE_CHANGE = 0x00FE,
            INPUT = 0x00FF,
            KEYFIRST = 0x0100,
            KEYDOWN = 0x0100,
            KEYUP = 0x0101,
            CHAR = 0x0102,
            DEADCHAR = 0x0103,
            SYSKEYDOWN = 0x0104,
            SYSKEYUP = 0x0105,
            SYSCHAR = 0x0106,
            SYSDEADCHAR = 0x0107,
            UNICHAR = 0x0109,
            KEYLAST = 0x0109,
            IME_STARTCOMPOSITION = 0x010D,
            IME_ENDCOMPOSITION = 0x010E,
            IME_COMPOSITION = 0x010F,
            IME_KEYLAST = 0x010F,
            INITDIALOG = 0x0110,
            COMMAND = 0x0111,
            SYSCOMMAND = 0x0112,
            TIMER = 0x0113,
            HSCROLL = 0x0114,
            VSCROLL = 0x0115,
            INITMENU = 0x0116,
            INITMENUPOPUP = 0x0117,
            MENUSELECT = 0x011F,
            MENUCHAR = 0x0120,
            ENTERIDLE = 0x0121,
            MENURBUTTONUP = 0x0122,
            MENUDRAG = 0x0123,
            MENUGETOBJECT = 0x0124,
            UNINITMENUPOPUP = 0x0125,
            MENUCOMMAND = 0x0126,
            CHANGEUISTATE = 0x0127,
            UPDATEUISTATE = 0x0128,
            QUERYUISTATE = 0x0129,
            CTLCOLORMSGBOX = 0x0132,
            CTLCOLOREDIT = 0x0133,
            CTLCOLORLISTBOX = 0x0134,
            CTLCOLORBTN = 0x0135,
            CTLCOLORDLG = 0x0136,
            CTLCOLORSCROLLBAR = 0x0137,
            CTLCOLORSTATIC = 0x0138,
            MOUSEFIRST = 0x0200,
            MOUSEMOVE = 0x0200,
            LBUTTONDOWN = 0x0201,
            LBUTTONUP = 0x0202,
            LBUTTONDBLCLK = 0x0203,
            RBUTTONDOWN = 0x0204,
            RBUTTONUP = 0x0205,
            RBUTTONDBLCLK = 0x0206,
            MBUTTONDOWN = 0x0207,
            MBUTTONUP = 0x0208,
            MBUTTONDBLCLK = 0x0209,
            MOUSEWHEEL = 0x020A,
            XBUTTONDOWN = 0x020B,
            XBUTTONUP = 0x020C,
            XBUTTONDBLCLK = 0x020D,
            MOUSEHWHEEL = 0x020E,
            MOUSELAST = 0x020E,
            PARENTNOTIFY = 0x0210,
            ENTERMENULOOP = 0x0211,
            EXITMENULOOP = 0x0212,
            NEXTMENU = 0x0213,
            SIZING = 0x0214,
            CAPTURECHANGED = 0x0215,
            MOVING = 0x0216,
            POWERBROADCAST = 0x0218,
            DEVICECHANGE = 0x0219,
            MDICREATE = 0x0220,
            MDIDESTROY = 0x0221,
            MDIACTIVATE = 0x0222,
            MDIRESTORE = 0x0223,
            MDINEXT = 0x0224,
            MDIMAXIMIZE = 0x0225,
            MDITILE = 0x0226,
            MDICASCADE = 0x0227,
            MDIICONARRANGE = 0x0228,
            MDIGETACTIVE = 0x0229,
            MDISETMENU = 0x0230,
            ENTERSIZEMOVE = 0x0231,
            EXITSIZEMOVE = 0x0232,
            DROPFILES = 0x0233,
            MDIREFRESHMENU = 0x0234,
            IME_SETCONTEXT = 0x0281,
            IME_NOTIFY = 0x0282,
            IME_CONTROL = 0x0283,
            IME_COMPOSITIONFULL = 0x0284,
            IME_SELECT = 0x0285,
            IME_CHAR = 0x0286,
            IME_REQUEST = 0x0288,
            IME_KEYDOWN = 0x0290,
            IME_KEYUP = 0x0291,
            MOUSEHOVER = 0x02A1,
            MOUSELEAVE = 0x02A3,
            NCMOUSEHOVER = 0x02A0,
            NCMOUSELEAVE = 0x02A2,
            WTSSESSION_CHANGE = 0x02B1,
            TABLET_FIRST = 0x02c0,
            TABLET_LAST = 0x02df,
            CUT = 0x0300,
            COPY = 0x0301,
            PASTE = 0x0302,
            CLEAR = 0x0303,
            UNDO = 0x0304,
            RENDERFORMAT = 0x0305,
            RENDERALLFORMATS = 0x0306,
            DESTROYCLIPBOARD = 0x0307,
            DRAWCLIPBOARD = 0x0308,
            PAINTCLIPBOARD = 0x0309,
            VSCROLLCLIPBOARD = 0x030A,
            SIZECLIPBOARD = 0x030B,
            ASKCBFORMATNAME = 0x030C,
            CHANGECBCHAIN = 0x030D,
            HSCROLLCLIPBOARD = 0x030E,
            QUERYNEWPALETTE = 0x030F,
            PALETTEISCHANGING = 0x0310,
            PALETTECHANGED = 0x0311,
            HOTKEY = 0x0312,
            PRINT = 0x0317,
            PRINTCLIENT = 0x0318,
            APPCOMMAND = 0x0319,
            THEMECHANGED = 0x031A,
            CLIPBOARDUPDATE = 0x031D,
            DWMCOMPOSITIONCHANGED = 0x031E,
            DWMNCRENDERINGCHANGED = 0x031F,
            DWMCOLORIZATIONCOLORCHANGED = 0x0320,
            DWMWINDOWMAXIMIZEDCHANGE = 0x0321,
            GETTITLEBARINFOEX = 0x033F,
            HANDHELDFIRST = 0x0358,
            HANDHELDLAST = 0x035F,
            AFXFIRST = 0x0360,
            AFXLAST = 0x037F,
            PENWINFIRST = 0x0380,
            PENWINLAST = 0x038F,
            APP = 0x8000,
            USER = 0x0400,
            CPL_LAUNCH = USER+0x1000,
            CPL_LAUNCHED = USER+0x1001,
            SYSTIMER = 0x118
        }

    }
}
'@
                Add-Type $fontCSharpCode

                # Get "Font" shell folder
                $shell = New-Object -COM "Shell.Application"
                $folder = $shell.NameSpace($CSIDL_FONTS)
                $fontsFolderPath = $folder.Self.Path
    
                try
                {
                    [string]$filePath = (resolve-path $filePath).path
                    [string]$fileDir  = split-path $filePath
                    [string]$fileName = split-path $filePath -leaf
                    [string]$fileExt = (Get-Item $filePath).extension
                    [string]$fileBaseName = $fileName -replace($fileExt ,"")
                    $shell = new-object -com shell.application
                    $myFolder = $shell.Namespace($fileDir)
                    $fileobj = $myFolder.Items().Item($fileName)
                    $fontName = $myFolder.GetDetailsOf($fileobj,21)
                    if ($fontName -eq "") { $fontName = $fileBaseName }
                    copy-item $filePath -destination $fontsFolderPath
                    $fontFinalPath = Join-Path $fontsFolderPath $fileName
                    $retVal = [FontResource.AddRemoveFonts]::AddFont($fontFinalPath)
                    if ($retVal -eq 0) {
                        Write-Log -Message "Failed to add font [$FilePath]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				        Throw "Failed to add font [$FilePath].: $($_.Exception.Message)"
                    }
                    else
                    {
                        Write-Log "Font [$filePath] installed successfully" -Source ${CmdletName}
                        Set-ItemProperty -path "$($fontRegistryPath)" -name "$($fontName)$($hashFontFileTypes.item($fileExt))" -value "$($fileName)" -type STRING
                    }
                }
                catch
                {
                    Write-Log -Message "Failed to add font [$FilePath]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				    Throw "Failed to add font [$FilePath].: $($_.Exception.Message)"
                }

                #############
        }

		Catch {
                Write-Log -Message "Failed to add font [$FilePath]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Throw "Failed to add font [$FilePath].: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Add-Font

#region Function Add-Path
Function Add-Path {
<#
.SYNOPSIS
	Add PATH
.DESCRIPTION
	Add a folder to the PATH environment variable
.PARAMETER Folder
	Folder to add to the PATH variable (environment varibales can be used too)
.EXAMPLE
	Add-Path "C:\Temp"
.EXAMPLE
	Add-Path "%SystemDrive%\Temp"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
    [Cmdletbinding()]
    param
    ( 
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [ValidateNotNullorEmpty()]
        [String[]]$Folder
    )

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
                Write-Log "[$Folder]" -Source ${CmdletName}
                
                # Get the PATH environment variable from the coresponding registry key (unexpanded)
                $Hive = [Microsoft.Win32.Registry]::LocalMachine
                $Key = $Hive.OpenSubKey("System\CurrentControlSet\Control\Session Manager\Environment")
                $OldPath = $Key.GetValue("PATH",$False, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)

                # See if a new folder has been supplied.
                If (!$Folder) { Return 'No Folder Supplied. $ENV:PATH Unchanged'}

                # See if the new Folder is already in the path (resolved or unresolved)
                IF ($ENV:PATH | Select-String -SimpleMatch $Folder) { Write-Log "[$Folder] already within the PATH variable" -Source ${CmdletName} -Severity 2; return}
                IF ($OldPath | Select-String -SimpleMatch $Folder) { Write-Log "[$Folder] already within the PATH variable" -Source ${CmdletName} -Severity 2; return}

                # Set the New Path variable 
                $NewPath=$OldPath+';'+$Folder
                Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $NewPath

                # Show success
                Write-Log "[$Folder] successfully added to the PATH variable" -Source ${CmdletName} -Severity 1

        }

		Catch {
                Write-Log -Message "Failed to add path [$Folder]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Throw "Failed to add font [$Folder].: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Add-Path

#region Function Close-InstallationProgress
Function Close-InstallationProgress {
<#
.SYNOPSIS
	Closes the dialog created by Show-InstallationProgress.
.DESCRIPTION
	Closes the dialog created by Show-InstallationProgress.
	This function is called by the Exit-Script function to close a running instance of the progress dialog if found.
.EXAMPLE
	Close-InstallationProgress
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		If ($script:ProgressSyncHash.Window.Dispatcher.Thread.ThreadState -eq 'Running') {
			## Close the progress thread
			Write-Log -Message 'Close the installation progress dialog.' -Source ${CmdletName}
			$script:ProgressSyncHash.Window.Dispatcher.InvokeShutdown()
			$script:ProgressSyncHash.Clear()
			$script:ProgressRunspace.Close()
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Convert-Base64
Function Convert-Base64 {
<#
.SYNOPSIS
	Returns the date/time for the local culture in a universal sortable date time pattern.
.DESCRIPTION
	Converts a text string to Base64 (Encode) or vice versa (Decode)
.PARAMETER Action
	The action to perform. Options: Encode, Decode
.PARAMETER String
	Text string to be converted to Base64 or vice versa
.PARAMETER SecureParameters
	Hides all parameters passed to the Encode/Decode comand to hide them in the log file.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default: $false.
.EXAMPLE
	Convert-Base64 -Action Encode -String "This is a test string"
	Returns the encoded text string
.EXAMPLE
	Convert-Base64 -Action Decode -String "VGhpcyBpcyBhIHRlc3Qgc3RyaW5n"
	Returns the decoded text string
.EXAMPLE
	Convert-Base64 -Action Decode -String "VGhpcyBpcyBhIHRlc3Qgc3RyaW5n"
	Returns the decoded text string
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[Parameter(Mandatory = $True)]
		[ValidateSet('Encode', 'Decode')]
		[string]$Action,
		[Parameter(Mandatory=$True)]
		[ValidateNotNullorEmpty()]
		[string]$String,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$SecureParameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$ContinueOnError
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
            # Encode
            If ($Action -ieq "Encode") {
                If (-not $SecureParameters) {Write-Log "${CmdletName} Encode [$String]" -Source ${CmdletName}} else {Write-Log "${CmdletName} Encode [********]" -Source ${CmdletName}}
                $Bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
                $OutputString =[Convert]::ToBase64String($Bytes)
                If (-not $SecureParameters) {Write-Log "${CmdletName} Encoded resutl is [$OutputString]" -Source ${CmdletName}} else {Write-Log "${CmdletName} Encoded result is [********]" -Source ${CmdletName}}
            }
			# Decode
            Else { 
                If (-not $SecureParameters) {Write-Log "${CmdletName} Decode [$String]" -Source ${CmdletName}} else {Write-Log "${CmdletName} Decode [********]" -Source ${CmdletName}}
                $OutputString = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($String))
                If (-not $SecureParameters) {Write-Log "${CmdletName} Decoded resutl is [$OutputString]" -Source ${CmdletName}} else {Write-Log "${CmdletName} Decoded result is [********]" -Source ${CmdletName}}
            }
			Write-Output -InputObject $OutputString
		}
		Catch {
                Write-Log -Message "Failed to Base64 encode/decode the specified string. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
    			If (-not $ContinueOnError) {
				Throw "Failed to Base64 encode/decode the specified string.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Convert-Base64

#region Function ConvertFrom-AAPINI
Function ConvertFrom-AAPINI {
<#
.SYNOPSIS
	Converts data from ini files to an object collection that can be used for further processing with Powershell
.DESCRIPTION
	ConvertFrom-IniFiletoObjectCollection combines the powers from 
	- ConvertFrom-IniFileToHashTable
	- Convertfrom-HashTableToObjectCollection
	to return data from an ini file as a collection of PSCustomObjects
	Every Object within this collection represents one of the Sections from your ini, 
	whereas the "Name" Property represents the Section Names from your INI-File. 
	All other Properties are created from key-value Pairs inside the corresponding Section
.PARAMETER Path
	Path to an INI-File
.EXAMPLE
	$MyIniContent = ConvertFrom-IniFiletoObjectCollection -Path "C:\my.ini"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[Parameter(Mandatory=$True)]
		[ValidateNotNullorEmpty()]
		[string]$Path
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		## Initialize Object collection
		write-log -Message "Initializing Object Collection" -DebugMessage
		$AppInformationCollection = @()
		
	}
	Process {
		Try {
			## Create Hash Table from ini file
			write-log -Message "Getting Data from $path"  -Severity 1 -Source ${CmdletName} 
			$HashTable = ConvertFrom-IniFileToHashTable -Path $Path

			## create object collection from returned hashtable
			write-log -Message "Converting Data to PSObjects"  -Severity 1 -Source ${CmdletName}
			$INIObjectCollection = Convertfrom-HashTableToObjectCollection -HashTable $HashTable 
			
			## Loop through each AAP.ini App Information
			foreach ($AAPAppInformation in $INIObjectCollection) {
				
				## If AppName is set
				if ($AAPAppInformation.AppName) {
					$AppInformation = New-Object -TypeName psobject
					# add each property 
					$AppInformation | add-member -MemberType NoteProperty -Name "Name" -Value $AAPAppInformation.Name
					$AppInformation | add-member -MemberType NoteProperty -Name "AppFolder" -Value $AAPAppInformation.PNFolder
					$AppInformation | add-member -MemberType NoteProperty -Name "AppName" -Value $AAPAppInformation.AppName
					Write-Log -Message "Adding ObjectMember Name with Value $($AAPAppInformation.Name)" -Severity 1 -Source ${CmdletName}
					
					## Append newly created Object to Object Collection
					$AppInformationCollection += $AppInformation
				}
			}
		}
		Catch {
				Write-Log -Message "Unexpected error . `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
				Throw "Unexpected error.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
		return $AppInformationCollection
	}
}
#endregion ConvertFrom-AAPINI

#region Function ConvertFrom-Ini
Function ConvertFrom-Ini {
<#
.SYNOPSIS
	Converts INI content into object.
.DESCRIPTION
	Use this command to convert a INI file content into a object. Each INI section will become a property name. 
	Then each section setting will become a nested object. Blank lines and comments starting with ; will be ignored. 
.PARAMETER InputObject
	Input object with INI content (i.e. $IniContent = Get-Content C:\windows\win.ini)
.OUTPUTS
	Output object
.EXAMPLE
	$IniObject = ConvertFrom-Ini (Get-Content -Path "C:\temp\example.ini") 
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param(
	[Parameter(Position=0,Mandatory=$true)]
	[PSObject[]]$InputObject
	)
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		Write-Log -Message "Processing convert from INI" -Severity 1 -Source ${CmdletName}
		# Init vars
		$obj = New-Object -TypeName PSObject -Property @{}
		$hash = [ordered]@{}
	}
    Process {
		Try {
			# Strip out comments that start with ; and blank lines
			$InputObject = $InputObject | Where-Object {$_ -notmatch "^(\s+)?;|^\s*$"}
			foreach ($line in $InputObject) {
                Write-verbose "Processing $line"
                if ($line -match "^\[.*\]$" -AND $hash.count -gt 0) {
                    # Has a hash count and is the next setting, add the section as a property
                    write-Verbose "Creating section $section"
                    Write-verbose ([pscustomobject]$hash | Out-String)
                    $obj | Add-Member -MemberType Noteproperty -Name $Section -Value $([pscustomobject]$Hash) -ea silentlycontinue
                    # Reset hash
                    Write-Verbose "Resetting hashtable"
                    $hash=[ordered]@{}
                    # Define the next section
                    $section = $line -replace "\[|\]",""
                    Write-Verbose "Next section $section"
                }
                elseif ($line -match "^\[.*\]$") {
                    # Get section name. This will only run for the first section heading
                    $section = $line -replace "\[|\]",""
                    Write-Verbose "New section $section"
                }
                elseif ($line -match "=") {
                    # Parse data
                    $data = $line.split("=").trim()
                    $hash.add($data[0],$data[1])
                }
                else {
                    # This should probably never happen
                    Write-verbose "Unexpected line $line"
                }
			} #foreach

			# Get last section
			If ($hash.count -gt 0) {
                        Write-verbose "Creating final section $section"
                        Write-verbose ([pscustomobject]$hash | Out-String)
                    # Add the section as a property
                    $obj | Add-Member -MemberType Noteproperty -Name $Section -Value $([pscustomobject]$Hash) -ea silentlycontinue
                }
                # Write the result to the pipeline
                $obj
		}
		Catch
		{
			Write-Log -Message "Failed to convert from INI. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			Throw "Failed to convert from INI.: $($_.Exception.Message)"
		}

	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
} #end function
#endregion Function ConvertFrom-Ini

#region Function ConvertFrom-IniFileToHashTable
Function ConvertFrom-IniFileToHashTable {
<#
.SYNOPSIS
	This function converts the contents of an ini file to a nested hash table that can be used for further operations
.DESCRIPTION
	Using regular Expressions, Sections, comments and Key-Value Pairs are identifie and written to a nested hash table 
.PARAMETER Path
	Specifies the Path to an ini file
.EXAMPLE
	ConvertFrom-IniFileToHashTable -Path "C:\my.ini"
.NOTES
	Created by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[Parameter(Mandatory=$True)]
		[ValidateNotNullorEmpty()]
		[string]$Path
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			# Initialize Hash-Table 
			$ini = [ordered]@{}
			# Switch command is executed for every line in source file
			Write-Log "Getting contents from $Path" -Severity 1 -DebugMessage
			switch -regex -file $Path
			{
				"^\[(.+)\]" # Section
				{
					$section = $matches[1]
					$ini[$section] = [ordered]@{}
					$CommentCount = 0
					Write-Log -Message "Section Header found, adding $section to Hashtable" -Severity 1 -source ${cmdletName} -DebugMessage
				}
				#"^(;.*)$" # Comment
				#{
				#	$value = $matches[1]
				#	$CommentCount = $CommentCount + 1
				#	$name = "Comment" + $CommentCount
				#	if ($section) {
				#		$ini[$section][$name] = $value
				#	}
				#	else {
				#		$ini["NoSection"] = [ordered]@{}
				#		$ini["NoSection"][$name] = $value
				#	}
				#	
				#} 
				"(.+?)\s*=(.*)" # Key
				{
					$name,$value = $matches[1..2]
					$ini[$section][$name] = $value
					Write-Log -Message "Section Header found, adding Name $name and value $value to Section $section" -Severity 1 -source ${cmdletName} -DebugMessage
				}
			}
			
		}
		Catch {
				Write-Log -Message "Unexpected error . `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
				Throw "Unexpected error.: $($_.Exception.Message)"
			}
		}
		
	}
	End {
		return $ini
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function ConvertFrom-IniFileToHashTable

#region Function ConvertFrom-HashTableToObjectCollection
Function ConvertFrom-HashTableToObjectCollection {
<#
.SYNOPSIS
	This Function converts Data from a nested hash table to a collection of PSCustomObjects
.DESCRIPTION
	Nested Hash Tables are optimal for storing multi-dimensional data, works together with "ConvertFrom-IniFileToHashTable"
	to create objects from ini files
.PARAMETER Hashtable
	A nested Hash Table
.EXAMPLE
	Convertfrom-HashTableToObjectCollection -Hashtable $MyHashTable
.NOTES
	Created by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[Parameter(Mandatory=$True)]
		[ValidateNotNullorEmpty()]
		$Hashtable
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header

		## Initialize Object collection
		write-log -Message "Initializing Object Collection" -DebugMessage
		$Objects = @()
	}
	Process {
		Try {
			foreach ($i in $HashTable.keys)
			{
				$Object = New-Object -TypeName psobject
				$Object | add-member -MemberType NoteProperty -Name "Name" -Value $i
				if (!($($HashTable[$i].GetType().Name) -eq "OrderedDictionary"))
				{
					#No Sections
					Write-log -Message "$i=$($HashTable[$i]) not in a section and will be skipped" -Severity 2 -Source ${CmdletName} -DebugMessage
				} else {
					#Get Section Name
					$section = $i
		
					# loop through each key 
					Foreach ($j in ($HashTable[$i].keys))
					{
						if ($j -match "^Comment[\d]+") {
							Write-Log -Message "Comment $j Found, this will be skipped" -Severity 2 -Source ${CmdletName}
						} else {
							# add each property 
							$Object | add-member -MemberType NoteProperty -Name $j -Value $($HashTable[$i][$j])
							Write-Log -Message "Adding ObjectMember $j with Value $($HashTable[$i][$j])" -Severity 1 -Source ${CmdletName} -DebugMessage
						}
		
					}
				}
				Write-Log -Message "Adding new Object to Collection" -Severity 1 -Source ${CmdletName} -DebugMessage
				$Objects += $Object
			}
		}
		Catch {
				Write-Log -Message "Unexpected error . `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName} 
				If (-not $ContinueOnError) {
				Throw "Unexpected error.: $($_.Exception.Message)"
			}
		}
	}
	End {
		return $Objects
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}#endregion Function Convertfrom-HashTableToObjectCollection

#region Function ConvertFrom-IniFiletoObjectCollection
Function ConvertFrom-IniFiletoObjectCollection {
<#
.SYNOPSIS
	Converts data from ini files to an object collection that can be used for further processing with Powershell
.DESCRIPTION
	ConvertFrom-IniFiletoObjectCollection combines the powers from 
	- ConvertFrom-IniFileToHashTable
	- Convertfrom-HashTableToObjectCollection
	to return data from an ini file as a collection of PSCustomObjects
	Every Object within this collection represents one of the Sections from your ini, 
	whereas the "Name" Property represents the Section Names from your INI-File. 
	All other Properties are created from key-value Pairs inside the corresponding Section
.PARAMETER Path
	Path to an INI-File
.EXAMPLE
	$MyIniContent = ConvertFrom-IniFiletoObjectCollection -Path "C:\my.ini"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[Parameter(Mandatory=$True)]
		[ValidateNotNullorEmpty()]
		[string]$Path
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			## Create Hash Table from ini file
			write-log -Message "Getting Data from $path"  -Severity 1 -Source ${CmdletName}
			$HashTable = ConvertFrom-IniFileToHashTable -Path $Path

			## create object collection from returned hashtable
			write-log -Message "Converting Data to PSObjects"  -Severity 1 -Source ${CmdletName}
			$INIObjectCollection = Convertfrom-HashTableToObjectCollection -HashTable $HashTable 
		}
		Catch {
				Write-Log -Message "Unexpected error . `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
				Throw "Unexpected error.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
		return $INIObjectCollection
	}
}
#endregion ConvertFrom-IniFiletoObjectCollection

#region Function Convert-RegistryPath
Function Convert-RegistryPath {
<#
.SYNOPSIS
	Converts the specified registry key path to a format that is compatible with built-in PowerShell cmdlets.
.DESCRIPTION
	Converts the specified registry key path to a format that is compatible with built-in PowerShell cmdlets.
	Converts registry key hives to their full paths. Example: HKLM is converted to "Registry::HKEY_LOCAL_MACHINE".
.PARAMETER Key
	Path to the registry key to convert (can be a registry hive or fully qualified path)
.PARAMETER SID
	The security identifier (SID) for a user. Specifying this parameter will convert a HKEY_CURRENT_USER registry key to the HKEY_USERS\$SID format.
	Specify this parameter from the Invoke-HKCURegistrySettingsForAllUsers function to read/edit HKCU registry settings for all users on the system.
.EXAMPLE
	Convert-RegistryPath -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1AD147D0-BE0E-3D6C-AC11-64F6DC4163F1}'
.EXAMPLE
	Convert-RegistryPath -Key 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1AD147D0-BE0E-3D6C-AC11-64F6DC4163F1}'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$SID
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		## Convert the registry key hive to the full path, only match if at the beginning of the line
		If ($Key -match '^HKLM:\\|^HKCU:\\|^HKCR:\\|^HKU:\\|^HKCC:\\|^HKPD:\\') {
			#  Converts registry paths that start with, e.g.: HKLM:\
			$key = $key -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\'
			$key = $key -replace '^HKCR:\\', 'HKEY_CLASSES_ROOT\'
			$key = $key -replace '^HKCU:\\', 'HKEY_CURRENT_USER\'
			$key = $key -replace '^HKU:\\', 'HKEY_USERS\'
			$key = $key -replace '^HKCC:\\', 'HKEY_CURRENT_CONFIG\'
			$key = $key -replace '^HKPD:\\', 'HKEY_PERFORMANCE_DATA\'
		}
		ElseIf ($Key -match '^HKLM:|^HKCU:|^HKCR:|^HKU:|^HKCC:|^HKPD:') {
			#  Converts registry paths that start with, e.g.: HKLM:
			$key = $key -replace '^HKLM:', 'HKEY_LOCAL_MACHINE\'
			$key = $key -replace '^HKCR:', 'HKEY_CLASSES_ROOT\'
			$key = $key -replace '^HKCU:', 'HKEY_CURRENT_USER\'
			$key = $key -replace '^HKU:', 'HKEY_USERS\'
			$key = $key -replace '^HKCC:', 'HKEY_CURRENT_CONFIG\'
			$key = $key -replace '^HKPD:', 'HKEY_PERFORMANCE_DATA\'
		}
		ElseIf ($Key -match '^HKLM\\|^HKCU\\|^HKCR\\|^HKU\\|^HKCC\\|^HKPD\\') {
			#  Converts registry paths that start with, e.g.: HKLM\
			$key = $key -replace '^HKLM\\', 'HKEY_LOCAL_MACHINE\'
			$key = $key -replace '^HKCR\\', 'HKEY_CLASSES_ROOT\'
			$key = $key -replace '^HKCU\\', 'HKEY_CURRENT_USER\'
			$key = $key -replace '^HKU\\', 'HKEY_USERS\'
			$key = $key -replace '^HKCC\\', 'HKEY_CURRENT_CONFIG\'
			$key = $key -replace '^HKPD\\', 'HKEY_PERFORMANCE_DATA\'
		}
		
		If ($PSBoundParameters.ContainsKey('SID')) {
			## If the SID variable is specified, then convert all HKEY_CURRENT_USER key's to HKEY_USERS\$SID				
			If ($key -match '^HKEY_CURRENT_USER\\') { $key = $key -replace '^HKEY_CURRENT_USER\\', "HKEY_USERS\$SID\" }
		}
		
		## Append the PowerShell drive to the registry key path
		If ($key -notmatch '^Registry::') {[string]$key = "Registry::$key" }
		
		If($Key -match '^Registry::HKEY_LOCAL_MACHINE|^Registry::HKEY_CLASSES_ROOT|^Registry::HKEY_CURRENT_USER|^Registry::HKEY_USERS|^Registry::HKEY_CURRENT_CONFIG|^Registry::HKEY_PERFORMANCE_DATA') {
			## Check for expected key string format
			Write-Log -Message "Return fully qualified registry key path [$key]." -Source ${CmdletName}
			Write-Output -InputObject $key
		}
		Else{
			#  If key string is not properly formatted, throw an error
			Throw "Unable to detect target registry hive in string [$key]."
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function ConvertTo-Ini
Function ConvertTo-Ini {
<#
.SYNOPSIS
	Converts Object to INI
.DESCRIPTION
	Use this command to convert a object into a INI file. First level property names are the sections, nested object properties are the key and values
.PARAMETER InputObject
	Input object
.OUTPUTS
	INI content
.EXAMPLE
	ConvertTo-Ini
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param(
	[Parameter(Position=0,Mandatory=$true)]
	$InputObject
	)
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		Write-Log -Message "Processing convert to INI" -Severity 1 -Source ${CmdletName}
	}
        Process {
		Try {
			# Get sections
			[array]$Sections = (Get-Member -InputObject $InputObject -MemberType NoteProperty).Name
			# Get keys and values within sections
			ForEach ($Section in $Sections) {
				Write-verbose "[$Section]"
				$OutObject+="[$Section]`r`n"
				[array]$Keys = (Get-Member -InputObject $InputObject.$Section -MemberType NoteProperty).Name
				ForEach ($Key in $Keys) {
					$value = $InputObject.$Section.psobject.properties[$key].value
					Write-verbose "$key=$value"
					$OutObject+="$key=$value`r`n"
				}
			} 
			Return $OutObject
        }
		Catch
		{
			Write-Log -Message "Failed to convert to INI. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			Throw "Failed to convert to INI.: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
} #end function
#endregion Function ConvertTo-Ini

#region Function ConvertTo-NTAccountOrSID
Function ConvertTo-NTAccountOrSID {
<#
.SYNOPSIS
	Convert between NT Account names and their security identifiers (SIDs).
.DESCRIPTION
	Specify either the NT Account name or the SID and get the other. Can also convert well known sid types.
.PARAMETER AccountName
	The Windows NT Account name specified in <domain>\<username> format.
	Use fully qualified account names (e.g., <domain>\<username>) instead of isolated names (e.g, <username>) because they are unambiguous and provide better performance.
.PARAMETER SID
	The Windows NT Account SID.
.PARAMETER WellKnownSIDName
	Specify the Well Known SID name translate to the actual SID (e.g., LocalServiceSid).
	To get all well known SIDs available on system: [enum]::GetNames([Security.Principal.WellKnownSidType])
.PARAMETER WellKnownToNTAccount
	Convert the Well Known SID to an NTAccount name
.EXAMPLE
	ConvertTo-NTAccountOrSID -AccountName 'CONTOSO\User1'
	Converts a Windows NT Account name to the corresponding SID
.EXAMPLE
	ConvertTo-NTAccountOrSID -SID 'S-1-5-21-1220945662-2111687655-725345543-14012660'
	Converts a Windows NT Account SID to the corresponding NT Account Name
.EXAMPLE
	ConvertTo-NTAccountOrSID -WellKnownSIDName 'NetworkServiceSid'
	Converts a Well Known SID name to a SID
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
	This is an internal script function and should typically not be called directly.
	The conversion can return an empty result if the user account does not exist anymore or if translation fails.
	http://blogs.technet.com/b/askds/archive/2011/07/28/troubleshooting-sid-translation-failures-from-the-obvious-to-the-not-so-obvious.aspx
	List of Well Known SIDs: http://msdn.microsoft.com/en-us/library/system.security.principal.wellknownsidtype(v=vs.110).aspx
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,ParameterSetName='NTAccountToSID',ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$AccountName,
		[Parameter(Mandatory=$true,ParameterSetName='SIDToNTAccount',ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$SID,
		[Parameter(Mandatory=$true,ParameterSetName='WellKnownName',ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$WellKnownSIDName,
		[Parameter(Mandatory=$false,ParameterSetName='WellKnownName')]
		[ValidateNotNullOrEmpty()]
		[Switch]$WellKnownToNTAccount
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Switch ($PSCmdlet.ParameterSetName) {
				'SIDToNTAccount' {
					[string]$msg = "the SID [$SID] to an NT Account name"
					Write-Log -Message "Convert $msg." -Source ${CmdletName}
					
					$NTAccountSID = New-Object -TypeName 'System.Security.Principal.SecurityIdentifier' -ArgumentList $SID
					$NTAccount = $NTAccountSID.Translate([Security.Principal.NTAccount])
					Write-Output -InputObject $NTAccount
				}
				'NTAccountToSID' {
					[string]$msg = "the NT Account [$AccountName] to a SID"
					Write-Log -Message "Convert $msg." -Source ${CmdletName}
					
					$NTAccount = New-Object -TypeName 'System.Security.Principal.NTAccount' -ArgumentList $AccountName
					$NTAccountSID = $NTAccount.Translate([Security.Principal.SecurityIdentifier])
					Write-Output -InputObject $NTAccountSID
				}
				'WellKnownName' {
					If ($WellKnownToNTAccount) {
						[string]$ConversionType = 'NTAccount'
					}
					Else {
						[string]$ConversionType = 'SID'
					}
					[string]$msg = "the Well Known SID Name [$WellKnownSIDName] to a $ConversionType"
					Write-Log -Message "Convert $msg." -Source ${CmdletName}
					
					#  Get the SID for the root domain
					Try {
						$MachineRootDomain = (Get-WmiObject -Class 'Win32_ComputerSystem' -ErrorAction 'Stop').Domain.ToLower()
						$ADDomainObj = New-Object -TypeName 'System.DirectoryServices.DirectoryEntry' -ArgumentList "LDAP://$MachineRootDomain"
						$DomainSidInBinary = $ADDomainObj.ObjectSid
						$DomainSid = New-Object -TypeName 'System.Security.Principal.SecurityIdentifier' -ArgumentList ($DomainSidInBinary[0], 0)
					}
					Catch {
						Write-Log -Message 'Unable to get Domain SID from Active Directory. Setting Domain SID to $null.' -Severity 2 -Source ${CmdletName}
						$DomainSid = $null
					}
					
					#  Get the SID for the well known SID name
					$WellKnownSidType = [Security.Principal.WellKnownSidType]::$WellKnownSIDName
					$NTAccountSID = New-Object -TypeName 'System.Security.Principal.SecurityIdentifier' -ArgumentList ($WellKnownSidType, $DomainSid)
					
					If ($WellKnownToNTAccount) {
						$NTAccount = $NTAccountSID.Translate([Security.Principal.NTAccount])
						Write-Output -InputObject $NTAccount
					}
					Else {
						Write-Output -InputObject $NTAccountSID
					}
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to convert $msg. It may not be a valid account anymore or there is some other problem. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Copy-File
Function Copy-File {
<#
.SYNOPSIS
	Copy a file or group of files to a destination path including verbose logging
.DESCRIPTION
	Copy a file or group of files to a destination path including verbose logging
.PARAMETER Path
	Path of the file to copy.
.PARAMETER Destination
	Destination Path of the file to copy.
.PARAMETER Recurse
	Copy files in subdirectories.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Copy-File -Path "$Files\MyApp.ini" -Destination "$Windir\MyApp.ini"
.EXAMPLE
	Copy-File -Path "$Files\*" -Destination "$Temp\tempfiles" -Recurse
	Copy all of the files in a folder to a destination folder.
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Destination,
		[Parameter(Mandatory=$false)]
		[switch]$Recurse = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			If ((-not ([IO.Path]::HasExtension($Destination))) -and (-not (Test-Path -LiteralPath $Destination -PathType 'Container'))) {
				$null = New-Item -Path $Destination -Type 'Directory' -Force -ErrorAction 'Stop'
			}
			
			If ($Recurse) {
				Write-Log -Message "Copy file(s) recursively in path [$path] to destination [$destination]." -Source ${CmdletName}
				$result = Copy-Item -Path $Path -Destination $Destination -Force -Recurse -ErrorAction 'Stop' -verbose 4>&1
                Write-Log $result
			}
			Else {
				Write-Log -Message "Copy file in path [$path] to destination [$destination]." -Source ${CmdletName}
				$result = Copy-Item -Path $Path -Destination $Destination -Force -ErrorAction 'Stop' -verbose 4>&1
                Write-Log $result
			}
		}
		Catch {
			Write-Log -Message "Failed to copy file(s) in path [$path] to destination [$destination]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to copy file(s) in path [$path] to destination [$destination]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Disable-TerminalServerInstallMode
Function Disable-TerminalServerInstallMode {
<#
.SYNOPSIS
	Changes to user install mode for Remote Desktop Session Host/Citrix servers.
.DESCRIPTION
	Changes to user install mode for Remote Desktop Session Host/Citrix servers.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Enable-TerminalServerInstall
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message 'Change terminal server into user execute mode...' -Source ${CmdletName}
			$terminalServerResult = & change.exe User /Execute
			
			If ($global:LastExitCode -ne 1) { Throw $terminalServerResult }
		}
		Catch {
			Write-Log -Message "Failed to change terminal server into user execute mode. `n$(Resolve-Error) " -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to change terminal server into user execute mode: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Edit-StringInFile
Function Edit-StringInFile {
<#
.SYNOPSIS
    Search and replace of strings in files
.DESCRIPTION
    Search and replace of strings in files, supporting regular expression, multi-line, encodings, etc.
.PARAMETER Pattern
    Specifies the regular expression pattern.
.PARAMETER Replacement
    Specifies the regular expression replacement pattern.
.PARAMETER Path
    Specifies the path to one or more files. Wildcards are permitted.
.PARAMETER LiteralPath
    Specifies the path to one or more files. The value of the this
    parameter is used exactly as it is typed. No characters are interpreted
    as wildcards.
.PARAMETER CaseSensitive
    Specifies case-sensitive matching. The default is to ignore case.
.PARAMETER Multiline
    Changes the meaning of ^ and $ so they match at the beginning and end,
    respectively, of any line, and not just the beginning and end of the
    entire file. The default is that ^ and $, respectively, match the
    beginning and end of the entire file.
.PARAMETER UnixText
    Causes $ to match only linefeed (\n) characters. By default, $ matches
    carriage return+linefeed (\r\n). (Windows-based text files usually use
    \r\n as line terminators, while Unix-based text files usually use only
    \n.)
.PARAMETER Overwrite
    Overwrites a file by creating a temporary file containing all
    replacements and then replacing the original file with the temporary
    file. The default is to output but not overwrite.
.PARAMETER Force
    Allows overwriting of read-only files. Note that this parameter cannot
    override security restrictions.
.PARAMETER Encoding
    Specifies the encoding for the file when -Overwrite is used. Possible
    values are: ASCII, BigEndianUnicode, Unicode, UTF32, UTF7, or UTF8. The
    default value is ASCII.
.INPUTS
    System.IO.FileInfo.
.OUTPUTS
    System.String without the -Overwrite parameter, or nothing with the
    -Overwrite parameter.
.LINK
    about_Regular_Expressions
.LINK
    http://windowsitpro.com/scripting/replacing-strings-files-using-powershell
.EXAMPLE
    Edit-StringInFile -Pattern 'fox' -Replacement 'tiger' -LiteralPath $SystemDrive\temp\ASCII.txt -Overwrite -CaseSensitive $True
.NOTES
    Originaly from App Deployment Toolkit, adapted by ceterion AG
    Based on http://www.psappdeploytoolkit.com/forums/topic/replace-filestring-extension/
.LINK
	http://psappdeploytoolkit.com
#>

    [CmdletBinding(DefaultParameterSetName="Path",SupportsShouldProcess=$True)]
        param(
        [parameter(Mandatory=$True,Position=0)]
        [String] $Pattern,
        [parameter(Mandatory=$True,Position=1)]
        [String] [AllowEmptyString()] $Replacement,
        [parameter(Mandatory=$True,ParameterSetName="Path",Position=2,ValueFromPipeline=$True)]
        [String[]] $Path,
        [parameter(Mandatory=$True,ParameterSetName="LiteralPath",Position=2)]
        [String[]] $LiteralPath,
        [Switch] $CaseSensitive,
        [Switch] $Multiline,
        [Switch] $UnixText,
        [Switch] $Overwrite,
        [Switch] $Force,
        [String] $Encoding="ASCII"
        )
    Begin {
        # Throw an error if $Encoding is not valid.
        $Encodings = @("ASCII","BigEndianUnicode","Unicode","UTF32","UTF7","UTF8")
        If ($encodings -notcontains $Encoding) {
        Throw "Encoding must be one of the following: $Encodings"
    }

    # Extended test-path: Check the parameter set name to see if we should use -literalpath or not.
    function Test-PathEx($path) {
        switch ($PSCmdlet.ParameterSetName) {
            "Path" {
            test-path $path
        }
        "LiteralPath" {
            test-path -literalpath $path
            }
        }
    }

    # Extended get-childitem: Check the parameter set name to see if we should use -literalpath or not.
    function Get-ChildItemEx($path) {switch ($PSCmdlet.ParameterSetName) {"Path" {get-childitem $path -force} "LiteralPath" {get-childitem -literalpath $path -force}}
    }

    # Outputs the full name of a temporary file in the specified path.
    function Get-TempName($path) {
        do {$tempname = join-path $path ([IO.Path]::GetRandomFilename())}
        while (test-path $tempname)
        $tempname
    }
    
    # Use '\r$' instead of '$' unless -UnixText specified because '$' alone matches '\n', not '\r\n'. Ignore '\$' (literal '$').
    if (-not $UnixText) {
        $Pattern = $Pattern -replace '(?<!\\)\$', '\r$'
    }
    
    # Build an array of Regex options and create the Regex object.
    $opts = @()
    if (-not $CaseSensitive) { $opts += "IgnoreCase" }
    if ($MultiLine) { $opts += "Multiline" }
    if ($opts.Length -eq 0) { $opts += "None" }
    $regex = new-object Text.RegularExpressions.Regex $Pattern, $opts

    # Get the name of this function and write header
    [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
    Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header

    }
    
    process {
        # The list of items to iterate depends on the parameter set name.
        switch ($PSCmdlet.ParameterSetName) {
        "Path" { $list = $Path }
        "LiteralPath" { $list = $LiteralPath }
        }
        # Iterate the items in the list of paths. If an item does not exist, continue to the next item in the list.
        foreach ($item in $list) {
            if (-not (test-pathEx $item)) {
            Write-Log -Message "Unable to find '$item'." -Source ${CmdletName}
            continue
            }
            # Iterate each item in the path. If an item is not a file, skip all remaining items.
            foreach ($file in get-childitemEx $item) {
                if ($file -isnot [IO.FileInfo]) {
                    Write-Log -Message "'$file' is not in the file system." -Source ${CmdletName}
                    break
                }
                # Get a temporary file name in the file's directory and create it as a empty file. If set-content fails, continue to the next file. Better to fail before than after reading the file for performance reasons.
                if ($Overwrite) {
                    $tempname = get-tempname $file.DirectoryName
                    set-content $tempname $NULL -confirm:$FALSE
                    if (-not $?) { continue }
                    Write-Log -Message "Created file '$tempname'." -Source ${CmdletName}
                }
                # Read all the text from the file into a single string. We have to do it this way to be able to search across line breaks.
                try {
                    Write-Log -Message "Reading '$file'." -Source ${CmdletName}
                    $text = [IO.File]::ReadAllText($file.FullName)
                    Write-Log -Message "Finished reading '$file'." -Source ${CmdletName}
                }
                catch [Management.Automation.MethodInvocationException] {
                    Write-Log -Message "$ERROR[0]" -Source ${CmdletName}
                    continue
                }
                # If -Overwrite not specified, output the result of the Replace method and continue to the next file.
                if (-not $Overwrite) {
                    $regex.Replace($text, $Replacement)
                    continue
                }
                # Do nothing further if we're in 'what if' mode.
                if ($WHATIFPREFERENCE) { continue }
                try {
                    Write-Log -Message "Writing '$tempname'." -Source ${CmdletName}
                    [IO.File]::WriteAllText("$tempname", $regex.Replace($text,
                    $Replacement), [Text.Encoding]::$Encoding)
                    Write-Log -Message "Finished writing '$tempname'." -Source ${CmdletName}
                    Write-Log -Message "Copying '$tempname' to '$file'." -Source ${CmdletName}
                    copy-item $tempname $file -force:$Force -erroraction Continue
                    if ($?) {
                        Write-Log -Message "Finished copying '$tempname' to '$file'." -Source ${CmdletName}
                    }
                    remove-item $tempname
                    if ($?) {
                        Write-Log -Message "Removed file '$tempname'." -Source ${CmdletName}
                    }
                }
                catch [Management.Automation.MethodInvocationException] {
                    Write-Log -Message "$ERROR[0]" -Source ${CmdletName}
                }
            } # foreach $file
        } # foreach $item
    } # process
    end { }
    }

#endregion Function Edit-StringInFile

#region Function Enable-TerminalServerInstallMode
Function Enable-TerminalServerInstallMode {
<#
.SYNOPSIS
	Changes to user install mode for Remote Desktop Session Host/Citrix servers.
.DESCRIPTION
	Changes to user install mode for Remote Desktop Session Host/Citrix servers.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Enable-TerminalServerInstall
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message 'Change terminal server into user install mode...' -Source ${CmdletName}
			$terminalServerResult = & change.exe User /Install
			
			If ($global:LastExitCode -ne 1) { Throw $terminalServerResult }
		}
		Catch {
			Write-Log -Message "Failed to change terminal server into user install mode. `n$(Resolve-Error) " -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to change terminal server into user install mode: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Exit-Script
Function Exit-Script {
<#
.SYNOPSIS
	Exit the script, perform cleanup actions, and pass an exit code to the parent process.
.DESCRIPTION
	Always use when exiting the script to ensure cleanup actions are performed.
.PARAMETER ExitCode
	The exit code to be passed from the script to the parent process, e.g. SCCM
.EXAMPLE
	Exit-Script -ExitCode 0
.EXAMPLE
	Exit-Script -ExitCode 1618
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[int32]$ExitCode = 0
	)
	
	# Set InstallPhase to exit script
	Set-InstallPhase 'Exit'

    # Get package end time & duration
    if ($Global:PackageStartTime){
        [datetime]$Global:PackageEndTime = Get-Date
        [timespan]$Global:PackageDuration = New-Timespan -Start $Global:PackageStartTime -End $Global:PackageEndTime
    }

	## Get the name of this function
	[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	
	## Stop the Close Program Dialog if running
    #If ($formCloseApps) { $formCloseApps.Close }
	
	## Close the Installation Progress Dialog if running
	#Close-InstallationProgress
	
	## If Terminal Server mode was set, turn it off
	If ($IsRDHost -eq $true) { Disable-TerminalServerInstallMode }
	
	## Determine action based on exit code
	Switch ($exitCode) {
		#$ConfigInstallationUIExitCode { $installSuccess = $false }
		#$ConfigInstallationDeferExitCode { $installSuccess = $false }
		3010 { $installSuccess = $true }
		1641 { $installSuccess = $true }
		0 { $installSuccess = $true }
		Default { $installSuccess = $false }
	}
	
	
    # Run auto publishing/unpublishing (if installation was sucessfull)
	If ($installSuccess -eq $true)
    {
        # Publish
        If ($deploymentType -ieq 'Install')
        {
            Invoke-AppConfig -Action Install

            # Add branding registry key
            if ($PackageName){ Set-RegistryKey -Key "HKLM\Software\$PackagingFrameworkName\InstalledPackages\$PackageName" -Name "Installed" -Value 1 -Type DWord }
            if ($PackageName){ Set-RegistryKey -Key "HKLM\Software\$PackagingFrameworkName\InstalledPackages\$PackageName" -Name "Date" -Value $(Get-Date -Format g) -Type String }
            
        }

        # Unpublish
        If ($deploymentType -ieq 'Uninstall')
        {
            Invoke-AppConfig -Action Uninstall

            # Remove local cached Json file
            Remove-File -path "$LogDir\$PackageName.json"

            # Add branding registry key
            if ($PackageName){ Remove-RegistryKey -Key "HKLM\Software\$PackagingFrameworkName\InstalledPackages\$PackageName" -Recurse }

        }
    }



    ## Determine if balloon notification should be shown
	#If ($DeployMode -ieq 'Silent') { [boolean]$ConfigShowBalloonNotifications = $false }
	
	If ($installSuccess) {
        <#
		If (Test-Path -LiteralPath $RegKeyDeferHistory -ErrorAction 'SilentlyContinue') {
			Write-Log -Message 'Remove deferral history...' -Source ${CmdletName}
			Remove-RegistryKey -Key $RegKeyDeferHistory -Recurse
		}
		[string]$balloonText = "$DeploymentTypeName $UIBalloonTextComplete"
		#>


		## Handle reboot prompts on successful script completion
		If (($AllowRebootPassThru) -and ((($MSIRebootDetected) -or ($exitCode -eq 3010)) -or ($exitCode -eq 1641))) {
			Write-Log -Message 'A restart has been flagged as required.' -Source ${CmdletName}
            #[string]$balloonText = "$DeploymentTypeName $UIBalloonTextRestartRequired"
			If (($MSIRebootDetected) -and ($exitCode -ne 1641)) { [int32]$exitCode = 3010 }
		}
		Else {
			[int32]$exitCode = 0
		}
		
		Write-Log -Message "$installName $DeploymentTypeName completed with exit code [$exitcode]." -Source ${CmdletName}
		#If ($ConfigShowBalloonNotifications) { Show-BalloonTip -BalloonTipIcon 'Info' -BalloonTipText $balloonText }
	}
	ElseIf (-not $installSuccess) {
		Write-Log -Message "$installName $DeploymentTypeName completed with exit code [$exitcode]." -Source ${CmdletName}
		If (($exitCode -eq $ConfigInstallationUIExitCode) -or ($exitCode -eq $ConfigInstallationDeferExitCode)) {
            #[string]$balloonText = "$DeploymentTypeName $UIBalloonTextFastRetry"
			#If ($ConfigShowBalloonNotifications) { Show-BalloonTip -BalloonTipIcon 'Warning' -BalloonTipText $balloonText }
		}
		Else {
            #[string]$balloonText = "$DeploymentTypeName $UIBalloonTextError"
			#If ($ConfigShowBalloonNotifications) { Show-BalloonTip -BalloonTipIcon 'Error' -BalloonTipText $balloonText }
		}
	}
	
	[string]$LogDash = '-' * 79
	Write-Log -Message $LogDash -Source ${CmdletName}

    #If ($script:notifyIcon) { Try { $script:notifyIcon.Dispose() } Catch {} }

	## Exit the script, returning the exit code to SCCM
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $exitCode; Exit } Else { Exit $exitCode }
}
#endregion

#region Function Expand-Variable
Function Expand-Variable {
<#
.SYNOPSIS
	Expands variables
.DESCRIPTION
	Returns the input string with resolved PowerShell and Environment variables
.PARAMETER InputString
	Input text string to be processed 
.PARAMETER VarType
	The type of variables to resolve. Options: all, powershell, environment
.EXAMPLE
	Expand-Variable -InputString "This is a test string with %USERNAME% and $PShome"
	Returns the text string with resolved environment and powershell variable
.EXAMPLE
	Expand-Variable -InputString 'This is a test string with %USERNAME% and $PShome' -VarType 'environment'
	Returns the text string with the environment variable resolved, but the powershell variable stays unresolved
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[Parameter(Mandatory=$True)]
		[ValidateNotNullorEmpty()]
		[string]$InputString,
		[Parameter(Mandatory = $false)]
		[ValidateSet('all', 'powershell', 'environment')]
		[string]$VarType = "all"
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
            If ($VarType -ieq "all" -or $VarType -ieq "environment"  ) {
                $InputString = [System.Environment]::ExpandEnvironmentVariables($InputString)
            }
            If ($VarType -ieq "all" -or $VarType -ieq "powershell"  ) {
                $InputString = $ExecutionContext.InvokeCommand.ExpandString($InputString)
            }
            Write-Log "Mode: $VarType Out: $InputString" -Source ${CmdletName}	-DebugMessage $true		
            Write-Output -InputObject $InputString
		}
		Catch {
                Write-Log -Message "Failed to expand variable. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
    			If (-not $ContinueOnError) {
				Throw "Failed to expand variable.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Expand-Variable

#region Function Get-EnvironmentVariable
Function Get-EnvironmentVariable {
<#
.SYNOPSIS
	Get an environment variable
.DESCRIPTION
	Get an environment variable
.PARAMETER Name
    Name of the environment variable
.PARAMETER Target
    Target of the environment variable, possible values are Process or User or Machine
.EXAMPLE
	Get-EnvironmentVariable Temp
.EXAMPLE
	Get-EnvironmentVariable -Name 'Temp' -Target 'Machine'
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
    [Cmdletbinding()]
    param
    ( 
        [Parameter(Mandatory=$True,Position=0)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory=$false,Position=1)]
		[ValidateSet('Process','User','Machine')]
		[String]$Target = 'Process'
    )

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
                $result = [environment]::GetEnvironmentVariable("$Name","$Target")
                Write-Log "[$Name] from [$Target] = [$result]" -Source ${CmdletName}
                Return $result
        }

		Catch {
                Write-Log -Message "Failed to get [$Name]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Throw "Failed to get [$Name].: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Get-EnvironmentVariable

#region Function Get-FileVersion
Function Get-FileVersion {
<#
.SYNOPSIS
	Gets file version 
.DESCRIPTION
	Gets the version of the specified file
.PARAMETER File
	Path of the file
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Get-FileVersion -File "$ProgramFilesX86\Adobe\Reader 11.0\Reader\AcroRd32.exe"
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$File,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Get file version info for file [$file]." -Source ${CmdletName}
			
			If (Test-Path -LiteralPath $File -PathType 'Leaf') {
				$fileVersion = (Get-Command -Name $file -ErrorAction 'Stop').FileVersionInfo.FileVersion
				If ($fileVersion) {
					## Remove product information to leave only the file version
					$fileVersion = ($fileVersion -split ' ' | Select-Object -First 1)
					
					Write-Log -Message "File version is [$fileVersion]." -Source ${CmdletName}
					Write-Output -InputObject $fileVersion
				}
				Else {
					Write-Log -Message 'No file version information found.' -Source ${CmdletName}
				}
			}
			Else {
				Throw "File path [$file] does not exist."
			}
		}
		Catch {
			Write-Log -Message "Failed to get file version info. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to get file version info: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Get-FreeDiskSpace
Function Get-FreeDiskSpace {
<#
.SYNOPSIS
	Retrieves the free disk space in MB on a particular drive (defaults to system drive)
.DESCRIPTION
	Retrieves the free disk space in MB on a particular drive (defaults to system drive)
.PARAMETER Drive
	Drive to check free disk space on
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Get-FreeDiskSpace -Drive 'C:'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Drive = $Global:SystemDrive,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Retrieve free disk space for drive [$Drive]." -Source ${CmdletName}
			$disk = Get-WmiObject -Class 'Win32_LogicalDisk' -Filter "DeviceID='$Drive'" -ErrorAction 'Stop'
			[double]$freeDiskSpace = [math]::Round($disk.FreeSpace / 1MB)
			
			Write-Log -Message "Free disk space for drive [$Drive]: [$freeDiskSpace MB]." -Source ${CmdletName}
			Write-Output -InputObject $freeDiskSpace
		}
		Catch {
			Write-Log -Message "Failed to retrieve free disk space for drive [$Drive]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to retrieve free disk space for drive [$Drive]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Get-HardwarePlatform
Function Get-HardwarePlatform {
<#
.SYNOPSIS
	Retrieves information about the hardware platform (physical or virtual)
.DESCRIPTION
	Retrieves information about the hardware platform (physical or virtual)
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Get-HardwarePlatform
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message 'Retrieve hardware platform information.' -Source ${CmdletName} -DebugMessage
			$hwBios = Get-WmiObject -Class 'Win32_BIOS' -ErrorAction 'Stop' | Select-Object -Property 'Version', 'SerialNumber'
			$hwMakeModel = Get-WMIObject -Class 'Win32_ComputerSystem' -ErrorAction 'Stop' | Select-Object -Property 'Model', 'Manufacturer'
			
			If ($hwBIOS.Version -match 'VRTUAL') { $hwType = 'Virtual:Hyper-V' }
			ElseIf ($hwBIOS.Version -match 'A M I') { $hwType = 'Virtual:Virtual PC' }
			ElseIf ($hwBIOS.Version -like '*Xen*') { $hwType = 'Virtual:Xen' }
			ElseIf ($hwBIOS.SerialNumber -like '*VMware*') { $hwType = 'Virtual:VMWare' }
			ElseIf (($hwMakeModel.Manufacturer -like '*Microsoft*') -and ($hwMakeModel.Model -notlike '*Surface*')) { $hwType = 'Virtual:Hyper-V' }
			ElseIf ($hwMakeModel.Manufacturer -like '*VMWare*') { $hwType = 'Virtual:VMWare' }
			ElseIf ($hwMakeModel.Model -like '*Virtual*') { $hwType = 'Virtual' }
			Else { $hwType = 'Physical' }
			
			Write-Output -InputObject $hwType
		}
		Catch {
			Write-Log -Message "Failed to retrieve hardware platform information. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to retrieve hardware platform information: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Get-IniValue
Function Get-IniValue {
<#
.SYNOPSIS
	Parses an INI file and returns the value of the specified section and key.
.DESCRIPTION
	Parses an INI file and returns the value of the specified section and key.
.PARAMETER FilePath
	Path to the INI file.
.PARAMETER Section
	Section within the INI file.
.PARAMETER Key
	Key within the section of the INI file.
.PARAMETER SuppressLog
	Disable log file output
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Get-IniValue -FilePath "$ProgramFilesX86\IBM\Notes\notes.ini" -Section 'Notes' -Key 'KeyFileName'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$FilePath,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Section,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$SuppressLog,
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		If (!$SuppressLog){
            Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
        }
	}
	Process {
		Try {
			If (!$SuppressLog){
                Write-Log -Message "Read INI Key: [Section = $Section] [Key = $Key]." -Source ${CmdletName}
            }
			
			If (-not (Test-Path -LiteralPath $FilePath -PathType 'Leaf')) { Throw "File [$filePath] could not be found." }
			
			$IniValue = [PackagingFramework.IniFile]::GetIniValue($Section, $Key, $FilePath)
			If (!$SuppressLog){
                Write-Log -Message "INI Key Value: [Section = $Section] [Key = $Key] [Value = $IniValue]." -Source ${CmdletName}
            }
			
			Write-Output -InputObject $IniValue
		}
		Catch {
			Write-Log -Message "Failed to read INI file key value. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to read INI file key value: $($_.Exception.Message)"
			}
		}
	}
	End {
		If (!$SuppressLog){
            Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
        }
	}
}
#endregion

#region Function Get-InstalledApplication
Function Get-InstalledApplication {
<#
.SYNOPSIS
	Retrieves information about installed applications.
.DESCRIPTION
	Retrieves information about installed applications by querying the registry. You can specify an application name, a product code, or both.
	Returns information about application publisher, name & version, product code, uninstall string, install source, location, date, and application architecture.
.PARAMETER Name
	The name of the application to retrieve information for. Performs a contains match on the application display name by default.
.PARAMETER Exact
	Specifies that the named application must be matched using the exact name.
.PARAMETER WildCard
	Specifies that the named application must be matched using a wildcard search.
.PARAMETER RegEx
	Specifies that the named application must be matched using a regular expression search.
.PARAMETER ProductCode
	The product code of the application to retrieve information for.
.PARAMETER IncludeUpdatesAndHotfixes
	Include matches against updates and hotfixes in results.
.EXAMPLE
	Get-InstalledApplication -Name 'Adobe Flash'
.EXAMPLE
	Get-InstalledApplication -ProductCode '{1AD147D0-BE0E-3D6C-AC11-64F6DC4163F1}'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string[]]$Name,
		[Parameter(Mandatory=$false)]
		[Switch]$Exact = $false,
		[Parameter(Mandatory=$false)]
		[Switch]$WildCard = $false,
		[Parameter(Mandatory=$false)]
		[Switch]$RegEx = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$ProductCode,
		[Parameter(Mandatory=$false)]
		[Switch]$IncludeUpdatesAndHotfixes
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {

		If ($name) {
			Write-Log -Message "Get information for installed Application Name(s) [$($name -join ', ')]..." -Source ${CmdletName}
		}
		If ($productCode) {
			Write-Log -Message "Get information for installed Product Code [$ProductCode]..." -Source ${CmdletName}
		}
		
		## Enumerate the installed applications from the registry for applications that have the "DisplayName" property
        [string[]]$RegKeyApplications = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        [psobject[]]$regKeyApplication = @()
		ForEach ($regKey in $RegKeyApplications) {
			If (Test-Path -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath') {
				[psobject[]]$UninstallKeyApps = Get-ChildItem -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath'
				ForEach ($UninstallKeyApp in $UninstallKeyApps) {
					Try {
						[psobject]$regKeyApplicationProps = Get-ItemProperty -LiteralPath $UninstallKeyApp.PSPath -ErrorAction 'Stop'
						If ($regKeyApplicationProps.DisplayName) { [psobject[]]$regKeyApplication += $regKeyApplicationProps }
					}
					Catch{
						Write-Log -Message "Unable to enumerate properties from registry key path [$($UninstallKeyApp.PSPath)]. `n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
						Continue
					}
				}
			}
		}
		If ($ErrorUninstallKeyPath) {
			Write-Log -Message "The following error(s) took place while enumerating installed applications from the registry. `n$(Resolve-Error -ErrorRecord $ErrorUninstallKeyPath)" -Severity 2 -Source ${CmdletName}
		}
		
		## Create a custom object with the desired properties for the installed applications and sanitize property details
		[psobject[]]$installedApplication = @()
		ForEach ($regKeyApp in $regKeyApplication) {
			Try {
				[string]$appDisplayName = ''
				[string]$appDisplayVersion = ''
				[string]$appPublisher = ''
				
				## Bypass any updates or hotfixes
				If (-not $IncludeUpdatesAndHotfixes) {
					If ($regKeyApp.DisplayName -match '(?i)kb\d+') { Continue }
					If ($regKeyApp.DisplayName -match 'Cumulative Update') { Continue }
					If ($regKeyApp.DisplayName -match 'Security Update') { Continue }
					If ($regKeyApp.DisplayName -match 'Hotfix') { Continue }
				}
				
				## Remove any control characters which may interfere with logging and creating file path names from these variables
				$appDisplayName = $regKeyApp.DisplayName -replace '[^\u001F-\u007F]',''
				$appDisplayVersion = $regKeyApp.DisplayVersion -replace '[^\u001F-\u007F]',''
				$appPublisher = $regKeyApp.Publisher -replace '[^\u001F-\u007F]',''
				
				## Determine if application is a 64-bit application
				[boolean]$Is64BitApp = If (($is64Bit) -and ($regKeyApp.PSPath -notmatch '^Microsoft\.PowerShell\.Core\\Registry::HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node')) { $true } Else { $false }
				
				If ($ProductCode) {
					## Verify if there is a match with the product code passed to the script
					If ($regKeyApp.PSChildName -match [regex]::Escape($productCode)) {
						Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] matching product code [$productCode]." -Source ${CmdletName}
						$installedApplication += New-Object -TypeName 'PSObject' -Property @{
							UninstallSubkey = $regKeyApp.PSChildName
							ProductCode = If ($regKeyApp.PSChildName -match $Global:MSIProductCodeRegExPattern) { $regKeyApp.PSChildName } Else { [string]::Empty }
							DisplayName = $appDisplayName
							DisplayVersion = $appDisplayVersion
							UninstallString = $regKeyApp.UninstallString
							InstallSource = $regKeyApp.InstallSource
							InstallLocation = $regKeyApp.InstallLocation
							InstallDate = $regKeyApp.InstallDate
							Publisher = $appPublisher
							Is64BitApplication = $Is64BitApp
						}
					}
				}
				
				If ($name) {
					## Verify if there is a match with the application name(s) passed to the script
					ForEach ($application in $Name) {
						$applicationMatched = $false
						If ($exact) {
							#  Check for an exact application name match
							If ($regKeyApp.DisplayName -eq $application) {
								$applicationMatched = $true
								Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] using exact name matching for search term [$application]." -Source ${CmdletName}
							}
						}
						ElseIf ($WildCard) {
							#  Check for wildcard application name match
							If ($regKeyApp.DisplayName -like $application) {
								$applicationMatched = $true
								Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] using wildcard matching for search term [$application]." -Source ${CmdletName}
							}
						}
						ElseIf ($RegEx) {
							#  Check for a regex application name match
							If ($regKeyApp.DisplayName -match $application) {
								$applicationMatched = $true
								Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] using regex matching for search term [$application]." -Source ${CmdletName}
							}
						}
						#  Check for a contains application name match
						ElseIf ($regKeyApp.DisplayName -match [regex]::Escape($application)) {
							$applicationMatched = $true
							Write-Log -Message "Found installed application [$appDisplayName] version [$appDisplayVersion] using contains matching for search term [$application]." -Source ${CmdletName}
						}
						
						If ($applicationMatched) {
							$installedApplication += New-Object -TypeName 'PSObject' -Property @{
								UninstallSubkey = $regKeyApp.PSChildName
								ProductCode = If ($regKeyApp.PSChildName -match $Global:MSIProductCodeRegExPattern) { $regKeyApp.PSChildName } Else { [string]::Empty }
								DisplayName = $appDisplayName
								DisplayVersion = $appDisplayVersion
								UninstallString = $regKeyApp.UninstallString
								InstallSource = $regKeyApp.InstallSource
								InstallLocation = $regKeyApp.InstallLocation
								InstallDate = $regKeyApp.InstallDate
								Publisher = $appPublisher
								Is64BitApplication = $Is64BitApp
							}
						}
					}
				}
			}
			Catch {
				Write-Log -Message "Failed to resolve application details from registry for [$appDisplayName]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Continue
			}
		}
		
		Write-Output -InputObject $installedApplication
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Get-LoggedOnUser
Function Get-LoggedOnUser {
<#
.SYNOPSIS
	Get session details for all local and RDP logged on users.
.DESCRIPTION
	Get session details for all local and RDP logged on users using Win32 APIs. Get the following session details:
	 NTAccount, SID, UserName, DomainName, SessionId, SessionName, ConnectState, IsCurrentSession, IsConsoleSession, IsUserSession, IsActiveUserSession
	 IsRdpSession, IsLocalAdmin, LogonTime, IdleTime, DisconnectTime, ClientName, ClientProtocolType, ClientDirectory, ClientBuildNumber
.EXAMPLE
	Get-LoggedOnUser
.NOTES
	Description of ConnectState property:
	Value		 Description
	-----		 -----------
	Active		 A user is logged on to the session.
	ConnectQuery The session is in the process of connecting to a client.
	Connected	 A client is connected to the session.
	Disconnected The session is active, but the client has disconnected from it.
	Down		 The session is down due to an error.
	Idle		 The session is waiting for a client to connect.
	Initializing The session is initializing.
	Listening 	 The session is listening for connections.
	Reset		 The session is being reset.
	Shadowing	 This session is shadowing another session.
	
	Description of IsActiveUserSession property:
	If a console user exists, then that will be the active user session.
	If no console user exists but users are logged in, such as on terminal servers, then the first logged-in non-console user that is either 'Active' or 'Connected' is the active user.
	
	Description of IsRdpSession property:
	Gets a value indicating whether the user is associated with an RDP client session.

	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message 'Get session information for all logged on users.' -Source ${CmdletName}
			Write-Output -InputObject ([PackagingFramework.QueryUser]::GetUserSessionInfo("$env:ComputerName"))
		}
		Catch {
			Write-Log -Message "Failed to get session information for all logged on users. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Get-MsiExitCodeMessage
Function Get-MsiExitCodeMessage {
<#
.SYNOPSIS
	Get message for MSI error code
.DESCRIPTION
	Get message for MSI error code by reading it from msimsg.dll
.PARAMETER MsiErrorCode
	MSI error code
.EXAMPLE
	Get-MsiExitCodeMessage -MsiErrorCode 1618
.NOTES
    Originaly from App Deployment Toolkit, adapted by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
	http://psappdeploytoolkit.com	
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[int32]$MsiExitCode
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Get message for exit code [$MsiExitCode]." -Source ${CmdletName}
			[string]$MsiExitCodeMsg = [PackagingFramework.Msi]::GetMessageFromMsiExitCode($MsiExitCode)
			Write-Output -InputObject $MsiExitCodeMsg
		}
		Catch {
			Write-Log -Message "Failed to get message for exit code [$MsiExitCode]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Get-MsiTableProperty
Function Get-MsiTableProperty {
<#
.SYNOPSIS
	Get all of the properties from a Windows Installer database table or the Summary Information stream and return as a custom object.
.DESCRIPTION
	Use the Windows Installer object to read all of the properties from a Windows Installer database table or the Summary Information stream.
.PARAMETER Path
	The fully qualified path to an database file. Supports .msi and .msp files.
.PARAMETER TransformPath
	The fully qualified path to a list of MST file(s) which should be applied to the MSI file.
.PARAMETER Table
	The name of the the MSI table from which all of the properties must be retrieved. Default is: 'Property'.
.PARAMETER TablePropertyNameColumnNum
	Specify the table column number which contains the name of the properties. Default is: 1 for MSIs and 2 for MSPs.
.PARAMETER TablePropertyValueColumnNum
	Specify the table column number which contains the value of the properties. Default is: 2 for MSIs and 3 for MSPs.
.PARAMETER GetSummaryInformation
	Retrieves the Summary Information for the Windows Installer database.
	Summary Information property descriptions: https://msdn.microsoft.com/en-us/library/aa372049(v=vs.85).aspx
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Get-MsiTableProperty -Path 'C:\Package\Example.msi' -TransformPath 'C:\Package\Example.mst'
	Retrieve all of the properties from the default 'Property' table.
.EXAMPLE
	Get-MsiTableProperty -Path 'C:\Package\Example.msi' -TransformPath 'C:\Package\Example.mst' -Table 'Property' | Select-Object -ExpandProperty ProductCode
	Retrieve all of the properties from the 'Property' table and then pipe to Select-Object to select the ProductCode property.
.EXAMPLE
	Get-MsiTableProperty -Path 'C:\Package\Example.msi' -GetSummaryInformation
	Retrieves the Summary Information for the Windows Installer database.
.NOTES
    Originaly from App Deployment Toolkit, adapted by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding(DefaultParameterSetName='TableInfo')]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateScript({ Test-Path -LiteralPath $_ -PathType 'Leaf' })]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[ValidateScript({ Test-Path -LiteralPath $_ -PathType 'Leaf' })]
		[string[]]$TransformPath,
		[Parameter(Mandatory=$false,ParameterSetName='TableInfo')]
		[ValidateNotNullOrEmpty()]
		[string]$Table = $(If ([IO.Path]::GetExtension($Path) -eq '.msi') { 'Property' } Else { 'MsiPatchMetadata' }),
		[Parameter(Mandatory=$false,ParameterSetName='TableInfo')]
		[ValidateNotNullorEmpty()]
		[int32]$TablePropertyNameColumnNum = $(If ([IO.Path]::GetExtension($Path) -eq '.msi') { 1 } Else { 2 }),
		[Parameter(Mandatory=$false,ParameterSetName='TableInfo')]
		[ValidateNotNullorEmpty()]
		[int32]$TablePropertyValueColumnNum = $(If ([IO.Path]::GetExtension($Path) -eq '.msi') { 2 } Else { 3 }),
		[Parameter(Mandatory=$true,ParameterSetName='SummaryInfo')]
		[ValidateNotNullorEmpty()]
		[switch]$GetSummaryInformation = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			If ($PSCmdlet.ParameterSetName -eq 'TableInfo') {
				Write-Log -Message "Read data from Windows Installer database file [$Path] in table [$Table]." -Source ${CmdletName}
			}
			Else {
				Write-Log -Message "Read the Summary Information from the Windows Installer database file [$Path]." -Source ${CmdletName}
			}
			
			## Create a Windows Installer object
			[__comobject]$Installer = New-Object -ComObject 'WindowsInstaller.Installer' -ErrorAction 'Stop'
			## Determine if the database file is a patch (.msp) or not
			If ([IO.Path]::GetExtension($Path) -eq '.msp') { [boolean]$IsMspFile = $true }
			## Define properties for how the MSI database is opened
			[int32]$msiOpenDatabaseModeReadOnly = 0
			[int32]$msiSuppressApplyTransformErrors = 63
			[int32]$msiOpenDatabaseMode = $msiOpenDatabaseModeReadOnly
			[int32]$msiOpenDatabaseModePatchFile = 32
			If ($IsMspFile) { [int32]$msiOpenDatabaseMode = $msiOpenDatabaseModePatchFile }
			## Open database in read only mode
			[__comobject]$Database = Invoke-ObjectMethod -InputObject $Installer -MethodName 'OpenDatabase' -ArgumentList @($Path, $msiOpenDatabaseMode)
			## Apply a list of transform(s) to the database
			If (($TransformPath) -and (-not $IsMspFile)) {
				ForEach ($Transform in $TransformPath) {
					$null = Invoke-ObjectMethod -InputObject $Database -MethodName 'ApplyTransform' -ArgumentList @($Transform, $msiSuppressApplyTransformErrors)
				}
			}
			
			## Get either the requested windows database table information or summary information
			If ($PSCmdlet.ParameterSetName -eq 'TableInfo') {
				## Open the requested table view from the database
				[__comobject]$View = Invoke-ObjectMethod -InputObject $Database -MethodName 'OpenView' -ArgumentList @("SELECT * FROM $Table")
				$null = Invoke-ObjectMethod -InputObject $View -MethodName 'Execute'
				
				## Create an empty object to store properties in
				[psobject]$TableProperties = New-Object -TypeName 'PSObject'
				
				## Retrieve the first row from the requested table. If the first row was successfully retrieved, then save data and loop through the entire table.
				#  https://msdn.microsoft.com/en-us/library/windows/desktop/aa371136(v=vs.85).aspx
				[__comobject]$Record = Invoke-ObjectMethod -InputObject $View -MethodName 'Fetch'
				While ($Record) {
					#  Read string data from record and add property/value pair to custom object
					$TableProperties | Add-Member -MemberType 'NoteProperty' -Name (Get-ObjectProperty -InputObject $Record -PropertyName 'StringData' -ArgumentList @($TablePropertyNameColumnNum)) -Value (Get-ObjectProperty -InputObject $Record -PropertyName 'StringData' -ArgumentList @($TablePropertyValueColumnNum)) -Force
					#  Retrieve the next row in the table
					[__comobject]$Record = Invoke-ObjectMethod -InputObject $View -MethodName 'Fetch'
				}
				Write-Output -InputObject $TableProperties
			}
			Else {
				## Get the SummaryInformation from the windows installer database
				[__comobject]$SummaryInformation = Get-ObjectProperty -InputObject $Database -PropertyName 'SummaryInformation'
				[hashtable]$SummaryInfoProperty = @{}
				## Summary property descriptions: https://msdn.microsoft.com/en-us/library/aa372049(v=vs.85).aspx
				$SummaryInfoProperty.Add('CodePage', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(1)))
				$SummaryInfoProperty.Add('Title', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(2)))
				$SummaryInfoProperty.Add('Subject', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(3)))
				$SummaryInfoProperty.Add('Author', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(4)))
				$SummaryInfoProperty.Add('Keywords', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(5)))
				$SummaryInfoProperty.Add('Comments', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(6)))
				$SummaryInfoProperty.Add('Template', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(7)))
				$SummaryInfoProperty.Add('LastSavedBy', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(8)))
				$SummaryInfoProperty.Add('RevisionNumber', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(9)))
				$SummaryInfoProperty.Add('LastPrinted', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(11)))
				$SummaryInfoProperty.Add('CreateTimeDate', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(12)))
				$SummaryInfoProperty.Add('LastSaveTimeDate', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(13)))
				$SummaryInfoProperty.Add('PageCount', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(14)))
				$SummaryInfoProperty.Add('WordCount', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(15)))
				$SummaryInfoProperty.Add('CharacterCount', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(16)))
				$SummaryInfoProperty.Add('CreatingApplication', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(18)))
				$SummaryInfoProperty.Add('Security', (Get-ObjectProperty -InputObject $SummaryInformation -PropertyName 'Property' -ArgumentList @(19)))
				[psobject]$SummaryInfoProperties = New-Object -TypeName 'PSObject' -Property $SummaryInfoProperty
				Write-Output -InputObject $SummaryInfoProperties
			}
		}
		Catch {
			Write-Log -Message "Failed to get the MSI table [$Table]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to get the MSI table [$Table]: $($_.Exception.Message)"
			}
		}
		Finally {
			Try {
				If ($View) {
					$null = Invoke-ObjectMethod -InputObject $View -MethodName 'Close' -ArgumentList @()
					Try { $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($View) } Catch { }
				}
				ElseIf($SummaryInformation) {
					Try { $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($SummaryInformation) } Catch { }
				}
			}
			Catch { }
			Try { $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($DataBase) } Catch { }
			Try { $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($Installer) } Catch { }
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Get-ObjectProperty
Function Get-ObjectProperty {
<#
.SYNOPSIS
	Get a property from any object.
.DESCRIPTION
	Get a property from any object.
.PARAMETER InputObject
	Specifies an object which has properties that can be retrieved.
.PARAMETER PropertyName
	Specifies the name of a property to retrieve.
.PARAMETER ArgumentList
	Argument to pass to the property being retrieved.
.EXAMPLE
	Get-ObjectProperty -InputObject $Record -PropertyName 'StringData' -ArgumentList @(1)
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
    http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,Position=0)]
		[ValidateNotNull()]
		[object]$InputObject,
		[Parameter(Mandatory=$true,Position=1)]
		[ValidateNotNullorEmpty()]
		[string]$PropertyName,
		[Parameter(Mandatory=$false,Position=2)]
		[object[]]$ArgumentList
	)
	
	Begin { }
	Process {
		## Retrieve property
		Write-Output -InputObject $InputObject.GetType().InvokeMember($PropertyName, [Reflection.BindingFlags]::GetProperty, $null, $InputObject, $ArgumentList, $null, $null, $null)
	}
	End { }
}
#endregion

#region Function Get-Path
Function Get-Path {
<#
.SYNOPSIS
	Get the PATH environment variable (unresolved)
.DESCRIPTION
	Get the PATH environment variable (unresolved)
.EXAMPLE
	Get-Path
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
    
    $Hive = [Microsoft.Win32.Registry]::LocalMachine
    $Key = $Hive.OpenSubKey("System\CurrentControlSet\Control\Session Manager\Environment")
    Return $Key.GetValue("PATH",$False, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
}
#endregion Function Get-Path

#region Function Get-Parameter
Function Get-Parameter {
<#
.SYNOPSIS
	Returns parameter variables
.DESCRIPTION
	Returns parameter variables from JSON, SCCM or CloudShaper
.PARAMETER Parameter
	The name of the parameter value, e.g. InstallDir (mandatory)
.PARAMETER Variable
	Variable name where to store the value (optional)
.PARAMETER Source
	Source where to look for parameters, possible values are Json, SCCM, CloudShaper and All, Default is Json (optional)
.PARAMETER Section
	Section where to look for parameters, not valid for SCCM, default for Json is 'Parameters', default for CloudShaper is 'Custom' (optional)
.PARAMETER Default
	Default value to return when the parameter is not found or empty (optional)
.PARAMETER Expand
	Defines if environment or powershell variables in a parameter value should be expanded (optional)
.PARAMETER SecureParameters
	Hides the parameter value in the log file, e.g. to suppress passwords in logs
.PARAMETER NoAutoGeneratedVariable
	Disable the automatic generated variable, usefull when you whant only to pipe the return value insated of creating a new variable
.PARAMETER NoAutoDecrypt
	Disable the automatic decrypt of encrpted variables
.PARAMETER NoWriteOutput
    Disable the return of the value to StdOut
.PARAMETER ContinueOnError
    Continue On Error
.EXAMPLE
	Get-Parameter 'InstallDir'
	Tries to gets the parameter "InstallDir" from all sources and puts the result into new variable with the name and value of this parameter
.EXAMPLE
	Get-Parameter 'InstallDir' -Source SCCM -Default 'C:\Temp' -Expand
	Tries to get the parameter "InstallDir" from SCCM and expands variables and or defaults to C:\temp when the parameter is not found.
.EXAMPLE
    $Return = Get-Parameter 'TestParam' -NoAutoGeneratedVariable
    Tries to gets the parameter "InstallDir" from all sources and returns the value to the pipe, no varaiable is generated automaticaly
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[Parameter(Mandatory = $True)]
		[ValidateNotNullorEmpty()]
		[string]$Parameter,

		[Parameter(Mandatory = $False)]
		[ValidateNotNullorEmpty()]
		[string]$Variable,

		[Parameter(Mandatory=$False)]
		[ValidateSet('All','Json','SCCM','CloudShaper')]
		[string]$Source = 'All',

		[Parameter(Mandatory=$False)]
        [ValidateNotNullorEmpty()]
		[string]$Section,

		[Parameter(Mandatory=$False)]
		[string]$Default,

		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$Expand,

		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$SecureParameters,

		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$NoAutoGeneratedVariable,

		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$NoAutoDecrypt,

		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$NoWriteOutput,

		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$ContinueOnError
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {

            # Init return variable with NULL
            $Return = $null

            # Default Section (if not specified. Note: Sections are only for JSON and CloudShaper but not for SCCM)
            If([string]::IsNullOrEmpty($Section)) {
                If (($Source -ieq "Json") -or ($Source -ieq "All") ){$Section = 'Parameters'}
                If ($Source -ieq "CloudShaper") {$Section = 'Custom'}
            }

           
            # Get parameter from package JSON file
            If (($Source -ieq "All") -or ($Source -ieq "Json")) {
                If(![string]::IsNullOrEmpty($PackageConfigFile.$Section.$Parameter))
                {
                    $TempReturn = $PackageConfigFile.$Section.$Parameter
                    If(![string]::IsNullOrEmpty($TempReturn)) {  
                        $Return = $TempReturn
                        If (-not $SecureParameters) {Write-Log "${CmdletName} [$Parameter] found in JSON with value [$Return]" -Source ${CmdletName}} else {Write-Log "${CmdletName} [$Parameter] found in JSON with value: [********]" -Source ${CmdletName}}
                    }
                    else
                    {
                        Write-Log "${CmdletName} [$Parameter] NOT found in JSON" -Severity 2 -DebugMessage -Source ${CmdletName}
                    }
                }
                else
                {
                    Write-Log "${CmdletName} [$Parameter] NOT found in JSON" -Severity 2 -DebugMessage -Source ${CmdletName}
                }
            }

            # Get parameter from SCCM
            If (($Source -ieq "All") -or ($Source -ieq "SCCM")) {
                If ($SMSTSEnvironment) 
                {
                    $TempReturn = $SMSTSEnvironment.Value($Parameter)
                    If(![string]::IsNullOrEmpty($TempReturn))  {  
                        $Return = $TempReturn
                        If (-not $SecureParameters) {Write-Log "${CmdletName} [$Parameter] found in SCCM with value [$Return]" -Source ${CmdletName}} else {Write-Log "${CmdletName} [$Parameter] found in SCCM with value: [********]" -Source ${CmdletName}}
                    }
                    else
                    {
                        Write-Log "${CmdletName} [$Parameter] NOT found in SCCM" -Severity 2 -DebugMessage -Source ${CmdletName}
                    }

                }
                else
                {
                    Write-Log "${CmdletName} [$Parameter] NOT found in SCCM" -Severity 2 -DebugMessage -Source ${CmdletName}
                }


            }

            # Get parameter from CloudShaper (aka visionapp.ini Custom section)
            If (($Source -ieq "All") -or ($Source -ieq "CloudShaper")) {
            
                # Get visionapp.ini path from registry
                If ($Is64Bit){
                    if(Test-Path -Path "HKLM:\Software\WOW6432Node\visionapp")
                    {
                        $visionappIni = (Get-ItemProperty -Path HKLM:\Software\WOW6432Node\visionapp -Name visionappIniFileName -ErrorAction SilentlyContinue).visionappIniFileName
                    }
                }
                else {
                    If(Test-Path -Path "HKLM:\Software\visionapp")
                    {
                        $visionappIni = (Get-ItemProperty -Path HKLM:\Software\visionapp -Name visionappIniFileName -ErrorAction SilentlyContinue).visionappIniFileName
                    }
                }

                # Get parameter from visionapp.ini
                if ($visionappIni)
                {
                    $TempReturn = Get-IniValue -FilePath $visionappIni -Section $Section -Key $Parameter -SuppressLog
                    If(![string]::IsNullOrEmpty($TempReturn)) {  
                        $Return = $TempReturn
                        If (-not $SecureParameters) {Write-Log "${CmdletName} [$Parameter] in sectin [$Section] found in visionapp.ini with value [$Return]" -Source ${CmdletName}} else {Write-Log "${CmdletName} [$Parameter] in section [$Section] found in visionapp.ini with value [********]" -Source ${CmdletName}}                
                    }
                    else
                    {
                        Write-Log "${CmdletName} [$Parameter] NOT found in visionapp.ini" -Severity 2 -DebugMessage -Source ${CmdletName}
                    }
                }
                else
                {
                    Write-Log "${CmdletName} [$Parameter] NOT found in visionapp.ini" -Severity 2 -DebugMessage -Source ${CmdletName}
                }
            }


            # Return default value when no parameter value is found and default value is specified
            If([string]::IsNullOrEmpty($Return)) {  
                If(![string]::IsNullOrEmpty($Default)) {  
                    $Return = $Default
                    If (-not $SecureParameters) {Write-Log "${CmdletName} [$Parameter] NOT found, using default value [$Return]" -Source ${CmdletName}} else {Write-Log "${CmdletName} [$Parameter] NOT found, using default value [********]" -Source ${CmdletName}}
                }
            }
            
            # Expand variable
            If(![string]::IsNullOrEmpty($Return)) {  
                if ($Expand -eq $True){
                    $Return = Expand-Variable -InputString $Return
                }
            }

            # Auto decrypt value if encrypted (and key exists)
            If ($NoAutoDecrypt -eq $false){
                If(![string]::IsNullOrEmpty($Return)) {
                    $key = (Get-ItemProperty -ErrorAction SilentlyContinue -Path "Registry::HKEY_CURRENT_USER\Software\$PackagingFrameworkName" -name 'Key').Key
                    If ($key){
                        If ($Return -match 'ENCRYPTAES256') { $Return = Invoke-Encryption -Action Decrypt -String $Return }
                    }
                }
            }

            # Auto-generate a global variable with the value when Variable option is specified
            If ($NoAutoGeneratedVariable -eq $False)
            {
                If(![string]::IsNullOrEmpty($Return)) {  
                    # User parameter name as variable name when no variable name is specified
                    If([string]::IsNullOrEmpty($Variable)) {
                        $Variable = $Parameter
                    }
                    # Generate variable
                    If(![string]::IsNullOrEmpty($Variable)) {
                        New-Variable -Name $Variable -Value $Return -Description 'Auto genrated variable by Get-Parameter' -Scope Global -Force
                    }
                }
            }

            # In NoAutoGeneratedVariable is enabled always return value to output
            if ($NoAutoGeneratedVariable -eq $true) {$NoWriteOutput = $false} 

            # In SecureParameters is enabled always disable write output
            if ($SecureParameters -eq $true) {$NoWriteOutput = $true} 

            # Return parameter value to output
            if ($NoWriteOutput -eq $false)
            {
			    Write-Output -InputObject $Return
            }

		}
		Catch {
                Write-Log -Message "Failed to get parameter. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
    			If (-not $ContinueOnError) {
				Throw "Failed to get parameter.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Get-Parameter

#region Function Get-PEFileArchitecture
Function Get-PEFileArchitecture {
<#
.SYNOPSIS
	Determine if a PE file is a 32-bit or a 64-bit file.
.DESCRIPTION
	Determine if a PE file is a 32-bit or a 64-bit file by examining the file's image file header.
	PE file extensions: .exe, .dll, .ocx, .drv, .sys, .scr, .efi, .cpl, .fon
.PARAMETER FilePath
	Path to the PE file to examine.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.PARAMETER PassThru
	Get the file object, attach a property indicating the file binary type, and write to pipeline
.EXAMPLE
	Get-PEFileArchitecture -FilePath "$env:windir\notepad.exe"
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[ValidateScript({ Test-Path -LiteralPath $_ -PathType 'Leaf' })]
		[IO.FileInfo[]]$FilePath,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true,
		[Parameter(Mandatory=$false)]
		[Switch]$PassThru
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		[string[]]$PEFileExtensions = '.exe', '.dll', '.ocx', '.drv', '.sys', '.scr', '.efi', '.cpl', '.fon'
		[int32]$MACHINE_OFFSET = 4
		[int32]$PE_POINTER_OFFSET = 60
	}
	Process {
		ForEach ($Path in $filePath) {
			Try {
				If ($PEFileExtensions -notcontains $Path.Extension) {
					Throw "Invalid file type. Please specify one of the following PE file types: $($PEFileExtensions -join ', ')"
				}
				
				[byte[]]$data = New-Object -TypeName 'System.Byte[]' -ArgumentList 4096
				$stream = New-Object -TypeName 'System.IO.FileStream' -ArgumentList ($Path.FullName, 'Open', 'Read')
				$null = $stream.Read($data, 0, 4096)
				$stream.Flush()
				$stream.Close()
				
				[int32]$PE_HEADER_ADDR = [BitConverter]::ToInt32($data, $PE_POINTER_OFFSET)
				[uint16]$PE_IMAGE_FILE_HEADER = [BitConverter]::ToUInt16($data, $PE_HEADER_ADDR + $MACHINE_OFFSET)
				Switch ($PE_IMAGE_FILE_HEADER) {
					0 { $PEArchitecture = 'Native' } # The contents of this file are assumed to be applicable to any machine type
					0x014c { $PEArchitecture = '32BIT' } # File for Windows 32-bit systems
					0x0200 { $PEArchitecture = 'Itanium-x64' } # File for Intel Itanium x64 processor family
					0x8664 { $PEArchitecture = '64BIT' } # File for Windows 64-bit systems
					Default { $PEArchitecture = 'Unknown' }
				}
				Write-Log -Message "File [$($Path.FullName)] has a detected file architecture of [$PEArchitecture]." -Source ${CmdletName}
				
				If ($PassThru) {
					#  Get the file object, attach a property indicating the type, and write to pipeline
					Get-Item -LiteralPath $Path.FullName -Force | Add-Member -MemberType 'NoteProperty' -Name 'BinaryType' -Value $PEArchitecture -Force -PassThru | Write-Output
				}
				Else {
					Write-Output -InputObject $PEArchitecture
				}
			}
			Catch {
				Write-Log -Message "Failed to get the PE file architecture. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to get the PE file architecture: $($_.Exception.Message)"
				}
				Continue
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Get-PendingReboot
Function Get-PendingReboot {
<#
.SYNOPSIS
	Get the pending reboot status on a local computer.
.DESCRIPTION
	Check WMI and the registry to determine if the system has a pending reboot operation from any of the following:
	a) Component Based Servicing (Vista, Windows 2008)
	b) Windows Update / Auto Update (XP, Windows 2003 / 2008)
	c) SCCM 2012 Clients (DetermineIfRebootPending WMI method)
	d) Pending File Rename Operations (XP, Windows 2003 / 2008)
.EXAMPLE
	Get-PendingReboot
	
	Returns custom object with following properties:
	ComputerName, LastBootUpTime, IsSystemRebootPending, IsCBServicingRebootPending, IsWindowsUpdateRebootPending, IsSCCMClientRebootPending, IsFileRenameRebootPending, PendingFileRenameOperations, ErrorMsg
	
	*Notes: ErrorMsg only contains something if an error occurred
.EXAMPLE
	(Get-PendingReboot).IsSystemRebootPending
	Returns boolean value determining whether or not there is a pending reboot operation.
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
    http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		## Initialize variables
		[string]$private:ComputerName = ([Net.Dns]::GetHostEntry('')).HostName
		$PendRebootErrorMsg = $null
	}
	Process {
		Write-Log -Message "Get the pending reboot status on the local computer [$ComputerName]." -Source ${CmdletName}
		
		## Get the date/time that the system last booted up
		Try {
			[nullable[datetime]]$LastBootUpTime = (Get-Date -ErrorAction 'Stop') - ([timespan]::FromMilliseconds([math]::Abs([Environment]::TickCount)))
		}
		Catch {
			[nullable[datetime]]$LastBootUpTime = $null
			[string[]]$PendRebootErrorMsg += "Failed to get LastBootUpTime: $($_.Exception.Message)"
			Write-Log -Message "Failed to get LastBootUpTime. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
		
		## Determine if a Windows Vista/Server 2008 and above machine has a pending reboot from a Component Based Servicing (CBS) operation
		Try {
			If (([version]$OSVersion).Major -ge 5) {
				If (Test-Path -LiteralPath 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending' -ErrorAction 'Stop') {
					[nullable[boolean]]$IsCBServicingRebootPending = $true
				}
				Else {
					[nullable[boolean]]$IsCBServicingRebootPending = $false
				}
			}
		}
		Catch {
			[nullable[boolean]]$IsCBServicingRebootPending = $null
			[string[]]$PendRebootErrorMsg += "Failed to get IsCBServicingRebootPending: $($_.Exception.Message)"
			Write-Log -Message "Failed to get IsCBServicingRebootPending. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
		
		## Determine if there is a pending reboot from a Windows Update
		Try {
			If (Test-Path -LiteralPath 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction 'Stop') {
				[nullable[boolean]]$IsWindowsUpdateRebootPending = $true
			}
			Else {
				[nullable[boolean]]$IsWindowsUpdateRebootPending = $false
			}
		}
		Catch {
			[nullable[boolean]]$IsWindowsUpdateRebootPending = $null
			[string[]]$PendRebootErrorMsg += "Failed to get IsWindowsUpdateRebootPending: $($_.Exception.Message)"
			Write-Log -Message "Failed to get IsWindowsUpdateRebootPending. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
		
		## Determine if there is a pending reboot from a pending file rename operation
		[boolean]$IsFileRenameRebootPending = $false
		$PendingFileRenameOperations = $null
		If (Test-RegistryKey -Key 'HKLM:SYSTEM\CurrentControlSet\Control\Session Manager' -Value 'PendingFileRenameOperations') {
			#  If PendingFileRenameOperations value exists, set $IsFileRenameRebootPending variable to $true
			[boolean]$IsFileRenameRebootPending = $true
			#  Get the value of PendingFileRenameOperations
			Try {
				[string[]]$PendingFileRenameOperations = Get-ItemProperty -LiteralPath 'HKLM:SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction 'Stop' | Select-Object -ExpandProperty 'PendingFileRenameOperations' -ErrorAction 'Stop'
			}
			Catch { 
				[string[]]$PendRebootErrorMsg += "Failed to get PendingFileRenameOperations: $($_.Exception.Message)"
				#Write-Log -Message "Failed to get PendingFileRenameOperations. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
		}
		
		## Determine SCCM 2012 Client reboot pending status
		Try {
			[boolean]$IsSccmClientNamespaceExists = $false
			[psobject]$SCCMClientRebootStatus = Invoke-WmiMethod -ComputerName $ComputerName -NameSpace 'ROOT\CCM\ClientSDK' -Class 'CCM_ClientUtilities' -Name 'DetermineIfRebootPending' -ErrorAction 'Stop'
			[boolean]$IsSccmClientNamespaceExists = $true
			If ($SCCMClientRebootStatus.ReturnValue -ne 0) {
				Throw "'DetermineIfRebootPending' method of 'ROOT\CCM\ClientSDK\CCM_ClientUtilities' class returned error code [$($SCCMClientRebootStatus.ReturnValue)]"
			}
			Else {
				Write-Log -Message 'Successfully queried SCCM client for reboot status.' -Source ${CmdletName}
				[nullable[boolean]]$IsSCCMClientRebootPending = $false
				If ($SCCMClientRebootStatus.IsHardRebootPending -or $SCCMClientRebootStatus.RebootPending) {
					[nullable[boolean]]$IsSCCMClientRebootPending = $true
					Write-Log -Message 'Pending SCCM reboot detected.' -Source ${CmdletName}
				}
				Else {
					Write-Log -Message 'Pending SCCM reboot not detected.' -Source ${CmdletName}
				}
			}
		}
		Catch [System.Management.ManagementException] {
			[nullable[boolean]]$IsSCCMClientRebootPending = $null
			[boolean]$IsSccmClientNamespaceExists = $false
			#Write-Log -Message "Failed to get IsSCCMClientRebootPending. Failed to detect the SCCM client WMI class." -Severity 3 -Source ${CmdletName}
		}
		Catch {
			[nullable[boolean]]$IsSCCMClientRebootPending = $null
			[string[]]$PendRebootErrorMsg += "Failed to get IsSCCMClientRebootPending: $($_.Exception.Message)"
			Write-Log -Message "Failed to get IsSCCMClientRebootPending. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
		
		## Determine if there is a pending reboot for the system
		[boolean]$IsSystemRebootPending = $false
		If ($IsCBServicingRebootPending -or $IsWindowsUpdateRebootPending -or $IsSCCMClientRebootPending -or $IsFileRenameRebootPending) {
			[boolean]$IsSystemRebootPending = $true
		}
		
		## Create a custom object containing pending reboot information for the system
		[psobject]$PendingRebootInfo = New-Object -TypeName 'PSObject' -Property @{
			ComputerName = $ComputerName
			LastBootUpTime = $LastBootUpTime
			IsSystemRebootPending = $IsSystemRebootPending
			IsCBServicingRebootPending = $IsCBServicingRebootPending
			IsWindowsUpdateRebootPending = $IsWindowsUpdateRebootPending
			IsSCCMClientRebootPending = $IsSCCMClientRebootPending
			IsFileRenameRebootPending = $IsFileRenameRebootPending
			PendingFileRenameOperations = $PendingFileRenameOperations
			ErrorMsg = $PendRebootErrorMsg
		}
		Write-Log -Message "Pending reboot status on the local computer [$ComputerName]: `n$($PendingRebootInfo | Format-List | Out-String)" -Source ${CmdletName}
	}
	End {
		Write-Output -InputObject ($PendingRebootInfo | Select-Object -Property 'ComputerName','LastBootUpTime','IsSystemRebootPending','IsCBServicingRebootPending','IsWindowsUpdateRebootPending','IsSCCMClientRebootPending','IsFileRenameRebootPending','PendingFileRenameOperations','ErrorMsg')
		
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Get-RegistryKey
Function Get-RegistryKey {
<#
.SYNOPSIS
	Retrieves value names and value data for a specified registry key or optionally, a specific value.
.DESCRIPTION
	Retrieves value names and value data for a specified registry key or optionally, a specific value.
	If the registry key does not exist or contain any values, the function will return $null by default. To test for existence of a registry key path, use built-in Test-Path cmdlet.
.PARAMETER Key
	Path of the registry key.
.PARAMETER Value
	Value to retrieve (optional).
.PARAMETER SID
	The security identifier (SID) for a user. Specifying this parameter will convert a HKEY_CURRENT_USER registry key to the HKEY_USERS\$SID format.
	Specify this parameter from the Invoke-HKCURegistrySettingsForAllUsers function to read/edit HKCU registry settings for all users on the system.
.PARAMETER ReturnEmptyKeyIfExists
	Return the registry key if it exists but it has no property/value pairs underneath it. Default is: $false.
.PARAMETER DoNotExpandEnvironmentNames
	Return unexpanded REG_EXPAND_SZ values. Default is: $false.	
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Get-RegistryKey -Key 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1AD147D0-BE0E-3D6C-AC11-64F6DC4163F1}'
.EXAMPLE
	Get-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\iexplore.exe'
.EXAMPLE
	Get-RegistryKey -Key 'HKLM:Software\Wow6432Node\Microsoft\Microsoft SQL Server Compact Edition\v3.5' -Value 'Version'
.EXAMPLE
	Get-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Value 'Path' -DoNotExpandEnvironmentNames 
	Returns %ProgramFiles%\Java instead of C:\Program Files\Java
.EXAMPLE
	Get-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Example' -Value '(Default)'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$Value,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$SID,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[Switch]$ReturnEmptyKeyIfExists = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[Switch]$DoNotExpandEnvironmentNames = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			## If the SID variable is specified, then convert all HKEY_CURRENT_USER key's to HKEY_USERS\$SID
			If ($PSBoundParameters.ContainsKey('SID')) {
				[string]$key = Convert-RegistryPath -Key $key -SID $SID
			}
			Else {
				[string]$key = Convert-RegistryPath -Key $key
			}
			
			## Check if the registry key exists
			If (-not (Test-Path -LiteralPath $key -ErrorAction 'Stop')) {
				Write-Log -Message "Registry key [$key] does not exist. Return `$null." -Severity 2 -Source ${CmdletName}
				$regKeyValue = $null
			}
			Else {
				If ($PSBoundParameters.ContainsKey('Value')) {
					Write-Log -Message "Get registry key [$key] value [$value]." -Source ${CmdletName}
				}
				Else {
					Write-Log -Message "Get registry key [$key] and all property values." -Source ${CmdletName}
				}
				
				## Get all property values for registry key
				$regKeyValue = Get-ItemProperty -LiteralPath $key -ErrorAction 'Stop'
				[int32]$regKeyValuePropertyCount = $regKeyValue | Measure-Object | Select-Object -ExpandProperty 'Count'
				
				## Select requested property
				If ($PSBoundParameters.ContainsKey('Value')) {
					#  Check if registry value exists
					[boolean]$IsRegistryValueExists = $false
					If ($regKeyValuePropertyCount -gt 0) {
						Try {
							[string[]]$PathProperties = Get-Item -LiteralPath $Key -ErrorAction 'Stop' | Select-Object -ExpandProperty 'Property' -ErrorAction 'Stop'
							If ($PathProperties -contains $Value) { $IsRegistryValueExists = $true }
						}
						Catch { }
					}
					
					#  Get the Value (do not make a strongly typed variable because it depends entirely on what kind of value is being read)
					If ($IsRegistryValueExists) {
						If ($DoNotExpandEnvironmentNames) { #Only useful on 'ExpandString' values
							If ($Value -like '(Default)') {
								$regKeyValue = $(Get-Item -LiteralPath $key -ErrorAction 'Stop').GetValue($null,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
							}
							Else {
								$regKeyValue = $(Get-Item -LiteralPath $key -ErrorAction 'Stop').GetValue($Value,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)	
							}							
						}
						ElseIf ($Value -like '(Default)') {
							$regKeyValue = $(Get-Item -LiteralPath $key -ErrorAction 'Stop').GetValue($null)
						}
						Else {
							$regKeyValue = $regKeyValue | Select-Object -ExpandProperty $Value -ErrorAction 'SilentlyContinue'
						}
					}
					Else {
						Write-Log -Message "Registry key value [$Key] [$Value] does not exist. Return `$null." -Source ${CmdletName}
						$regKeyValue = $null
					}
				}
				## Select all properties or return empty key object
				Else {
					If ($regKeyValuePropertyCount -eq 0) {
						If ($ReturnEmptyKeyIfExists) {
							Write-Log -Message "No property values found for registry key. Return empty registry key object [$key]." -Source ${CmdletName}
							$regKeyValue = Get-Item -LiteralPath $key -Force -ErrorAction 'Stop'
						}
						Else {
							Write-Log -Message "No property values found for registry key. Return `$null." -Source ${CmdletName}
							$regKeyValue = $null
						}
					}
				}
			}
			Write-Output -InputObject ($regKeyValue)
		}
		Catch {
			If (-not $Value) {
				Write-Log -Message "Failed to read registry key [$key]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to read registry key [$key]: $($_.Exception.Message)"
				}
			}
			Else {
				Write-Log -Message "Failed to read registry key [$key] value [$value]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to read registry key [$key] value [$value]: $($_.Exception.Message)"
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Get-ServiceStartMode
Function Get-ServiceStartMode
{
<#
.SYNOPSIS
	Get the service startup mode.
.DESCRIPTION
	Get the service startup mode.
.PARAMETER Name
	Specify the name of the service.
.PARAMETER ComputerName
	Specify the name of the computer. Default is: the local computer.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Get-ServiceStartMode -Name 'wuauserv'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdLetBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	Begin {
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Get the service [$Name] startup mode." -Source ${CmdletName}
			[string]$ServiceStartMode = (Get-WmiObject -ComputerName $ComputerName -Class 'Win32_Service' -Filter "Name='$Name'" -Property 'StartMode' -ErrorAction 'Stop').StartMode
			## If service start mode is set to 'Auto', change value to 'Automatic' to be consistent with 'Set-ServiceStartMode' function
			If ($ServiceStartMode -eq 'Auto') { $ServiceStartMode = 'Automatic'}
			
			## If on Windows Vista or higher, check to see if service is set to Automatic (Delayed Start)
			If (($ServiceStartMode -eq 'Automatic') -and (([version]$OSVersion).Major -gt 5)) {
				Try {
					[string]$ServiceRegistryPath = "HKLM:SYSTEM\CurrentControlSet\Services\$Name"
					[int32]$DelayedAutoStart = Get-ItemProperty -LiteralPath $ServiceRegistryPath -ErrorAction 'Stop' | Select-Object -ExpandProperty 'DelayedAutoStart' -ErrorAction 'Stop'
					If ($DelayedAutoStart -eq 1) { $ServiceStartMode = 'Automatic (Delayed Start)' }
				}
				Catch { }
			}
			
			Write-Log -Message "Service [$Name] startup mode is set to [$ServiceStartMode]." -Source ${CmdletName}
			Write-Output -InputObject $ServiceStartMode
		}
		Catch {
			Write-Log -Message "Failed to get the service [$Name] startup mode. `n$(Resolve-Error)" -Source ${CmdletName} -Severity 3
			If (-not $ContinueOnError) {
				Throw "Failed to get the service [$Name] startup mode: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Get-FileVerb
Function Get-FileVerb {
<#
.SYNOPSIS
	Gets file verbs
.DESCRIPTION
	Get the file verbs of a file (context menu items for a specific file type)
.PARAMETER file
	File
.EXAMPLE
	Get-FileVerb C:\windows\notepad.exe
.EXAMPLE
	Get-FileVerb C:\temp\document.pdf
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[Cmdletbinding()]
	param
	( 
		[Parameter(Mandatory=$True,Position=0)]
		[ValidateNotNullorEmpty()]
		[System.IO.FileInfo]$file
	)

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
				$shell=new-object -ComObject Shell.Application
				$ns=$shell.NameSpace($file.DirectoryName)
				Return $ns.ParseName($file.Name).Verbs()
		}

		Catch {
				Write-Log -Message "Failed to get verb for [$file]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Throw "Failed to get verb for [$file].: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Get-FileVerb

#region Function Get-WindowTitle
Function Get-WindowTitle {
<#
.SYNOPSIS
	Search for an open window title and return details about the window.
.DESCRIPTION
	Search for a window title. If window title searched for returns more than one result, then details for each window will be displayed.
	Returns the following properties for each window: WindowTitle, WindowHandle, ParentProcess, ParentProcessMainWindowHandle, ParentProcessId.
	Function does not work in SYSTEM context unless launched with "psexec.exe -s -i" to run it as an interactive process under the SYSTEM account.
.PARAMETER WindowTitle
	The title of the application window to search for using regex matching.
.PARAMETER GetAllWindowTitles
	Get titles for all open windows on the system.
.PARAMETER DisableFunctionLogging
	Disables logging messages to the script log file.
.EXAMPLE
	Get-WindowTitle -WindowTitle 'Microsoft Word'
	Gets details for each window that has the words "Microsoft Word" in the title.
.EXAMPLE
	Get-WindowTitle -GetAllWindowTitles
	Gets details for all windows with a title.
.EXAMPLE
	Get-WindowTitle -GetAllWindowTitles | Where-Object { $_.ParentProcess -eq 'WINWORD' }
	Get details for all windows belonging to Microsoft Word process with name "WINWORD".
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,ParameterSetName='SearchWinTitle')]
		[AllowEmptyString()]
		[string]$WindowTitle,
		[Parameter(Mandatory=$true,ParameterSetName='GetAllWinTitles')]
		[ValidateNotNullorEmpty()]
		[Switch]$GetAllWindowTitles = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[Switch]$DisableFunctionLogging = $false
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			If ($PSCmdlet.ParameterSetName -eq 'SearchWinTitle') {
				If (-not $DisableFunctionLogging) { Write-Log -Message "Find open window title(s) [$WindowTitle] using regex matching." -Source ${CmdletName} }
			}
			ElseIf ($PSCmdlet.ParameterSetName -eq 'GetAllWinTitles') {
				If (-not $DisableFunctionLogging) { Write-Log -Message 'Find all open window title(s).' -Source ${CmdletName} }
			}
			
			## Get all window handles for visible windows
			[IntPtr[]]$VisibleWindowHandles = [PackagingFramework.UiAutomation]::EnumWindows() | Where-Object { [PackagingFramework.UiAutomation]::IsWindowVisible($_) }
			
			## Discover details about each visible window that was discovered
			ForEach ($VisibleWindowHandle in $VisibleWindowHandles) {
				If (-not $VisibleWindowHandle) { Continue }
				## Get the window title
				[string]$VisibleWindowTitle = [PackagingFramework.UiAutomation]::GetWindowText($VisibleWindowHandle)
				If ($VisibleWindowTitle) {
					## Get the process that spawned the window
					[Diagnostics.Process]$Process = Get-Process -ErrorAction 'Stop' | Where-Object { $_.Id -eq [PackagingFramework.UiAutomation]::GetWindowThreadProcessId($VisibleWindowHandle) }
					If ($Process) {
						## Build custom object with details about the window and the process
						[psobject]$VisibleWindow = New-Object -TypeName 'PSObject' -Property @{
							WindowTitle = $VisibleWindowTitle
							WindowHandle = $VisibleWindowHandle
							ParentProcess= $Process.Name
							ParentProcessMainWindowHandle = $Process.MainWindowHandle
							ParentProcessId = $Process.Id
						}
						
						## Only save/return the window and process details which match the search criteria
						If ($PSCmdlet.ParameterSetName -eq 'SearchWinTitle') {
							$MatchResult = $VisibleWindow.WindowTitle -match $WindowTitle
							If ($MatchResult) {
								[psobject[]]$VisibleWindows += $VisibleWindow
							}
						}
						ElseIf ($PSCmdlet.ParameterSetName -eq 'GetAllWinTitles') {
							[psobject[]]$VisibleWindows += $VisibleWindow
						}
					}
				}
			}
		}
		Catch {
			If (-not $DisableFunctionLogging) { Write-Log -Message "Failed to get requested window title(s). `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName} }
		}
	}
	End {
		Write-Output -InputObject $VisibleWindows
		
		If ($DisableFunctionLogging) { . $RevertScriptLogging }
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Get-WindowTitle

#region Function Initialize-Script
Function Initialize-Script {
<#
.SYNOPSIS
	Initialize Script
.DESCRIPTION
	Initialize the package script, enumerates runtime variables and starts a log file
.EXAMPLE
	Initialize Script
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
    
    ##*=============================================
    ##* VARIABLE DECLARATION
    ##*=============================================
    
    Write-Verbose "Initialize-Script"

    # Store package start time
    [datetime]$Global:PackageStartTime = Get-Date

    ## Variables: PackagingFramework general
    [string]$Global:PackagingFrameworkName = 'PackagingFramework'
    [string]$Global:InstallTitle = "PackagingFramework"
    #[bool]$Global:ConfigShowBalloonNotifications = $true
    #[int32]$Global:ConfigInstallationUITimeout = 600
    
    ## Variables: Script Info
    [version]$Global:PackagingFrameworkModuleVersion = (Get-Module PackagingFramework).Version

    ## Variables: Datetime and Culture
    [datetime]$Global:CurrentDateTime = Get-Date
    [string]$Global:CurrentTime = Get-Date -Date $Global:CurrentDateTime -UFormat '%T'
    [string]$Global:CurrentDate = Get-Date -Date $Global:CurrentDateTime -UFormat '%d-%m-%Y'
    [timespan]$Global:CurrentTimeZoneBias = [timezone]::CurrentTimeZone.GetUtcOffset([datetime]::Now)
    [Globalization.CultureInfo]$Global:Culture = Get-Culture
    [string]$Global:CurrentLanguage = $Global:Culture.TwoLetterISOLanguageName.ToUpper()

    ## Variables: Error Handling
    [int32]$Global:MainExitCode = 0

    ## Variables: Environment Variables
    [psobject]$Global:PowerShellHost = $Host
    [psobject]$Global:ShellFolders = Get-ItemProperty -Path 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction 'SilentlyContinue'
    [string]$Global:AllUsersProfile = $env:ALLUSERSPROFILE
    [string]$Global:DefaultUserProfile = (Get-ItemProperty -Path 'HKLM:Software\Microsoft\Windows NT\CurrentVersion\ProfileList' -Name 'Default').Default
    [string]$Global:PublicUserProfile = (Get-ItemProperty -Path 'HKLM:Software\Microsoft\Windows NT\CurrentVersion\ProfileList' -Name 'Public').Public
    [string]$Global:ProfilesDirectory = (Get-ItemProperty -Path 'HKLM:Software\Microsoft\Windows NT\CurrentVersion\ProfileList' -Name 'ProfilesDirectory').ProfilesDirectory
    [string]$Global:AppData = [Environment]::GetFolderPath('ApplicationData')
    [string]$Global:ProcessorArchitecture = $env:PROCESSOR_ARCHITECTURE
    [string]$Global:CommonProgramFiles = [Environment]::GetFolderPath('CommonProgramFiles')
    [string]$Global:CommonProgramFilesX86 = ${env:CommonProgramFiles(x86)}
    [string]$Global:CommonDesktop   = $ShellFolders | Select-Object -ExpandProperty 'Common Desktop' -ErrorAction 'SilentlyContinue'
    [string]$Global:CommonDocuments = $ShellFolders | Select-Object -ExpandProperty 'Common Documents' -ErrorAction 'SilentlyContinue'
    [string]$Global:CommonStartMenuPrograms  = $ShellFolders | Select-Object -ExpandProperty 'Common Programs' -ErrorAction 'SilentlyContinue'
    [string]$Global:CommonStartMenu = $ShellFolders | Select-Object -ExpandProperty 'Common Start Menu' -ErrorAction 'SilentlyContinue'
    [string]$Global:CommonStartUp   = $ShellFolders | Select-Object -ExpandProperty 'Common Startup' -ErrorAction 'SilentlyContinue'
    [string]$Global:CommonTemplates = $ShellFolders | Select-Object -ExpandProperty 'Common Templates' -ErrorAction 'SilentlyContinue'
    [string]$Global:ComputerName = [Environment]::MachineName.ToUpper()
    [string]$Global:ComputerNameFQDN = ([Net.Dns]::GetHostEntry('localhost')).HostName
    [string]$Global:HomeDrive = $env:HOMEDRIVE
    [string]$Global:HomePath = $env:HOMEPATH
    [string]$Global:HomeShare = $env:HOMESHARE
    [string]$Global:LocalAppData = [Environment]::GetFolderPath('LocalApplicationData')
    [string[]]$Global:LogicalDrives = [Environment]::GetLogicalDrives()
    [string]$Global:ProgramFiles = [Environment]::GetFolderPath('ProgramFiles')
    [string]$Global:ProgramFilesX86 = ${env:ProgramFiles(x86)}
    [string]$Global:ProgramData = [Environment]::GetFolderPath('CommonApplicationData')
    [string]$Global:Public = $env:PUBLIC
    [string]$Global:SystemDrive = $env:SYSTEMDRIVE
    [string]$Global:SystemRoot = $env:SYSTEMROOT
    [string]$Global:Temp = [IO.Path]::GetTempPath()
    [string]$Global:TempFolder = Join-Path -Path $env:SYSTEMDRIVE\Temp -ChildPath ([System.IO.Path]::GetFileNameWithoutExtension(([System.IO.Path]::GetTempFileName())))
    [string]$Global:UserCookies = [Environment]::GetFolderPath('Cookies')
    [string]$Global:UserDesktop = [Environment]::GetFolderPath('DesktopDirectory')
    [string]$Global:UserFavorites = [Environment]::GetFolderPath('Favorites')
    [string]$Global:UserInternetCache = [Environment]::GetFolderPath('InternetCache')
    [string]$Global:UserInternetHistory = [Environment]::GetFolderPath('History')
    [string]$Global:UserMyDocuments = [Environment]::GetFolderPath('MyDocuments')
    [string]$Global:UserName = [Environment]::UserName
    [string]$Global:UserPictures = [Environment]::GetFolderPath('MyPictures')
    [string]$Global:UserProfile = $env:USERPROFILE
    [string]$Global:UserSendTo = [Environment]::GetFolderPath('SendTo')
    [string]$Global:UserStartMenu = [Environment]::GetFolderPath('StartMenu')
    [string]$Global:UserStartMenuPrograms = [Environment]::GetFolderPath('Programs')
    [string]$Global:UserStartUp = [Environment]::GetFolderPath('StartUp')
    [string]$Global:UserTemplates = [Environment]::GetFolderPath('Templates')
    [string]$Global:SystemDirectory = [Environment]::SystemDirectory
    [string]$Global:SysDir = [Environment]::SystemDirectory
    [string]$Global:WinDir = $env:WINDIR
    #  Handle X86 environment variables so they are never empty
    If (-not $Global:CommonProgramFilesX86) { [string]$Global:CommonProgramFilesX86 = $Global:CommonProgramFiles }
    If (-not $Global:ProgramFilesX86) { [string]$Global:ProgramFilesX86 = $Global:ProgramFiles }

    ## Variables: Domain Membership
    [boolean]$Global:IsMachinePartOfDomain = (Get-WmiObject -Class 'Win32_ComputerSystem' -ErrorAction 'SilentlyContinue').PartOfDomain
    [string]$Global:MachineWorkgroup = ''
    [string]$Global:MachineADDomain = ''
    [string]$Global:LogonServer = ''
    [string]$Global:MachineDomainController = ''
    If ($Global:IsMachinePartOfDomain) {
	    [string]$Global:MachineADDomain = (Get-WmiObject -Class 'Win32_ComputerSystem' -ErrorAction 'SilentlyContinue').Domain | Where-Object { $_ } | ForEach-Object { $_.ToLower() }
	    Try {
		    [string]$Global:LogonServer = $env:LOGONSERVER | Where-Object { (($_) -and (-not $_.Contains('\\MicrosoftAccount'))) } | ForEach-Object { $_.TrimStart('\') } | ForEach-Object { ([Net.Dns]::GetHostEntry($_)).HostName }
		    # If running in system context, fall back on the logonserver value stored in the registry
		    If (-not $Global:LogonServer) { [string]$Global:LogonServer = Get-ItemProperty -LiteralPath 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\History' -ErrorAction 'SilentlyContinue' | Select-Object -ExpandProperty 'DCName' -ErrorAction 'SilentlyContinue' }
		    [string]$Global:MachineDomainController = [DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().FindDomainController().Name
	    }
	    Catch { }
    }
    Else {
	    [string]$Global:MachineWorkgroup = (Get-WmiObject -Class 'Win32_ComputerSystem' -ErrorAction 'SilentlyContinue').Domain | Where-Object { $_ } | ForEach-Object { $_.ToUpper() }
    }
    [string]$Global:MachineDNSDomain = [Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName | Where-Object { $_ } | ForEach-Object { $_.ToLower() }
    [string]$Global:UserDNSDomain = $env:USERDNSDOMAIN | Where-Object { $_ } | ForEach-Object { $_.ToLower() }
    Try {
	    [string]$Global:UserDomain = [Environment]::UserDomainName.ToUpper()
    }
    Catch { }

    ## Variables: Operating System
    [psobject]$Global:ObjectOperatingSystem= Get-WmiObject -Class 'Win32_OperatingSystem' -ErrorAction 'SilentlyContinue'
    [string]$Global:OSName = $Global:ObjectOperatingSystem.Caption.Trim()
    [string]$Global:OSServicePack = $Global:ObjectOperatingSystem.CSDVersion
    [version]$Global:OSVersion = $Global:ObjectOperatingSystem.Version
    #  Get the operating system type
    [int32]$Global:OSProductType = $Global:ObjectOperatingSystem.ProductType
    [boolean]$Global:IsServerOS = [boolean]($Global:OSProductType -eq 3)
    [boolean]$Global:IsDomainControllerOS = [boolean]($Global:OSProductType -eq 2)
    [boolean]$Global:IsWorkStationOS = [boolean]($Global:OSProductType -eq 1)
    Switch ($Global:OSProductType) {
	    3 { [string]$Global:OSProductTypeName = 'Server' }
	    2 { [string]$Global:OSProductTypeName = 'Domain Controller' }
	    1 { [string]$Global:OSProductTypeName = 'Workstation' }
	    Default { [string]$Global:OSProductTypeName = 'Unknown' }
    }
    Remove-Variable ObjectOperatingSystem -Scope Global

    # Get RDSHost specific variables
    if ($IsServerOS -eq $true) {
        if((Get-WmiObject -Namespace "root\CIMV2\TerminalServices" -Class "Win32_TerminalServiceSetting" ).TerminalServerMode -eq "1") {$Global:IsRDHost=$true} else {$Global:IsRDHost=$false}
    } else  { $Global:IsRDHost=$false }
 
    # Get Citrix specific variables
    [string]$Global:IsCitrixAgent=$false ; if(get-service -name BrokerAgent -ErrorAction SilentlyContinue){[string]$Global:IsCitrixAgent=$true}
    [string]$Global:IsCitrixBroker=$false ; if(get-service -name CitrixBrokerService -ErrorAction SilentlyContinue){[string]$Global:IsCitrixBroker=$true}

    #  Get the OS Architecture
    [boolean]$Global:Is64Bit = [boolean]((Get-WmiObject -Class 'Win32_Processor' -ErrorAction 'SilentlyContinue' | Where-Object { $_.DeviceID -eq 'CPU0' } | Select-Object -ExpandProperty 'AddressWidth') -eq 64)
    If ($Global:Is64Bit) { [string]$Global:OSArchitecture = '64-bit' } Else { [string]$Global:OSArchitecture = '32-bit' }

    ## Variables: Current Process Architecture
    [boolean]$Global:Is64BitProcess = [boolean]([IntPtr]::Size -eq 8)
    If ($Global:Is64BitProcess) { [string]$Global:PSArchitecture = 'x64' } Else { [string]$Global:PSArchitecture = 'x86' }

    # Get Is<Version> variables
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 0) -and ($Global:IsServerOS -eq $false)) {$Global:IsWinVista = $true} else {$Global:IsWinVista = $false}
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 0) -and ($Global:IsServerOS -eq $true)) {$Global:IsWin2008 = $true} else {$Global:IsWin2008 = $false}
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 1) -and ($Global:IsServerOS -eq $false)) {$Global:IsWin7 = $true} else {$Global:IsWin7 = $false}
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 1) -and ($Global:IsServerOS -eq $true)) {$Global:IsWin2008R2 = $true} else {$Global:IsWin2008R2 = $false}
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 2) -and ($Global:IsServerOS -eq $false)) {$Global:IsWin8 = $true} else {$Global:IsWin8 = $false}
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 2) -and ($Global:IsServerOS -eq $true)) {$Global:IsWin2012 = $true} else {$Global:IsWin2012 = $false}
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 3) -and ($Global:IsServerOS -eq $false)) {$Global:IsWin81 = $true} else {$Global:IsWin81 = $false}
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 3) -and ($Global:IsServerOS -eq $true)) {$Global:IsWin2012R2 = $true} else {$Global:IsWin2012R2 = $false}
    if ((([version]$Global:OSVersion).Major -eq 10) -and (([version]$Global:OSVersion).Minor -eq 0) -and ($Global:IsServerOS -eq $false)) {$Global:IsWin10 = $true} else {$Global:IsWin10 = $false}
    if ((([version]$Global:OSVersion).Major -eq 10) -and (([version]$Global:OSVersion).Minor -eq 0) -and ($Global:IsServerOS -eq $true)) {$Global:IsWin2016 = $true} else {$Global:IsWin2016 = $false}

    # Get IsAtLeast<Version> variables
    if ((([version]$Global:OSVersion).Major -eq 10) -and (([version]$Global:OSVersion).Minor -eq 0))  {$Global:IsAtLeastWinVista = $true; $Global:IsAtLeastWin2008 = $true; $Global:IsAtLeastWin7 = $true; $Global:IsAtLeastWin2008R2 = $true; $Global:IsAtLeastWin8 = $true; $Global:IsAtLeastWin2012 = $true; $Global:IsAtLeastWin81 = $true; $Global:IsAtLeastWin2012R2 = $true; $Global:IsAtLeastWin10 = $true; $Global:IsAtLeastWin2016 = $true} 
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 3))  {$Global:IsAtLeastWinVista = $true; $Global:IsAtLeastWin2008 = $true; $Global:IsAtLeastWin7 = $true; $Global:IsAtLeastWin2008R2 = $true; $Global:IsAtLeastWin8 = $true; $Global:IsAtLeastWin2012 = $true; $Global:IsAtLeastWin81 = $true; $Global:IsAtLeastWin2012R2 = $true; $Global:IsAtLeastWin10 = $false; $Global:IsAtLeastWin2016 = $false} 
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 2))  {$Global:IsAtLeastWinVista = $true; $Global:IsAtLeastWin2008 = $true; $Global:IsAtLeastWin7 = $true; $Global:IsAtLeastWin2008R2 = $true; $Global:IsAtLeastWin8 = $true; $Global:IsAtLeastWin2012 = $true; $Global:IsAtLeastWin81 = $false; $Global:IsAtLeastWin2012R2 = $false; $Global:IsAtLeastWin10 = $false; $Global:IsAtLeastWin2016 = $false} 
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 1))  {$Global:IsAtLeastWinVista = $true; $Global:IsAtLeastWin2008 = $true; $Global:IsAtLeastWin7 = $true; $Global:IsAtLeastWin2008R2 = $true; $Global:IsAtLeastWin8 = $false; $Global:IsAtLeastWin2012 = $false; $Global:IsAtLeastWin81 = $false; $Global:IsAtLeastWin2012R2 = $false; $Global:IsAtLeastWin10 = $false; $Global:IsAtLeastWin2016 = $false} 
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 0))  {$Global:IsAtLeastWinVista = $true; $Global:IsAtLeastWin2008 = $true; $Global:IsAtLeastWin7 = $false; $Global:IsAtLeastWin2008R2 = $false; $Global:IsAtLeastWin8 = $false; $Global:IsAtLeastWin2012 = $false; $Global:IsAtLeastWin81 = $false; $Global:IsAtLeastWin2012R2 = $false; $Global:IsAtLeastWin10 = $false; $Global:IsAtLeastWin2016 = $false} 

    # Get IsAtMost<Version> variables
    if ((([version]$Global:OSVersion).Major -eq 10) -and (([version]$Global:OSVersion).Minor -eq 0))  {$Global:IsAtMostWinVista = $false; $Global:IsAtMostWin2008 = $false; $Global:IsAtMostWin7 = $false; $Global:IsAtMostWin2008R2 = $false; $Global:IsAtMostWin8 = $false; $Global:IsAtMostWin2012 = $false; $Global:IsAtMostWin81 = $false; $Global:IsAtMostWin2012R2 = $false; $Global:IsAtMostWin10 = $true; $Global:IsAtMostWin2016 = $true} 
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 3))  {$Global:IsAtMostWinVista = $false; $Global:IsAtMostWin2008 = $false; $Global:IsAtMostWin7 = $false; $Global:IsAtMostWin2008R2 = $false; $Global:IsAtMostWin8 = $false; $Global:IsAtMostWin2012 = $false; $Global:IsAtMostWin81 = $true; $Global:IsAtMostWin2012R2 = $true; $Global:IsAtMostWin10 = $true; $Global:IsAtMostWin2016 = $true} 
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 2))  {$Global:IsAtMostWinVista = $false; $Global:IsAtMostWin2008 = $false; $Global:IsAtMostWin7 = $false; $Global:IsAtMostWin2008R2 = $false; $Global:IsAtMostWin8 = $true; $Global:IsAtMostWin2012 = $true; $Global:IsAtMostWin81 = $true; $Global:IsAtMostWin2012R2 = $true; $Global:IsAtMostWin10 = $true; $Global:IsAtMostWin2016 = $true} 
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 1))  {$Global:IsAtMostWinVista = $false; $Global:IsAtMostWin2008 = $false; $Global:IsAtMostWin7 = $true; $Global:IsAtMostWin2008R2 = $true; $Global:IsAtMostWin8 = $true; $Global:IsAtMostWin2012 = $true; $Global:IsAtMostWin81 = $true; $Global:IsAtMostWin2012R2 = $true; $Global:IsAtMostWin10 = $true; $Global:IsAtMostWin2016 = $true} 
    if ((([version]$Global:OSVersion).Major -eq 6) -and (([version]$Global:OSVersion).Minor -eq 0))  {$Global:IsAtMostWinVista = $true; $Global:IsAtMostWin2008 = $true; $Global:IsAtMostWin7 = $true; $Global:IsAtMostWin2008R2 = $true; $Global:IsAtMostWin8 = $true; $Global:IsAtMostWin2012 = $true; $Global:IsAtMostWin81 = $true; $Global:IsAtMostWin2012R2 = $true; $Global:IsAtMostWin10 = $true; $Global:IsAtMostWin2016 = $true} 

    ## Variables: PowerShell And CLR (.NET) Versions
    [hashtable]$PSVersionHashTable = $PSVersionTable
    [version]$Global:PSVersionInfo = $PSVersionHashTable.PSVersion
    [version]$Global:CLRVersionInfo = $PSVersionHashTable.CLRVersion

    ## Variables: Permissions/Accounts
    [Security.Principal.WindowsIdentity]$Global:CurrentProcessToken = [Security.Principal.WindowsIdentity]::GetCurrent()
    [Security.Principal.SecurityIdentifier]$Global:CurrentProcessSID = $Global:CurrentProcessToken.User
    [string]$Global:ProcessNTAccount = $Global:CurrentProcessToken.Name
    [string]$Global:ProcessNTAccountSID = $Global:CurrentProcessSID.Value
    [boolean]$Global:IsAdmin = [boolean]($Global:CurrentProcessToken.Groups -contains [Security.Principal.SecurityIdentifier]'S-1-5-32-544')
    [boolean]$Global:IsLocalSystemAccount = $Global:CurrentProcessSID.IsWellKnown([Security.Principal.WellKnownSidType]'LocalSystemSid')
    [boolean]$Global:IsLocalServiceAccount = $Global:CurrentProcessSID.IsWellKnown([Security.Principal.WellKnownSidType]'LocalServiceSid')
    [boolean]$Global:IsNetworkServiceAccount = $Global:CurrentProcessSID.IsWellKnown([Security.Principal.WellKnownSidType]'NetworkServiceSid')
    [boolean]$Global:IsServiceAccount = [boolean]($Global:CurrentProcessToken.Groups -contains [Security.Principal.SecurityIdentifier]'S-1-5-6')
    [boolean]$Global:IsProcessUserInteractive = [Environment]::UserInteractive
    [string]$Global:LocalSystemNTAccount = (New-Object -TypeName 'System.Security.Principal.SecurityIdentifier' -ArgumentList ([Security.Principal.WellKnownSidType]::'LocalSystemSid', $null)).Translate([Security.Principal.NTAccount]).Value
    If ($Global:IsLocalSystemAccount -or $Global:IsLocalServiceAccount -or $Global:IsNetworkServiceAccount -or $Global:IsServiceAccount) { $Global:IsSessionZero = $true } Else { $Global:IsSessionZero = $false }  #  Check if script is running in session zero

    ## Variables: Script Name and Script Paths, Module name, etc.
    if ($MyInvocation.PSCommandPath) {[string]$Global:ScriptDirectory = Split-Path -Path $MyInvocation.PSCommandPath} else {[string]$Global:ScriptDirectory ="$MyInvocation.MyCommand.Definition"}
    [string]$Global:ModulePath = (Get-Module PackagingFramework).Path
    [string]$Global:ModuleName = [IO.Path]::GetFileNameWithoutExtension($Global:ModulePath)
    [string]$Global:ModuleFileName = Split-Path -Path $Global:ModulePath -Leaf
    [string]$Global:ModuleRoot = Split-Path -Path $Global:ModulePath -Parent

    ## Variables: Module Dependency Files (incl. if exists check)
    [string]$Global:LogoIcon = Join-Path -Path $Global:ModuleRoot -ChildPath 'PackagingFramework.ico'
    [string]$Global:LogoBanner = Join-Path -Path $Global:ModuleRoot -ChildPath 'PackagingFramework.png'
    [string]$ModuleJsonFile = Join-Path -Path $Global:ModuleRoot -ChildPath 'PackagingFramework.json'  # not global intentionally, only the json object will be clobal, but not the file !
    [string]$Global:CustomTypesFile = Join-Path -Path $Global:ModuleRoot -ChildPath 'PackagingFramework.cs'
    If (-not (Test-Path -LiteralPath $Global:LogoIcon -PathType 'Leaf')) { Throw 'Packaging Framework icon file not found.' }
    If (-not (Test-Path -LiteralPath $Global:LogoBanner -PathType 'Leaf')) { Throw 'Packaging Framework logo banner file not found.' }
    If (-not (Test-Path -LiteralPath $ModuleJsonFile -PathType 'Leaf')) { Throw 'Packaging Framework JSON configuration file not found.' }
    If (-not (Test-Path -LiteralPath $Global:CustomTypesFile -PathType 'Leaf')) { Throw 'Packaging Framework .cs custom types file not found.' }


    ## Get package info
    [string]$Global:PackageFileName = [IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath)
    [string]$Global:PackageName = [IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath)
    
    # If package name is not defined we assumed module is ised outside a package and because of this we disable the logging
    if(!$PackageName) {$DisableLogging = $true}

    ## Get config values from module JSON configuration file
    If ($Global:PSVersionInfo.Major -ge 5){ [psobject]$Global:ModuleConfigFile = get-content $ModuleJsonFile | ConvertFrom-Json  }
    else { [psobject]$Global:ModuleConfigFile = get-content $ModuleJsonFile -Raw | ConvertFrom-Json  } # ps versions older than 5 need the -raw paraemter

    #  Get Options
    [boolean]$Global:ConfigRequireAdmin = [boolean]::Parse($ModuleConfigFile.Options.RequireAdmin)
    [string]$Global:ConfigTempPath = $ExecutionContext.InvokeCommand.ExpandString($ModuleConfigFile.Options.TempPath)
    [string]$Global:ConfigRegPath = $ModuleConfigFile.Options.RegPath
    [string]$Global:LogDir = $ExecutionContext.InvokeCommand.ExpandString($ModuleConfigFile.Options.LogPath)
    If ($ModuleConfigFile.Options.LogPathPackageSubFolder -eq $true) {$Global:LogDir = $Global:LogDir + "\" + $PackageName}
    [string]$Global:ConfigLogStyle = $ModuleConfigFile.Options.LogStyle
    [boolean]$Global:ConfigLogWriteToHost = [boolean]::Parse($ModuleConfigFile.Options.LogWriteToHost)
    [boolean]$Global:ConfigLogDebugMessage = [boolean]::Parse($ModuleConfigFile.Options.LogDebugMessage)
    
    ## Variables: Files Directory
    [string]$Global:Files = Join-Path -Path $Global:ScriptDirectory -ChildPath 'Files'
    
    ## Set the deployment type to "Install" if it has not been specified
    If (-not $DeploymentType) { [string]$DeploymentType = 'Install' }

    ## Variables: RegEx Patterns
    [string]$Global:MSIProductCodeRegExPattern = '^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$'

    ## Variables: Registry Keys
    #  Registry keys for native and WOW64 applications
    [string]$RegKeyAppExecution = 'HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'

    ## COM Objects: Initialize
    [__comobject]$Global:Shell = New-Object -ComObject 'WScript.Shell' -ErrorAction 'SilentlyContinue'
    [__comobject]$Global:ShellApp = New-Object -ComObject 'Shell.Application' -ErrorAction 'SilentlyContinue'

    ## Variables: Reset/Remove Variables
    [boolean]$Global:MSIRebootDetected = $false
    [boolean]$Global:IsSCCMTaskSequence = $false

    ## Add the custom types
    If (-not ([Management.Automation.PSTypeName]'PackagingFramework.UiAutomation').Type) {
	    [string[]]$ReferencedAssemblies = 'System.Drawing', 'System.Windows.Forms', 'System.DirectoryServices'
	    Add-Type -Path $CustomTypesFile -ReferencedAssemblies $ReferencedAssemblies -IgnoreWarnings -ErrorAction 'Stop'
    }
    
    ## Set default vars if vars have not been specified
    If (-not $AppName) {
	    [string]$AppName = $PackagingFrameworkName
	    If (-not $AppVendor) { [string]$AppVendor = 'PS' }
	    If (-not $AppVersion) { [string]$AppVersion = $PackagingFrameworkModuleVersion }
	    If (-not $AppLang) { [string]$AppLang = $CurrentLanguage }
	    If (-not $AppRevision) { [string]$AppRevision = '01.00' }
	    If (-not $AppArch) { [string]$AppArch = '' }
    }
    If ($ReferredInstallTitle) { [string]$installTitle = $ReferredInstallTitle }
    If (-not $installTitle) {
	    [string]$installTitle = ("$AppVendor $AppName $AppVersion").Trim()
    }
    
    ## Sanitize the application details, as they can cause issues in the script
    [char[]]$InvalidFileNameChars = [IO.Path]::GetInvalidFileNameChars()
    [string]$AppVendor = $AppVendor -replace "[$InvalidFileNameChars]",'' -replace ' ',''
    [string]$AppName = $AppName -replace "[$InvalidFileNameChars]",'' -replace ' ',''
    [string]$AppVersion = $AppVersion -replace "[$InvalidFileNameChars]",'' -replace ' ',''
    [string]$AppArch = $AppArch -replace "[$InvalidFileNameChars]",'' -replace ' ',''
    [string]$AppLang = $AppLang -replace "[$InvalidFileNameChars]",'' -replace ' ',''
    [string]$AppRevision = $AppRevision -replace "[$InvalidFileNameChars]",'' -replace ' ',''

    ## Build the Installation Name
    If ($ReferredInstallName) { [string]$installName = $ReferredInstallName }
    If (-not $installName) {
	    If ($AppArch) {
		    [string]$installName = $AppVendor + '_' + $AppName + '_' + $AppVersion + '_' + $AppArch + '_' + $AppLang + '_' + $AppRevision
	    }
	    Else {
		    [string]$installName = $AppVendor + '_' + $AppName + '_' + $AppVersion + '_' + $AppLang + '_' + $AppRevision
	    }
    }
    [string]$installName = $installName.Trim('_') -replace '[_]+','_'


    ## Variables: Log Files
    If ($ReferredLogName) { [string]$Global:LogName = $ReferredLogName }
    If (-not $Global:LogName) { [string]$Global:LogName = $PackageFileName + '_' + $DeploymentType + '.log' }
    If (-not $ReferredLogName) { [string]$Global:LogName = $PackageFileName + '_' + $DeploymentType + '.log' }

    ## Initialize Logging
    $Global:InstallPhase = 'Initialization'
    $LogSeparator = '*' * 79
    Write-Log -Message ($LogSeparator) -Source $PackagingFrameworkName
    if($PackageName) {Write-Log -Message "[$PackageName] package started." -Source $PackagingFrameworkName}

    ## Import extensions (and check if module comes from module folder or package folder)
    If(Test-Path "$ScriptDirectory\PackagingFramework\PackagingFrameworkExtension.psd1" -PathType Leaf)
    {
        Write-Log -Message "Import Extension [$ScriptDirectory\PackagingFramework\PackagingFrameworkExtension.psd1]" -Severity 1 -Source $PackagingFrameworkName
        Import-Module "$ScriptDirectory\PackagingFramework\PackagingFrameworkExtension.psd1" -force -global
    }
    ElseIf(Test-Path "$ScriptDirectory\PackagingFrameworkExtension\PackagingFrameworkExtension.psd1" -PathType Leaf)
    {
        Write-Log -Message "Import Extension [$ScriptDirectory\PackagingFrameworkExtension\PackagingFrameworkExtension.psd1]" -Severity 1 -Source $PackagingFrameworkName
        Import-Module "$ScriptDirectory\PackagingFrameworkExtension\PackagingFrameworkExtension.psd1" -force -global
    }
    ElseIf(Test-Path $((Get-Module -Name PackagingFramework).ModuleBase + "\..\PackagingFrameworkExtension\PackagingFrameworkExtension.psd1") -PathType Leaf)
    {
        Write-Log -Message "Import Extension [$((Get-Module -Name PackagingFramework).ModuleBase + "\..\PackagingFrameworkExtension\PackagingFrameworkExtension.psd1")]" -Severity 1 -Source $PackagingFrameworkName
        Import-Module $((Get-Module -Name PackagingFramework).ModuleBase + "\..\PackagingFrameworkExtension\PackagingFrameworkExtension.psd1") -force -global
    }
    Else
    {
        Write-Log -Message "Import $PackagingFrameworkName Extension" -Severity 1 -Source $PackagingFrameworkName
        Import-Module PackagingFrameworkExtension -force -global 
    }

    # Write module info to log
    Write-Log -Message "$PackagingFrameworkName module version is [$PackagingFrameworkModuleVersion]" -Source $PackagingFrameworkName 
    Write-Log -Message "$PackagingFrameworkName module base [$((Get-Module -Name PackagingFramework).ModuleBase)]" -Source $PackagingFrameworkName 
    Write-Log -Message "$PackagingFrameworkName`Extension module version is [$((Get-Module -Name PackagingFrameworkExtension).Version)]" -Source $PackagingFrameworkName 
    Write-Log -Message "$PackagingFrameworkName`Extension module base [$((Get-Module -Name PackagingFrameworkExtension).ModuleBase)]" -Source $PackagingFrameworkName 

    # Make sure working directory is the script directory
    If (Test-Path -Path $ScriptDirectory -PathType Container){
        Set-Location -Path $ScriptDirectory
        Write-Log -Message "Working Directory [$((Get-Item -Path ".\" -Verbose).FullName)]" -Source $PackagingFrameworkName 
    }

    ## Log system/script information
    Write-Log -Message "Computer Name is [$ComputerNameFQDN]" -Source $PackagingFrameworkName
    Write-Log -Message "Current User is [$ProcessNTAccount]" -Source $PackagingFrameworkName
    If ($OSServicePack) {
	    Write-Log -Message "OS Version is [$OSName $OSServicePack $OSArchitecture $OSVersion]" -Source $PackagingFrameworkName
    }
    Else {
	    Write-Log -Message "OS Version is [$OSName $OSArchitecture $OSVersion]" -Source $PackagingFrameworkName
    }
    Write-Log -Message "OS Type is [$OSProductTypeName]" -Source $PackagingFrameworkName
    Write-Log -Message "Current Culture is [$($Culture.Name)] and UI language is [$CurrentLanguage]" -Source $PackagingFrameworkName
    Write-Log -Message "Hardware Platform is [$(Get-HardwarePlatform)]" -Source $PackagingFrameworkName
    Write-Log -Message "PowerShell Host is [$($PowerShellHost.Name)] with version [$($PowerShellHost.Version)]" -Source $PackagingFrameworkName
    Write-Log -Message "PowerShell Version is [$PSVersionInfo $PSArchitecture]" -Source $PackagingFrameworkName
    Write-Log -Message "PowerShell CLR (.NET) version is [$CLRVersionInfo]" -Source $PackagingFrameworkName

    ## Log details for all currently logged in users
    <#
    Write-Log -Message "Display session information for all logged on users: `n$($LoggedOnUserSessions | Format-List | Out-String)" -Source $PackagingFrameworkName
    If ($usersLoggedOn) {
	    Write-Log -Message "The following users are logged on to the system: [$($usersLoggedOn -join ', ')]." -Source $PackagingFrameworkName
	
	    #  Check if the current process is running in the context of one of the logged in users
	    If ($CurrentLoggedOnUserSession) {
		    Write-Log -Message "Current process is running with user account [$ProcessNTAccount] under logged in user session for [$($CurrentLoggedOnUserSession.NTAccount)]." -Source $PackagingFrameworkName
	    }
	    Else {
		    Write-Log -Message "Current process is running under a system account [$ProcessNTAccount]." -Source $PackagingFrameworkName
	    }
	
	    #  Display account and session details for the account running as the console user (user with control of the physical monitor, keyboard, and mouse)
	    If ($CurrentConsoleUserSession) {
		    Write-Log -Message "The following user is the console user [$($CurrentConsoleUserSession.NTAccount)] (user with control of physical monitor, keyboard, and mouse)." -Source $PackagingFrameworkName
	    }
	    Else {
		    Write-Log -Message 'There is no console user logged in (user with control of physical monitor, keyboard, and mouse).' -Source $PackagingFrameworkName
	    }
	
	    #  Display the account that will be used to execute commands in the user session when is running under the SYSTEM account
	    If ($RunAsActiveUser) {
		    Write-Log -Message "The active logged on user is [$($RunAsActiveUser.NTAccount)]." -Source $PackagingFrameworkName
	    }
    }
    Else {
	    Write-Log -Message 'No users are logged on to the system.' -Source $PackagingFrameworkName
    }
    #>


    ## Check if script is running from a SCCM Task Sequence
    if ($PackageName)  # don't run this when module is imported outside a package
    {
        Try {
	        [__comobject]$Global:SMSTSEnvironment = New-Object -ComObject 'Microsoft.SMS.TSEnvironment' -ErrorAction 'Stop'
	        Write-Log -Message 'Script is currently running from a SCCM Task Sequence.' -Source $PackagingFrameworkName
	        $Global:IsSCCMTaskSequence = $true
            #Write-Log -Message 'The following SCCM variables are defined:' -Source $PackagingFrameworkName
            #$Global:SMSTSEnvironment.GetVariables() | % { Write-Log -Message "$_ = $($Global:SMSTSEnvironment.Value($_))" -Source $PackagingFrameworkName} 
        }
        Catch {
	        Write-Log -Message 'Script is not running from a SCCM Task Sequence.' -Source $PackagingFrameworkName
	        $Global:IsSCCMTaskSequence = $false
        }
    }
    
    If ($DeployMode) { Write-Log -Message "Installation is running in [$DeployMode] mode." -Source $PackagingFrameworkName }

    ## Check deployment type (install/uninstall)
    If ($DeploymentType) { Write-Log -Message "Installation is running in [$DeploymentType] type." -Source $PackagingFrameworkName }

    # Deployment Type text strings
    Switch ($DeploymentType) {
	    'Install'   { $DeploymentTypeName = "Install" }
	    'Uninstall' { $DeploymentTypeName = "Uninstall" }
	    Default { $DeploymentTypeName = "Install" }
    }


    ## Check current permissions and exit if not running with Administrator rights
    If ($ConfigRequireAdmin) {
	    #  Check if the current process is running with elevated administrator permissions
	    If ((-not $IsAdmin) -and (-not $ShowBlockedAppDialog)) {
		    [string]$AdminPermissionErr = "[$PackagingFrameworkName] has an config file option [RequireAdmin] set to [True] so as to require Administrator rights to function. Please re-run the deployment script as an Administrator or change the option in the config file to not require Administrator rights"
		    Write-Log -Message $AdminPermissionErr -Severity 3 -Source $PackagingFrameworkName
            Show-DialogBox -Text $AdminPermissionErr -Icon 'Stop'
		    Throw $AdminPermissionErr
	    }
    }

    # Get vars from package JSON file
    if ($PackageName)  # don't run this when module is imported outside a package
    {
       
        # Get Package Json file (try $Computername.json first, then $PackageName.json)
        [string]$JSONFile = "$ScriptDirectory\$Computername.json"
        If (-not (Test-Path -LiteralPath $JSONFile -PathType 'Leaf')) 
        {
            [string]$JSONFile = "$ScriptDirectory\$PackageName.json"
            If (-not (Test-Path -LiteralPath $JSONFile -PathType 'Leaf')) 
            {
                Write-Log -Message "File [$ScriptDirectory\$PackageName.json] and/or [$ScriptDirectory\$Computername.json] not found. `n$(Resolve-Error)" -Severity 3 -Source $PackagingFrameworkName
                Throw "File [$ScriptDirectory\$PackageName.json] and/or [$ScriptDirectory\$Computername.json] not found. $($_.Exception.Message)"
            }
        }

        # Call TestPackage Name (and get name scheme element variables like AppName, AppVersion, etc.
        $NameSchemeTestResult = Test-PackageName
        If($NameSchemeTestResult -eq $true)
        {
            Write-Log -Message "Package file name [$PackageName] match the naming schema." -Source $PackagingFrameworkName
        }
        else
        {
            Write-Log -Message "Warning! Package file name [$PackageName] dose not match naming scheme configured in PackagingFramework.json" -Severity 2 -Source $PackagingFrameworkName
        }

        # Get repository share from registry
        [string]$ConfigRepositoryShare = (Get-ItemProperty -ErrorAction SilentlyContinue -Path "Registry::HKEY_LOCAL_MACHINE\Software\$PackagingFrameworkName" -name 'ConfigRepositoryShare').ConfigRepositoryShare 
        [string]$ConfigRepositoryUserAccount  = (Get-ItemProperty -ErrorAction SilentlyContinue -Path "Registry::HKEY_LOCAL_MACHINE\Software\$PackagingFrameworkName" -name 'ConfigRepositoryUserAccount').ConfigRepositoryUserAccount
        [string]$ConfigRepositoryUserPasswordEncrypted  = (Get-ItemProperty -ErrorAction SilentlyContinue -Path "Registry::HKEY_LOCAL_MACHINE\Software\$PackagingFrameworkName" -name 'ConfigRepositoryUserPasswordEncrypted').ConfigRepositoryUserPasswordEncrypted
        [string]$key = (Get-ItemProperty -ErrorAction SilentlyContinue -Path "Registry::HKEY_CURRENT_USER\Software\$PackagingFrameworkName" -name 'Key').Key
        if ($ConfigRepositoryUserAccount){
            if ($ConfigRepositoryUserPasswordEncrypted){
                if ($Key){
                    $ConfigRepositoryUserPassword = Invoke-Encryption -Action Decrypt -String $ConfigRepositoryUserPasswordEncrypted -SecureParameters
                    $SecureStringObject = ConvertTo-SecureString "$ConfigRepositoryUserPassword" -AsPlainText -Force # create secure password object for cred object
                    $CredsObject = New-Object System.Management.Automation.PSCredential ($ConfigRepositoryUserAccount,$SecureStringObject) # create cred object based on username & decrypted password
                    if (!(test-path -Path ConfigRepository:)) {New-PSDrive -name ConfigRepository -PSProvider FileSystem -root "$ConfigRepositoryShare" -Credential $CredsObject *>$null} # Map network share with cred object (when not already connected)
                } else {Write-Log "No encryption key found in registry"}
            } else {Write-Log "No encrypted password found in registry"}
        } else {Write-Log "No Config Repository User Account found"}

        if ($ConfigRepositoryShare){
            Write-Log "Config Repository Share info from registry [$ConfigRepositoryShare]"
            # Test if the share is available
            Try
            {
                If (Test-Path -LiteralPath $ConfigRepositoryShare -PathType 'Container')
                { 
                    Write-Log "Share [$ConfigRepositoryShare] is connectable."
                    # Test if a JSON file with the package name exists on the share
                    If (Test-Path -LiteralPath "$ConfigRepositoryShare\$PackageName\$PackageName.json" -PathType 'Leaf')
                    {
                        Write-Log "File [$ConfigRepositoryShare\$PackageName\$PackageName.json] found, it's now used."
                        $JSONFile = "$ConfigRepositoryShare\$PackageName\$PackageName.json"  #interchange json file
                        $PackageRepositoryFolder = "$ConfigRepositoryShare\$PackageName"
                    } 
                    else
                    {
                        Write-Log "File [$ConfigRepositoryShare\$PackageName\$PackageName.json] not found."
                        Write-Log "Continue using the local [$JSONFile] file."
                        $PackageRepositoryFolder = "$ScriptDirectory"
                    }
                } 
                else
                {
                    Write-Log "Unable to connect to share [$ConfigRepositoryShare]"
                    Throw "Unable to connect to share [$ConfigRepositoryShare] $($_.Exception.Message)"
                }
            }
            Catch
            {
                Throw "Unable to connect to share [$ConfigRepositoryShare] $($_.Exception.Message)"
            }
        }
        else
        {
            Write-Log "Registry key [HKLM\Software\$PackagingFrameworkName\ConfigRepositoryShare] not found, continue using the local file."
        }

        # Read general package parameters from the json file
        If ($Global:PSVersionInfo.Major -ge 5){ [psobject]$Global:PackageConfigFile = get-content $JSONFile | ConvertFrom-Json }
        else { [psobject]$Global:PackageConfigFile = get-content $JSONFile -Raw | ConvertFrom-Json } # ps versions older than 5 need the -raw paraemter
        [string]$PackageDate = $PackageConfigFile.Package.PackageDate
        [string]$PackageAuthor = $PackageConfigFile.Package.PackageAuthor
        [string]$PackageDescription = $PackageConfigFile.Package.PackageDescription
        [string]$InstallName = $Global:PackageName
        [string]$InstallTitle = $Global:PackageName

        # Make a local copy of the JSON file in the package log folder (e.g. used later for Citrix publishing)
        If ($deploymentType -ieq 'Install') {
            If ((Test-Path $LogDir) -eq $false) { New-Folder $LogDir }
            $PackageConfigFile | ConvertTo-Json -Depth 5 | Out-File "$LogDir\$Packagename.json"
        }
        If ($deploymentType -ieq 'Uninstall') {
            Remove-File -Path "$LogDir\$Packagename.json"
        }
        Write-Log "Package meta file: [$JSONFile]"
        
    }

    # Application and Account variable from JSON
    [Array]$Global:Accounts = $Null
    [Array]$Global:Applications = $Null
    foreach($TmpApp in $PackageConfigFile.Applications)
    {
        $Global:Applications += $TmpApp.AppName
        foreach($TmpAccount in $TmpApp.AppAccounts)
        {
            $Global:Accounts += $TmpAccount
        }
    }
    $Global:Applications = $Global:Applications | sort -unique
    $Global:Accounts = $Global:Accounts | sort -unique


    # Generat the (x86) environment variables from a x64 system on x86 system for compatibility
    if ($Is64Bit -eq $false){
        [environment]::SetEnvironmentVariable("ProgramFiles(x86)","$ProgramFiles")
        [environment]::SetEnvironmentVariable("CommonProgramFiles(x86)","$CommonProgramFiles")
    }


	# Change to terminal server install mode (on RDHost only)
	If ($IsRDHost -eq $true) { Enable-TerminalServerInstallMode }
    
    # write init completed
    Write-log "Initialize-Script completed."
    Write-Log -Message $LogSeparator -Source $PackagingFrameworkName

    # Chaneg default value for InstallPhase based on deployment type
    If ($deploymentType -ieq 'Install') { $Global:InstallPhase = 'Install' }
    If ($deploymentType -ieq 'Uninstall') { $Global:InstallPhase = 'Uninstall' }

    # Clear error object to start with a fresh error object inside the package
    $Error.Clear()
    $Global:Error.Clear()
    
}
#endregion Function Initialize-Script

#region Function Install-MSUpdates
Function Install-MSUpdates {
<#
.SYNOPSIS
	Install all Microsoft Updates in a given directory.
.DESCRIPTION
	Install all Microsoft Updates of type ".exe", ".msu", or ".msp" in a given directory (recursively search directory).
.PARAMETER Directory
	Directory containing the updates.
.EXAMPLE
	Install-MSUpdates -Directory "$Files\MSUpdates"
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Directory
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Write-Log -Message "Recursively install all Microsoft Updates in directory [$Directory]." -Source ${CmdletName}
		
		## KB Number pattern match
		$kbPattern = '(?i)kb\d{6,8}'
		
		## Get all hotfixes and install if required
		[IO.FileInfo[]]$files = Get-ChildItem -LiteralPath $Directory -Recurse -Include ('*.exe','*.msu','*.msp')
		ForEach ($file in $files) {
			If ($file.Name -match 'redist') {
				[version]$redistVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo($file).ProductVersion
				[string]$redistDescription = [Diagnostics.FileVersionInfo]::GetVersionInfo($file).FileDescription
				
				Write-Log -Message "Install [$redistDescription $redistVersion]..." -Source ${CmdletName}
				#  Handle older redistributables (ie, VC++ 2005)
				If ($redistDescription -match 'Win32 Cabinet Self-Extractor') {
					Start-Program -Path $file -Parameters '/q' -WindowStyle 'Hidden' -ContinueOnError $true
				}
				Else {
					Start-Program -Path $file -Parameters '/quiet /norestart' -WindowStyle 'Hidden' -ContinueOnError $true
				}
			}
			Else {
				#  Get the KB number of the file
				[string]$kbNumber = [regex]::Match($file.Name, $kbPattern).ToString()
				If (-not $kbNumber) { Continue }
				
				#  Check to see whether the KB is already installed
				If (-not (Test-MSUpdates -KBNumber $kbNumber)) {
					Write-Log -Message "KB Number [$KBNumber] was not detected and will be installed." -Source ${CmdletName}
					Switch ($file.Extension) {
						#  Installation type for executables (i.e., Microsoft Office Updates)
						'.exe' { Start-Program -Path $file -Parameters '/quiet /norestart' -WindowStyle 'Hidden' -ContinueOnError $true }
						#  Installation type for Windows updates using Windows Update Standalone Installer
						'.msu' { Start-Program -Path 'wusa.exe' -Parameters "`"$($file.FullName)`" /quiet /norestart" -WindowStyle 'Hidden' -ContinueOnError $true }
						#  Installation type for Windows Installer Patch
						'.msp' { Start-MSI -Action 'Patch' -Path $file -ContinueOnError $true }
					}
				}
				Else {
					Write-Log -Message "KB Number [$kbNumber] is already installed. Continue..." -Source ${CmdletName}
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Install-MultiplePackages

Function Install-MultiplePackages {
<#
.SYNOPSIS
	Install multiple packages
.DESCRIPTION
	Install multiple package framework packages in a order defined by a CSV file
    Supports Reboot and continues automaticatly after the reboot via AutoAdminLogon & RunOnce or SchTasks
    CSV file syntax:        
        PackageName;Date;Returncode;Installed
    Example:
        Adobe_FlashForFirefox_25.0.0.148_ML_01.00;;;
        Adobe_FlashForIE_25.0.0.148_ML_01.00;;;
        SubFolder\DonHo_NotepadPlusPlus_7.3.3_ML_01.00;;;
        REBOOT;;;
        SubFolder\dotPDN_Paint.Net_4.0.16_ML_01.00;;;
        SimonTatham_PuTTY_v0.68_EN_01.00;;;
		REBOOT;;;
	Note: 
	When UAC is enabled make sure to start you PowerShell session elevated when using this command.
	When using a built-in administrator account make sure the UAC Admin Approval Mode policy is configured
	is disabled (Computer\Security Settings|Local Policies|Security Options|User Account Control: Admin Approval Mode for Built-in Administrators account=Disable)
.PARAMETER CsvFile
	Specifies the CSV file with the package order
.PARAMETER PackageFolder
	Specifies the folder wher the packages are stored
.PARAMETER RunOnce
	Specifies the a RunOnce registry key entry is used to continue the installation aufter a reboot automaticaly (for AutoAdminLogon scenarios)
.PARAMETER Silent
	Suppress all dialogs
.EXAMPLE
	Install-MultiplePackages -CSVFile C:\Packages\install.csv -PackageFolder C:\Packages
.EXAMPLE
	Install-MultiplePackages -CSVFile C:\Packages\install.csv -PackageFolder C:\Packages -silent -runonce
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]$CsvFile,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]$PackageFolder,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$RunOnce,
		[Parameter(Mandatory = $false)]
		[switch]$Silent
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
            
            $LogFileFolder = Split-path -Path $CSVFile -Parent
            $LogFileName = "Install-MultiplePackages.log"
            

            # Open CSV file and process it line by line
            $objCSV = Import-Csv $CSVFile -Delimiter ';' # Get CSV object
            $objCSV | ForEach-Object { 
                
                # Counter for CSV possition
                $CurrentLine = $CurrentLine + 1

                # Check if package is not installed yet
                If ($_.Installed -ne 1) 
                {
                    # Check if current command is a reboot command or a package commnd
                    If ($_.PackageName -eq "REBOOT")
                    {
                        # Add "RunOnce" registry key to continue installation after reboot, but only when still some more lines in the CSV are to process after the reboot and -RunOnce is specified
                        if ($RunOnce -eq $true)
                        {
                            If ($CurrentLine -lt $objCSV.Count) {
                                if ($Silent -eq $false) {New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'Install-MultiplePackages' -PropertyType 'String' -Value """$env:WinDir\System32\WindowsPowerShell\v1.0\PowerShell.exe"" -ExecutionPolicy Unrestricted -Command ""&{Import-Module PackagingFramework ; Install-MultiplePackages -CSVFile $CSVFile -PackageFolder $PackageFolder -runonce}" -force}
                                if ($Silent -eq $true) {New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'Install-MultiplePackages' -PropertyType 'String' -Value """$env:WinDir\system32\WindowsPowerShell\v1.0\PowerShell.exe"" -ExecutionPolicy Unrestricted -Command ""&{Import-Module PackagingFramework ; Install-MultiplePackages -CSVFile $CSVFile -PackageFolder $PackageFolder -runonce -silent}" -force}
                            }
                            else
                            {
                               Remove-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'Install-MultiplePackages'-force
                               Write-Log "Final reboot, remove Run registry key" -Severity 1 -Source ${CmdletName} -LogType Legacy -LogFileDirectory $LogFileFolder -LogFileName $LogFileName 
                            }
                        }
                        
                        # Perform reboot and update CSV 
                        $_.Installed = "1" ; $_.Date = date ; $_.Returncode = "0"
                        $objCSV | Export-Csv $CSVFile -notypeinformation  -Delimiter ';'

                        if ($Silent -eq $false) { $return = Show-DialogBox -Text "The computer needs to be rebooted. Reboot now?" -Buttons OKCancel -Title "Install-MultiplePackages" -Icon Question }  else {$return = 'OK'}
                        If ($return -ieq 'OK')
                        {
                            Write-Log "REBOOT" ; Start-Sleep 5
                            Restart-Computer -Force ; Start-sleep 30 ; Exit 
                        }
                        else
                        {
                            Exit 3010
                        }

                    }
                    Else
                    {
                        # Get plain package name from package folder (without subfolder)
                        $PackageName = Split-Path $_.PackageName -leaf

                        # Get package sub folder
                        $PackageSubFolder = Split-Path $_.PackageName -parent

                        # Build Package file name and Working dir
                        $PackageFileName = $PackageFolder + "\" + $PackageSubFolder + "\" + $PackageName + "\" + $PackageName + ".ps1"
                        $PackageWorkingDir = $PackageFolder + "\" + $PackageSubFolder + "\" + $PackageName

                        # Check package existance, throw error if not found
                        if (-not (Test-path -path $PackageFileName -PathType Leaf)) {
                            Write-Log -Message "Package [$PackageFileName] not found. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName} -LogType Legacy -LogFileDirectory $LogFileFolder -LogFileName $LogFileName 
                            Write-Log -Message "Package [$PackageFileName] not found. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
                            if ($Silent -eq $false)  { Show-DialogBox -Text $(Resolve-Error) -Icon 'Stop' }
    			            If (-not $ContinueOnError) {
				                Throw "Package [$PackageFileName] not found.: $($_.Exception.Message)"
                            }
                        }
            
                        # Perform package installation
                        Write-Log "Start [$PackageFileName]" -Severity 1 -Source ${CmdletName} -LogType Legacy -LogFileDirectory $LogFileFolder -LogFileName $LogFileName 
						if ($Silent -eq $true) { $Process = Start-Process -FilePath PowerShell.exe -PassThru -Wait -ArgumentList "-file ""$PackageFileName"" -DeploymentType Install -DeployMode Silent"  -WorkingDirectory "$PackageWorkingDir" -Verb runAs -Verbose }
                        if ($Silent -eq $false) { $Process = Start-Process -FilePath PowerShell.exe -PassThru -Wait -ArgumentList "-file ""$PackageFileName"" -DeploymentType Install"  -WorkingDirectory "$PackageWorkingDir" -Verb runAs -Verbose }
                        $ExitCode = $process.ExitCode
                        Write-Log "End [$PackageFileName] with returncode [$ExitCode]" -Severity 1 -Source ${CmdletName} -LogType Legacy -LogFileDirectory $LogFileFolder -LogFileName $LogFileName 
                        
                        # Update CSV object with installation results
                        If (($Process.ExitCode -ne 0) -and ($Process.ExitCode -ne 3010)) {$_.Installed = "0"} else {$_.Installed = "1"}
                        $_.Date = date
                        $_.Returncode = $process.ExitCode
                        $objCSV | Export-Csv $CSVFile -notypeinformation  -Delimiter ';'

                        # Stop processing when unexpected exit code is detected, show msg and terminate with 1
                        If (($Process.ExitCode -ne 0) -and ($Process.ExitCode -ne 3010)) {if ($Silent -eq $false) {Show-DialogBox -Text "$PackageFileName terminated with unexpected return code $Process.ExitCode" -Icon 'Stop' } ; Exit 1}

                    } #reboot vs. package
                }# installed ne 1      
            } # for-each

            #Append a "COMPLETED" line to the end of the CSV
            $objCSV  += New-Object -TypeName PSObject -Property @{PackageName='COMPLETED';Date=date ;Returncode="0";Installed="1"}
            $objCSV | Export-Csv $CSVFile -notypeinformation  -Delimiter ';'
		}
		Catch {
                Write-Log -Message "Failed to install package. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName} -LogType Legacy -LogFileDirectory $LogFileFolder -LogFileName $LogFileName 
                Write-Log -Message "Failed to install package. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
                if ($Silent -eq $false)  { Show-DialogBox -Text $(Resolve-Error) -Icon 'Stop' }
    			If (-not $ContinueOnError) {
				Throw "Failed to install package.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Install-MultiplePackages

#region Function Install-SCCMSoftwareUpdates
Function Install-SCCMSoftwareUpdates {
<#
.SYNOPSIS
	Scans for outstanding SCCM updates to be installed and installs the pending updates.
.DESCRIPTION
	Scans for outstanding SCCM updates to be installed and installs the pending updates.
	Only compatible with SCCM 2012 Client or higher. This function can take several minutes to run.
.PARAMETER SoftwareUpdatesScanWaitInSeconds
	The amount of time to wait in seconds for the software updates scan to complete. Default is: 180 seconds.
.PARAMETER WaitForPendingUpdatesTimeout
	The amount of time to wait for missing and pending updates to install before exiting the function. Default is: 45 minutes.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Install-SCCMSoftwareUpdates

.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[int32]$SoftwareUpdatesScanWaitInSeconds = 180,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[timespan]$WaitForPendingUpdatesTimeout = $(New-TimeSpan -Minutes 45),
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message 'Scan for and install pending SCCM software updates.' -Source ${CmdletName}
			
			## Make sure SCCM client is installed and running
			Write-Log -Message 'Check to see if SCCM Client service [ccmexec] is installed and running.' -Source ${CmdletName}
			If (Test-ServiceExists -Name 'ccmexec') {
				If ($(Get-Service -Name 'ccmexec' -ErrorAction 'SilentlyContinue').Status -ne 'Running') {
					Throw "SCCM Client Service [ccmexec] exists but it is not in a 'Running' state."
				}
			} Else {
				Throw 'SCCM Client Service [ccmexec] does not exist. The SCCM Client may not be installed.'
			}
			
			## Determine the SCCM Client Version
			Try {
				[version]$SCCMClientVersion = Get-WmiObject -Namespace 'ROOT\CCM' -Class 'CCM_InstalledComponent' -ErrorAction 'Stop' | Where-Object { $_.Name -eq 'SmsClient' } | Select-Object -ExpandProperty 'Version' -ErrorAction 'Stop'
				Write-Log -Message "Installed SCCM Client Version Number [$SCCMClientVersion]." -Source ${CmdletName}
			}
			Catch {
				Write-Log -Message "Failed to determine the SCCM client version number. `n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
				Throw 'Failed to determine the SCCM client version number.'
			}
			#  If SCCM 2007 Client or lower, exit function
			If ($SCCMClientVersion.Major -le 4) {
				Throw 'SCCM 2007 or lower, which is incompatible with this function, was detected on this system.'
			}
			
			$StartTime = Get-Date
			## Trigger SCCM client scan for Software Updates
			Write-Log -Message 'Trigger SCCM client scan for Software Updates...' -Source ${CmdletName}
			Invoke-SCCMTask -ScheduleId 'SoftwareUpdatesScan'
			
			Write-Log -Message "The SCCM client scan for Software Updates has been triggered. The script is suspended for [$SoftwareUpdatesScanWaitInSeconds] seconds to let the update scan finish." -Source ${CmdletName}
			Start-Sleep -Seconds $SoftwareUpdatesScanWaitInSeconds
			
			## Find the number of missing updates
			Try {
				[Management.ManagementObject[]]$CMMissingUpdates = @(Get-WmiObject -Namespace 'ROOT\CCM\ClientSDK' -Query "SELECT * FROM CCM_SoftwareUpdate WHERE ComplianceState = '0'" -ErrorAction 'Stop')
			}
			Catch {
				Write-Log -Message "Failed to find the number of missing software updates. `n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
				Throw 'Failed to find the number of missing software updates.'
			}
			
			## Install missing updates and wait for pending updates to finish installing
			If ($CMMissingUpdates.Count) {
				#  Install missing updates
				Write-Log -Message "Install missing updates. The number of missing updates is [$($CMMissingUpdates.Count)]." -Source ${CmdletName}
				$CMInstallMissingUpdates = (Get-WmiObject -Namespace 'ROOT\CCM\ClientSDK' -Class 'CCM_SoftwareUpdatesManager' -List).InstallUpdates($CMMissingUpdates)
				
				#  Wait for pending updates to finish installing or the timeout value to expire
				Do {
					Start-Sleep -Seconds 60
					[array]$CMInstallPendingUpdates = @(Get-WmiObject -Namespace "ROOT\CCM\ClientSDK" -Query "SELECT * FROM CCM_SoftwareUpdate WHERE EvaluationState = 6 or EvaluationState = 7")
					Write-Log -Message "The number of updates pending installation is [$($CMInstallPendingUpdates.Count)]." -Source ${CmdletName}
				} While (($CMInstallPendingUpdates.Count -ne 0) -and ((New-TimeSpan -Start $StartTime -End $(Get-Date)) -lt $WaitForPendingUpdatesTimeout))
			}
			Else {
				Write-Log -Message 'There are no missing updates.' -Source ${CmdletName}
			}
		}
		Catch {
			Write-Log -Message "Failed to trigger installation of missing software updates. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to trigger installation of missing software updates: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Invoke-AppConfig
Function Invoke-AppConfig {
<#
.SYNOPSIS
	Performs various publishing steps like start menu publishing, Star menu layout modification, application lockdown
.DESCRIPTION
	Performs various publishing steps like start menu publishing, Star menu layout modification, application lockdown
.PARAMETER Action
	The action to perform. Options: Install, Uninstall
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default: $false.
.EXAMPLE
	Invoke-AppConfig -Action 'Install'
.EXAMPLE
	Invoke-AppConfig -Action 'Uninstall'
.NOTES
	Created by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[Parameter(Mandatory = $false)]
		[ValidateSet('Install', 'Uninstall')]
		[string]$Action = 'Install',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[switch]$ContinueOnError
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {

            # Get config values from global parameter file
            If ($Global:ModuleConfigFile.Options.StartMenuPublishing -eq $true) {[bool]$StartMenuPublishing = $true} else {[bool]$StartMenuPublishing = $false } 
            If ($Global:ModuleConfigFile.Options.StartMenuPublishingRootFolder -ne "") {[string]$StartMenuPublishingRootFolder = $ModuleConfigFile.Options.StartMenuPublishingRootFolder} else {[string]$StartMenuPublishingRootFolder = $CommonStartMenuPrograms }
            $StartMenuPublishingRootFolder = Expand-Variable -InputString $StartMenuPublishingRootFolder

            # Install
            If ($Action -ieq "Install") {

                # Application 
	            If($PackageConfigFile.Applications.count -gt 0) {
		            ForEach ($Application in $PackageConfigFile.Applications) {

                        # Create start menu shortcut 
			            If($StartMenuPublishing -ne $false) 
                        {
                            # Get ALL params from the JSON file parameters section and set to variable to be able to use them as vars in JSON application parameters, optional resolve powershell vars but not enivrionment vars)
                            ForEach ($Param in $PackageConfigFile.Parameters.psobject.Properties | where {$_.name} -like '*')
                            {
                                if ($Param.name){ 
                                    if ($($Param.name) -match "$"){ 
                                        if ($Param.value){ 
                                            $ResolvedValue = $ExecutionContext.InvokeCommand.ExpandString($($Param.value))
                                            Write-Log "Set-Variable [$($Param.name)] to [$ResolvedValue]" -DebugMessage
                                            Set-Variable -Name $($Param.name)  -Value $ResolvedValue 
                                        }
                                    } 
                                    else
                                    {
                                        if ($Param.value){ 
                                            Set-Variable -Name $($Param.name)  -Value $($Param.value)
                                            Write-Log "Set-Variable [$($Param.name)] to [$($Param.value)]" -DebugMessage
                                        }
                                    }
                                }
                            }

                            # Get params from JSON
			                $AppWorkingDirectory = $Application.AppWorkingDirectory
                            if($AppWorkingDirectory){ $AppWorkingDirectory = Expand-Variable -InputString $AppWorkingDirectory -VarType powershell} 
                            $AppCommandLineExecutable = $Application.AppCommandLineExecutable
                            if($AppCommandLineExecutable){ $AppCommandLineExecutable = Expand-Variable -InputString $AppCommandLineExecutable -VarType powershell}
                            $AppIconSource = $Application.AppIconSource
                            if($AppIconSource){ $AppIconSource = Expand-Variable -InputString $AppIconSource -VarType powershell}
                            $AppName = $Application.AppName
			                $AppCommandLineArguments = $Application.AppCommandLineArguments
			                $AppFolder = $Application.AppFolder
			                $AppDescription = $Application.AppDescription
                            if (!$AppIconSource) {$AppIconSource=$AppCommandLineExecutable}
                            if (!$AppIconIndex) {$AppIconIndex = 0}
                        
                            # Construct folder and link file name                        
                            $StartMenuFolder = "$StartMenuPublishingRootFolder\$AppFolder"
                            $StartMenuLinkFile = "$StartMenuFolder\$AppName" + ".lnk"

				            Write-Log -Message "Automatic start menu shortcut publishing ..." -Source ${CmdletName}
				            If (Test-Path -LiteralPath "$AppCommandLineExecutable" -PathType 'Leaf') { 
					            Write-Log -Message "Create shortcut: [$StartMenuFolder] for [$AppCommandLineExecutable]" -Source ${CmdletName}
					            New-Folder -Path "$StartMenuFolder"
					            New-Shortcut -Path "$StartMenuLinkFile" -TargetPath "$AppCommandLineExecutable" -IconLocation "$AppIconSource" -IconIndex "$AppIconIndex" -Description "$AppDescription" -WorkingDirectory "$AppWorkingDirectory" -Arguments "$AppCommandLineArguments"
				            }
				            Else { 
					            Write-Log -Message "Executable [$AppCommandLineExecutable] not found, shortcut creation failed" -Source ${CmdletName}
    	                		If (-not $ContinueOnError) {
				                    Throw "Executable [$AppCommandLineExecutable] not found, shortcut creation failed"
                                }
				            }
			            }

                        # Start Layout Modification (win10/Server2016 and newer only, only when AppPinToStart is specified)
                        If($OSVersion.Major -ge 10){
                            if(($Application.AppPinToStart -eq $true) -and ($AppFolder) -and ($AppName))
                            {
                                New-LayoutmodificationXML -AppFolder $AppFolder -AppName $AppName > $null
                            }
                        }

                        # App Lockdown
                        If(($Application.AppLockDown -eq $true) -or (($Application.AppLockDown -ieq "ServerOSOnly") -and ($IsServerOS -eq $true))) 
                        {
                            Write-log "Starting AppLockdown" -Severity 1 -DebugMessage
                            If(($Application.AppAccounts).count -ge 1)
                            {
                                ForEach ($AppAccount in $Application.AppAccounts) {
                                    $AppPath = Expand-Variable -InputString $Application.AppCommandLineExecutable -VarType powershell
                                    $AppAccount = Expand-Variable -InputString $AppAccount
                                    $AppFile = Split-Path -path $AppPath -Leaf
                                    $AppFolder = Split-Path -path $AppPath -Parent
                                    if(Test-Path -Path "$AppFolder\$AppFile" -PathType Leaf){
                                        Write-Log "Lockdown for [$AppFolder\$AppFile] and Trustee [$AppAccount]" -Severity 1 
                                        Set-Inheritance -Action 'Disable' -Path $AppFolder -Filename $AppFile # break inheritance
                                        Update-FilePermission -Action "Replace" -Path $AppFolder -Filename $AppFile -Trustee "S-1-5-32-545" -Permissions "Read" # reduce users permission to "read" instead "read&execute"
                                        Update-FilePermission -Action "Add" -Path $AppFolder -Filename $AppFile -Trustee $AppAccount -Permissions "ReadAndExecute" # give the application group read&execute
                                    }#test-path
                                    else
                                    {
                                        Write-log "File $AppFolder\$AppFile not found" -DebugMessage
                                    }
                                }#foreach
                            }#if accounts
                        }#app Lockdown

		            }
	            }


            }

			# Unpublish
            Else { 

                # Wait 1 seconde to avoid issues with some MSI setups
                Start-sleep 1

                # Application 
	            If($PackageConfigFile.Applications.count -gt 0) {
		            ForEach ($Application in $PackageConfigFile.Applications) {

                        # Remove start menu shortcut 
			            If($StartMenuPublishing -ne $false) 
                        {
			                $AppName = $Application.AppName
			                $AppFolder = $Application.AppFolder
                        
                            # Construct folder and link file name      
                            $StartMenuFolder = "$StartMenuPublishingRootFolder\$AppFolder"
                            $StartMenuLinkFile = "$StartMenuFolder\$AppName" + ".lnk"
                        
                            Write-Log -Message "Automatic start menu shortcut unpublishing ..." -Source ${CmdletName}

                            Write-Log -Message "Remove shortcut: [$StartMenuLinkFile]" -Source ${CmdletName}
                            Remove-File -path $StartMenuLinkFile
                            # Remove remaining empty folders (recursive, but only the empty ones)
                            do
                            {
                                $dirs = gci "$CommonStartMenuPrograms" -directory -recurse | Where { (gci $_.fullName -force).count -eq 0 } | select -expandproperty FullName
                                $dirs | Foreach-Object { Write-Log "Remove empty folder [$_]" -Source "Remove-Folder" ; Remove-Folder -path $_ -Verbose}
                            }
                            while ($dirs.count -gt 0)

                        }

                        # Remove Start Layout Modification (win10/Server2016 and newer only, only when AppPinToStart is specified)
                        # Uinstall not supported yet, next version
                        <#
                        If($OSVersion.Major -ge 10){
                            if(($Application.AppPinToStart -eq $true) -and ($AppFolder) -and ($AppName))
                            {
                                New-LayoutmodificationXML -AppFolder $AppFolder -AppName $AppName
                            }
                        }
                        #>



                    }
                }

            }



		}
		Catch {
                Write-Log -Message "Failed to publish. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
    			If (-not $ContinueOnError) {
				Throw "Failed to publish.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Invoke-AppConfig

#region Function Invoke-Encryption
Function Invoke-Encryption {
<#
.SYNOPSIS
	Encrypt or decrypt data
.DESCRIPTION
	Encrypt or decrypt data with n encryption key, has also options to generate and install a key
.PARAMETER Action
	The action to perform. Options: Encrypt, Decrypt, GenerateKey, InstallKey
.PARAMETER String
	Text string to encrypt or decrypt
.PARAMETER KeyFile
	File path/name of the key file, if not specivied the key is used from the registry
.PARAMETER SecureParameters
	Hides all data passed to the encryped/decrypted command in the log file.
.EXAMPLE
	Invoke-Encryption -Action Encrypt -String "This is a test string"
	Returns the encrypted string
.EXAMPLE
	Invoke-Encryption -Action Dencrypt -String "e6d0c742704a2be9d7d72b7263"
	Returns the decrypted string
.EXAMPLE
	Invoke-Encryption -Action GenerateKey -file 'C:\temp\new.key'
	Generates a new key file
.EXAMPLE
	Invoke-Encryption -Action InstallKey -file 'C:\temp\new.key'
	Installes an key file into the registry
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateSet('Encrypt','Decrypt','GenerateKey','InstallKey')]
		[string]$Action,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$String,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$KeyFile,
        [Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[Switch]$SecureParameters = $false
    )

    Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
        
        # Check key
        If ($KeyFile) {
            If (!(Test-Path -Path $KeyFile -PathType Leaf)) {Throw "Key File [$KeyFile] not found"}
        }
        If (!($KeyFile)) {
            $KeyExists = (Get-ItemProperty -ErrorAction SilentlyContinue -Path "Registry::HKEY_CURRENT_USER\Software\$PackagingFrameworkName" -name 'Key').Key
            If (!($KeyExists)) {Throw "Key not found in registry"} 
        }
        
	}
	Process {
		Try {

            ### GenerateKey
            If ($Action -ieq "GenerateKey") {
                Write-Log "${CmdletName} Start generating new key file" -Source ${CmdletName}
                if (Test-path -Path $KeyFile -PathType leaf) {Write-Log "${CmdletName} Key file [$KeyFile] already exists, please specify a new file name" -Source ${CmdletName} -Severity 2 ; Return}
                $Key = New-Object Byte[] 32   # its 32 bytte = AES-256 bit
                [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
                $Key | out-file $KeyFile -NoClobber
                Write-Log "${CmdletName} Key [$KeyFile] generated" -Source ${CmdletName}
            }

            ### InstallKey
            If ($Action -ieq "InstallKey") {
                Write-Log "${CmdletName} Start installing key file to registry" -Source ${CmdletName}
                $PlainTextKey = Get-Content $KeyFile | Out-String # Read key file and convert the array to a string
                $SecureStringKey = $PlainTextKey | ConvertTo-SecureString -AsPlainText -Force # Convert the plain text key to an secure string object
                $SecureStringKeyAsPlainText = $SecureStringKey | ConvertFrom-SecureString # Convert the secure string object to an secure string text string
                Set-RegistryKey -Key "HKEY_CURRENT_USER\SOFTWARE\$PackagingFrameworkName" -name "Key" -Value $SecureStringKeyAsPlainText # write key in secure string text string format into HKCU registry 
                Remove-Variable PlainTextKey ; Remove-Variable SecureStringKey ; Remove-Variable SecureStringKeyAsPlainText # remove key variables from ps session for security reason
            }

            ### Encrypt
            If ($Action -ieq "Encrypt") {
                If (-not $SecureParameters) {Write-Log "${CmdletName} Start encrypt of [$String]" -Source ${CmdletName}} else {Write-Log "${CmdletName} Start encrypt of [********]" -Source ${CmdletName}}
                If ($KeyFile) 
                {
                    $Key = Get-Content $KeyFile
                } 
                If (!($KeyFile)) 
                {
                    $key = (Get-ItemProperty -ErrorAction SilentlyContinue -Path "Registry::HKEY_CURRENT_USER\Software\$PackagingFrameworkName" -name 'Key').Key
                    $SecureStringObject = $key | ConvertTo-SecureString  # Convert the secure string text string key back to a secure string object
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureStringObject) # Decrypt the secure string object to plain text string
                    $PlainKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    $KeyArray = $PlainKey -split "`n" # convert back into an array
                    $Key = $keyArray[0..31] # make sure the array is 32 bit long and not 33 bit because of the last CRLF
                }
                $SecureString = New-Object System.Security.SecureString
                $Chars = $String.toCharArray()
                foreach ($Char in $Chars) {$SecureString.AppendChar($Char)}
                $EncryptedData = ConvertFrom-SecureString -SecureString $SecureString -Key $Key
                If($EncryptedData){$EncryptedData = "ENCRYPTAES256" + $EncryptedData} # Add header
                Return $EncryptedData
            }

            ### Decrypt
            If ($Action -ieq "Decrypt") {
                If (-not $SecureParameters) {Write-Log "${CmdletName} Start decrypt of [$String]" -Source ${CmdletName}} else {Write-Log "${CmdletName} Start decrypt of [********]" -Source ${CmdletName}}            
                If ($KeyFile) # get key from file
                {
                   $Key = Get-Content $KeyFile
                } 

                If (!($KeyFile)) # get key from registry
                {
                    $key = (Get-ItemProperty -ErrorAction SilentlyContinue -Path "Registry::HKEY_CURRENT_USER\Software\$PackagingFrameworkName" -name 'Key').Key
                    $SecureStringObject = $key | ConvertTo-SecureString  # Convert the secure string text string key back to a secure string object
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureStringObject) # Decrypt the secure string object to plain text string
                    $PlainKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    $KeyArray = $PlainKey -split "`n" # convert back into an array
                    $Key = $keyArray[0..31] # make sure the array is 32 bit long and not 33 bit because of the last CRLF
                }
                # Decrypt
                $String.TrimStart("ENCRYPTAES256")  | ConvertTo-SecureString -key $Key | 
                ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_))}
            }


            
		}
		Catch {
                Write-Log -Message "Invoke-Encryption failed. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
    			If (-not $ContinueOnError) {
				Throw "Invoke-Encryption failed.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}

}
#endregion Function Invoke-Encryption

#region Function Invoke-FileVerb
Function Invoke-FileVerb {
<#
.SYNOPSIS
	Invoke a verb (context menu items) from a file
.DESCRIPTION
	Invoke a verb (context menu items) from a file
.PARAMETER File
	File
.PARAMETER Verb
	Verb (Note: To get a list of supported verbs run Get-FileVerb)
.EXAMPLE
	Invoke-FileVerb -file 'C:\windows\notepad.exe' -verb '&Als Administrator ausführen'
.EXAMPLE
	Invoke-FileVerb - file 'C:\temp\document.pdf' -verb 'Print'
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[Cmdletbinding()]
	param
	( 
		[Parameter(Mandatory=$True,Position=0)]
		[ValidateNotNullorEmpty()]
		[System.IO.FileInfo]$file,
		[Parameter(Mandatory=$True,Position=1)]
		[ValidateNotNullorEmpty()]
		[String]$verb
	)
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {

			# Check for verb exists 
			$null = Get-FileVerb $file|Where-Object{$_.Name -eq $verb}|ForEach-Object{$VerbExist = $true} 
			if ($VerbExist -eq $true)
			{
				# Execute the verb for the file
				$null = Get-FileVerb $file|Where-Object{$_.Name -eq $verb}|ForEach-Object{$_.Doit()} 
			}
			else
			{
				Throw "Verb [$verb] not found for [$file]"
			}
		}
		Catch {
			Write-Log -Message "Failed to invoke verb [$verb] for [$file]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			Throw "Failed to invoke verb [$verb] for [$file].: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Invoke-FileVerb

#region Function Invoke-ObjectMethod
Function Invoke-ObjectMethod {
<#
.SYNOPSIS
	Invoke method on any object.
.DESCRIPTION
	Invoke method on any object with or without using named parameters.
.PARAMETER InputObject
	Specifies an object which has methods that can be invoked.
.PARAMETER MethodName
	Specifies the name of a method to invoke.
.PARAMETER ArgumentList
	Argument to pass to the method being executed. Allows execution of method without specifying named parameters.
.PARAMETER Parameter
	Argument to pass to the method being executed. Allows execution of method by using named parameters.
.EXAMPLE
	$ShellApp = New-Object -ComObject 'Shell.Application'
	$null = Invoke-ObjectMethod -InputObject $ShellApp -MethodName 'MinimizeAll'
	Minimizes all windows.
.EXAMPLE
	$ShellApp = New-Object -ComObject 'Shell.Application'
	$null = Invoke-ObjectMethod -InputObject $ShellApp -MethodName 'Explore' -Parameter @{'vDir'='C:\Windows'}
	Opens the C:\Windows folder in a Windows Explorer window.
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding(DefaultParameterSetName='Positional')]
	Param (
		[Parameter(Mandatory=$true,Position=0)]
		[ValidateNotNull()]
		[object]$InputObject,
		[Parameter(Mandatory=$true,Position=1)]
		[ValidateNotNullorEmpty()]
		[string]$MethodName,
		[Parameter(Mandatory=$false,Position=2,ParameterSetName='Positional')]
		[object[]]$ArgumentList,
		[Parameter(Mandatory=$true,Position=2,ParameterSetName='Named')]
		[ValidateNotNull()]
		[hashtable]$Parameter
	)
	
	Begin { }
	Process {
		If ($PSCmdlet.ParameterSetName -eq 'Named') {
			## Invoke method by using parameter names
			Write-Output -InputObject $InputObject.GetType().InvokeMember($MethodName, [Reflection.BindingFlags]::InvokeMethod, $null, $InputObject, ([object[]]($Parameter.Values)), $null, $null, ([string[]]($Parameter.Keys)))
		}
		Else {
			## Invoke method without using parameter names
			Write-Output -InputObject $InputObject.GetType().InvokeMember($MethodName, [Reflection.BindingFlags]::InvokeMethod, $null, $InputObject, $ArgumentList, $null, $null, $null)
		}
	}
	End { }
}
#endregion

#region Function Invoke-RegisterOrUnregisterDLL
Function Invoke-RegisterOrUnregisterDLL {
<#
.SYNOPSIS
	Register or unregister a DLL file.
.DESCRIPTION
	Register or unregister a DLL file using regsvr32.exe.
.PARAMETER FilePath
	Path to the DLL file.
.PARAMETER DLLAction
	Specify whether to register or unregister the DLL.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Invoke-RegisterOrUnregisterDLL -FilePath "C:\Test\DcTLSFileToDMSComp.dll" -DLLAction 'Register'
	Register DLL file using the actual name of this function
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$FilePath,
		[Parameter(Mandatory=$false)]
		[ValidateSet('Register','Unregister')]
		[string]$DLLAction,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		## Get name used to invoke this function in case the 'Register-DLL' or 'Unregister-DLL' alias was used and set the correct DLL action
		[string]${InvokedCmdletName} = $MyInvocation.InvocationName
		#  Set the correct register/unregister action based on the alias used to invoke this function
		If (${InvokedCmdletName} -ne ${CmdletName}) {
			Switch (${InvokedCmdletName}) {
				'Register-DLL' { [string]$DLLAction = 'Register' }
				'Unregister-DLL' { [string]$DLLAction = 'Unregister' }
			}
		}
		#  Set the correct DLL register/unregister action parameters
		If (-not $DLLAction) { Throw 'Parameter validation failed. Please specify the [-DLLAction] parameter to determine whether to register or unregister the DLL.' }
		[string]$DLLAction = ((Get-Culture).TextInfo).ToTitleCase($DLLAction.ToLower())
		Switch ($DLLAction) {
			'Register' { [string]$DLLActionParameters = "/s `"$FilePath`"" }
			'Unregister' { [string]$DLLActionParameters = "/s /u `"$FilePath`"" }
		}
	}
	Process {
		Try {
			Write-Log -Message "$DLLAction DLL file [$filePath]." -Source ${CmdletName}
			If (-not (Test-Path -LiteralPath $FilePath -PathType 'Leaf')) { Throw "File [$filePath] could not be found." }
			
			[string]$DLLFileBitness = Get-PEFileArchitecture -FilePath $filePath -ContinueOnError $false -ErrorAction 'Stop'
			If (($DLLFileBitness -ne '64BIT') -and ($DLLFileBitness -ne '32BIT')) {
				Throw "File [$filePath] has a detected file architecture of [$DLLFileBitness]. Only 32-bit or 64-bit DLL files can be $($DLLAction.ToLower() + 'ed')."
			}
			
			If ($Is64Bit) {
				If ($DLLFileBitness -eq '64BIT') {
					If ($Is64BitProcess) {
						[string]$RegSvr32Path = "$WinDir\system32\regsvr32.exe"
					}
					Else {
						[string]$RegSvr32Path = "$WinDir\sysnative\regsvr32.exe"
					}
				}
				ElseIf ($DLLFileBitness -eq '32BIT') {
					[string]$RegSvr32Path = "$WinDir\SysWOW64\regsvr32.exe"
				}
			}
			Else {
				If ($DLLFileBitness -eq '64BIT') {
					Throw "File [$filePath] cannot be $($DLLAction.ToLower()) because it is a 64-bit file on a 32-bit operating system."
				}
				ElseIf ($DLLFileBitness -eq '32BIT') {
					[string]$RegSvr32Path = "$WinDir\system32\regsvr32.exe"
				}
			}

			[psobject]$ExecuteResult = Start-Program -Path $RegSvr32Path -Parameters $DLLActionParameters -WindowStyle 'Hidden' -PassThru
			
			If ($ExecuteResult.ExitCode -ne 0) {
				If ($ExecuteResult.ExitCode -eq 60002) {
					Throw "Start-Program function failed with exit code [$($ExecuteResult.ExitCode)]."
				}
				Else {
					Throw "regsvr32.exe failed with exit code [$($ExecuteResult.ExitCode)]."
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to $($DLLAction.ToLower()) DLL file. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to $($DLLAction.ToLower()) DLL file: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
Set-Alias -Name 'Register-DLL' -Value 'Invoke-RegisterOrUnregisterDLL' -Scope 'Script' -Force -ErrorAction 'SilentlyContinue'
Set-Alias -Name 'Unregister-DLL' -Value 'Invoke-RegisterOrUnregisterDLL' -Scope 'Script' -Force -ErrorAction 'SilentlyContinue'
#endregion

#region Function Invoke-SCCMTask
Function Invoke-SCCMTask {
<#
.SYNOPSIS
	Triggers SCCM to invoke the requested schedule task id.
.DESCRIPTION
	Triggers SCCM to invoke the requested schedule task id.
.PARAMETER ScheduleId
	Name of the schedule id to trigger.
	Options: HardwareInventory, SoftwareInventory, HeartbeatDiscovery, SoftwareInventoryFileCollection, RequestMachinePolicy, EvaluateMachinePolicy,
	LocationServicesCleanup, SoftwareMeteringReport, SourceUpdate, PolicyAgentCleanup, RequestMachinePolicy2, CertificateMaintenance, PeerDistributionPointStatus,
	PeerDistributionPointProvisioning, ComplianceIntervalEnforcement, SoftwareUpdatesAgentAssignmentEvaluation, UploadStateMessage, StateMessageManager,
	SoftwareUpdatesScan, AMTProvisionCycle, UpdateStorePolicy, StateSystemBulkSend, ApplicationManagerPolicyAction, PowerManagementStartSummarizer
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Invoke-SCCMTask 'SoftwareUpdatesScan'
.EXAMPLE
	Invoke-SCCMTask
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateSet('HardwareInventory','SoftwareInventory','HeartbeatDiscovery','SoftwareInventoryFileCollection','RequestMachinePolicy','EvaluateMachinePolicy','LocationServicesCleanup','SoftwareMeteringReport','SourceUpdate','PolicyAgentCleanup','RequestMachinePolicy2','CertificateMaintenance','PeerDistributionPointStatus','PeerDistributionPointProvisioning','ComplianceIntervalEnforcement','SoftwareUpdatesAgentAssignmentEvaluation','UploadStateMessage','StateMessageManager','SoftwareUpdatesScan','AMTProvisionCycle','UpdateStorePolicy','StateSystemBulkSend','ApplicationManagerPolicyAction','PowerManagementStartSummarizer')]
		[string]$ScheduleID,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Invoke SCCM Schedule Task ID [$ScheduleId]..." -Source ${CmdletName}
				
			## Make sure SCCM client is installed and running
			Write-Log -Message 'Check to see if SCCM Client service [ccmexec] is installed and running.' -Source ${CmdletName}
			If (Test-ServiceExists -Name 'ccmexec') {
				If ($(Get-Service -Name 'ccmexec' -ErrorAction 'SilentlyContinue').Status -ne 'Running') {
					Throw "SCCM Client Service [ccmexec] exists but it is not in a 'Running' state."
				}
			} Else {
				Throw 'SCCM Client Service [ccmexec] does not exist. The SCCM Client may not be installed.'
			}
			
			## Determine the SCCM Client Version
			Try {
				[version]$SCCMClientVersion = Get-WmiObject -Namespace 'ROOT\CCM' -Class 'CCM_InstalledComponent' -ErrorAction 'Stop' | Where-Object { $_.Name -eq 'SmsClient' } | Select-Object -ExpandProperty 'Version' -ErrorAction 'Stop'
				Write-Log -Message "Installed SCCM Client Version Number [$SCCMClientVersion]." -Source ${CmdletName}
			}
			Catch {
				Write-Log -Message "Failed to determine the SCCM client version number. `n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
				Throw 'Failed to determine the SCCM client version number.'
			}
			
			## Create a hashtable of Schedule IDs compatible with SCCM Client 2007
			[hashtable]$ScheduleIds = @{
				HardwareInventory = '{00000000-0000-0000-0000-000000000001}'; # Hardware Inventory Collection Task
				SoftwareInventory = '{00000000-0000-0000-0000-000000000002}'; # Software Inventory Collection Task
				HeartbeatDiscovery = '{00000000-0000-0000-0000-000000000003}'; # Heartbeat Discovery Cycle
				SoftwareInventoryFileCollection = '{00000000-0000-0000-0000-000000000010}'; # Software Inventory File Collection Task
				RequestMachinePolicy = '{00000000-0000-0000-0000-000000000021}'; # Request Machine Policy Assignments
				EvaluateMachinePolicy = '{00000000-0000-0000-0000-000000000022}'; # Evaluate Machine Policy Assignments
				RefreshDefaultMp = '{00000000-0000-0000-0000-000000000023}'; # Refresh Default MP Task
				RefreshLocationServices = '{00000000-0000-0000-0000-000000000024}'; # Refresh Location Services Task
				LocationServicesCleanup = '{00000000-0000-0000-0000-000000000025}'; # Location Services Cleanup Task
				SoftwareMeteringReport = '{00000000-0000-0000-0000-000000000031}'; # Software Metering Report Cycle
				SourceUpdate = '{00000000-0000-0000-0000-000000000032}'; # Source Update Manage Update Cycle
				PolicyAgentCleanup = '{00000000-0000-0000-0000-000000000040}'; # Policy Agent Cleanup Cycle
				RequestMachinePolicy2 = '{00000000-0000-0000-0000-000000000042}'; # Request Machine Policy Assignments
				CertificateMaintenance = '{00000000-0000-0000-0000-000000000051}'; # Certificate Maintenance Cycle
				PeerDistributionPointStatus = '{00000000-0000-0000-0000-000000000061}'; # Peer Distribution Point Status Task
				PeerDistributionPointProvisioning = '{00000000-0000-0000-0000-000000000062}'; # Peer Distribution Point Provisioning Status Task
				ComplianceIntervalEnforcement = '{00000000-0000-0000-0000-000000000071}'; # Compliance Interval Enforcement
				SoftwareUpdatesAgentAssignmentEvaluation = '{00000000-0000-0000-0000-000000000108}'; # Software Updates Agent Assignment Evaluation Cycle
				UploadStateMessage = '{00000000-0000-0000-0000-000000000111}'; # Send Unsent State Messages
				StateMessageManager = '{00000000-0000-0000-0000-000000000112}'; # State Message Manager Task
				SoftwareUpdatesScan = '{00000000-0000-0000-0000-000000000113}'; # Force Update Scan
				AMTProvisionCycle = '{00000000-0000-0000-0000-000000000120}'; # AMT Provision Cycle
			}
			
			## If SCCM 2012 Client or higher, modify hashtabe containing Schedule IDs so that it only has the ones compatible with this version of the SCCM client
			If ($SCCMClientVersion.Major -ge 5) {
				$ScheduleIds.Remove('PeerDistributionPointStatus')
				$ScheduleIds.Remove('PeerDistributionPointProvisioning')
				$ScheduleIds.Remove('ComplianceIntervalEnforcement')
				$ScheduleIds.Add('UpdateStorePolicy','{00000000-0000-0000-0000-000000000114}') # Update Store Policy
				$ScheduleIds.Add('StateSystemBulkSend','{00000000-0000-0000-0000-000000000116}') # State System Policy Bulk Send Low
				$ScheduleIds.Add('ApplicationManagerPolicyAction','{00000000-0000-0000-0000-000000000121}') # Application Manager Policy Action
				$ScheduleIds.Add('PowerManagementStartSummarizer','{00000000-0000-0000-0000-000000000131}') # Power Management Start Summarizer
			}
			
			## Determine if the requested Schedule ID is available on this version of the SCCM Client
			If (-not ($ScheduleIds.ContainsKey($ScheduleId))) {
				Throw "The requested ScheduleId [$ScheduleId] is not available with this version of the SCCM Client [$SCCMClientVersion]."
			}
			
			## Trigger SCCM task
			Write-Log -Message "Trigger SCCM Task ID [$ScheduleId]." -Source ${CmdletName}
			[Management.ManagementClass]$SmsClient = [WMIClass]'ROOT\CCM:SMS_Client'
			$null = $SmsClient.TriggerSchedule($ScheduleIds.$ScheduleID)
		}
		Catch {
			Write-Log -Message "Failed to trigger SCCM Schedule Task ID [$($ScheduleIds.$ScheduleId)]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to trigger SCCM Schedule Task ID [$($ScheduleIds.$ScheduleId)]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Invoke-SCCMTask

#region Function Import-RegFile

Function Import-RegFile {
<#
.SYNOPSIS
	Bulk registry key import
.DESCRIPTION
	Bulk import of registry keys from a regedit.exe .reg file
.PARAMETER File
	File name of the .reg file
.PARAMETER ContinueOnError
	Continue if an error is encountered
.PARAMETER ResolveVars
	Resolve environment or PowerShell variables inside a .reg file while importing. 
    Please note, this feature cannot be used currently for variables that have no \ characters in the values because this need to be escaped in the .reg file syntax as \\
.PARAMETER Use32BitRegistry
	Imports the .reg file into the 32 bit registry branche on a 64 bit system
.EXAMPLE
	Import-RegFile $temp\test.reg
.EXAMPLE
    Import-RegFile -File "$temp\test.reg" -Use32BitRegistry -ResolveVars
.EXAMPLE
    Import-RegFile -File "$temp\test.reg" -Use32BitRegistry -ResolveVars -DetailedLog
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True)]
		[ValidateNotNullorEmpty()]
		[string]$File,
		[Parameter(Mandatory=$false)]
		[switch]$ContinueOnError,
		[Parameter(Mandatory=$false)]
		[switch]$ResolveVars,
		[Parameter(Mandatory=$false)]
		[switch]$Use32BitRegistry,
		[Parameter(Mandatory=$false)]
		[switch]$DetailedLog

	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {

            # check for reg file existence
            If (-not (Test-Path -LiteralPath $File -PathType 'Leaf')) { Throw "File [$File] not found." }

            # Read reg file
            $TmpRegFile = Get-Content -Path $File 
            
            # Generate temp file name for temp reg file
            [string]$ResolvedRegFile = Join-Path -Path $temp -ChildPath ([IO.Path]::GetFileName(([IO.Path]::GetTempFileName()))) -ErrorAction 'Stop'

            # write reg file content to log
            write-Log -message "Content of [$File]" -Source ${CmdletName} 
            foreach ($RegLine in $TmpRegFile) {

                # Expand variables in registry keys
                If ($ResolveVars -eq $true) {
                    #Resolve variables
                    if ($RegLine) { $RegLine = Expand-Variable -InputString $RegLine }

                    # Write new reg file with resolved variables
                    Add-Content $ResolvedRegFile $RegLine
                }

                # Write every registry keys to the log file (when enabled)
                if ($DetailedLog -eq $true) {
                    if ($RegLine) {
                        write-Log -message "$RegLine" -Source ${CmdletName}
                    } 
                }
            }

            # When resolve vars is active use temp file for the import
            If ($ResolveVars -eq $true) {
                $File = $ResolvedRegFile
            }

            # Perform reg import
            if ($Use32BitRegistry -ieq $true) { 
                Start-Program -Path "reg.exe" -Parameters "import ""$File"" /reg:32"
            }
            else {
                Start-Program -Path "reg.exe" -Parameters "import ""$File"""
            }

            # Delete temp reg file
            If (Test-Path -LiteralPath $ResolvedRegFile -PathType 'Leaf') {Remove-File -LiteralPath $ResolvedRegFile -ContinueOnError $True}
            
		}
		Catch {
                Write-Log -Message "Failed to bulk import registry keys via .reg file. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
    			If (-not $ContinueOnError) {
				Throw "Failed to bulk import registry keys via .reg file.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Import-RegFile

#region Function New-File
Function New-File {
<#
.SYNOPSIS
	Create a new file if not exist.
.DESCRIPTION
	Create a new file if not exist.
.PARAMETER Path
	Path to the folder where the new file should be created.
.PARAMETER Filename
	Filename of the new file.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	New-File -Path "$WinDir\System32" -Filename "file.txt"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
   		[string]$Path,
        [Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Filename,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			$NewFile = [String]($Path + "\" + $Filename)
			If (-not (Test-Path -LiteralPath $NewFile -PathType 'Leaf')) {
				Write-Log -Message "Create file [$NewFile]." -Source ${CmdletName}
				$null = New-Item -Path $NewFile -ItemType 'file' -ErrorAction 'Stop'
			}
			Else {
				Write-Log -Message "File [$NewFile] already exists." -Source ${CmdletName}
			}
		}
		Catch {
			Write-Log -Message "Failed to create file [$NewFile]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to create file [$NewFile]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function New-Folder
Function New-Folder {
<#
.SYNOPSIS
	Create a new folder.
.DESCRIPTION
	Create a new folder if it does not exist.
.PARAMETER Path
	Path to the new folder to create.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	New-Folder -Path "$WinDir\System32"
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			If (-not (Test-Path -LiteralPath $Path -PathType 'Container')) {
				Write-Log -Message "Create folder [$Path]." -Source ${CmdletName}
				$null = New-Item -Path $Path -ItemType 'Directory' -ErrorAction 'Stop'
			}
			Else {
				Write-Log -Message "Folder [$Path] already exists." -Source ${CmdletName}
			}
		}
		Catch {
			Write-Log -Message "Failed to create folder [$Path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to create folder [$Path]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function New-LayoutmodificationXML
Function New-LayoutmodificationXML {
<#
.SYNOPSIS
	New-LayoutmodificationXML exports and modifies Windows 10 and Windows Server 2016 Start Menu Layouts
.DESCRIPTION
	This CMDLet can be used to modify Windows Start Layout XML Files
	Input can be provided by passing one or more Objects or using Parameters "AppName" and "AppFolder"
	Objects passed to this function must at least contain "AppName" and "AppFolder" properties.
	Supported by default is:
		- Output from ConvertFrom-AAPIni
		- ceterion Packaging Framework "Applications" Section from PackageConfigFile JSON
.PARAMETER TemplatePath
	TemplatePath ca be used to specify an already exported Layoutmodification.xml
	If no value is provided, The Layout fdrom the current computer will be exported and used as template 
.PARAMETER ExportPath
	Full Path, the Layoutmodification will be exported to (Default is  "$($env:TEMP)\LayoutModification.xml")
.PARAMETER InputObject
	One or more Objects containing at least "AppName" and "AppFolder" properties
	Supported by default is:
		- Output from ConvertFrom-AAPIni
		- ceterion Packaging Framework "Applications" Section from PackageConfigFile JSON
	Supports Pipeline Input	
.PARAMETER AppFolder
	Startmenu Folder containing the link to the pinned application.
	Is also used to represent Group Name in Start Layout
.PARAMETER AppName
	Application Name. Must match the Application Name used in Startmenu Link
.PARAMETER ForcePin
	Switch Parameter to pin applications, even if no .lnk file is found in classic Start Menu
.PARAMETER StartMenuPath
	Can be used to modify Path to Start Menu Folder
.PARAMETER Purge
	Switch Parameter to remove all existing groups and Tiles from Template or exported Layoutmodification.xml
.PARAMETER Excludes
	Accepts an array of one or more strings with Applicationnames to ignore 
.EXAMPLE
	New-LayoutmodificationXML -AppName "MyApp" -FolderName "MyFolder"
.EXAMPLE
	New-LayoutmodificationXML -AppName "MyApp" -FolderName "MyFolder" -TemplatePath "C:\Temp\LayoutModificationTemplate.xml" -exportpath "C:\Temp\LayoutModification.xml" -ForcePin -StartMenuPath "$env:Programdata\Microsoft\Windows\Start Menu\Programs"
.EXAMPLE
	$MyAAPObject = ConvertFrom-AAPINI -Path "C:\Program Files (x86)\visionapp\vCT\AAP.ini"
	New-LayoutmodificationXML -InputObject $MyAAPObject
.EXAMPLE
	$MyAAPObject = ConvertFrom-AAPINI -Path "C:\Program Files (x86)\visionapp\vCT\AAP.ini"
	$MyAAPObject | New-LayoutmodificationXML -exportpath "C:\Temp\LayoutModification.xml" -ForcePin
.EXAMPLE
	$PackageConfigFile.Applications | New-LayoutmodificationXML -exportpath "C:\Temp\LayoutModification.xml" -ForcePin
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding(DefaultParameterSetName='None')]   
	param(
		## Input Template
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$TemplatePath = $null,
		
		## Export Path
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$ExportPath = "$($env:TEMP)\LayoutModification.xml",
		
		## One or more Objects containing Application Information
		[Parameter(ParameterSetName='Object')]
		[Parameter(
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		$InputObject,
		
		## AppFolder
		[Parameter(ParameterSetName='Single',Mandatory=$true)]
		[string]$AppFolder,
		
		## AppName
		[Parameter(ParameterSetName='Single',Mandatory=$true)]
		[string]$AppName,
	
		## ForcePin
		[parameter(Mandatory=$false)]
		[switch]$ForcePin = $false,

		## Prevent CMDLet from importing the LayoutModificationXML
		[parameter(Mandatory=$false)]
		[switch]$NoImport = $false,
		
		## Start Menu Path
		[Parameter(Mandatory=$false)]
		[string]$StartMenuPath = $CommonStartMenuPrograms,

		## Purge 
		[Parameter(Mandatory=$false)]
		[switch]$Purge = $false,

		## Purge 
		[Parameter(Mandatory=$false)]
		$Excludes
	)
		Begin {
			## Get the name of this function and write header
			[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	
			
			$ParamSetName = $PsCmdLet.ParameterSetName
			Write-Log -Message "ParametersetName is $ParamSetName" -Severity 1 -Source ${CmdletName}
	
			if ($ParamSetName -eq "Single") {
				$Inputobject = [PSCustomObject]@{
					AppName = $AppName
					AppFolder = $AppFolder
					}
			}
	
			switch ($StartMenuPath) {
				"$env:Programdata\Microsoft\Windows\Start Menu\Programs" { 
					$StartmenuRoot = "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs" 
				}
				"$Env:APPDATA\Microsoft\Windows\Start Menu\Programs" {
					$StartmenuRoot = "%APPDATA%\Microsoft\Windows\Start Menu\Programs"
				}
				"" {
					$StartMenuPath = "$env:Programdata\Microsoft\Windows\Start Menu\Programs"
					$StartmenuRoot = "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs"
				}
				Default{
					$StartMenuPath = "$env:Programdata\Microsoft\Windows\Start Menu\Programs"
					$StartmenuRoot = "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs"
				}
			}
			if (!$TemplatePath) {
				Write-Log -Message "Template Path not provided, exporting current layout to $($env:TEMP)\Layoutmodificationexport.xml" -Severity 1 -Source ${CmdletName}
				$TemplatePath = "$($env:TEMP)\Layoutmodificationexport.xml"
				Export-StartLayout -Path $TemplatePath
				
			}
			# Load exported LayoutModification XML from Template Path
			try{
				[xml]$LayoutModification = get-content $TemplatePath
				}
			catch [exception]{
				Write-Log -Message "Unexpected error . `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Unexpected error.: $($_.Exception.Message)"
				}
			}
	
			## get Schema definitions from existing xml file
			$namespace = @{}
			
			## Get all Nodes with Namespace Attribute
			$NamespaceAttributes = $LayoutModification.SelectNodes('//*').Attributes | where {$_.Prefix -eq 'xmlns'}
			foreach($Namespaceattribute in $NamespaceAttributes){
				
				# if attribute localname is not empty
				if($Namespaceattribute.LocalName){
					# if Namespace isn't present in namespaces table, yet
					if(!$namespace.$($Namespaceattribute.localname)){
						## add namespace name and URI to Hash Table
						$namespace.Add($Namespaceattribute.LocalName,$Namespaceattribute.'#text')
					}
				}
			}
			
			## Remove all Group Nodes to start with a blank Layout, if -purge Parameter has been provided
			if ($Purge) {
				Write-Log -Message "Purging exported Layout" -Severity 1 -Source ${CmdletName}
				$StartLayoutNodes = select-xml -xml $LayoutModification -XPath "//defaultlayout:StartLayout" -Namespace $namespace

				foreach ($StartLayoutNode in $StartLayoutNodes) {
					$StartLayoutNode.Node.removeall()
				}
			}
			
			## Set Maximum Amount of Columns within a group
			$MaxColumn = 6
			
			## Set Maximum Amount of Rows within a group
			$MaxRow = 8
		}
		Process {
			foreach ($Application in $InputObject) {			
				Try {
					Write-Log -Message "processing $($Application.AppName)" -Severity 1 -Source ${CmdletName} -DebugMessage
					
					if ($Excludes -contains $Application.AppName) {
						throw "Application excluded"
					}

					if($Application.AppFolder){
						$AppFolder = $($Application.AppFolder)
					}
					else{
						$AppFolder = "Misc"
					}
					$LinkPath = "$StartmenuRoot\$AppFolder\$($Application.AppName).lnk"
					$PSLinkPath = "$StartmenuPath\$AppFolder\$($Application.AppName).lnk"
					
					## check, if an appropriate Link is found
					if (!(Test-Path -Path "$PSLinkPath")) {
						## If not, and Forcepin Parameter is not provided, skip current pinning operation
						if (!$ForcePin) {
						
							Throw [System.IO.FileNotFoundException] "$LinkPath not found, processing next Shortcut"
						}
					}
					
					Write-Log "Fetching Group $AppFolder" -Severity 1 -Source ${CmdletName}
					$GroupNode = $(select-xml -xml $LayoutModification -XPath "//start:Group[@Name='$AppFolder']" -Namespace $namespace).Node 2>&1
					
					## Create new Group Node
					if (!$GroupNode) {
						Write-Log "Creating new Group $AppFolder" -Severity 1 -Source ${CmdletName}
						$StartLayoutNode = select-xml -xml $LayoutModification -XPath "//defaultlayout:StartLayout" -Namespace $namespace
						$GroupNode = $LayoutModification.CreateElement("start","Group",$namespace.start) 
						$NameAttribute = $LayoutModification.CreateAttribute('Name') 
						$NameAttribute.Value = $AppFolder
						$GroupNode.Attributes.Append($NameAttribute) 
	
						
						$StartLayoutNode.Node.AppendChild($GroupNode) 
						
						$GroupNode = $(select-xml -xml $LayoutModification -XPath "//start:Group[@Name='$AppFolder']" -Namespace $namespace).Node  
						$Row = 0
						$Column = 0
					}
					else {
						$MaxRowNode = $GroupNode.LastChild
						[int]$Row = ($MaxRowNode.Attributes | where {$_.Name -eq "Row"}).Value
						[int]$Column = ($MaxRowNode.Attributes | where {$_.Name -eq "Column"}).Value
						$SizeAttribute = ($MaxRowNode.Attributes | where {$_.Name -eq "Size"}).Value
	
						Write-Log -Message "Last Tile in group $AppFolder is $SizeAttribute with Row $Row and Column $Column" -severity 2 -Source ${CmdletName} -DebugMessage
	
						## Split SizeAttribute
						$TileSize = $SizeAttribute.split("x")
						
						## Calculate Start Coordinates for current Tile
						## Increment Coordinates based on Max Column and Tile Size
						if($Column + $TileSize[1] -lt $MaxColumn){
							$Column = $Column + $TileSize[1]
							
						}
						elseif ($Row + $TileSize[0] -lt $MaxRow){
							$Row = $Row + $TileSize[0]
							$Column = 0
						}
						else { 
							throw "Maximum Tiles in Group reached"
						}
					}
					
					Write-Log -Message "Creating Tile in group $AppFolder with Size 2x2 in Row $Row and Column $Column" -severity 1 -Source ${CmdletName} 
					## Create new Application Tile Node
					$DesktopApplicationTileNode = $LayoutModification.CreateElement("start","DesktopApplicationTile",$namespace.start) 2>&1
					
					# Set Size
					$SizeAttribute = $LayoutModification.CreateAttribute('Size')
					$SizeAttribute.Value = '2x2'
					$DesktopApplicationTileNode.Attributes.Append($SizeAttribute) 
	
					# Build "Column" Attribute and attach to Tile-Node
					$ColumnAttribute = $LayoutModification.CreateAttribute('Column')
					$ColumnAttribute.Value = $Column
					$DesktopApplicationTileNode.Attributes.Append($ColumnAttribute) 
	
					# Build "Row" Attribute and attach to Tile Node to 
					$RowAttribute = $LayoutModification.CreateAttribute('Row')
					$RowAttribute.Value = $Row
					$DesktopApplicationTileNode.Attributes.Append($RowAttribute) 
					
					$DesktopApplicationLinkPathAttribute = $LayoutModification.CreateAttribute('DesktopApplicationLinkPath') 
					$DesktopApplicationLinkPathAttribute.Value = $LinkPath
					$DesktopApplicationTileNode.Attributes.Append($DesktopApplicationLinkPathAttribute) 
				
                    $GroupNode.AppendChild($DesktopApplicationTileNode)  

                    
				}
				Catch [System.IO.FileNotFoundException] {
					Write-Log -Message "$LinkPath not found, processing next Shortcut" -Severity 2 -Source ${CmdletName}
				}
				Catch {
					if ($_.Exception.Message -eq "Maximum Tiles in Group reached") {
						
						Write-Log -Message "Maximum Tiles in Group $AppFolder reached, cannot add $($Application.appname)" -severity 2 -Source ${CmdletName}
					}
					elseif ($_.Exception.Message -eq "Application excluded") {
						Write-Log -Message "$($Application.appname) found in excludes, processing next" -severity 2 -Source ${CmdletName}
					}
					else{
						Write-Log -Message "Unexpected error . `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
						If (-not $ContinueOnError) {
							Throw "Unexpected error.: $($_.Exception.Message)"
						}
					}
				}
			}
		}
		End {
            Write-Log -Message "Exporting modified Layout to $ExportPath" -Severity 1 -Source ${CmdletName}
			$LayoutModification.save($ExportPath) 
			if (!$NoImport) {
				Write-Log -Message "Re-Importing the modified Layout $ExportPath to $env:SystemDrive" -Severity 1 -Source ${CmdletName}
				Import-StartLayout -LayoutPath $ExportPath -MountPath "$env:SystemDrive\" 
			}

			Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
		}
	}
	#endregion Function New-LayoutModificationXML

#region Function New-MsiTransform
Function New-MsiTransform {
<#
.SYNOPSIS
	Create a transform file for an MSI database.
.DESCRIPTION
	Create a transform file for an MSI database and create/modify properties in the Properties table.
.PARAMETER MsiPath
	Specify the path to an MSI file.
.PARAMETER ApplyTransformPath
	Specify the path to a transform which should be applied to the MSI database before any new properties are created or modified.
.PARAMETER NewTransformPath
	Specify the path where the new transform file with the desired properties will be created. If a transform file of the same name already exists, it will be deleted before a new one is created.
	Default is: a) If -ApplyTransformPath was specified but not -NewTransformPath, then <ApplyTransformPath>.new.mst
				b) If only -MsiPath was specified, then <MsiPath>.mst
.PARAMETER TransformProperties
	Hashtable which contains calls to Set-MsiProperty for configuring the desired properties which should be included in new transform file.
	Example hashtable: [hashtable]$TransformProperties = @{ 'ALLUSERS' = '1' }
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	[hashtable]$TransformProperties = {
		'ALLUSERS' = '1'
		'AgreeToLicense' = 'Yes'
		'REBOOT' = 'ReallySuppress'
		'RebootYesNo' = 'No'
		'ROOTDRIVE' = 'C:'
	}
	New-MsiTransform -MsiPath 'C:\Temp\PSADTInstall.msi' -TransformProperties $TransformProperties
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateScript({ Test-Path -LiteralPath $_ -PathType 'Leaf' })]
		[string]$MsiPath,
		[Parameter(Mandatory=$false)]
		[ValidateScript({ Test-Path -LiteralPath $_ -PathType 'Leaf' })]
		[string]$ApplyTransformPath,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$NewTransformPath,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[hashtable]$TransformProperties,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		## Define properties for how the MSI database is opened
		[int32]$msiOpenDatabaseModeReadOnly = 0
		[int32]$msiOpenDatabaseModeTransact = 1
		[int32]$msiViewModifyUpdate = 2
		[int32]$msiViewModifyReplace = 4
		[int32]$msiViewModifyDelete = 6
		[int32]$msiTransformErrorNone = 0
		[int32]$msiTransformValidationNone = 0
		[int32]$msiSuppressApplyTransformErrors = 63
	}
	Process {
		Try {
			Write-Log -Message "Create a transform file for MSI [$MsiPath]." -Source ${CmdletName}
			
			## Discover the parent folder that the MSI file resides in
			[string]$MsiParentFolder = Split-Path -Path $MsiPath -Parent -ErrorAction 'Stop'
			
			## Create a temporary file name for storing a second copy of the MSI database
			[string]$TempMsiPath = Join-Path -Path $MsiParentFolder -ChildPath ([IO.Path]::GetFileName(([IO.Path]::GetTempFileName()))) -ErrorAction 'Stop'
			
			## Create a second copy of the MSI database
			Write-Log -Message "Copy MSI database in path [$MsiPath] to destination [$TempMsiPath]." -Source ${CmdletName}
			$null = Copy-Item -LiteralPath $MsiPath -Destination $TempMsiPath -Force -ErrorAction 'Stop'
			
			## Create a Windows Installer object
			[__comobject]$Installer = New-Object -ComObject 'WindowsInstaller.Installer' -ErrorAction 'Stop'
			
			## Open both copies of the MSI database
			#  Open the original MSI database in read only mode
			Write-Log -Message "Open the MSI database [$MsiPath] in read only mode." -Source ${CmdletName}
			[__comobject]$MsiPathDatabase = Invoke-ObjectMethod -InputObject $Installer -MethodName 'OpenDatabase' -ArgumentList @($MsiPath, $msiOpenDatabaseModeReadOnly)
			#  Open the temporary copy of the MSI database in view/modify/update mode
			Write-Log -Message "Open the MSI database [$TempMsiPath] in view/modify/update mode." -Source ${CmdletName}
			[__comobject]$TempMsiPathDatabase = Invoke-ObjectMethod -InputObject $Installer -MethodName 'OpenDatabase' -ArgumentList @($TempMsiPath, $msiViewModifyUpdate)
			
			## If a MSI transform file was specified, then apply it to the temporary copy of the MSI database
			If ($ApplyTransformPath) {
				Write-Log -Message "Apply transform file [$ApplyTransformPath] to MSI database [$TempMsiPath]." -Source ${CmdletName}
				$null = Invoke-ObjectMethod -InputObject $TempMsiPathDatabase -MethodName 'ApplyTransform' -ArgumentList @($ApplyTransformPath, $msiSuppressApplyTransformErrors)
			}
			
			## Determine the path for the new transform file that will be generated
			If (-not $NewTransformPath) {
				If ($ApplyTransformPath) {
					[string]$NewTransformFileName = [IO.Path]::GetFileNameWithoutExtension($ApplyTransformPath) + '.new' + [IO.Path]::GetExtension($ApplyTransformPath)
				}
				Else {
					[string]$NewTransformFileName = [IO.Path]::GetFileNameWithoutExtension($MsiPath) + '.mst'
				}
				[string]$NewTransformPath = Join-Path -Path $MsiParentFolder -ChildPath $NewTransformFileName -ErrorAction 'Stop'
			}
			
			## Set the MSI properties in the temporary copy of the MSI database
			$TransformProperties.GetEnumerator() | ForEach-Object { Set-MsiProperty -DataBase $TempMsiPathDatabase -PropertyName $_.Key -PropertyValue $_.Value }
			
			## Commit the new properties to the temporary copy of the MSI database
			$null = Invoke-ObjectMethod -InputObject $TempMsiPathDatabase -MethodName 'Commit'
			
			## Reopen the temporary copy of the MSI database in read only mode
			#  Release the database object for the temporary copy of the MSI database
			$null = [Runtime.Interopservices.Marshal]::ReleaseComObject($TempMsiPathDatabase)
			#  Open the temporary copy of the MSI database in read only mode
			Write-Log -Message "Re-open the MSI database [$TempMsiPath] in read only mode." -Source ${CmdletName}
			[__comobject]$TempMsiPathDatabase = Invoke-ObjectMethod -InputObject $Installer -MethodName 'OpenDatabase' -ArgumentList @($TempMsiPath, $msiOpenDatabaseModeReadOnly)
			
			## Delete the new transform file path if it already exists
			If (Test-Path -LiteralPath $NewTransformPath -PathType 'Leaf' -ErrorAction 'Stop') {
				Write-Log -Message "A transform file of the same name already exists. Deleting transform file [$NewTransformPath]." -Source ${CmdletName}
				$null = Remove-Item -LiteralPath $NewTransformPath -Force -ErrorAction 'Stop'
			}
			
			## Generate the new transform file by taking the difference between the temporary copy of the MSI database and the original MSI database
			Write-Log -Message "Generate new transform file [$NewTransformPath]." -Source ${CmdletName}
			$null = Invoke-ObjectMethod -InputObject $TempMsiPathDatabase -MethodName 'GenerateTransform' -ArgumentList @($MsiPathDatabase, $NewTransformPath)
			$null = Invoke-ObjectMethod -InputObject $TempMsiPathDatabase -MethodName 'CreateTransformSummaryInfo' -ArgumentList @($MsiPathDatabase, $NewTransformPath, $msiTransformErrorNone, $msiTransformValidationNone)
			
			If (Test-Path -LiteralPath $NewTransformPath -PathType 'Leaf' -ErrorAction 'Stop') {
				Write-Log -Message "Successfully created new transform file in path [$NewTransformPath]." -Source ${CmdletName}
			}
			Else {
				Throw "Failed to generate transform file in path [$NewTransformPath]."
			}
		}
		Catch {
			Write-Log -Message "Failed to create new transform file in path [$NewTransformPath]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to create new transform file in path [$NewTransformPath]: $($_.Exception.Message)"
			}
		}
		Finally {
			Try { $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($TempMsiPathDatabase) } Catch { }
			Try { $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($MsiPathDatabase) } Catch { }
			Try { $null = [Runtime.Interopservices.Marshal]::ReleaseComObject($Installer) } Catch { }
			Try {
				## Delete the temporary copy of the MSI database
				If (Test-Path -LiteralPath $TempMsiPath -PathType 'Leaf' -ErrorAction 'Stop') {
					$null = Remove-Item -LiteralPath $TempMsiPath -Force -ErrorAction 'Stop'
				}
			}
			Catch { }
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function New-Package
Function New-Package {
<#
.SYNOPSIS
	Create a new package
.DESCRIPTION
	Create a new package base on the default template and naming scheme
.PARAMETER Path
	Specify the path wher to create the package
.PARAMETER Name
	Specify the package name (based on the naming scheme configured in PackageFramework.json)
.PARAMETER ExcludeModuleFiles
	Don't copy module files into the package folder
.EXAMPLE	
    New-Package -Path C:\Temp -Name 'Microsoft_Office_16.0_EN_01.00'
.EXAMPLE	
    New-Package -Path C:\Temp -Name 'Microsoft_Project_16.0_EN_01.00' -ExcludeModuleFiles
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
   		[string]$Path,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[switch]$ExcludeModuleFiles
	)

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try
        {
            
            # Check if script is initialize
            if (-not($ModuleConfigFile)) {  Throw "Please run Initialize-Script befor you run this command" }

            # Check package name against naming scheme, abort if not valid
            $NameSchemeTestResult = Test-PackageName -Name $Name
            If ($NameSchemeTestResult -eq $false) { Throw "The package name [$name] doesn't match the naming scheme" }

            # Check if package exists, abort if already exists
            If(Test-path -Path $Path\$Name -PathType Container) { Throw "The folder [$Path\$Name] already exists, package creation aborted" }

            # Create new package folder
            New-Folder -path "$Path\$Name"
            
            # Create new files folder inside the package folder
            New-Folder -path "$Path\$Name\Files"

            # Copy packageing Framework module fiels (if ExcludeModuleFiles is not specified)
            if (-not ($ExcludeModuleFiles)) 
            {
                $ModuleBaseMain = $((Get-Module -Name PackagingFramework).ModuleBase)
                $ModuleBaseExtension = $((Get-Module -Name PackagingFrameworkExtension).ModuleBase)
                Copy-File "$ModuleBaseMain\PackagingFramework*.*" "$Path\$Name\PackagingFramework"
                Copy-File "$ModuleBaseExtension\PackagingFramework*.*" "$Path\$Name\PackagingFramework"
            }

            # Create PS1 file
[string]$TemplateFile = @"
[CmdletBinding()] Param ([Parameter(Mandatory=`$false)] [ValidateSet('Install','Uninstall')] [string]`$DeploymentType='Install', [Parameter(Mandatory=`$false)] [ValidateSet('Interactive','Silent','NonInteractive')] [string]`$DeployMode='Interactive')
Try {

    # Import Packaging Framework module
    if (Test-Path '.\PackagingFramework\PackagingFramework.psd1') {Import-Module .\PackagingFramework\PackagingFramework.psd1 -force ; Initialize-Script} else {if (Test-Path '.\PackagingFramework\PackagingFramework.psd1') {Import-Module .\PackagingFramework\PackagingFramework.psd1 -force ; Initialize-Script} else {Import-Module PackagingFramework -force ; Initialize-Script}}

    # Install
    If (`$deploymentType -ieq 'Install') {
        # <PLACE YOUR CODE HERE>
    }

    # Uninstall
    If (`$deploymentType -ieq 'Uninstall') {
        # <PLACE YOUR CODE HERE>
    }

    # Call the exit-Script
    Exit-Script -ExitCode `$mainExitCode

}
Catch { [int32]`$mainExitCode = 60001; [string]`$mainErrorMessage = "`$(Resolve-Error)" ; Write-Log -Message `$mainErrorMessage -Severity 3 -Source `$PackagingFrameworkName ; Show-DialogBox -Text `$mainErrorMessage -Icon 'Stop' ; Exit-Script -ExitCode `$mainExitCode}
"@
# Save the PS1 file
Write-Log "Create $Name.ps1" -Source "Out-File"
$TemplateFile | Out-File -FilePath "$Path\$Name\$Name.ps1" -Encoding utf8

# Create JSON file
[string]$TemplateFile = @"
{
  "Package": {
    "PackageDate": "$(Get-Date -Format d)",
    "PackageAuthor": "$env:USERNAME",
    "PackageDescription": "$AppVendor $AppName $AppVersion"
  },
  "Applications": [
    {
      "AppName": "$AppName",
      "AppFolder": "$AppName",
      "AppCommandLineExecutable": "`$ProgramFiles\\$AppName\\$AppName.exe",
      "AppCommandLineArguments": "",
      "AppWorkingDirectory": "`$ProgramFiles\\$AppName\\",
      "AppAccounts": [ ]
    }
  ],
  "DetectionMethods": [ ],
  "Dependencies": [ ],
  "Parameters": { },
  "Notes": [ ],
  "ChangeLog": [
    "Version 1.0 initial release"
  ]
}
"@
        # Save the Json file
        Write-Log "Create $Name.json" -Source "Out-File"
        $TemplateFile | Out-File -FilePath "$Path\$Name\$Name.json" -Encoding Unicode
		}
		Catch {
			Write-Log -Message "Failed to create package. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
            Throw "Failed to create package: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function New-Shortcut
Function New-Shortcut {
<#
.SYNOPSIS
	Creates a new .lnk or .url type shortcut
.DESCRIPTION
	Creates a new shortcut .lnk or .url file, with configurable options
.PARAMETER Path
	Path to save the shortcut
.PARAMETER TargetPath
	Target path or URL that the shortcut launches
.PARAMETER Arguments
	Arguments to be passed to the target path
.PARAMETER IconLocation
	Location of the icon used for the shortcut
.PARAMETER IconIndex
	Executables, DLLs, ICO files with multiple icons need the icon index to be specified
.PARAMETER Description
	Description of the shortcut
.PARAMETER WorkingDirectory
	Working Directory to be used for the target path
.PARAMETER WindowStyle
	Windows style of the application. Options: Normal, Maximized, Minimized. Default is: Normal.
.PARAMETER RunAsAdmin
	Set shortcut to run program as administrator. This option will prompt user to elevate when executing shortcut.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	New-Shortcut -Path "$ProgramData\Microsoft\Windows\Start Menu\My Shortcut.lnk" -TargetPath "$WinDir\system32\notepad.exe" -IconLocation "$WinDir\system32\notepad.exe" -Description 'Notepad' -WorkingDirectory "$HomeDrive\$HomePath"
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$TargetPath,
		[Parameter(Mandatory=$false)]
		[string]$Arguments,
		[Parameter(Mandatory=$false)]
		[string]$IconLocation,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$IconIndex,
		[Parameter(Mandatory=$false)]
		[string]$Description,
		[Parameter(Mandatory=$false)]
		[string]$WorkingDirectory,
		[Parameter(Mandatory=$false)]
		[ValidateSet('Normal','Maximized','Minimized')]
		[string]$WindowStyle,
		[Parameter(Mandatory=$false)]
		[Switch]$RunAsAdmin,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		If (-not $Shell) { [__comobject]$Shell = New-Object -ComObject 'WScript.Shell' -ErrorAction 'Stop' }
	}
	Process {
		Try {
			Try {
				[IO.FileInfo]$Path = [IO.FileInfo]$Path
				[string]$PathDirectory = $Path.DirectoryName
				
				If (-not (Test-Path -LiteralPath $PathDirectory -PathType 'Container' -ErrorAction 'Stop')) {
					Write-Log -Message "Create shortcut directory [$PathDirectory]." -Source ${CmdletName}
					$null = New-Item -Path $PathDirectory -ItemType 'Directory' -Force -ErrorAction 'Stop'
				}
			}
			Catch {
				Write-Log -Message "Failed to create shortcut directory [$PathDirectory]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Throw
			}
			
			Write-Log -Message "Create shortcut [$($path.FullName)]." -Source ${CmdletName}
			If (($path.FullName).EndsWith('.url')) {
				[string[]]$URLFile = '[InternetShortcut]'
				$URLFile += "URL=$targetPath"
				If ($iconIndex) { $URLFile += "IconIndex=$iconIndex" }
				If ($IconLocation) { $URLFile += "IconFile=$iconLocation" }
				$URLFile | Out-File -FilePath $path.FullName -Force -Encoding 'default' -ErrorAction 'Stop'
			}
			ElseIf (($path.FullName).EndsWith('.lnk')) {
				If (($iconLocation -and $iconIndex) -and (-not ($iconLocation.Contains(',')))) {
					$iconLocation = $iconLocation + ",$iconIndex"
				}
				Switch ($windowStyle) {
					'Normal' { $windowStyleInt = 1 }
					'Maximized' { $windowStyleInt = 3 }
					'Minimized' { $windowStyleInt = 7 }
					Default { $windowStyleInt = 1 }
				}
				$shortcut = $shell.CreateShortcut($path.FullName)
				$shortcut.TargetPath = $targetPath
                if ($arguments) { $shortcut.Arguments = $arguments }
				if ($description) { $shortcut.Description = $description }
				if ($workingDirectory) { $shortcut.WorkingDirectory = $workingDirectory }
				if ($windowStyleInt) { $shortcut.WindowStyle = $windowStyleInt }
				If ($iconLocation) { $shortcut.IconLocation = $iconLocation }
				$shortcut.Save()
				
				## Set shortcut to run program as administrator
				If ($RunAsAdmin) {
					Write-Log -Message 'Set shortcut to run program as administrator.' -Source ${CmdletName}
					$TempFileName = [IO.Path]::GetRandomFileName()
					$TempFile = [IO.FileInfo][IO.Path]::Combine($Path.Directory, $TempFileName)
					$Writer = New-Object -TypeName 'System.IO.FileStream' -ArgumentList ($TempFile, ([IO.FileMode]::Create)) -ErrorAction 'Stop'
					$Reader = $Path.OpenRead()
					While ($Reader.Position -lt $Reader.Length) {
						$Byte = $Reader.ReadByte()
						If ($Reader.Position -eq 22) { $Byte = 34 }
						$Writer.WriteByte($Byte)
					}
					$Reader.Close()
					$Writer.Close()
					$Path.Delete()
					$null = Rename-Item -Path $TempFile -NewName $Path.Name -Force -ErrorAction 'Stop'
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to create shortcut [$($path.FullName)]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to create shortcut [$($path.FullName)]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Remove-EnvironmentVariable
Function Remove-EnvironmentVariable {
<#
.SYNOPSIS
	Remove an environment variable
.DESCRIPTION
	Remove an environment variable
.PARAMETER Name
    Name of the environment variable
.PARAMETER Target
    Target of the environment variable, possible values are Process or User or Machine
.EXAMPLE
	Remove-EnvironmentVariable 'TestVar1'
.EXAMPLE
	Remove-EnvironmentVariable -Name 'TestVar2' -Target 'Machine'
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
    [Cmdletbinding()]
    param
    ( 
        [Parameter(Mandatory=$True,Position=0)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory=$false,Position=2)]
		[ValidateSet('Process','User','Machine')]
		[String]$Target = 'Process'
    )

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
                [environment]::SetEnvironmentVariable("$Name",$null,"$Target")
                Write-Log "[$Name] from [$Target]" -Source ${CmdletName}
        }

		Catch {
                Write-Log -Message "Failed to remove [$Name]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Throw "Failed to remove [$Name].: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Remove-EnvironmentVariable

#region Function Remove-File
Function Remove-File {
<#
.SYNOPSIS
	Removes one or more items from a given path on the filesystem.
.DESCRIPTION
	Removes one or more items from a given path on the filesystem.
.PARAMETER Path
	Specifies the path on the filesystem to be resolved. The value of Path will accept wildcards. Will accept an array of values.
.PARAMETER LiteralPath
	Specifies the path on the filesystem to be resolved. The value of LiteralPath is used exactly as it is typed; no characters are interpreted as wildcards. Will accept an array of values.
.PARAMETER Recurse
	Deletes the files in the specified location(s) and in all child items of the location(s).
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Remove-File -Path 'C:\Windows\Downloaded Program Files\Temp.inf'
.EXAMPLE
	Remove-File -LiteralPath 'C:\Windows\Downloaded Program Files' -Recurse
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,ParameterSetName='Path')]
		[ValidateNotNullorEmpty()]
		[string[]]$Path,
		[Parameter(Mandatory=$true,ParameterSetName='LiteralPath')]
		[ValidateNotNullorEmpty()]
		[string[]]$LiteralPath,
		[Parameter(Mandatory=$false)]
		[Switch]$Recurse = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		## Build hashtable of parameters/value pairs to be passed to Remove-Item cmdlet
		[hashtable]$RemoveFileSplat =  @{ 'Recurse' = $Recurse
										  'Force' = $true
										  'ErrorVariable' = '+ErrorRemoveItem'
										}
		If ($ContinueOnError) {
			$RemoveFileSplat.Add('ErrorAction', 'SilentlyContinue')
		}
		Else {
			$RemoveFileSplat.Add('ErrorAction', 'Stop')
		}
		
		## Resolve the specified path, if the path does not exist, display a warning instead of an error
		If ($PSCmdlet.ParameterSetName -eq 'Path') { [string[]]$SpecifiedPath = $Path } Else { [string[]]$SpecifiedPath = $LiteralPath }
		ForEach ($Item in $SpecifiedPath) {
			Try {
				If ($PSCmdlet.ParameterSetName -eq 'Path') {
					[string[]]$ResolvedPath += Resolve-Path -Path $Item -ErrorAction 'Stop' | Where-Object { $_.Path } | Select-Object -ExpandProperty 'Path' -ErrorAction 'Stop'
				}
				Else {
					[string[]]$ResolvedPath += Resolve-Path -LiteralPath $Item -ErrorAction 'Stop' | Where-Object { $_.Path } | Select-Object -ExpandProperty 'Path' -ErrorAction 'Stop'
				}
			}
			Catch [System.Management.Automation.ItemNotFoundException] {
				Write-Log -Message "Unable to resolve file(s) for deletion in path [$Item] because path does not exist." -Severity 2 -Source ${CmdletName}
			}
			Catch {
				Write-Log -Message "Failed to resolve file(s) for deletion in path [$Item]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to resolve file(s) for deletion in path [$Item]: $($_.Exception.Message)"
				}
			}
		}
		
		## Delete specified path if it was successfully resolved
		If ($ResolvedPath) {
			ForEach ($Item in $ResolvedPath) {
				Try {
					If (($Recurse) -and (Test-Path -LiteralPath $Item -PathType 'Container')) {
						Write-Log -Message "Delete file(s) recursively in path [$Item]..." -Source ${CmdletName}
					}
					Else {
						Write-Log -Message "Delete file in path [$Item]..." -Source ${CmdletName}
					}
					$null = Remove-Item @RemoveFileSplat -LiteralPath $Item
				}
				Catch {
					Write-Log -Message "Failed to delete file(s) in path [$Item]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
					If (-not $ContinueOnError) {
						Throw "Failed to delete file(s) in path [$Item]: $($_.Exception.Message)"
					}
				}
			}
		}
		
		If ($ErrorRemoveItem) {
			Write-Log -Message "The following error(s) took place while removing file(s) in path [$SpecifiedPath]. `n$(Resolve-Error -ErrorRecord $ErrorRemoveItem)" -Severity 2 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Remove-Folder
Function Remove-Folder {
<#
.SYNOPSIS
	Remove folder and files if they exist.
.DESCRIPTION
	Remove folder and all files recursively in a given path.
.PARAMETER Path
	Path to the folder to remove.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Remove-Folder -Path "$WinDir\Downloaded Program Files"
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
			If (Test-Path -LiteralPath $Path -PathType 'Container') {
				Try {
                    $result = Remove-Item -LiteralPath $Path -Force -Recurse -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorRemoveFolder' -verbose 4>&1
                    Write-Log $result
					If ($ErrorRemoveFolder) {
						Write-Log -Message "The following error(s) took place while deleting folder(s) and file(s) recursively from path [$path]. `n$(Resolve-Error -ErrorRecord $ErrorRemoveFolder)" -Severity 2 -Source ${CmdletName}
					}		
				}
				Catch {
					Write-Log -Message "Failed to delete folder(s) and file(s) recursively from path [$path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
					If (-not $ContinueOnError) {
						Throw "Failed to delete folder(s) and file(s) recursively from path [$path]: $($_.Exception.Message)"
					}
				}
			}
			Else {
				Write-Log -Message "Folder [$Path] does not exists..." -Source ${CmdletName}
			}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Remove-Font
Function Remove-Font {
<#
.SYNOPSIS
	Removes a font
.DESCRIPTION
	Uninstalles and unregister a font from the Windows Font folder
.PARAMETER File
	File name of the font (without path)
.EXAMPLE
	Remove-Font Arial.ttf
.NOTES
    Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True)]
		[ValidateNotNullorEmpty()]
		[string]$File
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
                Write-Log "Uninstalling [$File]" -Source ${CmdletName}
                
                ##############

                # Define constants
                set-variable CSIDL_FONTS 0x14

                # Create hashtable containing valid font file extensions and text to append to Registry entry name.
                $hashFontFileTypes = @{}
                $hashFontFileTypes.Add(".fon", "")
                $hashFontFileTypes.Add(".fnt", "")
                $hashFontFileTypes.Add(".ttf", " (TrueType)")
                $hashFontFileTypes.Add(".ttc", " (TrueType)")
                $hashFontFileTypes.Add(".otf", " (OpenType)")

                # Initialize variables
                $invocation = (Get-Variable MyInvocation -Scope 0).Value
                #$scriptPath = Split-Path $Invocation.MyCommand.Path
                $fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"


# Load C# code
$fontCSharpCode = @'
using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.Runtime.InteropServices;

namespace FontResource
{
    public class AddRemoveFonts
    {
        private static IntPtr HWND_BROADCAST = new IntPtr(0xffff);
        private static IntPtr HWND_TOP = new IntPtr(0);
        private static IntPtr HWND_BOTTOM = new IntPtr(1);
        private static IntPtr HWND_TOPMOST = new IntPtr(-1);
        private static IntPtr HWND_NOTOPMOST = new IntPtr(-2);
        private static IntPtr HWND_MESSAGE = new IntPtr(-3);

        [DllImport("gdi32.dll")]
        static extern int AddFontResource(string lpFilename);

        [DllImport("gdi32.dll")]
        static extern int RemoveFontResource(string lpFileName);

        [DllImport("user32.dll",CharSet=CharSet.Auto)]
        private static extern int SendMessage(IntPtr hWnd, WM wMsg, IntPtr wParam, IntPtr lParam);

        [return: MarshalAs(UnmanagedType.Bool)]
        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool PostMessage(IntPtr hWnd, WM Msg, IntPtr wParam, IntPtr lParam);

        public static int AddFont(string fontFilePath) {
            FileInfo fontFile = new FileInfo(fontFilePath);
            if (!fontFile.Exists) 
            {
                return 0; 
            }
            try 
            {
                int retVal = AddFontResource(fontFilePath);

                //This version of SendMessage is a blocking call until all windows respond.
                //long result = SendMessage(HWND_BROADCAST, WM.FONTCHANGE, IntPtr.Zero, IntPtr.Zero);

                //Alternatively PostMessage instead of SendMessage to prevent application hang
                bool posted = PostMessage(HWND_BROADCAST, WM.FONTCHANGE, IntPtr.Zero, IntPtr.Zero);

                return retVal;
            }
            catch
            {
                return 0;
            }
        }

        public static int RemoveFont(string fontFileName) {
            //FileInfo fontFile = new FileInfo(fontFileName);
            //if (!fontFile.Exists) 
            //{
            //    return false; 
            //}
            try 
            {
                int retVal = RemoveFontResource(fontFileName);

                //This version of SendMessage is a blocking call until all windows respond.
                //long result = SendMessage(HWND_BROADCAST, WM.FONTCHANGE, IntPtr.Zero, IntPtr.Zero);

                //Alternatively PostMessage instead of SendMessage to prevent application hang
                bool posted = PostMessage(HWND_BROADCAST, WM.FONTCHANGE, IntPtr.Zero, IntPtr.Zero);

                return retVal;
            }
            catch
            {
                return 0;
            }
        }

        public enum WM : uint
        {
            NULL = 0x0000,
            CREATE = 0x0001,
            DESTROY = 0x0002,
            MOVE = 0x0003,
            SIZE = 0x0005,
            ACTIVATE = 0x0006,
            SETFOCUS = 0x0007,
            KILLFOCUS = 0x0008,
            ENABLE = 0x000A,
            SETREDRAW = 0x000B,
            SETTEXT = 0x000C,
            GETTEXT = 0x000D,
            GETTEXTLENGTH = 0x000E,
            PAINT = 0x000F,
            CLOSE = 0x0010,
            QUERYENDSESSION = 0x0011,
            QUERYOPEN = 0x0013,
            ENDSESSION = 0x0016,
            QUIT = 0x0012,
            ERASEBKGND = 0x0014,
            SYSCOLORCHANGE = 0x0015,
            SHOWWINDOW = 0x0018,
            WININICHANGE = 0x001A,
            SETTINGCHANGE = WM.WININICHANGE,
            DEVMODECHANGE = 0x001B,
            ACTIVATEAPP = 0x001C,
            FONTCHANGE = 0x001D,
            TIMECHANGE = 0x001E,
            CANCELMODE = 0x001F,
            SETCURSOR = 0x0020,
            MOUSEACTIVATE = 0x0021,
            CHILDACTIVATE = 0x0022,
            QUEUESYNC = 0x0023,
            GETMINMAXINFO = 0x0024,
            PAINTICON = 0x0026,
            ICONERASEBKGND = 0x0027,
            NEXTDLGCTL = 0x0028,
            SPOOLERSTATUS = 0x002A,
            DRAWITEM = 0x002B,
            MEASUREITEM = 0x002C,
            DELETEITEM = 0x002D,
            VKEYTOITEM = 0x002E,
            CHARTOITEM = 0x002F,
            SETFONT = 0x0030,
            GETFONT = 0x0031,
            SETHOTKEY = 0x0032,
            GETHOTKEY = 0x0033,
            QUERYDRAGICON = 0x0037,
            COMPAREITEM = 0x0039,
            GETOBJECT = 0x003D,
            COMPACTING = 0x0041,
            COMMNOTIFY = 0x0044,
            WINDOWPOSCHANGING = 0x0046,
            WINDOWPOSCHANGED = 0x0047,
            POWER = 0x0048,
            COPYDATA = 0x004A,
            CANCELJOURNAL = 0x004B,
            NOTIFY = 0x004E,
            INPUTLANGCHANGEREQUEST = 0x0050,
            INPUTLANGCHANGE = 0x0051,
            TCARD = 0x0052,
            HELP = 0x0053,
            USERCHANGED = 0x0054,
            NOTIFYFORMAT = 0x0055,
            CONTEXTMENU = 0x007B,
            STYLECHANGING = 0x007C,
            STYLECHANGED = 0x007D,
            DISPLAYCHANGE = 0x007E,
            GETICON = 0x007F,
            SETICON = 0x0080,
            NCCREATE = 0x0081,
            NCDESTROY = 0x0082,
            NCCALCSIZE = 0x0083,
            NCHITTEST = 0x0084,
            NCPAINT = 0x0085,
            NCACTIVATE = 0x0086,
            GETDLGCODE = 0x0087,
            SYNCPAINT = 0x0088,
            NCMOUSEMOVE = 0x00A0,
            NCLBUTTONDOWN = 0x00A1,
            NCLBUTTONUP = 0x00A2,
            NCLBUTTONDBLCLK = 0x00A3,
            NCRBUTTONDOWN = 0x00A4,
            NCRBUTTONUP = 0x00A5,
            NCRBUTTONDBLCLK = 0x00A6,
            NCMBUTTONDOWN = 0x00A7,
            NCMBUTTONUP = 0x00A8,
            NCMBUTTONDBLCLK = 0x00A9,
            NCXBUTTONDOWN = 0x00AB,
            NCXBUTTONUP = 0x00AC,
            NCXBUTTONDBLCLK = 0x00AD,
            INPUT_DEVICE_CHANGE = 0x00FE,
            INPUT = 0x00FF,
            KEYFIRST = 0x0100,
            KEYDOWN = 0x0100,
            KEYUP = 0x0101,
            CHAR = 0x0102,
            DEADCHAR = 0x0103,
            SYSKEYDOWN = 0x0104,
            SYSKEYUP = 0x0105,
            SYSCHAR = 0x0106,
            SYSDEADCHAR = 0x0107,
            UNICHAR = 0x0109,
            KEYLAST = 0x0109,
            IME_STARTCOMPOSITION = 0x010D,
            IME_ENDCOMPOSITION = 0x010E,
            IME_COMPOSITION = 0x010F,
            IME_KEYLAST = 0x010F,
            INITDIALOG = 0x0110,
            COMMAND = 0x0111,
            SYSCOMMAND = 0x0112,
            TIMER = 0x0113,
            HSCROLL = 0x0114,
            VSCROLL = 0x0115,
            INITMENU = 0x0116,
            INITMENUPOPUP = 0x0117,
            MENUSELECT = 0x011F,
            MENUCHAR = 0x0120,
            ENTERIDLE = 0x0121,
            MENURBUTTONUP = 0x0122,
            MENUDRAG = 0x0123,
            MENUGETOBJECT = 0x0124,
            UNINITMENUPOPUP = 0x0125,
            MENUCOMMAND = 0x0126,
            CHANGEUISTATE = 0x0127,
            UPDATEUISTATE = 0x0128,
            QUERYUISTATE = 0x0129,
            CTLCOLORMSGBOX = 0x0132,
            CTLCOLOREDIT = 0x0133,
            CTLCOLORLISTBOX = 0x0134,
            CTLCOLORBTN = 0x0135,
            CTLCOLORDLG = 0x0136,
            CTLCOLORSCROLLBAR = 0x0137,
            CTLCOLORSTATIC = 0x0138,
            MOUSEFIRST = 0x0200,
            MOUSEMOVE = 0x0200,
            LBUTTONDOWN = 0x0201,
            LBUTTONUP = 0x0202,
            LBUTTONDBLCLK = 0x0203,
            RBUTTONDOWN = 0x0204,
            RBUTTONUP = 0x0205,
            RBUTTONDBLCLK = 0x0206,
            MBUTTONDOWN = 0x0207,
            MBUTTONUP = 0x0208,
            MBUTTONDBLCLK = 0x0209,
            MOUSEWHEEL = 0x020A,
            XBUTTONDOWN = 0x020B,
            XBUTTONUP = 0x020C,
            XBUTTONDBLCLK = 0x020D,
            MOUSEHWHEEL = 0x020E,
            MOUSELAST = 0x020E,
            PARENTNOTIFY = 0x0210,
            ENTERMENULOOP = 0x0211,
            EXITMENULOOP = 0x0212,
            NEXTMENU = 0x0213,
            SIZING = 0x0214,
            CAPTURECHANGED = 0x0215,
            MOVING = 0x0216,
            POWERBROADCAST = 0x0218,
            DEVICECHANGE = 0x0219,
            MDICREATE = 0x0220,
            MDIDESTROY = 0x0221,
            MDIACTIVATE = 0x0222,
            MDIRESTORE = 0x0223,
            MDINEXT = 0x0224,
            MDIMAXIMIZE = 0x0225,
            MDITILE = 0x0226,
            MDICASCADE = 0x0227,
            MDIICONARRANGE = 0x0228,
            MDIGETACTIVE = 0x0229,
            MDISETMENU = 0x0230,
            ENTERSIZEMOVE = 0x0231,
            EXITSIZEMOVE = 0x0232,
            DROPFILES = 0x0233,
            MDIREFRESHMENU = 0x0234,
            IME_SETCONTEXT = 0x0281,
            IME_NOTIFY = 0x0282,
            IME_CONTROL = 0x0283,
            IME_COMPOSITIONFULL = 0x0284,
            IME_SELECT = 0x0285,
            IME_CHAR = 0x0286,
            IME_REQUEST = 0x0288,
            IME_KEYDOWN = 0x0290,
            IME_KEYUP = 0x0291,
            MOUSEHOVER = 0x02A1,
            MOUSELEAVE = 0x02A3,
            NCMOUSEHOVER = 0x02A0,
            NCMOUSELEAVE = 0x02A2,
            WTSSESSION_CHANGE = 0x02B1,
            TABLET_FIRST = 0x02c0,
            TABLET_LAST = 0x02df,
            CUT = 0x0300,
            COPY = 0x0301,
            PASTE = 0x0302,
            CLEAR = 0x0303,
            UNDO = 0x0304,
            RENDERFORMAT = 0x0305,
            RENDERALLFORMATS = 0x0306,
            DESTROYCLIPBOARD = 0x0307,
            DRAWCLIPBOARD = 0x0308,
            PAINTCLIPBOARD = 0x0309,
            VSCROLLCLIPBOARD = 0x030A,
            SIZECLIPBOARD = 0x030B,
            ASKCBFORMATNAME = 0x030C,
            CHANGECBCHAIN = 0x030D,
            HSCROLLCLIPBOARD = 0x030E,
            QUERYNEWPALETTE = 0x030F,
            PALETTEISCHANGING = 0x0310,
            PALETTECHANGED = 0x0311,
            HOTKEY = 0x0312,
            PRINT = 0x0317,
            PRINTCLIENT = 0x0318,
            APPCOMMAND = 0x0319,
            THEMECHANGED = 0x031A,
            CLIPBOARDUPDATE = 0x031D,
            DWMCOMPOSITIONCHANGED = 0x031E,
            DWMNCRENDERINGCHANGED = 0x031F,
            DWMCOLORIZATIONCOLORCHANGED = 0x0320,
            DWMWINDOWMAXIMIZEDCHANGE = 0x0321,
            GETTITLEBARINFOEX = 0x033F,
            HANDHELDFIRST = 0x0358,
            HANDHELDLAST = 0x035F,
            AFXFIRST = 0x0360,
            AFXLAST = 0x037F,
            PENWINFIRST = 0x0380,
            PENWINLAST = 0x038F,
            APP = 0x8000,
            USER = 0x0400,
            CPL_LAUNCH = USER+0x1000,
            CPL_LAUNCHED = USER+0x1001,
            SYSTIMER = 0x118
        }

    }
}
'@
                Add-Type $fontCSharpCode

                # Get "Font" shell folder
                $shell = New-Object -COM "Shell.Application"
                $folder = $shell.NameSpace($CSIDL_FONTS)
                $fontsFolderPath = $folder.Self.Path

                # Helper Function Get-RegistryStringNameFromValue()
                function Get-RegistryStringNameFromValue([string] $keyPath, [string] $valueData)
                {
                    $pattern = [Regex]::Escape($valueData)

                    foreach($property in (Get-ItemProperty $keyPath).PsObject.Properties)
                    {
                        ## Skip the property if it was one PowerShell added
                        if(($property.Name -eq "PSPath") -or
                            ($property.Name -eq "PSChildName"))
                        {
                            continue
                        }
                        ## Search the text of the property
                        $propertyText = "$($property.Value)"
                        if($propertyText -match $pattern)
                        {
                            "$($property.Name)"
                        }
                    }
                }

                try
                {
                    $fontFinalPath = Join-Path $fontsFolderPath $file
                    
                    # Check if font exists, skip uninstall if font doesn't  exists
                    if (Test-Path $fontFinalPath) 
                    {
                        Write-Log "Font found at [$fontFinalPath]" -Source ${CmdletName}
                    }
                    else
                    {
                        Write-Log "Font file [$fontFinalPath] not found, nothing to remove." -Source ${CmdletName} -Severity 2
                        return
                    }

                    $retVal = [FontResource.AddRemoveFonts]::RemoveFont($fontFinalPath)
                    if ($retVal -eq 0) {
                        Write-Log -Message "Failed to remove font [$File]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				        Throw "Failed to remove font [$File].: $($_.Exception.Message)"
                    }
                    else
                    {
                        $fontRegistryvaluename = (Get-RegistryStringNameFromValue $fontRegistryPath $file)
                        Write-Log "Font Display Name [$fontRegistryvaluename]" -Source ${CmdletName}
                        if ($fontRegistryvaluename -ne "")
                        {
                            Remove-ItemProperty -path $fontRegistryPath -name $fontRegistryvaluename
                        }
                        Remove-Item $fontFinalPath
                        if ($error[0] -ne $null)
                        {
                            Write-Log -Message "Failed to remove font [$File]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				            Throw "Failed to remove font [$File].: $($_.Exception.Message)"
                        }
                        else
                        {
                            Write-Log "[$file] removed successfully" -Source ${CmdletName}
                        }
                    }
                }
                catch
                {
                    Write-Log -Message "Failed to remove font [$File]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				    Throw "Failed to remove font [$File].: $($_.Exception.Message)"
                }

                #############
        }

		Catch {
                Write-Log -Message "Failed to remove font [$File]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Throw "Failed to remove font [$File].: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Remove-Font

#region Function Remove-Path
Function Remove-Path {
<#
.SYNOPSIS
	Remove a PATH
.DESCRIPTION
	Remove a folder from the PATH environment variable
.PARAMETER Folder
	Folder to remove from  the PATH variable
.EXAMPLE
	Remove-Path "C:\Temp"
.EXAMPLE
	Remove-Path "%SystemDrive%\Temp"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>

    [Cmdletbinding()]
    param
    ( 
        [parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
        [ValidateNotNullorEmpty()]
        [String[]]$Folder
    )

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {


            # Get the Current PATH (unexpanded)
            $Hive = [Microsoft.Win32.Registry]::LocalMachine
            $Key = $Hive.OpenSubKey("System\CurrentControlSet\Control\Session Manager\Environment")
            [string]$NewPath = $Key.GetValue("PATH",$False, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            $OldPath=$NewPath # store new path as old path for later compare afte the replace

            # Find the value to remove, replace it with $NULL, if not found do nothing
            $NewPath = $NewPath.Replace($Folder,$null)
            if ($NewPath -eq $OldPath) 
            {
                Write-log "[$Folder] not found in PATH, no change" -Source ${CmdletName} -Severity 2
            } 
            else 
            {
                # Make sure ther is no double ; after the replace
                $NewPath = $NewPath.Replace(";;",";") 

                # Make sure the string is not ending with ";"
                $NewPath = $NewPath.TrimEnd(";") 

                # Update the Path environment variable
                Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
                Write-log "[$Folder] found and removed from PATH" -Source ${CmdletName} -Severity 1
            }

        }

		Catch {
                Write-Log -Message "Failed to remove path [$Folder]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Throw "Failed to remove font [$Folder].: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}

}
#endregion Function Remove-Path

#region Function Remove-MSIApplications
Function Remove-MSIApplications {
<#
.SYNOPSIS
	Removes all MSI applications matching the specified application name.
.DESCRIPTION
	Removes all MSI applications matching the specified application name.
	Enumerates the registry for installed applications matching the specified application name and uninstalls that application using the product code, provided the uninstall string matches "msiexec".
.PARAMETER Name
	The name of the application to uninstall. Performs a regex match on the application display name by default.
.PARAMETER Exact
	Specifies that the named application must be matched using the exact name.
.PARAMETER WildCard
	Specifies that the named application must be matched using a wildcard search.
.PARAMETER Parameters
	Overrides the default parameters specified in the configuration file. Uninstall default is: "REBOOT=ReallySuppress /QN".
.PARAMETER AddParameters
	Adds to the default parameters specified in the configuration file. Uninstall default is: "REBOOT=ReallySuppress /QN".
.PARAMETER FilterApplication
	Two-dimensional array that contains one or more (property, value, match-type) sets that should be used to filter the list of results returned by Get-InstalledApplication to only those that should be uninstalled.
	Properties that can be filtered upon: ProductCode, DisplayName, DisplayVersion, UninstallString, InstallSource, InstallLocation, InstallDate, Publisher, Is64BitApplication
.PARAMETER ExcludeFromUninstall
	Two-dimensional array that contains one or more (property, value, match-type) sets that should be excluded from uninstall if found.
	Properties that can be excluded: ProductCode, DisplayName, DisplayVersion, UninstallString, InstallSource, InstallLocation, InstallDate, Publisher, Is64BitApplication
.PARAMETER IncludeUpdatesAndHotfixes
	Include matches against updates and hotfixes in results.
.PARAMETER LoggingOptions
	Overrides the default logging options specified in the configuration file. Default options are: "/L*v".
.PARAMETER LogName
	Overrides the default log file name. The default log file name is generated from the MSI file name. If LogName does not end in .log, it will be automatically appended.
	For uninstallations, by default the product code is resolved to the DisplayName and version of the application.
.PARAMETER PassThru
	Returns ExitCode, STDOut, and STDErr output from the process.
.PARAMETER ContinueOnError
	Continue if an exit code is returned by msiexec that is not recognized. Default is: $true.
.EXAMPLE
	Remove-MSIApplications -Name 'Adobe Flash'
	Removes all versions of software that match the name "Adobe Flash"
.EXAMPLE
	Remove-MSIApplications -Name 'Adobe'
	Removes all versions of software that match the name "Adobe"
.EXAMPLE
	Remove-MSIApplications -Name 'Java 8 Update' -FilterApplication ('Is64BitApplication', $false, 'Exact'),('Publisher', 'Oracle Corporation', 'Exact')
																	)
	Removes all versions of software that match the name "Java 8 Update" where the software is 32-bits and the publisher is "Oracle Corporation".
.EXAMPLE
	Remove-MSIApplications -Name 'Java 8 Update' -FilterApplication (,('Publisher', 'Oracle Corporation', 'Exact')) -ExcludeFromUninstall (,('DisplayName', 'Java 8 Update 45', 'RegEx'))
	Removes all versions of software that match the name "Java 8 Update" and also have "Oracle Corporation" as the Publisher; however, it does not uninstall "Java 8 Update 45" of the software. 
	NOTE: if only specifying a single row in the two-dimensional arrays, the array must have the extra parentheses and leading comma as in this example.
.EXAMPLE
	Remove-MSIApplications -Name 'Java 8 Update' -ExcludeFromUninstall (,('DisplayName', 'Java 8 Update 45', 'RegEx'))
	Removes all versions of software that match the name "Java 8 Update"; however, it does not uninstall "Java 8 Update 45" of the software. 
	NOTE: if only specifying a single row in the two-dimensional array, the array must have the extra parentheses and leading comma as in this example.
.EXAMPLE
	Remove-MSIApplications -Name 'Java 8 Update' -ExcludeFromUninstall 
			('Is64BitApplication', $true, 'Exact'),
			('DisplayName', 'Java 8 Update 45', 'Exact'),
			('DisplayName', 'Java 8 Update 4*', 'WildCard'),
			('DisplayName', 'Java 8 Update 45', 'RegEx')
		
	Removes all versions of software that match the name "Java 8 Update"; however, it does not uninstall 64-bit versions of the software, Update 45 of the software, or any Update that starts with 4.
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
	More reading on how to create arrays if having trouble with -FilterApplication or -ExcludeFromUninstall parameter: http://blogs.msdn.com/b/powershell/archive/2007/01/23/array-literals-in-powershell.aspx
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[Switch]$Exact = $false,
		[Parameter(Mandatory=$false)]
		[Switch]$WildCard = $false,
		[Parameter(Mandatory=$false)]
		[Alias('Arguments')]
		[ValidateNotNullorEmpty()]
		[string]$Parameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$AddParameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[array]$FilterApplication = @(@()),
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[array]$ExcludeFromUninstall = @(@()),
		[Parameter(Mandatory=$false)]
		[Switch]$IncludeUpdatesAndHotfixes = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$LoggingOptions,
		[Parameter(Mandatory=$false)]
		[Alias('LogName')]
		[string]$private:LogName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[Switch]$PassThru = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		## Build the hashtable with the options that will be passed to Get-InstalledApplication using splatting
		[hashtable]$GetInstalledApplicationSplat = @{ Name = $name }
		If ($Exact) { $GetInstalledApplicationSplat.Add( 'Exact', $Exact) }
		ElseIf ($WildCard) { $GetInstalledApplicationSplat.Add( 'WildCard', $WildCard) }
		If ($IncludeUpdatesAndHotfixes) { $GetInstalledApplicationSplat.Add( 'IncludeUpdatesAndHotfixes', $IncludeUpdatesAndHotfixes) }
		
		[psobject[]]$installedApplications = Get-InstalledApplication @GetInstalledApplicationSplat 
						
		Write-Log -Message "Found [$($installedApplications.Count)] application(s) that matched the specified criteria [$Name]." -Source ${CmdletName}
		
		## Filter the results from Get-InstalledApplication
		[Collections.ArrayList]$removeMSIApplications = New-Object -TypeName 'System.Collections.ArrayList'
		If (($null -ne $installedApplications) -and ($installedApplications.Count)) {
			ForEach ($installedApplication in $installedApplications) {
				If ($installedApplication.UninstallString -notmatch 'msiexec') {
					Write-Log -Message "Skipping removal of application [$($installedApplication.DisplayName)] because uninstall string [$($installedApplication.UninstallString)] does not match `"msiexec`"." -Severity 2 -Source ${CmdletName}
					Continue
				}
				If ([string]::IsNullOrEmpty($installedApplication.ProductCode)) {
					Write-Log -Message "Skipping removal of application [$($installedApplication.DisplayName)] because unable to discover MSI ProductCode from application's registry Uninstall subkey [$($installedApplication.UninstallSubkey)]." -Severity 2 -Source ${CmdletName}
					Continue
				}
				
				#  Filter the results from Get-InstalledApplication to only those that should be uninstalled
				If (($null -ne $FilterApplication) -and ($FilterApplication.Count)) {
					Write-Log -Message "Filter the results to only those that should be uninstalled as specified in parameter [-FilterApplication]." -Source ${CmdletName}
					[boolean]$addAppToRemoveList = $false
					ForEach ($Filter in $FilterApplication) {
						If ($Filter[2] -eq 'RegEx') {
							If ($installedApplication.($Filter[0]) -match [regex]::Escape($Filter[1])) {
								[boolean]$addAppToRemoveList = $true
								Write-Log -Message "Preserve removal of application [$($installedApplication.DisplayName) $($installedApplication.Version)] because of regex match against [-FilterApplication] criteria." -Source ${CmdletName}
							}
						}
						ElseIf ($Filter[2] -eq 'WildCard') {
							If ($installedApplication.($Filter[0]) -like $Filter[1]) {
								[boolean]$addAppToRemoveList = $true
								Write-Log -Message "Preserve removal of application [$($installedApplication.DisplayName) $($installedApplication.Version)] because of wildcard match against [-FilterApplication] criteria." -Source ${CmdletName}
							}
						}
						ElseIf ($Filter[2] -eq 'Exact') {
							If ($installedApplication.($Filter[0]) -eq $Filter[1]) {
								[boolean]$addAppToRemoveList = $true
								Write-Log -Message "Preserve removal of application [$($installedApplication.DisplayName) $($installedApplication.Version)] because of exact match against [-FilterApplication] criteria." -Source ${CmdletName}
							}
						}
					}
				}
				Else {
					[boolean]$addAppToRemoveList = $true
				}
				
				#  Filter the results from Get-InstalledApplication to remove those that should never be uninstalled
				If (($null -ne $ExcludeFromUninstall) -and ($ExcludeFromUninstall.Count)) {
					ForEach ($Exclude in $ExcludeFromUninstall) {
						If ($Exclude[2] -eq 'RegEx') {
							If ($installedApplication.($Exclude[0]) -match [regex]::Escape($Exclude[1])) {
								[boolean]$addAppToRemoveList = $false
								Write-Log -Message "Skipping removal of application [$($installedApplication.DisplayName) $($installedApplication.Version)] because of regex match against [-ExcludeFromUninstall] criteria." -Source ${CmdletName}
							}
						}
						ElseIf ($Exclude[2] -eq 'WildCard') {
							If ($installedApplication.($Exclude[0]) -like $Exclude[1]) {
								[boolean]$addAppToRemoveList = $false
								Write-Log -Message "Skipping removal of application [$($installedApplication.DisplayName) $($installedApplication.Version)] because of wildcard match against [-ExcludeFromUninstall] criteria." -Source ${CmdletName}
							}
						}
						ElseIf ($Exclude[2] -eq 'Exact') {
							If ($installedApplication.($Exclude[0]) -eq $Exclude[1]) {
								[boolean]$addAppToRemoveList = $false
								Write-Log -Message "Skipping removal of application [$($installedApplication.DisplayName) $($installedApplication.Version)] because of exact match against [-ExcludeFromUninstall] criteria." -Source ${CmdletName}
							}
						}
					}
				}
				
				If ($addAppToRemoveList) {
					Write-Log -Message "Adding application to list for removal: [$($installedApplication.DisplayName) $($installedApplication.Version)]." -Source ${CmdletName}
					$removeMSIApplications.Add($installedApplication)
				}
			}
		}
		
		## Build the hashtable with the options that will be passed to Start-MSI using splatting
		[hashtable]$ExecuteMSISplat =  @{ Action = 'Uninstall'; Path = '' }
		If ($ContinueOnError) { $ExecuteMSISplat.Add( 'ContinueOnError', $ContinueOnError) }
		If ($Parameters) { $ExecuteMSISplat.Add( 'Parameters', $Parameters) }
		ElseIf ($AddParameters) { $ExecuteMSISplat.Add( 'AddParameters', $AddParameters) }
		If ($LoggingOptions) { $ExecuteMSISplat.Add( 'LoggingOptions', $LoggingOptions) }
		If ($LogName) { $ExecuteMSISplat.Add( 'LogName', $LogName) }
		If ($PassThru) { $ExecuteMSISplat.Add( 'PassThru', $PassThru) }
		If ($IncludeUpdatesAndHotfixes) { $ExecuteMSISplat.Add( 'IncludeUpdatesAndHotfixes', $IncludeUpdatesAndHotfixes) }
		
		If (($null -ne $removeMSIApplications) -and ($removeMSIApplications.Count)) {
			ForEach ($removeMSIApplication in $removeMSIApplications) {
				Write-Log -Message "Remove application [$($removeMSIApplication.DisplayName) $($removeMSIApplication.Version)]." -Source ${CmdletName}
				$ExecuteMSISplat.Path = $removeMSIApplication.ProductCode
				If ($PassThru) {
					[psobject[]]$ExecuteResults += Start-MSI @ExecuteMSISplat
				}
				Else {
					Start-MSI @ExecuteMSISplat
				}
			}
		}
		Else {
			Write-Log -Message 'No applications found for removal. Continue...' -Source ${CmdletName}
		}
	}
	End {
		If ($PassThru) { Write-Output -InputObject $ExecuteResults }
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Remove-RegistryKey
Function Remove-RegistryKey {
<#
.SYNOPSIS
	Deletes the specified registry key or value.
.DESCRIPTION
	Deletes the specified registry key or value.
.PARAMETER Key
	Path of the registry key to delete.
.PARAMETER Name
	Name of the registry value to delete.
.PARAMETER Recurse
	Delete registry key recursively.
.PARAMETER SID
	The security identifier (SID) for a user. Specifying this parameter will convert a HKEY_CURRENT_USER registry key to the HKEY_USERS\$SID format.
	Specify this parameter from the Invoke-HKCURegistrySettingsForAllUsers function to read/edit HKCU registry settings for all users on the system.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Remove-RegistryKey -Key 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce'
.EXAMPLE
	Remove-RegistryKey -Key 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name 'RunAppInstall'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[Switch]$Recurse,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$SID,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			## If the SID variable is specified, then convert all HKEY_CURRENT_USER key's to HKEY_USERS\$SID
			If ($PSBoundParameters.ContainsKey('SID')) {
				[string]$Key = Convert-RegistryPath -Key $Key -SID $SID
			}
			Else {
				[string]$Key = Convert-RegistryPath -Key $Key
			}
			
			If (-not ($Name)) {
				If (Test-Path -LiteralPath $Key -ErrorAction 'Stop') {
					If ($Recurse) {
						Write-Log -Message "Delete registry key recursively [$Key]." -Source ${CmdletName}
						$null = Remove-Item -LiteralPath $Key -Force -Recurse -ErrorAction 'Stop'
					}
					Else {
						If ($null -eq (Get-ChildItem -LiteralPath $Key -ErrorAction 'Stop')){
							## Check if there are subkeys of $Key, if so, executing Remove-Item will hang. Avoiding this with Get-ChildItem.
							Write-Log -Message "Delete registry key [$Key]." -Source ${CmdletName}
							$null = Remove-Item -LiteralPath $Key -Force -ErrorAction 'Stop'
						}
						Else {
							Throw "Unable to delete child key(s) of [$Key] without [-Recurse] switch."
						}
					}
				}
				Else {
					Write-Log -Message "Unable to delete registry key [$Key] because it does not exist." -Severity 2 -Source ${CmdletName}
				}
			}
			Else {
				If (Test-Path -LiteralPath $Key -ErrorAction 'Stop') {
					Write-Log -Message "Delete registry value [$Key] [$Name]." -Source ${CmdletName}
					
					If ($Name -eq '(Default)') {
						## Remove (Default) registry key value with the following workaround because Remove-ItemProperty cannot remove the (Default) registry key value
						$null = (Get-Item -LiteralPath $Key -ErrorAction 'Stop').OpenSubKey('','ReadWriteSubTree').DeleteValue('')
					}
					Else {
						$null = Remove-ItemProperty -LiteralPath $Key -Name $Name -Force -ErrorAction 'Stop'
					}
				}
				Else {
					Write-Log -Message "Unable to delete registry value [$Key] [$Name] because registry key does not exist." -Severity 2 -Source ${CmdletName}
				}
			}
		}
		Catch [System.Management.Automation.PSArgumentException] {
			Write-Log -Message "Unable to delete registry value [$Key] [$Name] because it does not exist." -Severity 2 -Source ${CmdletName}
		}
		Catch {
			If (-not ($Name)) {
				Write-Log -Message "Failed to delete registry key [$Key]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to delete registry key [$Key]: $($_.Exception.Message)"
				}
			}
			Else {
				Write-Log -Message "Failed to delete registry value [$Key] [$Name]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to delete registry value [$Key] [$Name]: $($_.Exception.Message)"
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Resolve-Error
Function Resolve-Error {
<#
.SYNOPSIS
	Enumerate error record details.
.DESCRIPTION
	Enumerate an error record, or a collection of error record, properties. By default, the details for the last error will be enumerated.
.PARAMETER ErrorRecord
	The error record to resolve. The default error record is the latest one: $global:Error[0]. This parameter will also accept an array of error records.
.PARAMETER Property
	The list of properties to display from the error record. Use "*" to display all properties.
	Default list of error properties is: Message, FullyQualifiedErrorId, ScriptStackTrace, PositionMessage, InnerException
.PARAMETER GetErrorRecord
	Get error record details as represented by $_.
.PARAMETER GetErrorInvocation
	Get error record invocation information as represented by $_.InvocationInfo.
.PARAMETER GetErrorException
	Get error record exception details as represented by $_.Exception.
.PARAMETER GetErrorInnerException
	Get error record inner exception details as represented by $_.Exception.InnerException. Will retrieve all inner exceptions if there is more than one.
.EXAMPLE
	Resolve-Error
.EXAMPLE
	Resolve-Error -Property *
.EXAMPLE
	Resolve-Error -Property InnerException
.EXAMPLE
	Resolve-Error -GetErrorInvocation:$false
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[AllowEmptyCollection()]
		[array]$ErrorRecord,
		[Parameter(Mandatory=$false,Position=1)]
		[ValidateNotNullorEmpty()]
		[string[]]$Property = ('Message','InnerException','FullyQualifiedErrorId','ScriptStackTrace','PositionMessage'),
		[Parameter(Mandatory=$false,Position=2)]
		[Switch]$GetErrorRecord = $true,
		[Parameter(Mandatory=$false,Position=3)]
		[Switch]$GetErrorInvocation = $true,
		[Parameter(Mandatory=$false,Position=4)]
		[Switch]$GetErrorException = $true,
		[Parameter(Mandatory=$false,Position=5)]
		[Switch]$GetErrorInnerException = $true
	)
	
	Begin {
		## If function was called without specifying an error record, then choose the latest error that occurred
		If (-not $ErrorRecord) {
			If ($global:Error.Count -eq 0) {
				#Write-Warning -Message "The `$Error collection is empty"
				Return
			}
			Else {
				[array]$ErrorRecord = $global:Error[0]
			}
		}
		
		## Allows selecting and filtering the properties on the error object if they exist
		[scriptblock]$SelectProperty = {
			Param (
				[Parameter(Mandatory=$true)]
				[ValidateNotNullorEmpty()]
				$InputObject,
				[Parameter(Mandatory=$true)]
				[ValidateNotNullorEmpty()]
				[string[]]$Property
			)
			
			[string[]]$ObjectProperty = $InputObject | Get-Member -MemberType '*Property' | Select-Object -ExpandProperty 'Name'
			ForEach ($Prop in $Property) {
				If ($Prop -eq '*') {
					[string[]]$PropertySelection = $ObjectProperty
					Break
				}
				ElseIf ($ObjectProperty -contains $Prop) {
					[string[]]$PropertySelection += $Prop
				}
			}
			Write-Output -InputObject $PropertySelection
		}
		
		#  Initialize variables to avoid error if 'Set-StrictMode' is set
		$LogErrorRecordMsg = $null
		$LogErrorInvocationMsg = $null
		$LogErrorExceptionMsg = $null
		$LogErrorMessageTmp = $null
		$LogInnerMessage = $null
	}
	Process {
		If (-not $ErrorRecord) { Return }
		ForEach ($ErrRecord in $ErrorRecord) {
			## Capture Error Record
			If ($GetErrorRecord) {
				[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord -Property $Property
				$LogErrorRecordMsg = $ErrRecord | Select-Object -Property $SelectedProperties
			}
			
			## Error Invocation Information
			If ($GetErrorInvocation) {
				If ($ErrRecord.InvocationInfo) {
					[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord.InvocationInfo -Property $Property
					$LogErrorInvocationMsg = $ErrRecord.InvocationInfo | Select-Object -Property $SelectedProperties
				}
			}
			
			## Capture Error Exception
			If ($GetErrorException) {
				If ($ErrRecord.Exception) {
					[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrRecord.Exception -Property $Property
					$LogErrorExceptionMsg = $ErrRecord.Exception | Select-Object -Property $SelectedProperties
				}
			}
			
			## Display properties in the correct order
			If ($Property -eq '*') {
				#  If all properties were chosen for display, then arrange them in the order the error object displays them by default.
				If ($LogErrorRecordMsg) { [array]$LogErrorMessageTmp += $LogErrorRecordMsg }
				If ($LogErrorInvocationMsg) { [array]$LogErrorMessageTmp += $LogErrorInvocationMsg }
				If ($LogErrorExceptionMsg) { [array]$LogErrorMessageTmp += $LogErrorExceptionMsg }
			}
			Else {
				#  Display selected properties in our custom order
				If ($LogErrorExceptionMsg) { [array]$LogErrorMessageTmp += $LogErrorExceptionMsg }
				If ($LogErrorRecordMsg) { [array]$LogErrorMessageTmp += $LogErrorRecordMsg }
				If ($LogErrorInvocationMsg) { [array]$LogErrorMessageTmp += $LogErrorInvocationMsg }
			}
			
			If ($LogErrorMessageTmp) {
				$LogErrorMessage = 'Error Record:'
				$LogErrorMessage += "`n-------------"
				$LogErrorMsg = $LogErrorMessageTmp | Format-List | Out-String
				$LogErrorMessage += $LogErrorMsg
			}
			
			## Capture Error Inner Exception(s)
			If ($GetErrorInnerException) {
				If ($ErrRecord.Exception -and $ErrRecord.Exception.InnerException) {
					$LogInnerMessage = 'Error Inner Exception(s):'
					$LogInnerMessage += "`n-------------------------"
					
					$ErrorInnerException = $ErrRecord.Exception.InnerException
					$Count = 0
					
					While ($ErrorInnerException) {
						[string]$InnerExceptionSeperator = '~' * 40
						
						[string[]]$SelectedProperties = & $SelectProperty -InputObject $ErrorInnerException -Property $Property
						$LogErrorInnerExceptionMsg = $ErrorInnerException | Select-Object -Property $SelectedProperties | Format-List | Out-String
						
						If ($Count -gt 0) { $LogInnerMessage += $InnerExceptionSeperator }
						$LogInnerMessage += $LogErrorInnerExceptionMsg
						
						$Count++
						$ErrorInnerException = $ErrorInnerException.InnerException
					}
				}
			}
			
			If ($LogErrorMessage) { $Output = $LogErrorMessage }
			If ($LogInnerMessage) { $Output += $LogInnerMessage }
			
			Write-Output -InputObject $Output
			
			If (Test-Path -LiteralPath 'variable:Output') { Clear-Variable -Name 'Output' }
			If (Test-Path -LiteralPath 'variable:LogErrorMessage') { Clear-Variable -Name 'LogErrorMessage' }
			If (Test-Path -LiteralPath 'variable:LogInnerMessage') { Clear-Variable -Name 'LogInnerMessage' }
			If (Test-Path -LiteralPath 'variable:LogErrorMessageTmp') { Clear-Variable -Name 'LogErrorMessageTmp' }
		}
	}
	End {
	}
}
#endregion

#region Function Send-Keys
Function Send-Keys {
<#
.SYNOPSIS
	Send a sequence of keys to one or more application windows.
.DESCRIPTION
	Send a sequence of keys to one or more application window. If window title searched for returns more than one window, then all of them will receive the sent keys.
	Function does not work in SYSTEM context unless launched with "psexec.exe -s -i" to run it as an interactive process under the SYSTEM account.
.PARAMETER WindowTitle
	The title of the application window to search for using regex matching.
.PARAMETER GetAllWindowTitles
	Get titles for all open windows on the system.
.PARAMETER WindowHandle
	Send keys to a specific window where the Window Handle is already known.
.PARAMETER Keys
	The sequence of keys to send. Info on Key input at: http://msdn.microsoft.com/en-us/library/System.Windows.Forms.SendKeys(v=vs.100).aspx
.PARAMETER WaitSeconds
	An optional number of seconds to wait after the sending of the keys.
.EXAMPLE
	Send-Keys -WindowTitle 'foobar - Notepad' -Key 'Hello world'
	Send the sequence of keys "Hello world" to the application titled "foobar - Notepad".
.EXAMPLE
	Send-Keys -WindowTitle 'foobar - Notepad' -Key 'Hello world' -WaitSeconds 5
	Send the sequence of keys "Hello world" to the application titled "foobar - Notepad" and wait 5 seconds.
.EXAMPLE
	Send-Keys -WindowHandle ([IntPtr]17368294) -Key 'Hello world'
	Send the sequence of keys "Hello world" to the application with a Window Handle of '17368294'.
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
	http://msdn.microsoft.com/en-us/library/System.Windows.Forms.SendKeys(v=vs.100).aspx
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,Position=0)]
		[AllowEmptyString()]
		[ValidateNotNull()]
		[string]$WindowTitle,
		[Parameter(Mandatory=$false,Position=1)]
		[ValidateNotNullorEmpty()]
		[Switch]$GetAllWindowTitles = $false,
		[Parameter(Mandatory=$false,Position=2)]
		[ValidateNotNullorEmpty()]
		[IntPtr]$WindowHandle,
		[Parameter(Mandatory=$false,Position=3)]
		[ValidateNotNullorEmpty()]
		[string]$Keys,
		[Parameter(Mandatory=$false,Position=4)]
		[ValidateNotNullorEmpty()]
		[int32]$WaitSeconds
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		## Load assembly containing class System.Windows.Forms.SendKeys
		Add-Type -AssemblyName 'System.Windows.Forms' -ErrorAction 'Stop'
		
		[scriptblock]$SendKeys = {
			Param (
				[Parameter(Mandatory=$true)]
				[ValidateNotNullorEmpty()]
				[IntPtr]$WindowHandle
			)
			Try {
				## Bring the window to the foreground
				[boolean]$IsBringWindowToFrontSuccess = [PackagingFramework.UiAutomation]::BringWindowToFront($WindowHandle)
				If (-not $IsBringWindowToFrontSuccess) { Throw 'Failed to bring window to foreground.'}
				
				## Send the Key sequence
				If ($Keys) {
					[boolean]$IsWindowModal = If ([PackagingFramework.UiAutomation]::IsWindowEnabled($WindowHandle)) { $false } Else { $true }
					If ($IsWindowModal) { Throw 'Unable to send keys to window because it may be disabled due to a modal dialog being shown.' }
					[Windows.Forms.SendKeys]::SendWait($Keys)
					Write-Log -Message "Sent key(s) [$Keys] to window title [$($Window.WindowTitle)] with window handle [$WindowHandle]." -Source ${CmdletName}
					
					If ($WaitSeconds) {
						Write-Log -Message "Sleeping for [$WaitSeconds] seconds." -Source ${CmdletName}
						Start-Sleep -Seconds $WaitSeconds
					}
				}
			}
			Catch {
				Write-Log -Message "Failed to send keys to window title [$($Window.WindowTitle)] with window handle [$WindowHandle]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
		}
	}
	Process {
		Try {
			If ($WindowHandle) {
				[psobject]$Window = Get-WindowTitle -GetAllWindowTitles | Where-Object { $_.WindowHandle -eq $WindowHandle }
				If (-not $Window) {
					Write-Log -Message "No windows with Window Handle [$WindowHandle] were discovered." -Severity 2 -Source ${CmdletName}
					Return
				}
				& $SendKeys -WindowHandle $Window.WindowHandle
			}
			Else {
				[hashtable]$GetWindowTitleSplat = @{}
				If ($GetAllWindowTitles) { $GetWindowTitleSplat.Add( 'GetAllWindowTitles', $GetAllWindowTitles) }
				Else { $GetWindowTitleSplat.Add( 'WindowTitle', $WindowTitle) }
				[psobject[]]$AllWindows = Get-WindowTitle @GetWindowTitleSplat
				If (-not $AllWindows) {
					Write-Log -Message 'No windows with the specified details were discovered.' -Severity 2 -Source ${CmdletName}
					Return
				}
				
				ForEach ($Window in $AllWindows) {
					& $SendKeys -WindowHandle $Window.WindowHandle
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to send keys to specified window. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Set-AutoAdminLogon

Function Set-AutoAdminLogon{
<#
.SYNOPSIS
    Enables or disables Auto Admin Logon
.DESCRIPTION
    Enables or disables Auto Admin Logon and optionaly runs a script via RunOnce.
    Note: To use AutoAdminLogon is a security risc because the password is stored in clear text in the Windows registry, please use it with caution
.PARAMETER Username
    Provide the username that the system would use to login. Syntax: Domain\Username or Username@Domain (Or use Computer\Username name for a local account)
.PARAMETER Password
    Provide the Password for the user.
.PARAMETER AutoLogonCount
    Sets the number of times the system would reboot without asking for credentials. Default is 1.
.PARAMETER PurgeAutoAdminLogonKey
    Disables AutoAdminLogon by removing the coresponding registry keys
.EXAMPLE
    Set-AutoAdminLogon -Username "MyDomain\MyAdmin" -Password "MyPassword"
.EXAMPLE
    Set-AutoAdminLogon -Username "MyAdmin@MyDomain" -Password "MyPassword" -AutoLogonCount "3" -Script "c:\Temp\MyScript.cmd"
.EXAMPLE
    Set-AutoAdminLogon -Purge
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,ParameterSetName='Create')]
        [String]$Username,
        [Parameter(Mandatory=$False,ParameterSetName='Create')]
        [String]$Password,
        [Parameter(Mandatory=$False,ParameterSetName='Create')]
        [AllowEmptyString()]
        [String]$Count,
        [Parameter(Mandatory=$False,ParameterSetName='Create')]
        [AllowEmptyString()]
        [String]$Script,
        [Parameter(Mandatory=$false,ParameterSetName='Purge')]
		[switch]$Purge
    )

    Begin
    {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header

    }
    
    Process
    {

        Try
        {

            # Declaration
            $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
            $RegROPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"

            # Set vs Purge
            If($Purge -eq $true)
            {
                Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon" -Value "0" -Type String  
                Set-ItemProperty -Path $RegPath -Name "AutoLogonCount" -Value "0" -Type Dword
                Remove-ItemProperty -Path  $RegPath -Name "DefaultUsername"
                Remove-ItemProperty -Path  $RegPath -Name "DefaultPassword"
            }
            else
            {

                # Setting registry values
                Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String  
                Set-ItemProperty $RegPath "DefaultUsername" -Value "$Username" -type String  
                Set-ItemProperty $RegPath "DefaultPassword" -Value "$Password" -type String
                if($AutoLogonCount)
                {
                    Set-ItemProperty $RegPath "AutoLogonCount" -Value "$Count" -type DWord
                }
                else
                {
                    Set-ItemProperty $RegPath "AutoLogonCount" -Value "1" -type DWord
                }
                if($Script)
                {
                    Set-ItemProperty $RegROPath "(Default)" -Value "$Script" -type String
                }
                else
                {
                    Set-ItemProperty $RegROPath "(Default)" -Value "" -type String
                }  
                Write-Log -Message "Auto Admin Logon configured for [$Username]" -Severity 1 -Source ${CmdletName}
            }
            

                  
        }
        Catch
        {
            Write-Log -Message "Failed to set Auto Admin Logon. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
        }
    }
    
    End
    {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer    
    }

}

#endregion Function Set-AutoAdminLogon

#region Function Set-ActiveSetup
Function Set-ActiveSetup {
<#
.SYNOPSIS
	Creates an Active Setup entry in the registry to execute a file for each user upon login. (Extended Version)
.DESCRIPTION
	Active Setup allows handling of per-user changes registry/file changes upon login.
	A registry key is created in the HKLM registry hive which gets replicated to the HKCU hive when a user logs in.
	If the "Version" value of the Active Setup entry in HKLM is higher than the version value in HKCU, the file referenced in "StubPath" is executed.
	This Function:
	- Creates the registry entries in HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\$PackageName.
	- Creates StubPath value depending on the file extension of the $StubExePath parameter.
	- Copies/overwrites the StubPath file to $StubExePath destination path if file exists in 'Source' subdirectory of script directory.
.PARAMETER StubExePath
	Full destination path to the file that will be executed for each user that logs in.
	If this file exists in the 'Files' subdirectory of the script directory, it will be copied to the destination path.
.PARAMETER Arguments
	Arguments to pass to the file being executed.
.PARAMETER Description
	Description for the Active Setup. Users will see "Setting up personalized settings for: $Description" at logon. Default is: $installName.
.PARAMETER Key
	Name of the registry key for the Active Setup entry. Default is: $PackageName.
.PARAMETER Version
	Optional, Default is 1,0,0,0 if not specified. Specify version for Active setup entry. Active Setup is not triggered if Version value has more than 8 consecutive digits. Use commas to get around this limitation.
.PARAMETER Locale
	Optional. Arbitrary string used to specify the installation language of the file being executed. Not replicated to HKCU.
.PARAMETER UserGroups
	Optional. Limit active setup execution to specific user goups, be default it runs for all users
.PARAMETER PurgeActiveSetupKey
	Remove Active Setup entry from HKLM registry hive.
.PARAMETER DisableActiveSetup
	Disables the Active Setup entry so that the StubPath file will not be executed.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Set-ActiveSetup -StubExePath "$ProgramFiles\My Application\Active Setup Script.ps1" -Description 'My Application User Config' -Key "$PackageName" -Version '1,0,0,1'
.EXAMPLE
	Set-ActiveSetup -Key 'ProgramUserConfig' -PurgeActiveSetupKey
	Deletes "ProgramUserConfig" active setup entry from all registry hives.
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
    Changes:
    At install/uninstall runtime only the HKLM Active Setup registry key are created
    The Active Setup 'Version' registry default value is no longer based on the current date/time because this will cause issues when roaming profiles are used and different clients or server have different version numbers because of different installation times.
    New optional '-UserGroups' parameter, when specified the access permissions on the Active Setup registry entry is change in a way that the Active Setup entry runs only for this group and no longer for all users. Note: Multiple user groups can be specified as an array. 
    Hint: To test active setup entires you can simply run C:\Windows\system32\runonce.exe /AlternateShellStartup 
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,ParameterSetName='Create')]
		[ValidateNotNullorEmpty()]
		[string]$StubExePath,
		[Parameter(Mandatory=$false,ParameterSetName='Create')]
		[ValidateNotNullorEmpty()]
		[string]$Arguments,
		[Parameter(Mandatory=$false,ParameterSetName='Create')]
		[ValidateNotNullorEmpty()]
		[string]$Description = $Global:InstallName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Key = $PackageName,
		[Parameter(Mandatory=$false,ParameterSetName='Create')]
		[ValidateNotNullorEmpty()]
		[string]$Version = '1,0,0,0',
		[Parameter(Mandatory=$false,ParameterSetName='Create')]
		[ValidateNotNullorEmpty()]
		[string]$Locale,
		[Parameter(Mandatory=$false,ParameterSetName='Create')]
		[ValidateNotNullorEmpty()]
		[switch]$DisableActiveSetup = $false,
		[Parameter(Mandatory=$false,ParameterSetName='Create')]
		[ValidateNotNullorEmpty()]
        [array]$UserGroups,
		[Parameter(Mandatory=$true,ParameterSetName='Purge')]
		[switch]$PurgeActiveSetupKey,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {

            # Convert version number to active setup foramt (numbers with coma only)
            $Version= $Version.Replace(".",",")
            $Version = $Version -replace "[^0-9,]"

            # Strings
			[string]$ActiveSetupKey = "HKLM:SOFTWARE\Microsoft\Active Setup\Installed Components\$Key"
			[string]$HKCUActiveSetupKey = "HKCU:Software\Microsoft\Active Setup\Installed Components\$Key"
			
			## Delete Active Setup registry entry from the HKLM hive and for all logon user registry hives on the system
			If ($PurgeActiveSetupKey) {
				Write-Log -Message "Remove Active Setup entry [$ActiveSetupKey]." -Source ${CmdletName}
				Remove-RegistryKey -Key $ActiveSetupKey -Recurse
				Return
			}
			
			## Verify a file with a supported file extension was specified in $StubExePath
			[string[]]$StubExePathFileExtensions = '.exe', '.vbs', '.cmd', '.ps1', '.js'
			[string]$StubExeExt = [IO.Path]::GetExtension($StubExePath)
			If ($StubExePathFileExtensions -notcontains $StubExeExt) {
				Throw "Unsupported Active Setup StubPath file extension [$StubExeExt]."
			}
			
			## Copy file to $StubExePath from the 'source' subdirectory of the script directory (if it exists there)
			[string]$StubExePath = [Environment]::ExpandEnvironmentVariables($StubExePath)
			[string]$ActiveSetupFileName = [IO.Path]::GetFileName($StubExePath)
			[string]$StubExeFile = Join-Path -Path $Files -ChildPath $ActiveSetupFileName
			[string]$StubPath = Split-Path -parent $StubExePath
			If (Test-Path -LiteralPath $StubExeFile -PathType 'Leaf') {
				#  This will overwrite the StubPath file if $StubExePath already exists on target
				New-Folder -Path "$StubPath"
				Copy-File -Path $StubExeFile -Destination $StubPath -ContinueOnError $false
			}
			
			## Check if the $StubExePath file exists
			If (-not (Test-Path -LiteralPath "$StubPath\$ActiveSetupFileName" -PathType 'Leaf')) { Throw "Active Setup StubPath file [$ActiveSetupFileName] is missing." }
			
			## Define Active Setup StubPath according to file extension of $StubExePath
			Switch ($StubExeExt) {
				'.exe' {
					[string]$CUStubExePath = $StubExePath
					[string]$CUArguments = $Arguments
					[string]$StubPath = "$CUStubExePath"
				}
				{'.vbs','.js' -contains $StubExeExt} {
					[string]$CUStubExePath = "$WinDir\system32\cscript.exe"
					[string]$CUArguments = "//nologo `"$StubExePath`""
					[string]$StubPath = "$CUStubExePath $CUArguments"
				}
				'.cmd' {
					[string]$CUStubExePath = "$WinDir\system32\CMD.exe"
					[string]$CUArguments = "/C `"$StubExePath`""
					[string]$StubPath = "$CUStubExePath $CUArguments"
				}
				'.ps1' {
					[string]$CUStubExePath = "$PSHOME\powershell.exe"
					[string]$CUArguments = "-ExecutionPolicy Bypass -NoProfile -NoLogo -WindowStyle Hidden -Command & { & `\`"$StubExePath`\`"}"
					[string]$StubPath = "$CUStubExePath $CUArguments"
				}
			}
			If ($Arguments) {
				[string]$StubPath = "$StubPath $Arguments"
				If ($StubExeExt -ne '.exe') { [string]$CUArguments = "$CUArguments $Arguments" }
			}
			
			## Create the Active Setup entry in the registry
			[scriptblock]$SetActiveSetupRegKeys = {
				Param (
					[Parameter(Mandatory=$true)]
					[ValidateNotNullorEmpty()]
					[string]$ActiveSetupRegKey,
					[Parameter(Mandatory=$false)]
					[ValidateNotNullorEmpty()]
					[string]$SID
				)
				If ($SID) {
					Set-RegistryKey -Key $ActiveSetupRegKey -Name '(Default)' -Value $Description -SID $SID -ContinueOnError $false
					Set-RegistryKey -Key $ActiveSetupRegKey -Name 'StubPath' -Value $StubPath -Type 'String' -SID $SID -ContinueOnError $false
					Set-RegistryKey -Key $ActiveSetupRegKey -Name 'Version' -Value $Version -SID $SID -ContinueOnError $false
					If ($Locale) { Set-RegistryKey -Key $ActiveSetupRegKey -Name 'Locale' -Value $Locale -SID $SID -ContinueOnError $false }
					If ($DisableActiveSetup) {
						Set-RegistryKey -Key $ActiveSetupRegKey -Name 'IsInstalled' -Value 0 -Type 'DWord' -SID $SID -ContinueOnError $false
					}
					Else {
						Set-RegistryKey -Key $ActiveSetupRegKey -Name 'IsInstalled' -Value 1 -Type 'DWord' -SID $SID -ContinueOnError $false
					}
				}
				Else {
					Set-RegistryKey -Key $ActiveSetupRegKey -Name '(Default)' -Value $Description -ContinueOnError $false
					Set-RegistryKey -Key $ActiveSetupRegKey -Name 'StubPath' -Value $StubPath -Type 'String' -ContinueOnError $false
					Set-RegistryKey -Key $ActiveSetupRegKey -Name 'Version' -Value $Version -ContinueOnError $false
					If ($Locale) { Set-RegistryKey -Key $ActiveSetupRegKey -Name 'Locale' -Value $Locale -ContinueOnError $false }
					If ($DisableActiveSetup) {
						Set-RegistryKey -Key $ActiveSetupRegKey -Name 'IsInstalled' -Value 0 -Type 'DWord' -ContinueOnError $false
					}
					Else {
						Set-RegistryKey -Key $ActiveSetupRegKey -Name 'IsInstalled' -Value 1 -Type 'DWord' -ContinueOnError $false
					}
				}
				
			}
			& $SetActiveSetupRegKeys -ActiveSetupRegKey $ActiveSetupKey

            ## User Group permissions (optional if specified
            if ($UserGroups)
            {
                Set-Inheritance -Action 'Disable' -Path $ActiveSetupKey  # break inheritance 
                foreach ($UserGroup in $UserGroups) 
                {
                    Update-RegistryPermission -Action 'Add' -Key $ActiveSetupKey -Trustee $UserGroup -Permissions 'ReadKey' # grand specific application group read key permissions
                }
                Update-RegistryPermission -Action 'Delete' -Key $ActiveSetupKey -Trustee 'S-1-5-32-545'             # remove built-in local users group permissions
            }

		}
		Catch {
			Write-Log -Message "Failed to set Active Setup registry entry. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to set Active Setup registry entry: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Set-EnvironmentVariable
Function Set-EnvironmentVariable {
<#
.SYNOPSIS
	Set an environment variable
.DESCRIPTION
	Set an environment variable to diffren types levels (Process, User, Machine
.PARAMETER Name
    Name of your environment variable
.PARAMETER Value
    Value of your environment variable
.PARAMETER Target
    Target, possible values are Process or User or Machine
.EXAMPLE
	Set-EnvironmentVariable 'TestVar1' 'This is a test value'
.EXAMPLE
	Set-EnvironmentVariable -Name 'TestVar2' -Value 'This is a test value' -Target 'Machine'
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
    [Cmdletbinding()]
    param
    ( 
        [Parameter(Mandatory=$True,Position=0)]
        [ValidateNotNullorEmpty()]
        [String]$Name,
        [Parameter(Mandatory=$false,Position=1)]
        [ValidateNotNullorEmpty()]
        [String]$Value,
        [Parameter(Mandatory=$false,Position=2)]
		[ValidateSet('Process','User','Machine')]
		[String]$Target = 'Process'
    )

	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
                [environment]::SetEnvironmentVariable("$Name","$Value","$Target")
                Write-Log "[$Name] to [$value] on [$Target]" -Source ${CmdletName}
        }

		Catch {
                Write-Log -Message "Failed to set [$Name]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Throw "Failed to set [$Name].: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Set-EnvironmentVariable

#region Function Set-Inheritance
Function Set-Inheritance
{
<#
.SYNOPSIS
	Enable or disable registry, file or folder inheritance
.DESCRIPTION
	Enable or disable inheritance for registry keys, files and folder with advanced options
.PARAMETER Action
	The action to perform. Options: Add, Remove
.PARAMETER Path
	Name of the registry key or folder.
.PARAMETER Filename
	Name of the file.
.Parameter Recurse
	Enable recursive action
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $false.
.EXAMPLE
	Set-Inheritance -Action "Enable" -Path "C:\Temp" -Filename "test.txt"
	Set-Inheritance -Action "Disable" -Path "C:\Temp" -Filename "test.txt"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateSet('Enable', 'Disable')]
		[ValidateNotNullorEmpty()]
		[string]$Action,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullorEmpty()]
		[string]$Filename,
		[Parameter(Mandatory = $false)]
		[switch]$Recurse,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $false
	)
	
	Begin
	{
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {

            # Internal Functions - Start
            Function Set-FolderInheritance
            {
            <#
            .SYNOPSIS
	            Enable or disable folder inheritance
            .DESCRIPTION
	            Enable or disable inheritance for folders
            .PARAMETER Action
	            The action to perform. Options: Add, Remove
            .PARAMETER Path
	            Name of the path to the folder.
            .PARAMETER ContinueOnError
	            Continue if an error is encountered. Default is: $false.
            .EXAMPLE
	            Set-FolderInheritance -Action "Enable" -Path "C:\Temp"
	            Set-FolderInheritance -Action "Disable" -Path "C:\Temp"
            .NOTES
	            This is an internal script function and should typically not be called directly.
            .LINK
	            http://www.ceterion.com
            #>
	            [CmdletBinding()]
	            Param (
		            [Parameter(Mandatory = $true)]
		            [ValidateSet('Enable', 'Disable')]
		            [ValidateNotNullorEmpty()]
		            [string]$Action,
		            [Parameter(Mandatory = $true)]
		            [ValidateNotNullorEmpty()]
		            [string]$Path,
		            [Parameter(Mandatory = $false)]
		            [ValidateNotNullOrEmpty()]
		            [boolean]$ContinueOnError = $false
	            )
	
	            Begin
	            {
		            ## Get the name of this function and write header
		            [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		            Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	            }
	            Process {
		            Try {
			            If ($Action -ieq "Enable") {
				            # Get current ACL from Target
				            $FolderACL = Get-Acl -Path "$Path"
				            # Set new value to current ACL
				            $FolderACL.SetAccessRuleProtection($false,$false)
				            # Save modified ACL
				            Set-ACL "$Path" $FolderACL
				            Write-Log -Message "[${CmdletName}] Enable inheritance to folder [$Path]" -Severity 1 -Source ${CmdletName}
			            }
			            Else {
				            # Get current ACL from Target
				            $FolderACL = Get-Acl -Path "$Path"
				            # Set new value to current ACL
				            $FolderACL.SetAccessRuleProtection($true,$true)
				            # Save modified ACL
				            Set-ACL "$Path" $FolderACL
				            Write-Log -Message "[${CmdletName}] Disable inheritance to folder [$Path]" -Severity 1 -Source ${CmdletName}
			            }
		            }
		            Catch {
			            Write-Log -Message "Failed to change the folder inheritance. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			            If (-not $ContinueOnError) {
				            Throw "Failed to change the inheritance: $($_.Exception.Message)"
			            }
		            }
	            }
	            End {
		            Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	            }
            }

            Function Set-FileInheritance
            {
            <#
            .SYNOPSIS
	            Enable or disable inheritance to a file
            .DESCRIPTION
	            Enable or disable inheritance for files
            .PARAMETER Action
	            The action to perform. Options: Add, Remove
            .PARAMETER Path
	            Name of the path.
            .PARAMETER Filename
	            Name of the file.
            .PARAMETER ContinueOnError
	            Continue if an error is encountered. Default is: $false.
            .EXAMPLE
	            Set-FileInheritance -Action "Enable" -Path "C:\Temp" -Filename "test.txt"
	            Set-FileInheritance -Action "Disable" -Path "C:\Temp" -Filename "test.txt"
            .NOTES
	            This is an internal script function and should typically not be called directly.
            .LINK
	            http://www.ceterion.com
            #>
	            [CmdletBinding()]
	            Param (
		            [Parameter(Mandatory = $true)]
		            [ValidateSet('Enable', 'Disable')]
		            [ValidateNotNullorEmpty()]
		            [string]$Action,
		            [Parameter(Mandatory = $true)]
		            [ValidateNotNullorEmpty()]
		            [string]$Path,
		            [Parameter(Mandatory = $true)]
		            [ValidateNotNullorEmpty()]
		            [string]$Filename,
		            [Parameter(Mandatory = $false)]
		            [ValidateNotNullOrEmpty()]
		            [boolean]$ContinueOnError = $false
	            )
	
	            Begin
	            {
		            ## Get the name of this function and write header
		            [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		            Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	            }
	            Process {
		            Try {
			            If ($Action -ieq "Enable") {
				            # Get current ACL from Target
				            $FileACL = Get-Acl -Path "$Path\$Filename" 
				            # Set new value to current ACL
				            $FileACL.SetAccessRuleProtection($false,$false)
				            # Save modified ACL
				            Set-ACL "$Path\$Filename" $FileACL
				            Write-Log -Message "[${CmdletName}] Enable inheritance to file [$Path\$Filename]" -Severity 1 -Source ${CmdletName}
			            }
			            Else {
				            # Get current ACL from Target
				            $FileACL = Get-Acl -Path "$Path\$Filename"
				            # Set new value to current ACL
				            $FileACL.SetAccessRuleProtection($true,$true)
				            # Save modified ACL
				            Set-ACL "$Path\$Filename" $FileACL
				            Write-Log -Message "[${CmdletName}] Disable inheritance to file [$Path\$Filename]" -Severity 1 -Source ${CmdletName}
			            }
		            }
		            Catch {
			            Write-Log -Message "Failed to change the folder inheritance. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			            If (-not $ContinueOnError) {
				            Throw "Failed to change the inheritance: $($_.Exception.Message)"
			            }
		            }
	            }
	            End {
		            Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	            }
            }

            Function Set-RegistryInheritance
            {
            <#
            .SYNOPSIS
	            Enable or disable registry inheritance
            .DESCRIPTION
	            Enable or disable inheritance for registry keys
            .PARAMETER Action
	            The action to perform. Options: Add, Remove
            .PARAMETER Path
	            Name of the registry key.
            .PARAMETER ContinueOnError
	            Continue if an error is encountered. Default is: $false.
            .EXAMPLE
	            Set-Inheritance -Action "Enable" -Path "C:\Temp" -Filename "test.txt"
	            Set-Inheritance -Action "Disable" -Path "C:\Temp" -Filename "test.txt"
            .NOTES
	            This is an internal script function and should typically not be called directly.
            .LINK
	            http://www.ceterion.com
            #>
	            [CmdletBinding()]
	            Param (
		            [Parameter(Mandatory = $true)]
		            [ValidateSet('Enable', 'Disable')]
		            [ValidateNotNullorEmpty()]
		            [string]$Action,
		            [Parameter(Mandatory = $true)]
		            [ValidateNotNullorEmpty()]
		            [string]$Path,
		            [Parameter(Mandatory = $false)]
		            [ValidateNotNullOrEmpty()]
		            [boolean]$ContinueOnError = $false
	            )
	
	            Begin
	            {
		            ## Get the name of this function and write header
		            [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		            Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	            }
	            Process {
		            Try {
			            If ($Path.StartsWith('HK'))	{
				            $RegPath = Convert-RegistryPath -Key "$Path"
				            # Convert registy key to needed format
				            $RegPSDrive = $RegPath.TrimStart('Registry::')
				            # Create Powershell drive because Get-ACL and Set-ACL bug
				            New-PSDrive -Name "RegDrive" -PSProvider "Registry" -Root "$RegPSDrive" | Out-Null
				            Write-Log -Message "[${CmdletName}] Convert registry key to valid format" -Severity 1 -Source ${CmdletName}
			            }
		
			            If ($Action -ieq "Enable") {
				            # Get current ACL from Target
				            $RegACL = Get-ACL -Path 'RegDrive:'
				            # Set new value to current ACL
				            $RegACL.SetAccessRuleProtection($false,$false)
				            # Save modified ACL
				            Set-ACL -Path "RegDrive:" -AclObject $RegACL
				            Write-Log -Message "[${CmdletName}] Enable inheritance to key [$RegPath]" -Severity 1 -Source ${CmdletName}
			            }
			            Else {
				            # Get current ACL from Target
				            $RegACL = Get-ACL -Path 'RegDrive:'
				            # Set new value to current ACL
				            $RegACL.SetAccessRuleProtection($true,$true)
				            # Save modified ACL
				            Set-ACL -Path "RegDrive:" -AclObject $RegACL
				            Write-Log -Message "[${CmdletName}] Disable inheritance to key [$RegPath]" -Severity 1 -Source ${CmdletName}
			            }
			
			            # Remove Powershell drive
			            Remove-PSDrive -Name "RegDrive"
		            }
		            Catch {
			            Write-Log -Message "Failed to change the folder inheritance. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			            If (-not $ContinueOnError) {
				            Throw "Failed to change the inheritance: $($_.Exception.Message)"
			            }
		            }
	            }
	            End {
		            Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	            }
            }

            Function Remove-NotInheritedPermissions
            {
            <#
            .SYNOPSIS
	            Remove not inherited permission from path
            .DESCRIPTION
	            Remove permissions from the access control list which are not inherited permission from the parent folder
            .PARAMETER Path
	            Name of the path to the file, folder or registry key
            .PARAMETER ContinueOnError
	            Continue if an error is encountered. Default is: $false.
            .EXAMPLE
	            Remove-NotInheritedPermissions -Path "HKEY_CURRENT_USER\Test"
	            Remove-NotInheritedPermissions -Path "C:\Temp\Test"
	            Remove-NotInheritedPermissions -Path "C:\Temp\Test\test.txt"
            .NOTES
	            This is an internal script function and should typically not be called directly.
            .LINK
	            http://www.ceterion.com
            #>
	            [CmdletBinding()]
	            Param (
		            [Parameter(Mandatory = $true)]
		            [ValidateNotNullorEmpty()]
		            [string]$Path,
		            [Parameter(Mandatory = $false)]
		            [ValidateNotNullOrEmpty()]
		            [boolean]$ContinueOnError = $false
	            )
	
	            Begin
	            {
		            ## Get the name of this function and write header
		            [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		            Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	            }
	            Process {
		            Try {
			            If ($Path.StartsWith('HK'))	{
				            $Path = Convert-RegistryPath -Key "$Path"
			            }
		
			            # Get current ACL from Target
			            $ACL = Get-Acl -Path "$Path" 
			            # Set new value to current ACL
			            Foreach($ACLEntry in $ACL.access) {
				            If($ACLEntry.isinherited -eq $false) {
					            $ACL.RemoveAccessRule($ACLEntry)
					            Write-Log -Message "[${CmdletName}] Remove not inherited accounts successfully." -Severity 1 -Source ${CmdletName}
					            # Save modified ACL
					            Set-ACL "$Path" $ACL | Out-Null
				            }
			            }
		            }
		            Catch {
			            Write-Log -Message "Failed to romove not inherited accounts. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			            If (-not $ContinueOnError) {
				            Throw "Failed to change the inheritance: $($_.Exception.Message)"
			            }
		            }
	            }
	            End {
		            Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	            }
            }
            # Internal Functions - End

			If ($Path.StartsWith('HK'))	{
				If ($Action -ieq "Disable") {
					Set-RegistryInheritance -Action "Disable" -Path "$Path" 
				
				}
				Else {
					If($Recurse) {
						Set-RegistryInheritance -Action "Enable" -Path "$Path"
						$path = Convert-RegistryPath -Key "$Path"
						Remove-NotInheritedPermissions -Path "$Path"
						$Subkeys = Get-ChildItem -Path "$Path"
						ForEach ($Subkey in $Subkeys) {	
							Set-RegistryInheritance -Action "Enable" -Path "$Subkey"
							Remove-NotInheritedPermissions -Path "$Subkey"
						}
					}
					Else {
						Set-RegistryInheritance -Action "Enable" -Path "$Path"
						Remove-NotInheritedPermissions -Path "$Path"
					}
				}
			}
			Else {
				If(!$Filename) {
					If ($Action -ieq "Disable") {
						Set-FolderInheritance -Action "Disable" -Path "$Path"	
					}
					Else {
						If($Recurse) {
							Set-FolderInheritance -Action "Enable" -Path "$Path"
							Remove-NotInheritedPermissions -Path "$Path"
							$SubDirs = Get-ChildItem -Path "$Path\*" | Where { $_.PSisContainer }
							ForEach ($SubDir in $SubDirs) { 
								Set-FolderInheritance -Action "Enable" -Path "$SubDir"
								Remove-NotInheritedPermissions -Path "$SubDir"
							}
						}
						Else {
							Set-FolderInheritance -Action "Enable" -Path "$Path"
							Remove-NotInheritedPermissions -Path "$Path"
						}
					}
				}
				Else {
					If ($Action -ieq "Disable") {
						Set-FileInheritance -Action "Disable" -Path "$Path" -Filename "$Filename"
					}
					Else {
						Set-FileInheritance -Action "Enable" -Path "$Path" -Filename "$Filename"
						Remove-NotInheritedPermissions -Path "$Path\$Filename"
					}
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to change the inheritance. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to change the inheritance: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Set-IniValue
Function Set-IniValue {
<#
.SYNOPSIS
	Opens an INI file and sets the value of the specified section and key.
.DESCRIPTION
	Opens an INI file and sets the value of the specified section and key.
.PARAMETER FilePath
	Path to the INI file.
.PARAMETER Section
	Section within the INI file.
.PARAMETER Key
	Key within the section of the INI file.
.PARAMETER Value
	Value for the key within the section of the INI file. To remove a value, set this variable to $null.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Set-IniValue -FilePath "$ProgramFilesX86\IBM\Notes\notes.ini" -Section 'Notes' -Key 'KeyFileName' -Value 'MyFile.ID'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$FilePath,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Section,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		# Don't strongly type this variable as [string] b/c PowerShell replaces [string]$Value = $null with an empty string
		[Parameter(Mandatory=$true)]
		[AllowNull()]
		$Value,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Write INI Key Value: [Section = $Section] [Key = $Key] [Value = $Value]." -Source ${CmdletName}
			
			If (-not (Test-Path -LiteralPath $FilePath -PathType 'Leaf')) { Throw "File [$filePath] could not be found." }
			
			[PackagingFramework.IniFile]::SetIniValue($Section, $Key, ([Text.StringBuilder]$Value), $FilePath)
		}
		Catch {
			Write-Log -Message "Failed to write INI file key value. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to write INI file key value: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Set-InstallPhase
Function Set-InstallPhase {
<#
.SYNOPSIS
	Specify the Install Phase parameter
.DESCRIPTION
	Command to specify the Install Phase parameter that is used to seperate sections in your installation script and log file
.PARAMETER String
	Text string that is used as install phase
.EXAMPLE
	Set-InstallPhase "Install"
.EXAMPLE
	Set-InstallPhase "Uninstall"
.EXAMPLE
	Set-InstallPhase "Repair"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[Parameter(Mandatory=$True)]
		[ValidateNotNullorEmpty()]
		[string]$InstallPhase
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
            [string]$Global:InstallPhase = $InstallPhase

		}
		Catch {
                Write-Log -Message "Failed to set install phase string. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
    			If (-not $ContinueOnError) {
				Throw "Failed to set install phase string.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Set-InstallPhase

#region Function Set-MsiProperty
Function Set-MsiProperty {
<#
.SYNOPSIS
	Set a property in the MSI property table.
.DESCRIPTION
	Set a property in the MSI property table.
.PARAMETER DataBase
	Specify a ComObject representing an MSI database opened in view/modify/update mode.
.PARAMETER PropertyName
	The name of the property to be set/modified.
.PARAMETER PropertyValue
	The value of the property to be set/modified.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Set-MsiProperty -DataBase $TempMsiPathDatabase -PropertyName 'ALLUSERS' -PropertyValue '1'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[__comobject]$DataBase,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$PropertyName,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$PropertyValue,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Set the MSI Property Name [$PropertyName] with Property Value [$PropertyValue]." -Source ${CmdletName}
			
			## Open the requested table view from the database
			[__comobject]$View = Invoke-ObjectMethod -InputObject $DataBase -MethodName 'OpenView' -ArgumentList @("SELECT * FROM Property WHERE Property='$PropertyName'")
			$null = Invoke-ObjectMethod -InputObject $View -MethodName 'Execute'
			
			## Retrieve the requested property from the requested table.
			#  https://msdn.microsoft.com/en-us/library/windows/desktop/aa371136(v=vs.85).aspx
			[__comobject]$Record = Invoke-ObjectMethod -InputObject $View -MethodName 'Fetch'
			
			## Close the previous view on the MSI database
			$null = Invoke-ObjectMethod -InputObject $View -MethodName 'Close' -ArgumentList @()
			$null = [Runtime.Interopservices.Marshal]::ReleaseComObject($View)
			
			## Set the MSI property
			If ($Record) {
				#  If the property already exists, then create the view for updating the property
				[__comobject]$View = Invoke-ObjectMethod -InputObject $DataBase -MethodName 'OpenView' -ArgumentList @("UPDATE Property SET Value='$PropertyValue' WHERE Property='$PropertyName'")
			}
			Else {
				#  If property does not exist, then create view for inserting the property
				[__comobject]$View = Invoke-ObjectMethod -InputObject $DataBase -MethodName 'OpenView' -ArgumentList @("INSERT INTO Property (Property, Value) VALUES ('$PropertyName','$PropertyValue')")
			}
			#  Execute the view to set the MSI property
			$null = Invoke-ObjectMethod -InputObject $View -MethodName 'Execute'
		}
		Catch {
			Write-Log -Message "Failed to set the MSI Property Name [$PropertyName] with Property Value [$PropertyValue]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to set the MSI Property Name [$PropertyName] with Property Value [$PropertyValue]: $($_.Exception.Message)"
			}
		}
		Finally {
			Try {
				If ($View) {
					$null = Invoke-ObjectMethod -InputObject $View -MethodName 'Close' -ArgumentList @()
					$null = [Runtime.Interopservices.Marshal]::ReleaseComObject($View)
				}
			}
			Catch { }
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Set-PinnedApplication
Function Set-PinnedApplication {
<#
.SYNOPSIS
	Pins or unpins a shortcut to the start menu or task bar.
.DESCRIPTION
	Pins or unpins a shortcut to the start menu or task bar.
	This should typically be run in the user context, as pinned items are stored in the user profile.
	NOTE: This command is deprecated, it's only supported on Windows 7/8 and Server 2008/2012 and the first Windows 10 version
	but doesn't  support newer Windows 10 versions or Server 2016. On this newer OS versions you have to use the layout XML
	feature, please refer to: https://docs.microsoft.com/en-US/windows/configuration/configure-windows-10-taskbar
.PARAMETER Action
	Action to be performed. Options: 'PintoStartMenu','UnpinfromStartMenu','PintoTaskbar','UnpinfromTaskbar'.
.PARAMETER FilePath
	Path to the shortcut file to be pinned or unpinned.
.EXAMPLE
	Set-PinnedApplication -Action 'PintoStartMenu' -FilePath "$ProgramFilesX86\IBM\Lotus\Notes\notes.exe"
.EXAMPLE
	Set-PinnedApplication -Action 'UnpinfromTaskbar' -FilePath "$ProgramFilesX86\IBM\Lotus\Notes\notes.exe"
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateSet('PintoStartMenu','UnpinfromStartMenu','PintoTaskbar','UnpinfromTaskbar')]
		[string]$Action,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$FilePath
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		#region Function Get-PinVerb
		Function Get-PinVerb {
			[CmdletBinding()]
			Param (
				[Parameter(Mandatory=$true)]
				[ValidateNotNullorEmpty()]
				[int32]$VerbId
			)
			
			[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
			
			Write-Log -Message "Get localized pin verb for verb id [$VerbID]." -Source ${CmdletName}
			[string]$PinVerb = [PackagingFramework.FileVerb]::GetPinVerb($VerbId)
			Write-Log -Message "Verb ID [$VerbID] has a localized pin verb of [$PinVerb]." -Source ${CmdletName}
			Write-Output -InputObject $PinVerb
		}
		#endregion
		
		#region Function Invoke-Verb
		Function Invoke-Verb {
			[CmdletBinding()]
			Param (
				[Parameter(Mandatory=$true)]
				[ValidateNotNullorEmpty()]
				[string]$FilePath,
				[Parameter(Mandatory=$true)]
				[ValidateNotNullorEmpty()]
				[string]$Verb
			)
			
			Try {
				[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
				$verb = $verb.Replace('&','')
				$path = Split-Path -Path $FilePath -Parent -ErrorAction 'Stop'
				$folder = $shellApp.Namespace($path)
				$item = $folder.ParseName((Split-Path -Path $FilePath -Leaf -ErrorAction 'Stop'))
				$itemVerb = $item.Verbs() | Where-Object { $_.Name.Replace('&','') -eq $verb } -ErrorAction 'Stop'
				
				If ($null -eq $itemVerb) {
					Write-Log -Message "Performing action [$verb] is not programmatically supported for this file [$FilePath]." -Severity 2 -Source ${CmdletName}
				}
				Else {
					Write-Log -Message "Perform action [$verb] on [$FilePath]." -Source ${CmdletName}
					$itemVerb.DoIt()
				}
			}
			Catch {
				Write-Log -Message "Failed to perform action [$verb] on [$FilePath]. `n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
			}
		}
		#endregion
		
		If (([version]$OSVersion).Major -ge 10) {
			Write-Log -Message "Detected Windows 10 or higher, using Windows 10 verb codes." -Source ${CmdletName}
			[hashtable]$Verbs = @{
				'PintoStartMenu' = 51201
				'UnpinfromStartMenu' = 51394
				'PintoTaskbar' = 5386
				'UnpinfromTaskbar' = 5387
			}
		}
		Else {
			[hashtable]$Verbs = @{
			'PintoStartMenu' = 5381
			'UnpinfromStartMenu' = 5382
			'PintoTaskbar' = 5386
			'UnpinfromTaskbar' = 5387
			}
		}
		
	}
	Process {
		Try {
			Write-Log -Message "Execute action [$Action] for file [$FilePath]." -Source ${CmdletName}
			
			If (-not (Test-Path -LiteralPath $FilePath -PathType 'Leaf' -ErrorAction 'Stop')) {
				Throw "Path [$filePath] does not exist."
			}
			
			If (-not ($Verbs.$Action)) {
				Throw "Action [$Action] not supported. Supported actions are [$($Verbs.Keys -join ', ')]."
			}
			
			[string]$PinVerbAction = Get-PinVerb -VerbId $Verbs.$Action
			If (-not ($PinVerbAction)) {
				Throw "Failed to get a localized pin verb for action [$Action]. Action is not supported on this operating system."
			}
			
			Invoke-Verb -FilePath $FilePath -Verb $PinVerbAction
		}
		Catch {
			Write-Log -Message "Failed to execute action [$Action]. `n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Set-RegistryKey
Function Set-RegistryKey {
<#
.SYNOPSIS
	Creates a registry key name, value, and value data; it sets the same if it already exists.
.DESCRIPTION
	Creates a registry key name, value, and value data; it sets the same if it already exists.
.PARAMETER Key
	The registry key path.
.PARAMETER Name
	The value name.
.PARAMETER Value
	The value data.
.PARAMETER Type
	The type of registry value to create or set. Options: 'Binary','DWord','ExpandString','MultiString','None','QWord','String','Unknown'. Default: String.
.PARAMETER SID
	The security identifier (SID) for a user. Specifying this parameter will convert a HKEY_CURRENT_USER registry key to the HKEY_USERS\$SID format.
	Specify this parameter from the Invoke-HKCURegistrySettingsForAllUsers function to read/edit HKCU registry settings for all users on the system.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Set-RegistryKey -Key $blockedAppPath -Name 'Debugger' -Value $blockedAppDebuggerValue
.EXAMPLE
	Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'Debugger' -Value $blockedAppDebuggerValue -Type String
.EXAMPLE
	Set-RegistryKey -Key 'HKCU\Software\Microsoft\Example' -Name 'Data' -Value (0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x02,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x02,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x00,0x01,0x01,0x01,0x02,0x02,0x02) -Type 'Binary'
.EXAMPLE
    Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Example' -Value '(Default)'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Key,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		$Value,
		[Parameter(Mandatory=$false)]
		[ValidateSet('Binary','DWord','ExpandString','MultiString','None','QWord','String','Unknown')]
		[Microsoft.Win32.RegistryValueKind]$Type = 'String',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$SID,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			[string]$RegistryValueWriteAction = 'set'
			
			## If the SID variable is specified, then convert all HKEY_CURRENT_USER key's to HKEY_USERS\$SID
			If ($PSBoundParameters.ContainsKey('SID')) {
				[string]$key = Convert-RegistryPath -Key $key -SID $SID
			}
			Else {
				[string]$key = Convert-RegistryPath -Key $key
			}
			
			## Replace forward slash character to allow forward slash in name of registry key rather than creating new subkey
			$key = $key.Replace('/',"$([char]0x2215)")
			
			## Create registry key if it doesn't exist
			If (-not (Test-Path -LiteralPath $key -ErrorAction 'Stop')) {
				Try {
					Write-Log -Message "Create registry key [$key]." -Source ${CmdletName}
					$null = New-Item -Path $key -ItemType 'Registry' -Force -ErrorAction 'Stop'
				}
				Catch {
					Throw
				}
			}
			
			If ($Name) {
				## Set registry value if it doesn't exist
				If (-not (Get-ItemProperty -LiteralPath $key -Name $Name -ErrorAction 'SilentlyContinue')) {
					Write-Log -Message "Set registry key value: [$key] [$name = $value]." -Source ${CmdletName}
					$null = New-ItemProperty -LiteralPath $key -Name $name -Value $value -PropertyType $Type -ErrorAction 'Stop'
				}
				## Update registry value if it does exist
				Else {
					[string]$RegistryValueWriteAction = 'update'
					If ($Name -eq '(Default)') {
						## Set Default registry key value with the following workaround, because Set-ItemProperty contains a bug and cannot set Default registry key value
						$null = $(Get-Item -LiteralPath $key -ErrorAction 'Stop').OpenSubKey('','ReadWriteSubTree').SetValue($null,$value)
					} 
					Else {
						Write-Log -Message "Update registry key value: [$key] [$name = $value]." -Source ${CmdletName}
						$null = Set-ItemProperty -LiteralPath $key -Name $name -Value $value -ErrorAction 'Stop'
					}
				}
			}
		}
		Catch {
			If ($Name) {
				Write-Log -Message "Failed to $RegistryValueWriteAction value [$value] for registry key [$key] [$name]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to $RegistryValueWriteAction value [$value] for registry key [$key] [$name]: $($_.Exception.Message)"
				}
			}
			Else {
				Write-Log -Message "Failed to set registry key [$key]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				If (-not $ContinueOnError) {
					Throw "Failed to set registry key [$key]: $($_.Exception.Message)"
				}
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Set-ServiceStartMode
Function Set-ServiceStartMode
{
<#
.SYNOPSIS
	Set the service startup mode.
.DESCRIPTION
	Set the service startup mode.
.PARAMETER Name
	Specify the name of the service.
.PARAMETER ComputerName
	Specify the name of the computer. Default is: the local computer.
.PARAMETER StartMode
	Specify startup mode for the service. Options: Automatic, Automatic (Delayed Start), Manual, Disabled, Boot, System.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Set-ServiceStartMode -Name 'wuauserv' -StartMode 'Automatic (Delayed Start)'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdLetBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory=$true)]
		[ValidateSet('Automatic','Automatic (Delayed Start)','Manual','Disabled','Boot','System')]
		[string]$StartMode,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	Begin {
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			## If on lower than Windows Vista and 'Automatic (Delayed Start)' selected, then change to 'Automatic' because 'Delayed Start' is not supported.
			If (($StartMode -eq 'Automatic (Delayed Start)') -and (([version]$OSVersion).Major -lt 6)) { $StartMode = 'Automatic' }
			
			Write-Log -Message "Set service [$Name] startup mode to [$StartMode]." -Source ${CmdletName}
			
			## Set the name of the start up mode that will be passed to sc.exe
			[string]$ScExeStartMode = $StartMode
			If ($StartMode -eq 'Automatic') { $ScExeStartMode = 'Auto' }
			If ($StartMode -eq 'Automatic (Delayed Start)') { $ScExeStartMode = 'Delayed-Auto' }
			If ($StartMode -eq 'Manual') { $ScExeStartMode = 'Demand' }
			
			## Set the start up mode using sc.exe. Note: we found that the ChangeStartMode method in the Win32_Service WMI class set services to 'Automatic (Delayed Start)' even when you specified 'Automatic' on Win7, Win8, and Win10.
			$ChangeStartMode = & sc.exe config $Name start= $ScExeStartMode
			
			If ($global:LastExitCode -ne 0) {
				Throw "sc.exe failed with exit code [$($global:LastExitCode)] and message [$ChangeStartMode]."
			}
			
			Write-Log -Message "Successfully set service [$Name] startup mode to [$StartMode]." -Source ${CmdletName}
		}
		Catch {
			Write-Log -Message "Failed to set service [$Name] startup mode to [$StartMode]. `n$(Resolve-Error)" -Source ${CmdletName} -Severity 3
			If (-not $ContinueOnError) {
				Throw "Failed to set service [$Name] startup mode to [$StartMode]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Show-DialogBox
Function Show-DialogBox {
<#
.SYNOPSIS
	Display a custom dialog box with optional title, buttons, icon and timeout.
	Show-InstallationPrompt is recommended over this function as it provides more customization and uses consistent branding with the other UI components.
.DESCRIPTION
	Display a custom dialog box with optional title, buttons, icon and timeout. The default button is "OK", the default Icon is "None", and the default Timeout is none.
.PARAMETER Text
	Text in the message dialog box
.PARAMETER Title
	Title of the message dialog box
.PARAMETER Buttons
	Buttons to be included on the dialog box. Options: OK, OKCancel, AbortRetryIgnore, YesNoCancel, YesNo, RetryCancel, CancelTryAgainContinue. Default: OK.
.PARAMETER DefaultButton
	The Default button that is selected. Options: First, Second, Third. Default: First.
.PARAMETER Icon
	Icon to display on the dialog box. Options: None, Stop, Question, Exclamation, Information. Default: None.
.PARAMETER Timeout
	Timeout period in seconds before automatically closing the dialog box with the return message "Timeout".
.PARAMETER TopMost
	Specifies whether the message box is a system modal message box and appears in a topmost window. Default: $true.
.EXAMPLE
	Show-DialogBox -Title 'Installed Complete' -Text 'Installation has completed. Please click OK and restart your computer.' -Icon 'Information'
.EXAMPLE
	Show-DialogBox -Title 'Installation Notice' -Text 'Installation will take approximately 30 minutes. Do you wish to proceed?' -Buttons 'OKCancel' -DefaultButton 'Second' -Icon 'Exclamation' -Timeout 600
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,Position=0,HelpMessage='Enter a message for the dialog box')]
		[ValidateNotNullorEmpty()]
		[string]$Text,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Title = $Global:InstallTitle,
		[Parameter(Mandatory=$false)]
		[ValidateSet('OK','OKCancel','AbortRetryIgnore','YesNoCancel','YesNo','RetryCancel','CancelTryAgainContinue')]
		[string]$Buttons = 'OK',
		[Parameter(Mandatory=$false)]
		[ValidateSet('First','Second','Third')]
		[string]$DefaultButton = 'First',
		[Parameter(Mandatory=$false)]
		[ValidateSet('Exclamation','Information','None','Stop','Question')]
		[string]$Icon = 'None',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Timeout = 600,
		[Parameter(Mandatory=$false)]
		[Switch]$TopMost = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		#  Bypass if in silent mode
		If ($deployMode -ieq 'silent') {
			Write-Log -Message "Bypassing Dialog Box [Mode: $deployMode]: $Text..." -Source ${CmdletName}
			Return
		}
		
		Write-Log -Message "Display Dialog Box with message: $Text..." -Source ${CmdletName}
		
		[hashtable]$dialogButtons = @{
			'OK' = 0
			'OKCancel' = 1
			'AbortRetryIgnore' = 2
			'YesNoCancel' = 3
			'YesNo' = 4
			'RetryCancel' = 5
			'CancelTryAgainContinue' = 6
		}
		
		[hashtable]$dialogIcons = @{
			'None' = 0
			'Stop' = 16
			'Question' = 32
			'Exclamation' = 48
			'Information' = 64
		}
		
		[hashtable]$dialogDefaultButton = @{
			'First' = 0
			'Second' = 256
			'Third' = 512
		}
		
		Switch ($TopMost) {
			$true { $dialogTopMost = 4096 }
			$false { $dialogTopMost = 0 }
		}
        
        [__comobject]$Shell = New-Object -ComObject 'WScript.Shell' -ErrorAction 'SilentlyContinue'
        $response = $Shell.Popup($Text, $Timeout, $Title, ($dialogButtons[$Buttons] + $dialogIcons[$Icon] + $dialogDefaultButton[$DefaultButton] + $dialogTopMost))
		
		Switch ($response) {
			1 {
				Write-Log -Message 'Dialog Box Response: OK' -Source ${CmdletName}
				Write-Output -InputObject 'OK'
			}
			2 {
				Write-Log -Message 'Dialog Box Response: Cancel' -Source ${CmdletName}
				Write-Output -InputObject 'Cancel'
			}
			3 {
				Write-Log -Message 'Dialog Box Response: Abort' -Source ${CmdletName}
				Write-Output -InputObject 'Abort'
			}
			4 {
				Write-Log -Message 'Dialog Box Response: Retry' -Source ${CmdletName}
				Write-Output -InputObject 'Retry'
			}
			5 {
				Write-Log -Message 'Dialog Box Response: Ignore' -Source ${CmdletName}
				Write-Output -InputObject 'Ignore'
			}
			6 {
				Write-Log -Message 'Dialog Box Response: Yes' -Source ${CmdletName}
				Write-Output -InputObject 'Yes'
			}
			7 {
				Write-Log -Message 'Dialog Box Response: No' -Source ${CmdletName}
				Write-Output -InputObject 'No'
			}
			10 {
				Write-Log -Message 'Dialog Box Response: Try Again' -Source ${CmdletName}
				Write-Output -InputObject 'Try Again'
			}
			11 {
				Write-Log -Message 'Dialog Box Response: Continue' -Source ${CmdletName}
				Write-Output -InputObject 'Continue'
			}
			-1 {
				Write-Log -Message 'Dialog Box Timed Out...' -Source ${CmdletName}
				Write-Output -InputObject 'Timeout'
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Show-HelpConsole
Function Show-HelpConsole {
<#
.SYNOPSIS
	Displays the help console
.DESCRIPTION
	Displays a graphical console to browse the help for the Packaging Framework functions
.EXAMPLE
	Show-HelpConsole
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>


	## Import the Assemblies
	Add-Type -AssemblyName 'System.Windows.Forms' -ErrorAction 'Stop'
	Add-Type -AssemblyName 'System.Drawing' -ErrorAction 'Stop'

	## Form Objects
	$HelpForm = New-Object -TypeName 'System.Windows.Forms.Form'
	$HelpListBox = New-Object -TypeName 'System.Windows.Forms.ListBox'
	$HelpTextBox = New-Object -TypeName 'System.Windows.Forms.RichTextBox'
	$InitialFormWindowState = New-Object -TypeName 'System.Windows.Forms.FormWindowState'

	## Form Code
	$System_Drawing_Size = New-Object -TypeName 'System.Drawing.Size'
	$System_Drawing_Size.Height = 665
	$System_Drawing_Size.Width = 957
	$HelpForm.ClientSize = $System_Drawing_Size
	$HelpForm.DataBindings.DefaultDataSourceUpdateMode = 0
	$HelpForm.Name = 'HelpForm'
	$HelpForm.Text = 'PowerShell Packaging Framework Help Console'
	$HelpForm.WindowState = 'Normal'
	$HelpForm.ShowInTaskbar = $true
	$HelpForm.FormBorderStyle = 'Fixed3D'
	$HelpForm.MaximizeBox = $false
	$HelpListBox.Anchor = 7
	$HelpListBox.BorderStyle = 1
	$HelpListBox.DataBindings.DefaultDataSourceUpdateMode = 0
	$HelpListBox.Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList ('Microsoft Sans Serif', 9.75, 1, 3, 1)
	$HelpListBox.FormattingEnabled = $true
	$HelpListBox.ItemHeight = 16
	$System_Drawing_Point = New-Object -TypeName 'System.Drawing.Point'
	$System_Drawing_Point.X = 0
	$System_Drawing_Point.Y = 0
	$HelpListBox.Location = $System_Drawing_Point
	$HelpListBox.Name = 'HelpListBox'
	$System_Drawing_Size = New-Object -TypeName 'System.Drawing.Size'
	$System_Drawing_Size.Height = 658
	$System_Drawing_Size.Width = 271
	$HelpListBox.Size = $System_Drawing_Size
	$HelpListBox.Sorted = $true
	$HelpListBox.TabIndex = 2
	$HelpListBox.add_SelectedIndexChanged({ $HelpTextBox.Text = Get-Help -Name $HelpListBox.SelectedItem -Detailed | Out-String })
	$helpFunctions = Get-Command -CommandType 'Function' | Where-Object { ($_.HelpUri -match 'ceterion') -or ($_.HelpUri -match 'psappdeploytoolkit') -and ($_.Definition -notmatch 'internal script function') } | Select-Object -ExpandProperty Name
	ForEach ($helpFunction in $helpFunctions) {
		$null = $HelpListBox.Items.Add($helpFunction)
	}
	$HelpForm.Controls.Add($HelpListBox)
	$HelpTextBox.Anchor = 11
	$HelpTextBox.BorderStyle = 1
	$HelpTextBox.DataBindings.DefaultDataSourceUpdateMode = 0
	$HelpTextBox.Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList ('Microsoft Sans Serif', 8.5, 0, 3, 1)
	$HelpTextBox.ForeColor = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
	$System_Drawing_Point = New-Object -TypeName System.Drawing.Point
	$System_Drawing_Point.X = 277
	$System_Drawing_Point.Y = 0
	$HelpTextBox.Location = $System_Drawing_Point
	$HelpTextBox.Name = 'HelpTextBox'
	$HelpTextBox.ReadOnly = $True
	$System_Drawing_Size = New-Object -TypeName 'System.Drawing.Size'
	$System_Drawing_Size.Height = 658
	$System_Drawing_Size.Width = 680
	$HelpTextBox.Size = $System_Drawing_Size
	$HelpTextBox.TabIndex = 1
	$HelpTextBox.Text = ''
	$HelpForm.Controls.Add($HelpTextBox)

	## Save the initial state of the form
	$InitialFormWindowState = $HelpForm.WindowState
	## Init the OnLoad event to correct the initial state of the form
	$HelpForm.add_Load($OnLoadForm_StateCorrection)
	## Show the Form
	$null = $HelpForm.ShowDialog()

}

#endregion Function Show-HelpConsole

#region Function Start-Program
Function Start-Program {
<#
.SYNOPSIS
	Execute a process with optional arguments, working directory, window style.
.DESCRIPTION
	Executes a process, e.g. a file included in the Files directory of the package, or a file on the local machine.
	Provides various options for handling the return codes (see Parameters).
.PARAMETER Path
	Path to the file to be executed. If the file is located directly in the "Files" directory of the package, only the file name needs to be specified.
	Otherwise, the full path of the file must be specified. If the files is in a subdirectory of "Files", use the "$Files" variable as shown in the example.
.PARAMETER Parameters
	Arguments to be passed to the executable
.PARAMETER SecureParameters
	Hides all parameters passed to the executable from the log file
.PARAMETER WindowStyle
	Style of the window of the process executed. Options: Normal, Hidden, Maximized, Minimized. Default: Normal.
	Note: Not all processes honor the "Hidden" flag. If it it not working, then check the command line options for the process being executed to see it has a silent option.
.PARAMETER CreateNoWindow
	Specifies whether the process should be started with a new window to contain it. Default is false.
.PARAMETER WorkingDirectory
	The working directory used for executing the process. Defaults to the directory of the file being executed.
.PARAMETER NoWait
	Immediately continue after executing the process.
.PARAMETER PassThru
	Returns ExitCode, STDOut, and STDErr output from the process.
.PARAMETER WaitForMsiExec
	Sometimes an EXE bootstrapper will launch an MSI install. In such cases, this variable will ensure that
	this function waits for the msiexec engine to become available before starting the install.
.PARAMETER MsiExecWaitTime
	Specify the length of time in seconds to wait for the msiexec engine to become available. Default: 600 seconds (10 minutes).
.PARAMETER IgnoreExitCodes
	List the exit codes to ignore.
.PARAMETER ContinueOnError
	Continue if an exit code is returned by the process that is not recognized. Default: $false.
.EXAMPLE
	Start-Program -Path 'uninstall_flash_player_64bit.exe' -Parameters '/uninstall' -WindowStyle 'Hidden'
	If the file is in the "Files" directory of the package, only the file name needs to be specified.
.EXAMPLE
	Start-Program -Path "$Files\Bin\setup.exe" -Parameters '/S' -WindowStyle 'Hidden'
.EXAMPLE
	Start-Program -Path 'setup.exe' -Parameters '/S' -IgnoreExitCodes '1,2'
.EXAMPLE
	Start-Program -Path 'setup.exe' -Parameters "-s -f2`"$ConfigLogDir\$installName.log`""
	Launch InstallShield "setup.exe" from the ".\Files" sub-directory and force log files to the logging folder.
.EXAMPLE
	Start-Program -Path 'setup.exe' -Parameters "/s /v`"ALLUSERS=1 /qn /L* \`"$ConfigLogDir\$installName.log`"`""
	Launch InstallShield "setup.exe" with embedded MSI and force log files to the logging folder.
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[Alias('FilePath')]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[Alias('Arguments')]
		[ValidateNotNullorEmpty()]
		[string[]]$Parameters,
		[Parameter(Mandatory=$false)]
		[Switch]$SecureParameters = $false,
		[Parameter(Mandatory=$false)]
		[ValidateSet('Normal','Hidden','Maximized','Minimized')]
		[Diagnostics.ProcessWindowStyle]$WindowStyle = 'Normal',
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[Switch]$CreateNoWindow = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$WorkingDirectory,
		[Parameter(Mandatory=$false)]
		[Switch]$NoWait = $false,
		[Parameter(Mandatory=$false)]
		[Switch]$PassThru = $false,
		[Parameter(Mandatory=$false)]
		[Switch]$WaitForMsiExec = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[timespan]$MsiExecWaitTime = $(New-TimeSpan -Seconds 600),
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$IgnoreExitCodes,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $false
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			$private:returnCode = $null
			
			## Validate and find the fully qualified path for the $Path variable.
			If (([IO.Path]::IsPathRooted($Path)) -and ([IO.Path]::HasExtension($Path))) {
				Write-Log -Message "[$Path] is a valid fully qualified path, continue." -Source ${CmdletName}
				If (-not (Test-Path -LiteralPath $Path -PathType 'Leaf' -ErrorAction 'Stop')) {
					Throw "File [$Path] not found."
				}
			}
			Else {
				#  The first directory to search will be the 'Files' subdirectory of the script directory
				[string]$PathFolders = $Files
				#  Add the current location of the console (Windows always searches this location first)
				[string]$PathFolders = $PathFolders + ';' + (Get-Location -PSProvider 'FileSystem').Path
				#  Add the new path locations to the PATH environment variable
				$env:PATH = $PathFolders + ';' + $env:PATH
				
				#  Get the fully qualified path for the file. Get-Command searches PATH environment variable to find this value.
				[string]$FullyQualifiedPath = Get-Command -Name $Path -CommandType 'Application' -TotalCount 1 -Syntax -ErrorAction 'Stop'
				
				#  Revert the PATH environment variable to it's original value
				$env:PATH = $env:PATH -replace [regex]::Escape($PathFolders + ';'), ''
				
				If ($FullyQualifiedPath) {
					Write-Log -Message "[$Path] successfully resolved to fully qualified path [$FullyQualifiedPath]." -Source ${CmdletName}
					$Path = $FullyQualifiedPath
				}
				Else {
					Throw "[$Path] contains an invalid path or file name."
				}
			}
			
			## Set the Working directory (if not specified)
			If (-not $WorkingDirectory) { $WorkingDirectory = Split-Path -Path $Path -Parent -ErrorAction 'Stop' }
			
			## If MSI install, check to see if the MSI installer service is available or if another MSI install is already underway.
			## Please note that a race condition is possible after this check where another process waiting for the MSI installer
			##  to become available grabs the MSI Installer mutex before we do. Not too concerned about this possible race condition.
			If (($Path -match 'msiexec') -or ($WaitForMsiExec)) {
				[boolean]$MsiExecAvailable = Test-IsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds $MsiExecWaitTime.TotalMilliseconds
				Start-Sleep -Seconds 1
				If (-not $MsiExecAvailable) {
					#  Default MSI exit code for install already in progress
					[int32]$returnCode = 1618
					Throw 'Please complete in progress MSI installation before proceeding with this install.'
				}
			}
			
			Try {
				## Disable Zone checking to prevent warnings when running executables
				$env:SEE_MASK_NOZONECHECKS = 1
				
				## Using this variable allows capture of exceptions from .NET methods. Private scope only changes value for current function.
				$private:previousErrorActionPreference = $ErrorActionPreference
				$ErrorActionPreference = 'Stop'
				
				## Define process
				$processStartInfo = New-Object -TypeName 'System.Diagnostics.ProcessStartInfo' -ErrorAction 'Stop'
				$processStartInfo.FileName = $Path
				$processStartInfo.WorkingDirectory = $WorkingDirectory
				$processStartInfo.UseShellExecute = $false
				$processStartInfo.ErrorDialog = $false
				$processStartInfo.RedirectStandardOutput = $true
				$processStartInfo.RedirectStandardError = $true
				$processStartInfo.CreateNoWindow = $CreateNoWindow
				If ($Parameters) { $processStartInfo.Arguments = $Parameters }
				If ($windowStyle) { $processStartInfo.WindowStyle = $WindowStyle }
				$process = New-Object -TypeName 'System.Diagnostics.Process' -ErrorAction 'Stop'
				$process.StartInfo = $processStartInfo
				
				## Add event handler to capture process's standard output redirection
				[scriptblock]$processEventHandler = { If (-not [string]::IsNullOrEmpty($EventArgs.Data)) { $Event.MessageData.AppendLine($EventArgs.Data) } }
				$stdOutBuilder = New-Object -TypeName 'System.Text.StringBuilder' -ArgumentList ''
				$stdOutEvent = Register-ObjectEvent -InputObject $process -Action $processEventHandler -EventName 'OutputDataReceived' -MessageData $stdOutBuilder -ErrorAction 'Stop'
				
				## Start Process
				Write-Log -Message "Working Directory is [$WorkingDirectory]." -Source ${CmdletName}
				If ($Parameters) {
					If ($Parameters -match '-Command \&') {
						Write-Log -Message "Executing [$Path [PowerShell ScriptBlock]]..." -Source ${CmdletName}
					}
					Else {
						If ($SecureParameters) {
							Write-Log -Message "Executing [$Path (Parameters Hidden)]..." -Source ${CmdletName}
						}
						Else {							
							Write-Log -Message "Executing [$Path $Parameters]..." -Source ${CmdletName}
						}
					}
				}
				Else {
					Write-Log -Message "Executing [$Path]..." -Source ${CmdletName}
				}
				[boolean]$processStarted = $process.Start()
				
				If ($NoWait) {
					Write-Log -Message 'NoWait parameter specified. Continuing without waiting for exit code...' -Source ${CmdletName}
				}
				Else {
					$process.BeginOutputReadLine()
					$stdErr = $($process.StandardError.ReadToEnd()).ToString() -replace $null,''
					
					## Instructs the Process component to wait indefinitely for the associated process to exit.
					$process.WaitForExit()
					
					## HasExited indicates that the associated process has terminated, either normally or abnormally. Wait until HasExited returns $true.
					While (-not ($process.HasExited)) { $process.Refresh(); Start-Sleep -Seconds 1 }
					
					## Get the exit code for the process
					Try {
						[int32]$returnCode = $process.ExitCode
					}
					Catch [System.Management.Automation.PSInvalidCastException] {
						#  Catch exit codes that are out of int32 range
						[int32]$returnCode = 60013
					}
					
					## Unregister standard output event to retrieve process output
					If ($stdOutEvent) { Unregister-Event -SourceIdentifier $stdOutEvent.Name -ErrorAction 'Stop'; $stdOutEvent = $null }
					$stdOut = $stdOutBuilder.ToString() -replace $null,''
					
					If ($stdErr.Length -gt 0) {
						Write-Log -Message "Standard error output from the process: $stdErr" -Severity 3 -Source ${CmdletName}
					}
				}
			}
			Finally {
				## Make sure the standard output event is unregistered
				If ($stdOutEvent) { Unregister-Event -SourceIdentifier $stdOutEvent.Name -ErrorAction 'Stop'}
				
				## Free resources associated with the process, this does not cause process to exit
				If ($process) { $process.Close() }
				
				## Re-enable Zone checking
				Remove-Item -LiteralPath 'env:SEE_MASK_NOZONECHECKS' -ErrorAction 'SilentlyContinue'
				
				If ($private:previousErrorActionPreference) { $ErrorActionPreference = $private:previousErrorActionPreference }
			}
			
			If (-not $NoWait) {
				## Check to see whether we should ignore exit codes
				$ignoreExitCodeMatch = $false
				If ($ignoreExitCodes) {
					#  Split the processes on a comma
					[int32[]]$ignoreExitCodesArray = $ignoreExitCodes -split ','
					ForEach ($ignoreCode in $ignoreExitCodesArray) {
						If ($returnCode -eq $ignoreCode) { $ignoreExitCodeMatch = $true }
					}
				}
				#  Or always ignore exit codes
				If ($ContinueOnError) { $ignoreExitCodeMatch = $true }
				
				## If the passthru switch is specified, return the exit code and any output from process
				If ($PassThru) {
					Write-Log -Message "Execution completed with exit code [$returnCode]." -Source ${CmdletName}
					[psobject]$ExecutionResults = New-Object -TypeName 'PSObject' -Property @{ ExitCode = $returnCode; StdOut = $stdOut; StdErr = $stdErr }
					Write-Output -InputObject $ExecutionResults
				}
				ElseIf ($ignoreExitCodeMatch) {
					Write-Log -Message "Execution complete and the exit code [$returncode] is being ignored." -Source ${CmdletName}
				}
				ElseIf (($returnCode -eq 3010) -or ($returnCode -eq 1641)) {
					Write-Log -Message "Execution completed successfully with exit code [$returnCode]. A reboot is required." -Severity 2 -Source ${CmdletName}
					Set-Variable -Name 'MSIRebootDetected' -Value $true -Scope 'Script'
				}
				ElseIf (($returnCode -eq 1605) -and ($Path -match 'msiexec')) {
					Write-Log -Message "Execution failed with exit code [$returnCode] because the product is not currently installed." -Severity 3 -Source ${CmdletName}
				}
				ElseIf (($returnCode -eq -2145124329) -and ($Path -match 'wusa')) {
					Write-Log -Message "Execution failed with exit code [$returnCode] because the Windows Update is not applicable to this system." -Severity 3 -Source ${CmdletName}
				}
				ElseIf (($returnCode -eq 17025) -and ($Path -match 'fullfile')) {
					Write-Log -Message "Execution failed with exit code [$returnCode] because the Office Update is not applicable to this system." -Severity 3 -Source ${CmdletName}
				}
				ElseIf ($returnCode -eq 0) {
					Write-Log -Message "Execution completed successfully with exit code [$returnCode]." -Source ${CmdletName}
				}
				Else {
					[string]$MsiExitCodeMessage = ''
					If ($Path -match 'msiexec') {
						[string]$MsiExitCodeMessage = Get-MsiExitCodeMessage -MsiExitCode $returnCode
					}
					
					If ($MsiExitCodeMessage) {
						Write-Log -Message "Execution failed with exit code [$returnCode]: $MsiExitCodeMessage" -Severity 3 -Source ${CmdletName}
					}
					Else {
						Write-Log -Message "Execution failed with exit code [$returnCode]." -Severity 3 -Source ${CmdletName}
					}
					Exit-Script -ExitCode $returnCode
				}
			}
		}
		Catch {
			If ([string]::IsNullOrEmpty([string]$returnCode)) {
				[int32]$returnCode = 60002
				Write-Log -Message "Function failed, setting exit code to [$returnCode]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
			Else {
				Write-Log -Message "Execution completed with exit code [$returnCode]. Function failed. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
			If ($PassThru) {
				[psobject]$ExecutionResults = New-Object -TypeName 'PSObject' -Property @{ ExitCode = $returnCode; StdOut = If ($stdOut) { $stdOut } Else { '' }; StdErr = If ($stdErr) { $stdErr } Else { '' } }
				Write-Output -InputObject $ExecutionResults
			}
			Else {
				Exit-Script -ExitCode $returnCode
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Start-MSI
Function Start-MSI {
<#
.SYNOPSIS
	Executes msiexec.exe to perform the following actions for MSI & MSP files and MSI product codes: install, uninstall, patch, repair, active setup.
.DESCRIPTION
	Executes msiexec.exe to perform the following actions for MSI & MSP files and MSI product codes: install, uninstall, patch, repair, active setup.
	If the -Action parameter is set to "Install" and the MSI is already installed, the function will exit.
	Automatically generates a log file name and creates a verbose log file for all msiexec operations.
	Expects the MSI or MSP file to be located in the "Files" sub directory of the package. Expects transform files to be in the same directory as the MSI file.
.PARAMETER Action
	The action to perform. Options: Install, Uninstall, Patch, Repair, ActiveSetup.
.PARAMETER Path
	The path to the MSI/MSP file or the product code of the installed MSI.
.PARAMETER Transform
	The name of the transform file(s) to be applied to the MSI. The transform file is expected to be in the same directory as the MSI file.
.PARAMETER Patch
	The name of the patch (msp) file(s) to be applied to the MSI for use with the "Install" action. The patch file is expected to be in the same directory as the MSI file.
.PARAMETER Parameters
	Overrides the default parameters. Install default is: "REBOOT=ReallySuppress /QB!". Uninstall default is: "REBOOT=ReallySuppress /QN".
.PARAMETER AddParameters
	Adds to the default parameters. Default is: "REBOOT=ReallySuppress /QB!". Uninstall default is: "REBOOT=ReallySuppress /QN".
.PARAMETER SecureParameters
	Hides all parameters passed to the MSI or MSP file from the package log file.
.PARAMETER LoggingOptions
	Overrides the default logging options. Default options are: "/L*v+".
.PARAMETER LogName
	Overrides the default log file name. The default log file name is generated from the package file name. If LogName does not end in .log, it will be automatically appended.
.PARAMETER WorkingDirectory
	Overrides the working directory. The working directory is set to the location of the MSI file.
.PARAMETER SkipMSIAlreadyInstalledCheck
	Skips the check to determine if the MSI is already installed on the system. Default is: $false.
.PARAMETER IncludeUpdatesAndHotfixes
	Include matches against updates and hotfixes in results.
.PARAMETER PassThru
	Returns ExitCode, STDOut, and STDErr output from the process.
.PARAMETER ContinueOnError
	Continue if an exit code is returned by msiexec that is not recognized. Default is: $false.
.EXAMPLE
	Start-MSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi'
	Installs an MSI
.EXAMPLE
	Start-MSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi' -Transform 'Adobe_FlashPlayer_11.2.202.233_x64_EN_01.mst' -Parameters '/QN'
	Installs an MSI, applying a transform and overriding the default MSI parameters
.EXAMPLE
	[psobject]$ExecuteMSIResult = Start-MSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi' -PassThru
	Installs an MSI and stores the result of the execution into a variable by using the -PassThru option
.EXAMPLE
	Start-MSI -Action 'Uninstall' -Path '{26923b43-4d38-484f-9b9e-de460746276c}'
	Uninstalls an MSI using a product code
.EXAMPLE
	Start-MSI -Action 'Patch' -Path 'Adobe_Reader_11.0.3_EN.msp'
	Installs an MSP
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateSet('Install','Uninstall','Patch','Repair','ActiveSetup')]
		[string]$Action = 'Install',
		[Parameter(Mandatory=$true,HelpMessage='Please enter either the path to the MSI/MSP file or the ProductCode')]
		[ValidateScript({($_ -match $Global:MSIProductCodeRegExPattern) -or ('.msi','.msp' -contains [IO.Path]::GetExtension($_))})]
		[Alias('FilePath')]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Transform,
		[Parameter(Mandatory=$false)]
		[Alias('Arguments')]
		[ValidateNotNullorEmpty()]
		[string]$Parameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$AddParameters,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[Switch]$SecureParameters = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Patch,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$LoggingOptions,
		[Parameter(Mandatory=$false)]
		[Alias('LogName')]
		[string]$Private:LogName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$WorkingDirectory,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[Switch]$SkipMSIAlreadyInstalledCheck = $false,
		[Parameter(Mandatory=$false)]
		[Switch]$IncludeUpdatesAndHotfixes = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[Switch]$PassThru = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $false
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
        
        [string]$ConfigMSILoggingOptions = "/L*V+"
        [string]$ConfigMSIInstallParams = "REBOOT=ReallySuppress /QB-!"
        [string]$ConfigMSISilentParams = "REBOOT=ReallySuppress /QN"
        [string]$ConfigMSIUninstallParams = "REBOOT=ReallySuppress /QN"
        [string]$ExeMsiexec = 'msiexec.exe'


		## Initialize variable indicating whether $Path variable is a Product Code or not
		[boolean]$PathIsProductCode = $false
		
		## If the path matches a product code
		If ($Path -match $Global:MSIProductCodeRegExPattern) {
			#  Set variable indicating that $Path variable is a Product Code
			[boolean]$PathIsProductCode = $true
			
			#  Resolve the product code to a publisher, application name, and version
			Write-Log -Message 'Resolve product code to a publisher, application name, and version.' -Source ${CmdletName}
			
			If ($IncludeUpdatesAndHotfixes) {
				[psobject]$productCodeNameVersion = Get-InstalledApplication -ProductCode $path -IncludeUpdatesAndHotfixes | Select-Object -Property 'Publisher', 'DisplayName', 'DisplayVersion' -First 1 -ErrorAction 'SilentlyContinue'	
			}
			Else {
				[psobject]$productCodeNameVersion = Get-InstalledApplication -ProductCode $path | Select-Object -Property 'Publisher', 'DisplayName', 'DisplayVersion' -First 1 -ErrorAction 'SilentlyContinue'
			}
									
			#  Build the log file name
            <#
			If (-not $LogName) {
				If ($productCodeNameVersion) {
					If ($productCodeNameVersion.Publisher) {
						$LogName = ($productCodeNameVersion.Publisher + '_' + $productCodeNameVersion.DisplayName + '_' + $productCodeNameVersion.DisplayVersion) -replace "[$InvalidFileNameChars]",'' -replace ' ',''
					}
					Else {
						$LogName = ($productCodeNameVersion.DisplayName + '_' + $productCodeNameVersion.DisplayVersion) -replace "[$InvalidFileNameChars]",'' -replace ' ',''
					}
				}
				Else {
					#  Out of other options, make the Product Code the name of the log file
					$LogName = $Path
				}
			}
            #>
		}

		<#
        Else {
			#  Get the log file name without file extension
			If (-not $LogName) { $LogName = ([IO.FileInfo]$path).BaseName } ElseIf ('.log','.txt' -contains [IO.Path]::GetExtension($LogName)) { $LogName = [IO.Path]::GetFileNameWithoutExtension($LogName) }
		}
        #>
		
        # when LogName is not specified use package name as logname and add _MSI to the name
        If (-not $LogName) { $LogName = $PackageName + '_' + 'MSI' }

        <#
		If ($ConfigCompressLogs) {
			## Build the log file path
			[string]$logPath = Join-Path -Path $LogTempFolder -ChildPath $LogName
		}
		Else {
        #>
			## Create the Log directory if it doesn't already exist
			If (-not (Test-Path -LiteralPath $LogDir -PathType 'Container' -ErrorAction 'SilentlyContinue')) {
				$null = New-Item -Path $LogDir -ItemType 'Directory' -ErrorAction 'SilentlyContinue'
			}
			## Build the log file path
			[string]$logPath = Join-Path -Path $LogDir -ChildPath $LogName
        #	}


		## Set the installation Parameters
		If ($DeployMode -ieq 'Silent') {
			$msiInstallDefaultParams = $ConfigMSISilentParams
			$msiUninstallDefaultParams = $ConfigMSISilentParams
		}
		Else {
			$msiInstallDefaultParams = $ConfigMSIInstallParams
			$msiUninstallDefaultParams = $ConfigMSIUninstallParams
		}
		
		## Build the MSI Parameters
		Switch ($action) {
			'Install' { $option = '/i'; [string]$msiLogFile = "$logPath" + '_Install'; $msiDefaultParams = $msiInstallDefaultParams }
			'Uninstall' { $option = '/x'; [string]$msiLogFile = "$logPath" + '_Uninstall'; $msiDefaultParams = $msiUninstallDefaultParams }
			'Patch' { $option = '/update'; [string]$msiLogFile = "$logPath" + '_Patch'; $msiDefaultParams = $msiInstallDefaultParams }
			'Repair' { $option = '/f'; [string]$msiLogFile = "$logPath" + '_Repair'; $msiDefaultParams = $msiInstallDefaultParams }
			'ActiveSetup' { $option = '/fups'; [string]$msiLogFile = "$logPath" + '_ActiveSetup' }
		}
		
		## Append ".log" to the MSI logfile path and enclose in quotes
		If ([IO.Path]::GetExtension($msiLogFile) -ne '.log') {
			[string]$msiLogFile = $msiLogFile + '.log'
			[string]$msiLogFile = "`"$msiLogFile`""
		}
		
		## If the MSI is in the Files directory, set the full path to the MSI
		If (Test-Path -LiteralPath (Join-Path -Path $Files -ChildPath $path -ErrorAction 'SilentlyContinue') -PathType 'Leaf' -ErrorAction 'SilentlyContinue') {
			[string]$msiFile = Join-Path -Path $Files -ChildPath $path
		}
		ElseIf (Test-Path -LiteralPath $Path -ErrorAction 'SilentlyContinue') {
			[string]$msiFile = (Get-Item -LiteralPath $Path).FullName
		}
		ElseIf ($PathIsProductCode) {
			[string]$msiFile = $Path
		}
		Else {
			Write-Log -Message "Failed to find MSI file [$path]." -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to find MSI file [$path]."
			}
			Continue
		}
		
		## Set the working directory of the MSI
		If ((-not $PathIsProductCode) -and (-not $workingDirectory)) { [string]$workingDirectory = Split-Path -Path $msiFile -Parent }
		
		## Enumerate all transforms specified, qualify the full path if possible and enclose in quotes
		If ($transform) {
			[string[]]$transforms = $transform -split ','
			0..($transforms.Length - 1) | ForEach-Object {
				If (Test-Path -LiteralPath (Join-Path -Path (Split-Path -Path $msiFile -Parent) -ChildPath $transforms[$_]) -PathType 'Leaf') {
					$transforms[$_] = Join-Path -Path (Split-Path -Path $msiFile -Parent) -ChildPath $transforms[$_].Replace('.\','')
				}
				Else {
					$transforms[$_] = $transforms[$_]
				}
			}
			[string]$mstFile = "`"$($transforms -join ';')`""
		}
		
		## Enumerate all patches specified, qualify the full path if possible and enclose in quotes
		If ($patch) {
			[string[]]$patches = $patch -split ','
			0..($patches.Length - 1) | ForEach-Object {
				If (Test-Path -LiteralPath (Join-Path -Path (Split-Path -Path $msiFile -Parent) -ChildPath $patches[$_]) -PathType 'Leaf') {
					$patches[$_] = Join-Path -Path (Split-Path -Path $msiFile -Parent) -ChildPath $patches[$_].Replace('.\','')
				}
				Else {
					$patches[$_] = $patches[$_]
				}
			}
			[string]$mspFile = "`"$($patches -join ';')`""
		}
		
		## Get the ProductCode of the MSI
		If ($PathIsProductCode) {
			[string]$MSIProductCode = $path
		}
		ElseIf ([IO.Path]::GetExtension($msiFile) -eq '.msi') {
			Try {
				[hashtable]$GetMsiTablePropertySplat = @{ Path = $msiFile; Table = 'Property'; ContinueOnError = $false }
				If ($transforms) { $GetMsiTablePropertySplat.Add( 'TransformPath', $transforms ) }
				[string]$MSIProductCode = Get-MsiTableProperty @GetMsiTablePropertySplat | Select-Object -ExpandProperty 'ProductCode' -ErrorAction 'Stop'
			}
			Catch {
				Write-Log -Message "Failed to get the ProductCode from the MSI file. Continue with requested action [$Action]..." -Source ${CmdletName}
			}
		}
		
		## Enclose the MSI file in quotes to avoid issues with spaces when running msiexec
		[string]$msiFile = "`"$msiFile`""
		
		## Start building the MsiExec command line starting with the base action and file
		[string]$argsMSI = "$option $msiFile"
		#  Add MST
		If ($transform) { $argsMSI = "$argsMSI TRANSFORMS=$mstFile TRANSFORMSSECURE=1" }
		#  Add MSP
		If ($patch) { $argsMSI = "$argsMSI PATCH=$mspFile" }
		#  Replace default parameters if specified.
		If ($Parameters) { $argsMSI = "$argsMSI $Parameters" } Else { $argsMSI = "$argsMSI $msiDefaultParams" }
		#  Append parameters to default parameters if specified.
		If ($AddParameters) { $argsMSI = "$argsMSI $AddParameters" }
		#  Add custom Logging Options if specified, otherwise, add default Logging Options from Config file
		If ($LoggingOptions) { $argsMSI = "$argsMSI $LoggingOptions $msiLogFile" } Else { $argsMSI = "$argsMSI $ConfigMSILoggingOptions $msiLogFile" }

		## Check if the MSI is already installed. If no valid ProductCode to check, then continue with requested MSI action.
		If ($MSIProductCode) {
			If ($SkipMSIAlreadyInstalledCheck) {
				[boolean]$IsMsiInstalled = $false
			}
			Else {								
				If ($IncludeUpdatesAndHotfixes) {
					[psobject]$MsiInstalled = Get-InstalledApplication -ProductCode $MSIProductCode -IncludeUpdatesAndHotfixes
				}
				Else {
					[psobject]$MsiInstalled = Get-InstalledApplication -ProductCode $MSIProductCode					
				}				
				If ($MsiInstalled) { [boolean]$IsMsiInstalled = $true }
			}
		}
		Else {
			If ($Action -eq 'Install') { [boolean]$IsMsiInstalled = $false } Else { [boolean]$IsMsiInstalled = $true }
		}
		
		If (($IsMsiInstalled) -and ($Action -eq 'Install')) {
			Write-Log -Message "The MSI is already installed on this system. Skipping action [$Action]..." -Source ${CmdletName}
		}
		ElseIf (((-not $IsMsiInstalled) -and ($Action -eq 'Install')) -or ($IsMsiInstalled)) {
			Write-Log -Message "Executing MSI action [$Action]..." -Source ${CmdletName}
			#  Build the hashtable with the options that will be passed to Start-Program using splatting
			[hashtable]$ExecuteProcessSplat =  @{ Path = $ExeMsiexec
												  Parameters = $argsMSI
												  WindowStyle = 'Normal' }
			If ($WorkingDirectory) { $ExecuteProcessSplat.Add( 'WorkingDirectory', $WorkingDirectory) }
			If ($ContinueOnError) { $ExecuteProcessSplat.Add( 'ContinueOnError', $ContinueOnError) }
			If ($SecureParameters) { $ExecuteProcessSplat.Add( 'SecureParameters', $SecureParameters) }
			If ($PassThru) { $ExecuteProcessSplat.Add( 'PassThru', $PassThru) }
			#  Call the Start-Program function
			If ($PassThru) {
				[psobject]$ExecuteResults = Start-Program @ExecuteProcessSplat
			}
			Else {
				Start-Program @ExecuteProcessSplat
			}
			#  Refresh environment variables for Windows Explorer process as Windows does not consistently update environment variables created by MSIs
			Update-Desktop
		}
		Else {
			Write-Log -Message "The MSI is not installed on this system. Skipping action [$Action]..." -Source ${CmdletName}
		}
	}
	End {
		If ($PassThru) { Write-Output -InputObject $ExecuteResults }
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Start-NSISWrapper
Function Start-NSISWrapper {
<#
.SYNOPSIS
	NSIS Wrapper for Packaging Framework packges
.DESCRIPTION
	Wrapps a PowerShell based Packaging Framework package into an NSIS based setup executable
    Req. installed NSIS compiler
.PARAMETER Path
    Path to the package folder
.PARAMETER ExcludeModuleFiles
	Don't copy module files into the package folder
.EXAMPLE
	Start-NSISWrapper C:\Packages\IgorPavlov_7ZipX64_16.04_ML_01.00
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[Parameter(Mandatory = $True)]
		[ValidateNotNullorEmpty()]
		[string]$Path,
		[Parameter(Mandatory=$false)]
		[switch]$ExcludeModuleFiles
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
            Write-Log "Start wrapping [$Path]" -Source ${CmdletName}

            # Detect NSIS
            [boolean]$Is64Bit = [boolean]((Get-WmiObject -Class 'Win32_Processor' -ErrorAction 'SilentlyContinue' | Where-Object { $_.DeviceID -eq 'CPU0' } | Select-Object -ExpandProperty 'AddressWidth') -eq 64)
            If ($Is64Bit -eq $true) {$NSISFolder = Get-RegistryKey -key 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\NSIS' -Value 'InstallLocation'}
            If ($Is64Bit -eq $false) {$NSISFolder = Get-RegistryKey -key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\NSIS' -Value 'InstallLocation'}
            $NSISCompiler = "$NSISFolder\makensis.exe"
            If (!(Test-Path -Path $NSISCompiler)) { Write-Log "NSIS compiler not found, please install NSIS first" -Source ${CmdletName} -Severity 2 ; Throw "NSIS compiler not found" }

            # Check package path 
            If (!(Test-Path -Path $Path)) { Write-Log "Path $path not found!" -Source ${CmdletName} -Severity 2 ; Throw "Path $path not found!" }

            # Check package files folder
            If (!(Test-Path -Path "$Path\Files")) { Write-Log "Path $path\Files not found!" -Source ${CmdletName} -Severity 2 ; Throw "Path $path\Files not found!" }

            # Check PackageFramework folder in packge (if ExcludeModuleFiles is not used)
            If ($ExcludeModuleFiles -ne $true)
            {
                If (!(Test-Path -Path "$Path\PackagingFramework")) { Write-Log "Path $path\PackagingFramework not found!" -Source ${CmdletName} -Severity 2 ; Throw "Path $path\PackagingFramework not found!" }
            }
            
            # Get package name from folder name
            $PackageName = Split-Path $Path -Leaf
            
            # Create .nsi script file
            [string]$NSISScriptStart = @"
!define CompanyName 'ceterion AG'
!define LegalCopyright 'ceterion AG'
!define ProductName 'Packaging Framework'
!define Version '1.0.0.0'
!include x64.nsh
VIProductVersion `${Version}
VIAddVersionKey 'ProductName' '`${CompanyName} `${ProductName}'
VIAddVersionKey 'CompanyName' '`${CompanyName}'
VIAddVersionKey 'LegalCopyright' '`${LegalCopyright}'
VIAddVersionKey 'FileVersion' '`${Version}'
VIAddVersionKey 'ProductVersion' '`${Version}'
VIAddVersionKey 'FileDescription' '`${CompanyName} `${ProductName}'
BrandingText /TRIMLEFT '`${ProductName}'
SetCompress auto
SetDatablockOptimize on
CRCCheck on
XPStyle on
RequestExecutionLevel highest
ShowInstDetails show
AutoCloseWindow true
SilentInstall normal
OutFile '$PackageName.exe'
Section 'Main'
    Var /GLOBAL TempFolder
    Var /GLOBAL ReturnCode
    Var /GLOBAL SystemDrive
    ReadEnvStr `$SystemDrive SystemDrive
    GetTempFileName `$TempFolder
    StrCpy `$TempFolder `$TempFolder '' -8
    StrCpy `$TempFolder `$TempFolder 4
    StrCpy `$TempFolder `$SystemDrive\Temp\INS_`$TempFolder
    SetOutPath `$TempFolder\$PackageName
    File $PackageName.ps1
    File $PackageName.json
    SetOutPath `$TempFolder\$PackageName\Files
    File /r Files\*.*
"@
[string]$NSISScriptPFFiles = @"
    SetOutPath `$TempFolder\$PackageName\PackagingFramework
    File /r PackagingFramework\*.*
"@
[string]$NSISScriptEnd = @"
    SetRegView 64
    `${DisableX64FSRedirection}
    ExecWait '"`$SysDir\WindowsPowerShell\v1.0\PowerShell.exe" -ExecutionPolicy RemoteSigned -File "`$TempFolder\$PackageName\$PackageName.ps1"' `$ReturnCode
    SetRegView 32
    `${EnableX64FSRedirection}
    SetOutPath `$Temp
    RMDir /r `$TempFolder
    DetailPrint 'Return code: `$ReturnCode'
    SetErrorLevel `$ReturnCode
SectionEnd
"@
            # Create string with/without package framework section
            if ($ExcludeModuleFiles -ne $true)
            {
                [string]$NSISScript = $NSISScriptStart + "`r`n" + $NSISScriptPFFiles + "`r`n" + $NSISScriptEnd
            }
            else
            {
                [string]$NSISScript = $NSISScriptStart + "`r`n" + $NSISScriptEnd
            }
            

            Write-Log "Generating NSIS script file [$Path\$PackageName.nsi]" -Source ${CmdletName} 
            $NSISScript | Out-File -FilePath "$Path\$PackageName.nsi"
            
            # Compile with NSIS
            Write-Log "Start NSIS compile of [$Path\$PackageName.nsi]" -Source ${CmdletName} 
            Start-Program -Path $NSISCompiler -Parameters "$Path\$PackageName.nsi"
            Write-Log "NSIS wrapping of [$Path] complete" -Source ${CmdletName}

		}
		Catch {
                Write-Log -Message "Failed to wrap package. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
    			If (-not $ContinueOnError) {
				Throw "Failed to wrap package.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Start-NSISWrapper

#region Function Start-ServiceAndDependencies
Function Start-ServiceAndDependencies {
<#
.SYNOPSIS
	Start Windows service and its dependencies.
.DESCRIPTION
	Start Windows service and its dependencies.
.PARAMETER Name
	Specify the name of the service.
.PARAMETER ComputerName
	Specify the name of the computer. Default is: the local computer.
.PARAMETER SkipServiceExistsTest
	Choose to skip the test to check whether or not the service exists if it was already done outside of this function.
.PARAMETER SkipDependentServices
	Choose to skip checking for and starting dependent services. Default is: $false.
.PARAMETER PendingStatusWait
	The amount of time to wait for a service to get out of a pending state before continuing. Default is 60 seconds.
.PARAMETER PassThru
	Return the System.ServiceProcess.ServiceController service object.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Start-ServiceAndDependencies -Name 'wuauserv'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$SkipServiceExistsTest,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$SkipDependentServices,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[timespan]$PendingStatusWait = (New-TimeSpan -Seconds 60),
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$PassThru,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	Begin {
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			## Check to see if the service exists
			If ((-not $SkipServiceExistsTest) -and (-not (Test-ServiceExists -ComputerName $ComputerName -Name $Name -ContinueOnError $false))) {
				Write-Log -Message "Service [$Name] does not exist." -Source ${CmdletName} -Severity 2
				Throw "Service [$Name] does not exist."
			}
			
			## Get the service object
			Write-Log -Message "Get the service object for service [$Name]." -Source ${CmdletName}
			[ServiceProcess.ServiceController]$Service = Get-Service -ComputerName $ComputerName -Name $Name -ErrorAction 'Stop'
			## Wait up to 60 seconds if service is in a pending state
			[string[]]$PendingStatus = 'ContinuePending', 'PausePending', 'StartPending', 'StopPending'
			If ($PendingStatus -contains $Service.Status) {
				Switch ($Service.Status) {
					'ContinuePending' { $DesiredStatus = 'Running' }
					'PausePending' { $DesiredStatus = 'Paused' }
					'StartPending' { $DesiredStatus = 'Running' }
					'StopPending' { $DesiredStatus = 'Stopped' }
				}
				Write-Log -Message "Waiting for up to [$($PendingStatusWait.TotalSeconds)] seconds to allow service pending status [$($Service.Status)] to reach desired status [$DesiredStatus]." -Source ${CmdletName}
				$Service.WaitForStatus([ServiceProcess.ServiceControllerStatus]$DesiredStatus, $PendingStatusWait)
				$Service.Refresh()
			}
			## Discover if the service is currently stopped
			Write-Log -Message "Service [$($Service.ServiceName)] with display name [$($Service.DisplayName)] has a status of [$($Service.Status)]." -Source ${CmdletName}
			If ($Service.Status -ne 'Running') {
				#  Start the parent service
				Write-Log -Message "Start parent service [$($Service.ServiceName)] with display name [$($Service.DisplayName)]." -Source ${CmdletName}
				[ServiceProcess.ServiceController]$Service = Start-Service -InputObject (Get-Service -ComputerName $ComputerName -Name $Service.ServiceName -ErrorAction 'Stop') -PassThru -WarningAction 'SilentlyContinue' -ErrorAction 'Stop'
				
				#  Discover all dependent services that are stopped and start them
				If (-not $SkipDependentServices) {
					Write-Log -Message "Discover all dependent service(s) for service [$Name] which are not 'Running'." -Source ${CmdletName}
					[ServiceProcess.ServiceController[]]$DependentServices = Get-Service -ComputerName $ComputerName -Name $Service.ServiceName -DependentServices -ErrorAction 'Stop' | Where-Object { $_.Status -ne 'Running' }
					If ($DependentServices) {
						ForEach ($DependentService in $DependentServices) {
							Write-Log -Message "Start dependent service [$($DependentService.ServiceName)] with display name [$($DependentService.DisplayName)] and a status of [$($DependentService.Status)]." -Source ${CmdletName}
							Try {
								Start-Service -InputObject (Get-Service -ComputerName $ComputerName -Name $DependentService.ServiceName -ErrorAction 'Stop') -WarningAction 'SilentlyContinue' -ErrorAction 'Stop'
							}
							Catch {
								Write-Log -Message "Failed to start dependent service [$($DependentService.ServiceName)] with display name [$($DependentService.DisplayName)] and a status of [$($DependentService.Status)]. Continue..." -Severity 2 -Source ${CmdletName}
								Continue
							}
						}
					}
					Else {
						Write-Log -Message "Dependent service(s) were not discovered for service [$Name]." -Source ${CmdletName}
					}
				}
			}
		}
		Catch {
			Write-Log -Message "Failed to start the service [$Name]. `n$(Resolve-Error)" -Source ${CmdletName} -Severity 3
			If (-not $ContinueOnError) {
				Throw "Failed to start the service [$Name]: $($_.Exception.Message)"
			}
		}
		Finally {
			#  Return the service object if option selected
			If ($PassThru -and $Service) { Write-Output -InputObject $Service }
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Stop-ServiceAndDependencies
Function Stop-ServiceAndDependencies {
<#
.SYNOPSIS
	Stop Windows service and its dependencies.
.DESCRIPTION
	Stop Windows service and its dependencies.
.PARAMETER Name
	Specify the name of the service.
.PARAMETER ComputerName
	Specify the name of the computer. Default is: the local computer.
.PARAMETER SkipServiceExistsTest
	Choose to skip the test to check whether or not the service exists if it was already done outside of this function.
.PARAMETER SkipDependentServices
	Choose to skip checking for and stopping dependent services. Default is: $false.
.PARAMETER PendingStatusWait
	The amount of time to wait for a service to get out of a pending state before continuing. Default is 60 seconds.
.PARAMETER PassThru
	Return the System.ServiceProcess.ServiceController service object.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Stop-ServiceAndDependencies -Name 'wuauserv'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$SkipServiceExistsTest,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$SkipDependentServices,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[timespan]$PendingStatusWait = (New-TimeSpan -Seconds 60),
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$PassThru,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	Begin {
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			## Check to see if the service exists
			If ((-not $SkipServiceExistsTest) -and (-not (Test-ServiceExists -ComputerName $ComputerName -Name $Name -ContinueOnError $false))) {
				Write-Log -Message "Service [$Name] does not exist." -Source ${CmdletName} -Severity 2
				Throw "Service [$Name] does not exist."
			}
			
			## Get the service object
			Write-Log -Message "Get the service object for service [$Name]." -Source ${CmdletName}
			[ServiceProcess.ServiceController]$Service = Get-Service -ComputerName $ComputerName -Name $Name -ErrorAction 'Stop'
			## Wait up to 60 seconds if service is in a pending state
			[string[]]$PendingStatus = 'ContinuePending', 'PausePending', 'StartPending', 'StopPending'
			If ($PendingStatus -contains $Service.Status) {
				Switch ($Service.Status) {
					'ContinuePending' { $DesiredStatus = 'Running' }
					'PausePending' { $DesiredStatus = 'Paused' }
					'StartPending' { $DesiredStatus = 'Running' }
					'StopPending' { $DesiredStatus = 'Stopped' }
				}
				Write-Log -Message "Waiting for up to [$($PendingStatusWait.TotalSeconds)] seconds to allow service pending status [$($Service.Status)] to reach desired status [$DesiredStatus]." -Source ${CmdletName}
				$Service.WaitForStatus([ServiceProcess.ServiceControllerStatus]$DesiredStatus, $PendingStatusWait)
				$Service.Refresh()
			}
			## Discover if the service is currently running
			Write-Log -Message "Service [$($Service.ServiceName)] with display name [$($Service.DisplayName)] has a status of [$($Service.Status)]." -Source ${CmdletName}
			If ($Service.Status -ne 'Stopped') {
				#  Discover all dependent services that are running and stop them
				If (-not $SkipDependentServices) {
					Write-Log -Message "Discover all dependent service(s) for service [$Name] which are not 'Stopped'." -Source ${CmdletName}
					[ServiceProcess.ServiceController[]]$DependentServices = Get-Service -ComputerName $ComputerName -Name $Service.ServiceName -DependentServices -ErrorAction 'Stop' | Where-Object { $_.Status -ne 'Stopped' }
					If ($DependentServices) {
						ForEach ($DependentService in $DependentServices) {
							Write-Log -Message "Stop dependent service [$($DependentService.ServiceName)] with display name [$($DependentService.DisplayName)] and a status of [$($DependentService.Status)]." -Source ${CmdletName}
							Try {
								Stop-Service -InputObject (Get-Service -ComputerName $ComputerName -Name $DependentService.ServiceName -ErrorAction 'Stop') -Force -WarningAction 'SilentlyContinue' -ErrorAction 'Stop'
							}
							Catch {
								Write-Log -Message "Failed to start dependent service [$($DependentService.ServiceName)] with display name [$($DependentService.DisplayName)] and a status of [$($DependentService.Status)]. Continue..." -Severity 2 -Source ${CmdletName}
								Continue
							}
						}
					}
					Else {
						Write-Log -Message "Dependent service(s) were not discovered for service [$Name]." -Source ${CmdletName}
					}
				}
				#  Stop the parent service
				Write-Log -Message "Stop parent service [$($Service.ServiceName)] with display name [$($Service.DisplayName)]." -Source ${CmdletName}
				[ServiceProcess.ServiceController]$Service = Stop-Service -InputObject (Get-Service -ComputerName $ComputerName -Name $Service.ServiceName -ErrorAction 'Stop') -Force -PassThru -WarningAction 'SilentlyContinue' -ErrorAction 'Stop'
			}
		}
		Catch {
			Write-Log -Message "Failed to stop the service [$Name]. `n$(Resolve-Error)" -Source ${CmdletName} -Severity 3
			If (-not $ContinueOnError) {
				Throw "Failed to stop the service [$Name]: $($_.Exception.Message)"
			}
		}
		Finally {
			#  Return the service object if option selected
			If ($PassThru -and $Service) { Write-Output -InputObject $Service }
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Test-IsMutexAvailable
Function Test-IsMutexAvailable {
<#
.SYNOPSIS
	Wait, up to a timeout value, to check if current thread is able to acquire an exclusive lock on a system mutex.
.DESCRIPTION
	A mutex can be used to serialize applications and prevent multiple instances from being opened at the same time.
	Wait, up to a timeout (default is 1 millisecond), for the mutex to become available for an exclusive lock.
.PARAMETER MutexName
	The name of the system mutex.
.PARAMETER MutexWaitTime
	The number of milliseconds the current thread should wait to acquire an exclusive lock of a named mutex. Default is: 1 millisecond.
	A wait time of -1 milliseconds means to wait indefinitely. A wait time of zero does not acquire an exclusive lock but instead tests the state of the wait handle and returns immediately.
.EXAMPLE
	Test-IsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds 500
.EXAMPLE
	Test-IsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds (New-TimeSpan -Minutes 5).TotalMilliseconds
.EXAMPLE
	Test-IsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds (New-TimeSpan -Seconds 60).TotalMilliseconds
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
	http://psappdeploytoolkit.com
	http://msdn.microsoft.com/en-us/library/aa372909(VS.85).asp
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateLength(1,260)]
		[string]$MutexName,
		[Parameter(Mandatory=$false)]
		[ValidateScript({($_ -ge -1) -and ($_ -le [int32]::MaxValue)})]
		[int32]$MutexWaitTimeInMilliseconds = 1
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		## Initialize Variables
		[timespan]$MutexWaitTime = [timespan]::FromMilliseconds($MutexWaitTimeInMilliseconds)
		If ($MutexWaitTime.TotalMinutes -ge 1) {
			[string]$WaitLogMsg = "$($MutexWaitTime.TotalMinutes) minute(s)"
		}
		ElseIf ($MutexWaitTime.TotalSeconds -ge 1) {
			[string]$WaitLogMsg = "$($MutexWaitTime.TotalSeconds) second(s)"
		}
		Else {
			[string]$WaitLogMsg = "$($MutexWaitTime.Milliseconds) millisecond(s)"
		}
		[boolean]$IsUnhandledException = $false
		[boolean]$IsMutexFree = $false
		[Threading.Mutex]$OpenExistingMutex = $null
	}
	Process {
		Write-Log -Message "Check to see if mutex [$MutexName] is available. Wait up to [$WaitLogMsg] for the mutex to become available." -Source ${CmdletName}
		Try {
			## Using this variable allows capture of exceptions from .NET methods. Private scope only changes value for current function.
			$private:previousErrorActionPreference = $ErrorActionPreference
			$ErrorActionPreference = 'Stop'
			
			## Open the specified named mutex, if it already exists, without acquiring an exclusive lock on it. If the system mutex does not exist, this method throws an exception instead of creating the system object.
			[Threading.Mutex]$OpenExistingMutex = [Threading.Mutex]::OpenExisting($MutexName)
			## Attempt to acquire an exclusive lock on the mutex. Use a Timespan to specify a timeout value after which no further attempt is made to acquire a lock on the mutex.
			$IsMutexFree = $OpenExistingMutex.WaitOne($MutexWaitTime, $false)
		}
		Catch [Threading.WaitHandleCannotBeOpenedException] {
			## The named mutex does not exist
			$IsMutexFree = $true
		}
		Catch [ObjectDisposedException] {
			## Mutex was disposed between opening it and attempting to wait on it
			$IsMutexFree = $true
		}
		Catch [UnauthorizedAccessException] {
			## The named mutex exists, but the user does not have the security access required to use it
			$IsMutexFree = $false
		}
		Catch [Threading.AbandonedMutexException] {
			## The wait completed because a thread exited without releasing a mutex. This exception is thrown when one thread acquires a mutex object that another thread has abandoned by exiting without releasing it.
			$IsMutexFree = $true
		}
		Catch {
			$IsUnhandledException = $true
			## Return $true, to signify that mutex is available, because function was unable to successfully complete a check due to an unhandled exception. Default is to err on the side of the mutex being available on a hard failure.
			Write-Log -Message "Unable to check if mutex [$MutexName] is available due to an unhandled exception. Will default to return value of [$true]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			$IsMutexFree = $true
		}
		Finally {
			If ($IsMutexFree) {
				If (-not $IsUnhandledException) {
					Write-Log -Message "Mutex [$MutexName] is available for an exclusive lock." -Source ${CmdletName}
				}
			}
			Else {
				If ($MutexName -eq 'Global\_MSIExecute') {
					## Get the command line for the MSI installation in progress
					Try {
						[string]$msiInProgressCmdLine = Get-WmiObject -Class 'Win32_Process' -Filter "name = 'msiexec.exe'" -ErrorAction 'Stop' | Where-Object { $_.CommandLine } | Select-Object -ExpandProperty 'CommandLine' | Where-Object { $_ -match '\.msi' } | ForEach-Object { $_.Trim() }
					}
					Catch { }
					Write-Log -Message "Mutex [$MutexName] is not available for an exclusive lock because the following MSI installation is in progress [$msiInProgressCmdLine]." -Severity 2 -Source ${CmdletName}
				}
				Else {
					Write-Log -Message "Mutex [$MutexName] is not available because another thread already has an exclusive lock on it." -Source ${CmdletName}
				}
			}
			
			If (($null -ne $OpenExistingMutex) -and ($IsMutexFree)) {
				## Release exclusive lock on the mutex
				$null = $OpenExistingMutex.ReleaseMutex()
				$OpenExistingMutex.Close()
			}
			If ($private:previousErrorActionPreference) { $ErrorActionPreference = $private:previousErrorActionPreference }
		}
	}
	End {
		Write-Output -InputObject $IsMutexFree
		
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Test-MSUpdates
Function Test-MSUpdates {
<#
.SYNOPSIS
	Test whether a Microsoft Windows update is installed.
.DESCRIPTION
	Test whether a Microsoft Windows update is installed.
.PARAMETER KBNumber
	KBNumber of the update.
.PARAMETER ContinueOnError
	Suppress writing log message to console on failure to write message to log file. Default is: $true.
.EXAMPLE
	Test-MSUpdates -KBNumber 'KB2549864'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,Position=0,HelpMessage='Enter the KB Number for the Microsoft Update')]
		[ValidateNotNullorEmpty()]
		[string]$KBNumber,
		[Parameter(Mandatory=$false,Position=1)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message "Check if Microsoft Update [$kbNumber] is installed." -Source ${CmdletName}
			
			## Default is not found
			[boolean]$kbFound = $false
			
			## Check for update using built in PS cmdlet which uses WMI in the background to gather details
			If ([int]$PSVersionInfo.Major -ge 3) {
				Get-Hotfix -Id $kbNumber -ErrorAction 'SilentlyContinue' | ForEach-Object { $kbFound = $true }
			}
			Else {
				Write-Log -Message 'Older version of Powershell detected, Get-Hotfix cmdlet is not supported.' -Source ${CmdletName}
			}
						
			If (-not $kbFound) {
				Write-Log -Message 'Unable to detect Windows update history via Get-Hotfix cmdlet. Trying via COM object.' -Source ${CmdletName}
			
				## Check for update using ComObject method (to catch Office updates)
				[__comobject]$UpdateSession = New-Object -ComObject "Microsoft.Update.Session"
				[__comobject]$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
				#  Indicates whether the search results include updates that are superseded by other updates in the search results
				$UpdateSearcher.IncludePotentiallySupersededUpdates = $false
				#  Indicates whether the UpdateSearcher goes online to search for updates.
				$UpdateSearcher.Online = $false
				[int32]$UpdateHistoryCount = $UpdateSearcher.GetTotalHistoryCount()
				If ($UpdateHistoryCount -gt 0) {
					[psobject]$UpdateHistory = $UpdateSearcher.QueryHistory(0, $UpdateHistoryCount) |
									Select-Object -Property 'Title','Date',
															@{Name = 'Operation'; Expression = { Switch ($_.Operation) { 1 {'Installation'}; 2 {'Uninstallation'}; 3 {'Other'} } } },
															@{Name = 'Status'; Expression = { Switch ($_.ResultCode) { 0 {'Not Started'}; 1 {'In Progress'}; 2 {'Successful'}; 3 {'Incomplete'}; 4 {'Failed'}; 5 {'Aborted'} } } },
															'Description' |
									Sort-Object -Property 'Date' -Descending
					ForEach ($Update in $UpdateHistory) {
						If (($Update.Operation -ne 'Other') -and ($Update.Title -match "\($KBNumber\)")) {
							$LatestUpdateHistory = $Update
							Break
						}
					}
					If (($LatestUpdateHistory.Operation -eq 'Installation') -and ($LatestUpdateHistory.Status -eq 'Successful')) {
						Write-Log -Message "Discovered the following Microsoft Update: `n$($LatestUpdateHistory | Format-List | Out-String)" -Source ${CmdletName}
						$kbFound = $true
					}
					$null = [Runtime.Interopservices.Marshal]::ReleaseComObject($UpdateSession)
					$null = [Runtime.Interopservices.Marshal]::ReleaseComObject($UpdateSearcher)
				}
				Else {
					Write-Log -Message 'Unable to detect Windows update history via COM object.' -Source ${CmdletName}
				}
			}
			
			## Return Result
			If (-not $kbFound) {
				Write-Log -Message "Microsoft Update [$kbNumber] is not installed." -Source ${CmdletName}
				Write-Output -InputObject $false
			}
			Else {
				Write-Log -Message "Microsoft Update [$kbNumber] is installed." -Source ${CmdletName}
				Write-Output -InputObject $true
			}
		}
		Catch {
			Write-Log -Message "Failed discovering Microsoft Update [$kbNumber]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed discovering Microsoft Update [$kbNumber]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Test-Package
Function Test-Package {
<#
.SYNOPSIS
	Test package
.DESCRIPTION
	Validate the syntax of Packaging Framework packages
.PARAMETER Path
	The path to a folder with one or multiple packages
.OUTPUTS
    Object
.EXAMPLE
	Test-Package C:\PackageFolder
.EXAMPLE
    Test-Package C:\PackageFolder | Sort Severity | Format-Table Package,Severity,Description
.EXAMPLE
    Test-Package C:\PackageFolder | Out-GridView
.EXAMPLE
    Test-Package C:\PackageFolder | Export-csv -Path C:\temp\result.csv ; Start-Process -FilePath Excel.exe -ArgumentList C:\temp\result.csv
.EXAMPLE
    Test-Package C:\PackageFolder | Format-Table Package,Description | Out-Printer "Microsoft Print to PDF"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[ValidateNotNullorEmpty()]
		[Parameter(Mandatory = $True)]
		[string]$path
    )
 	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header

        # Check if script is initialize
        if (-not($ModuleConfigFile)) {  Throw "Please run Initialize-Script befor you run this command" }

        # Check if path exists
        if(-not(Test-path -path $path -PathType Container)) {  Throw "Path $path doesn't exists" }

        # internal Test-PSScript helper function
        function Test-PSScript 
        { 
        <#
        .SYNOPSIS
	        Validate the syntax of a PowerShell script (PS1 file)
        .DESCRIPTION
	        Validate the syntax of a PowerShell script (PS1 file)
        .PARAMETER FilePath
	        The FilePath to PowerShell script file
        .OUTPUT
	        Extended token object 
        .EXAMPLE
	        Test-PSScript C:\Temp\MyScript.ps1
        .NOTES
            Based on http://blogs.microsoft.co.il/scriptfanatic/2009/09/07/parsing-powershell-scripts/
            Adapted by ceterion for the packaging Framework
        .LINK
	        http://www.ceterion.com
        #>
		         Param( 
					[Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] 
					[ValidateNotNullOrEmpty()] 
					[Alias('PSPath','FullName')]
					[System.String[]] $FilePath
		         ) 
		         Begin 
		         { 
		         $total=$fails=0 
		         } 
		         Process 
		         { 
		         $FilePath | Foreach-Object { 
			         if(Test-Path -Path $_ -PathType Leaf) 
			         { 
				         $Path = Convert-Path -Path $_ 
				         $Errors = $null 
				         $Content = Get-Content -Path $path
				         $Tokens = [System.Management.Automation.PsParser]::Tokenize($Content,[ref]$Errors) 
				         if($Errors) 
				         { 
					        $fails+=1 
					         $Errors | Foreach-Object { 
					         	$_.Token | Add-Member -MemberType NoteProperty -Name Path -Value $Path -PassThru | Add-Member -MemberType NoteProperty -Name ErrorMessage -Value $_.Message -PassThru 
					         } 
							} 
							$total+=1
				         }
	         } 
	         } 
	         End
	        { 
	         } 
        } # function

	}
	Process {
		Try {
            
            # Get als packages ps1 files into an array
            [array]$Packages = gci $path -Filter *_*.ps1 -Recurse

            # Create an arrar to store the results
            $ResultObject = @()
                
            # Process all packages
            Foreach($file in $Packages)
            {
                # Progress bar
                $PackageCount++
                Write-Progress -activity "Checking packages..." -status "Processing: $PackageFolder\$PackageName" -PercentComplete (($PackageCount / $Packages.length)  * 100)
                
                # Get package folder name from file system
                [String]$PackageFolder = $file.Directory
                $PackageFolderName = $PackageFolder.split("\")[-1]
                $PackageName = Split-Path $PackageFolderName -Leaf
                Write-Log "Performing package check on [$PackageFolder\$PackageName]" -Source ${CmdletName}
                    
                    # Read PS1 file
                    [string]$PS1Content = get-content "$PackageFolder\$PackageName.ps1"
                
                    # Check package naming scheme
                    if($ModuleConfigFile.PackageValidation.CheckNamingScheme -eq $true)
                    {
                        $PackageNameTestResult = Test-PackageName -Name $PackageName
                        if ($PackageNameTestResult -ne $true) {$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Error"; Description="[$PackageName] is not a valid package name, please check naming scheme"}}
                    }

                    # Check if files folder exists
                    if($ModuleConfigFile.PackageValidation.CheckFilesFolder -eq $true)
                    {
                        If (!(Test-Path -Path "$PackageFolder\Files" -PathType Container)) {$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Warning"; Description="The folder $PackageFolder\Files doesn't exists"}}
                    }

                    # Check if PackagingFramework folder exists and check included version
                    if($ModuleConfigFile.PackageValidation.CheckModuleFolder -eq $true)
                    {
                        # Check for PackagingFramework folder
                        If (!(Test-Path -Path "$PackageFolder\PackagingFramework" -PathType Container)) {$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Warning"; Description="The folder $PackageFolder\PackagingFramework doesn't exists"}}

                        # Check included PackagingFramework and PackagingFrameworkExtension version
                        If (Test-Path -Path "$PackageFolder\PackagingFramework\PackagingFramework.psd1" -PathType Leaf){
                            $PSDContent = Get-Content -Path "$PackageFolder\PackagingFramework\PackagingFramework.psd1" | Out-String | Invoke-Expression 
                            if ($($PSDContent.ModuleVersion) -eq $((Get-Module PackagingFramework).Version)) {Write-log "Module version match" -Source ${CmdletName} -DebugMessage} else { Write-log "Current module version is [$((Get-Module PackagingFramework).Version)] and package module version is [$($PSDContent.ModuleVersion)]" -Source ${CmdletName} -Severity 2 -DebugMessage ; $ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Warning"; Description="Current module version is [$((Get-Module PackagingFramework).Version)] and package module version is [$($PSDContent.ModuleVersion)]"}  }
                        }
                        If (Test-Path -Path "$PackageFolder\PackagingFramework\PackagingFrameworkExtension.psd1" -PathType Leaf){
                            $PSDContent = Get-Content -Path "$PackageFolder\PackagingFramework\PackagingFrameworkExtension.psd1" | Out-String | Invoke-Expression 
                            if ($($PSDContent.ModuleVersion) -eq $((Get-Module PackagingFrameworkExtension).Version)) {Write-log "Module extension version match" -Source ${CmdletName} -DebugMessage} else { Write-log "Current module extension version is [$((Get-Module PackagingFramework).Version)] and package extension module version is [$($PSDContent.ModuleVersion)]" -Source ${CmdletName} -Severity 2 -DebugMessage ; $ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Warning"; Description="Current extension module version is [$((Get-Module PackagingFramework).Version)] and package extension module version is [$($PSDContent.ModuleVersion)]"}  }
                        }
                    }

                    # Check PS1 syntax
                    if($ModuleConfigFile.PackageValidation.CheckSyntaxErrorsInPS1 -eq $true)
                    {
                        $PS1SyntaxCheckResult = Test-PSScript "$PackageFolder\$PackageName.ps1"
                        if ($PS1SyntaxCheckResult) {$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Error"; Description="PowerShell script syntax error: $($PS1SyntaxCheckResult[0].ErrorMessage)"}}
                    }

                    # Check JSON syntax
                    if($ModuleConfigFile.PackageValidation.CheckSyntaxErrorsInJson -eq $true) 
                    {
                        If (Test-Path -Path "$PackageFolder\$PackageName.json") 
                        {
                            # Open JSon file
                            try
                            {
                                If ($PSVersionInfo.Major -ge 5)
                                {
                                    [string]$JsonContent = get-content "$PackageFolder\$PackageName.json"
                                    [psobject]$objJsonFile = get-content "$PackageFolder\$PackageName.json" | ConvertFrom-Json
                                }
                                else
                                {
                                    [string]$JsonContent = get-content "$PackageFolder\$PackageName.json" -Raw
                                    [psobject]$objJsonFile = get-content "$PackageFolder\$PackageName.json" -Raw | ConvertFrom-Json
                                }
                            }
                            catch
                            {
                                $ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Error"; Description="Syntax error in $PackageName.json file, please check syntax"}
                            }

                            # Check other JSON parameter for existance
                            if (!($objJsonFile.Package.PackageDescription)) {$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Warning"; Description="Parameter PackageDescription is not definied in JSON file"}}
                            if (!($objJsonFile.Package.PackageDate)) {$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Warning"; Description="Parameter PackageDate is not definied in JSON file"}}
                            if (!($objJsonFile.Package.PackageAuthor)) {$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Warning"; Description="Parameter PackageAuthor is not definied in JSON file"}}

                            # Check if at least one detection method entry exists.
                            if($ModuleConfigFile.PackageValidation.CheckJsonDetectionMethod -eq $true) 
                            {
                                if ($objJsonFile.DetectionMethods.count -eq 0) {$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Warning"; Description="No DetectionMethods section found in JSON file"}}
                            }

                            # Check if at least one change log entry exists.
                            if($ModuleConfigFile.PackageValidation.CheckJsonChangeLog -eq $true) 
                            {
                                if ($objJsonFile.ChangeLog.count -eq 0) {$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Warning"; Description="No ChangeLog section found in JSON file"}}
                            }

                            # Check apps inside the Application section
                            if($ModuleConfigFile.PackageValidation.CheckJsonApplications -eq $true) 
                            {
                                if ($objJsonFile.Applications.count -ge 1) {
                                    foreach ($line in $objJsonFile.Applications) 
                                    {
                                        # Check mandatory publ. app params 
                                        if (!$line.AppName){$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Error"; Description="Application without AppName parameter found"}}
                                        if (!$line.AppCommandLineExecutable){$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Error"; Description="Application without AppCommandLineExecutable parameter found"}}
                                
                                        # Check accounts, warn when empty
                                        if ($line.AppName){
                                            if($PackageConfigFile.PackageValidation.CheckJsonApplicationsAccounts -eq $true) {
                                                If ($line.AppAccounts.Count -eq 0) {$ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Warning"; Description="Application [$($line.AppName)] has no AppAccounts specified"}}
                                            }
                                        }
                                    }
                                }
                            }
                        } # json file exists
                        else
                        {
                            $ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity="Error"; Description="The JSON file $PackageName.json doesn't exists"}
                        }
              
                } # CheckJsonForSyntaxErrors 
                
                # Check PS1 file based on search pattern
                foreach ($Pattern in $ModuleConfigFile.PackageValidation.SearchPatternPS1File) 
                {
                    $SearchResult = Select-String -InputObject $PS1Content -Pattern $Pattern.Pattern 
                    if($SearchResult) { Write-Log "$($Pattern.Description)" -Source ${CmdletName} -Severity 2 -DebugMessage ; $ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity=$($Pattern.Severity); Description=$($Pattern.Description)}} 
                }
              
                # Check Json file based on search pattern
                foreach ($Pattern in $ModuleConfigFile.PackageValidation.SearchPatternJsonFile) 
                {
                    $SearchResult = Select-String -InputObject $JsonContent -Pattern $Pattern.Pattern -SimpleMatch
                    if($SearchResult) { Write-Log "$($Pattern.Description)" -Source ${CmdletName} -Severity 2 -DebugMessage ; $ResultObject += New-Object -TypeName psobject -Property @{Package=$PackageName; Severity=$($Pattern.Severity); Description=$($Pattern.Description)}}
                }
            } # for each package
        Return $ResultObject
		}
		Catch {
                Write-Log -Message "Failed to test package. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
    			If (-not $ContinueOnError) {
				Throw "Failed to test package.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Test-Package

#region Function Test-PackageName
Function Test-PackageName {
<#
.SYNOPSIS
	Test package name
.DESCRIPTION
	Validate package name against package naming scheme
.PARAMETER PackageName
	The package name to validate, leve empty to use the current package name
.OUTPUTS
	Returns $true or $false and shows error details on StdOut
.EXAMPLE
	Test-Package
.EXAMPLE
	Test-Package -name 'Microsoft_Notepad_1.0_DE_01.00'
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		#  Get the current date
		[ValidateNotNullorEmpty()]
		[Parameter(Mandatory = $false)]
		[string]$Name = $Global:PackageName
    )
 	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}#begin
	Process {

        # Check if script is initialize
        if (-not($ModuleConfigFile)) {  Throw "Please run Initialize-Script befor you run this command" }

        Write-Log "Performing name scheme check on [$Name]" -Source ${CmdletName}
        foreach($NamingScheme in $ModuleConfigFile.PackageNamingScheme)
        {

            # Get naming scheme settings from json file
            [string]$Scheme = $NamingScheme.Scheme
            [string]$Separator = $NamingScheme.Separator
            Write-Log "Scheme: $Scheme" -Source ${CmdletName} -DebugMessage
            Write-Log "Separator: $Separator" -Source ${CmdletName} -DebugMessage

            # Check if package name has the same element cout as the naming sheme
            If (($Name.ToCharArray() | Where-Object {$_ -eq $Separator} | Measure-Object).Count -ne ($Scheme.ToCharArray() | Where-Object {$_ -eq $Separator} | Measure-Object).Count)
            {
                $ElementCountTestPassed=$false
                Write-Log "Package name [$Name] does not match the naming scheme element count [$(($Name.ToCharArray() | Where-Object {$_ -eq $Separator} | Measure-Object).Count)] != [$(($Scheme.ToCharArray() | Where-Object {$_ -eq $Separator} | Measure-Object).Count)]" -Source ${CmdletName} -Severity 2 -DebugMessage
                Continue
            }
            Else
            {
                $ElementCountTestPassed=$True
                Write-Log "Package name [$Name] match the naming scheme element count [$(($Name.ToCharArray() | Where-Object {$_ -eq $Separator} | Measure-Object).Count)] = [$(($Scheme.ToCharArray() | Where-Object {$_ -eq $Separator} | Measure-Object).Count)]" -Source ${CmdletName} -Severity 1 -DebugMessage
            }

            # Split on seperator and loop through each element of the package name    
            [array]$SchemeArray = $Scheme.Split($Separator)
            [array]$PackageNameArray = $Name.Split($Separator)
            [Int]$ElementCount = 0
            [bool]$ElementRegExTestPassed=$True # will be set to false when regex test will fail
            Foreach ($SchemeElement in $SchemeArray) {
                Write-Log "Naming scheme element [$($SchemeElement)] found with value [$($PackageNameArray[$ElementCount])]" -Source ${CmdletName} -DebugMessage
                Set-Variable -Name $SchemeElement -Value $PackageNameArray[$ElementCount] -Scope Global
                # Syntax check each element
                $RegExRuleName = "RegEx$SchemeElement"
                [string]$RegExRule = $NamingScheme.$RegExRuleName
                If ($RegExRule) {
                    If ($PackageNameArray[$ElementCount] -match $RegExRule) 
                    {
                        Write-Log "Compare [$SchemeElement] with value [$($PackageNameArray[$ElementCount])] against RegEx [$RegExRule] was successful" -Source ${CmdletName} -DebugMessage
                    }
                    Else
                    {
                        Write-Log "Compare [$SchemeElement] with value [$($PackageNameArray[$ElementCount])] against RegEx [$RegExRule] failed" -Source ${CmdletName} -Severity 2 -DebugMessage
                        $ElementRegExTestPassed=$false
                    }
                }
                Else
                {
                    Write-Log "No RegEx rule found for element [$SchemeElement], no regex check is performend " -Source ${CmdletName} -Severity 2 -DebugMessage
                }
                $ElementCount++
            } #foreach
            # If not a single RegEx test failes leave loop with $true
            If (($ElementCountTestPassed -eq $true) -and ($ElementRegExTestPassed -eq $true)) { Return $true } else { Return $false }
        } #foreach
        
        # When end is reached, and not a singel naming schem matched return false
        Return $false

	}#process
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}#end
} #function 
#endregion Function Test-PackageName

#region Function Test-Ping
Function Test-Ping {
<#
.SYNOPSIS
    Pings IP, Hostname or FDQN to check alive status or retrive details from remote host
.DESCRIPTION
    Pings IP, Hostname or FDQN to check alive status or retrive details from remote host
.PARAMETER ComputerName
    Name or IP the target computer.
.PARAMETER Count
    Number of echo ICMP requests sent. The default value is 4.
.PARAMETER BufferSize
    Buffer used with this command. Default is 32 bytes.
.PARAMETER TimeToLive
    Maximum number of times the ICMP echo message can be forwarded before reaching its destination.
    Range is 1-255. Default is 64
.PARAMETER TimeOut
    Maximum number of milliseconds to wait for the ICMP echo reply message from target.
.PARAMETER DontFragment
    If true and the total packet size exceeds the maximum packet size that can be transmitted by one of the routing nodes between the local and remote computers, the ICMP echo request fails. 
    When this happens, the Status is set to PacketTooBig.
.PARAMETER PassThru
    Returns a PSObject with remote host details
.PARAMETER ContinueOnError
    Continue if an error is encountered. Default is: $True.
.EXAMPLE
    Test-Ping -ComputerName 'www.google.com'
.EXAMPLE
    Test-Ping -ComputerName '5.5.5.5'
.EXAMPLE
    Test-Ping -ComputerName '5.5.5.5' -PassThru
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, HelpMessage="CN,IPAddress,__SERVER,Server,Destination")]
        [Alias('CN','__SERVER','IPAddress','Server')]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
        [Parameter(Mandatory=$false, HelpMessage="Number of echo ICMP requests sent, default is 4")]
        [ValidateNotNullOrEmpty()]
        [Int]$Count = 4,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$BufferSize = 32,
        [Parameter(Mandatory=$false, HelpMessage="Number of hops before it gives up, default is 32")]
        [ValidateNotNullOrEmpty()]
        [Alias('TTL')]
        [Int]$TimeToLive = 64,
        [Parameter(Mandatory=$false, HelpMessage="Time to live in milliseconds, default is 64")]
        [ValidateNotNullOrEmpty()]
        [Int32]$timeout = 1000,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Bool]$DontFragment = $false,
        [Parameter(Mandatory=$false, HelpMessage="Returns a PSObject instead of [Bool]")]
        [ValidateNotNullOrEmpty()]
        [switch]$PassThru
    )

    Begin {
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }

    Process {
        Try {
            [Bool]$resolve = $True
            [system.net.NetworkInformation.PingOptions]$options = new-object system.net.networkinformation.pingoptions
            $options.TTL = $TimeToLive
            $options.DontFragment = $DontFragment
            [array]$buffer = ([system.text.encoding]::ASCII).getbytes("a"*$buffersize)
            Try {
                $IpAddress = [System.Net.Dns]::GetHostAddresses($ComputerName)
                $ping = new-object system.net.networkinformation.ping
                $reply = $ping.Send($ComputerName,$timeout,$buffer,$options)
                [String]$hostname = ([System.Net.Dns]::GetHostEntry($ComputerName)).hostname
            } Catch {
                $reply = @{} 
                $reply.status = 'FailDnsLookup'
                $ErrorMessage = "$($_.Exception.Message) $($_.Exception.InnerException)"
                Write-Log -Message "$ErrorMessage" -Severity 3 -Source ${CmdletName}
        }
            If ($reply.status -eq "Success"){ $IsAlive = $True } else { $IsAlive = $false }
            $info = @{}
            $info.InputGiven = $ComputerName
            $info.status = $reply.status
            $info.RoundtripTime = $reply.RoundtripTime
            $info.Hostname = $hostname
            $info.AddressUsed = $reply.Address
            $info.AddressAll = $IpAddress
            $info.TimeToLive = $options.TTL
            $info.DontFragment = $options.DontFragment
            $info.IsAlive = $IsAlive
            $info.Buffer = $buffer
            $info.ErrorMessage = $ErrorMessage
            If ($PassThru) {
            New-Object PSObject -Property $info -ErrorAction SilentlyContinue
        } Else {
            Write-Output $IsAlive
        }
        }
            Catch {
                Write-Log -Message "Failed ping to see if [$ComputerName] is alive on the network: $($_.Exception.Message) $($_.Exception.InnerException)" -Severity 3 -Source ${CmdletName}
                If ($PassThru) {
                If ($info) { New-Object PSObject -Property $info -ErrorAction SilentlyContinue }
                } Else {
                Write-Output $false
                }
            }
        }
        End {
            Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
        }
    }
#endregion Function Test-Ping

#region Function Test-RegistryKey
function Test-RegistryKey {
<#
.SYNOPSIS
    Tests if a registry Key and/or value exists and can also test if the value is of certain type
.DESCRIPTION
    Tests if a registry Key and/or value exists and can also test if the value is of certain type.PARAMETER Key
    Path of the registry key (Required).
.PARAMETER Name
    The value name (optional).
.PARAMETER Value
    Value to compare against (optional).
.PARAMETER Type
    The type of registry value. Options: 'Binary','DWord','MultiString','QWord','String'. (optional).
    UN-supported Types: 'ExpandString','None','Unknown'
.EXAMPLE
    # Key exists tests
    Test-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
.EXAMPLE
    # Value exist tests
    Test-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -Name Install
.EXAMPLE
    # Value Type tests
    Test-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -Name Install -Type DWord
.EXAMPLE
    # Default value tests
    Test-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4" -Name '(Default)'
.EXAMPLE
    # Value Content tests
    Test-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -Name Install -Value 1
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,HelpMessage = "Path of the registry key")]
        [ValidateNotNullorEmpty()]
        [string]$Key,
        [Parameter(Mandatory=$false,HelpMessage = "The value name (optional). For a key's default value use (default)")]
        [ValidateNotNull()]
        [String]$Name,
        [Parameter(Mandatory=$false,HelpMessage = "Value Type (optional). Use 'String' for 'ExpandString'")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Binary','DWord','MultiString','QWord','String')]
        [Microsoft.Win32.RegistryValueKind]$Type,
        [Parameter(Mandatory=$false)]
        $Value #do NOT cast data type! $null or empty could also be given!
    )

    Begin {
        ## Get the name of this function and write header
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
    }

    Process {
        $Key = Convert-RegistryPath -Key $Key
        if( -not (Test-Path -Path $Key -PathType Container) ) {
            Write-Host "Key [$Key] does NOT Exists" -Source ${CmdletName}
            return $false # No point testing for the value
        } 
        $AllKeyValues = Get-ItemProperty -Path $Key
        If ($PSBoundParameters.ContainsKey('ValueName') ) { # If ($Name) {
            If ( -not $AllKeyValues ) {
                Write-log "Key [$Key] Exists but has no values!" -Source ${CmdletName}
                return $false
            }
        $ValDataRead = Get-Member -InputObject $AllKeyValues -Name $Name # Converts REG_SZ to Int32 if it's a number
        Write-log "Value [$Name] Exists and contains [$ValDataRead]" -Source ${CmdletName}
        if( $ValDataRead ) {
        $ValDataRead = $($AllKeyValues.$Name) # Converts REG_SZ to Int32 if it's a number
        Write-log "Value [$Name] Exists and contains [$ValDataRead]" -Source ${CmdletName}
        If ($Value) { # Do a data compare
        If ($Value -eq $ValDataRead) { # If there is no way to
            Return $true
            } Else { Return $false }
            } ElseIf ($Type) { # Do a Type compare
                $ValTypeRead = switch ($Name.gettype().Name) {
                "String"{'String'}
                "Int32" {'DWord'}
                "Int64" {'QWord'}
                "String[]" {'MultiString'}
                "Byte[]" {'Binary'}
                default {'Unknown'}
            }
        Write-log "Value [$Name] is of type [$ValTypeRead]" -Source ${CmdletName}
        If ($ValTypeRead -eq $Type) {
        Return $true
        } Eelse {return $false }
        } Else {
        Return $true
        } # If ($Value) {
        } else {
        Write-log "Key [$Key] exist but [$Name] does not exist" -Source ${CmdletName}
        Return $false
        }
        } Else { #The Key exists but we don't care about its values
            Write-log "Key [$Key] Exists" -Source ${CmdletName}
            Return $true
        }
    }

    End {
        Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
    } 
} # Test-RegistryKey 

#endregion Function Test-RegistryKey

#region Function Test-ServiceExists
Function Test-ServiceExists {
<#
.SYNOPSIS
	Check to see if a service exists.
.DESCRIPTION
	Check to see if a service exists (using WMI method because Get-Service will generate ErrorRecord if service doesn't exist).
.PARAMETER Name
	Specify the name of the service.
	Note: Service name can be found by executing "Get-Service | Format-Table -AutoSize -Wrap" or by using the properties screen of a service in services.msc.
.PARAMETER ComputerName
	Specify the name of the computer. Default is: the local computer.
.PARAMETER PassThru
	Return the WMI service object.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Test-ServiceExists -Name 'wuauserv'
.EXAMPLE
	Test-ServiceExists -Name 'testservice' -PassThru | Where-Object { $_ } | ForEach-Object { $_.Delete() }
	Check if a service exists and then delete it by using the -PassThru parameter.
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:ComputerName,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$PassThru,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	Begin {
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			$ServiceObject = Get-WmiObject -ComputerName $ComputerName -Class 'Win32_Service' -Filter "Name='$Name'" -ErrorAction 'Stop'
			If ($ServiceObject) {
				Write-Log -Message "Service [$Name] exists." -Source ${CmdletName}
				If ($PassThru) { Write-Output -InputObject $ServiceObject } Else { Write-Output -InputObject $true }
			}
			Else {
				Write-Log -Message "Service [$Name] does not exist." -Source ${CmdletName}
				If ($PassThru) { Write-Output -InputObject $ServiceObject } Else { Write-Output -InputObject $false }
			}
		}
		Catch {
			Write-Log -Message "Failed check to see if service [$Name] exists." -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed check to see if service [$Name] exists: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Test-WellKnownSID
Function Test-WellKnownSID {
<#
.SYNOPSIS
	Check if a SID is well known
.DESCRIPTION
	Check if a SID is well known. The function returns only $true or $false
.PARAMETER SID
	SID to check if it is well known
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default: $false.
.EXAMPLE
	Check-WellKnownSID -SID "S-1-5-32-544"
.NOTES
	Created by ceterion AG
	This is an internal script function and should typically not be called directly.
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True)]
		[ValidateNotNullorEmpty()]
		[string]$SID,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $false
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		#well known SID to name map
        $wellKnownSIDs = @{
            'S-1-0' = 'Null Authority'
            'S-1-0-0' = 'Nobody'
            'S-1-1' = 'World Authority'
            'S-1-1-0' = 'Everyone'
            'S-1-2' = 'Local Authority'
            'S-1-2-0' = 'Local'
            'S-1-2-1' = 'Console Logon'
            'S-1-3' = 'Creator Authority'
            'S-1-3-0' = 'Creator Owner'
            'S-1-3-1' = 'Creator Group'
            'S-1-3-2' = 'Creator Owner Server'
            'S-1-3-3' = 'Creator Group Server'
            'S-1-3-4' = 'Owner Rights'
            'S-1-5-80-0' = 'All Services'
            'S-1-4' = 'Non-unique Authority'
            'S-1-5' = 'NT Authority'
            'S-1-5-1' = 'Dialup'
            'S-1-5-2' = 'Network'
            'S-1-5-3' = 'Batch'
            'S-1-5-4' = 'Interactive'
            'S-1-5-6' = 'Service'
            'S-1-5-7' = 'Anonymous'
            'S-1-5-8' = 'Proxy'
            'S-1-5-9' = 'Enterprise Domain Controllers'
            'S-1-5-10' = 'Principal Self'
            'S-1-5-11' = 'Authenticated Users'
            'S-1-5-12' = 'Restricted Code'
            'S-1-5-13' = 'Terminal Server Users'
            'S-1-5-14' = 'Remote Interactive Logon'
            'S-1-5-15' = 'This Organization'
            'S-1-5-17' = 'This Organization'
            'S-1-5-18' = 'Local System'
            'S-1-5-19' = 'NT Authority'
            'S-1-5-20' = 'NT Authority'
            'S-1-5-32-544' = 'Administrators'
            'S-1-5-32-545' = 'Users'
            'S-1-5-32-546' = 'Guests'
            'S-1-5-32-547' = 'Power Users'
            'S-1-5-32-548' = 'Account Operators'
            'S-1-5-32-549' = 'Server Operators'
            'S-1-5-32-550' = 'Print Operators'
            'S-1-5-32-551' = 'Backup Operators'
            'S-1-5-32-552' = 'Replicators'
            'S-1-5-64-10' = 'NTLM Authentication'
            'S-1-5-64-14' = 'SChannel Authentication'
            'S-1-5-64-21' = 'Digest Authority'
            'S-1-5-80' = 'NT Service'
            'S-1-5-83-0' = 'NT VIRTUAL MACHINE\Virtual Machines'
            'S-1-16-0' = 'Untrusted Mandatory Level'
            'S-1-16-4096' = 'Low Mandatory Level'
            'S-1-16-8192' = 'Medium Mandatory Level'
            'S-1-16-8448' = 'Medium Plus Mandatory Level'
            'S-1-16-12288' = 'High Mandatory Level'
            'S-1-16-16384' = 'System Mandatory Level'
            'S-1-16-20480' = 'Protected Process Mandatory Level'
            'S-1-16-28672' = 'Secure Process Mandatory Level'
            'S-1-5-32-554' = 'BUILTIN\Pre-Windows 2000 Compatible Access'
            'S-1-5-32-555' = 'BUILTIN\Remote Desktop Users'
            'S-1-5-32-556' = 'BUILTIN\Network Configuration Operators'
            'S-1-5-32-557' = 'BUILTIN\Incoming Forest Trust Builders'
            'S-1-5-32-558' = 'BUILTIN\Performance Monitor Users'
            'S-1-5-32-559' = 'BUILTIN\Performance Log Users'
            'S-1-5-32-560' = 'BUILTIN\Windows Authorization Access Group'
            'S-1-5-32-561' = 'BUILTIN\Terminal Server License Servers'
            'S-1-5-32-562' = 'BUILTIN\Distributed COM Users'
            'S-1-5-32-569' = 'BUILTIN\Cryptographic Operators'
            'S-1-5-32-573' = 'BUILTIN\Event Log Readers'
            'S-1-5-32-574' = 'BUILTIN\Certificate Service DCOM Access'
            'S-1-5-32-575' = 'BUILTIN\RDS Remote Access Servers'
            'S-1-5-32-576' = 'BUILTIN\RDS Endpoint Servers'
            'S-1-5-32-577' = 'BUILTIN\RDS Management Servers'
            'S-1-5-32-578' = 'BUILTIN\Hyper-V Administrators'
            'S-1-5-32-579' = 'BUILTIN\Access Control Assistance Operators'
            'S-1-5-32-580' = 'BUILTIN\Remote Management Users'
		}
	}
	Process {
		Try {

            # check if SID is well known
            ForEach ($wellKnownSID in $wellKnownSIDs) {
				Write-Log -message "Check SID: [$SID]" -Source ${CmdletName}
				If($wellKnownSID.Keys -match $SID) { $wellKnown = $true ; break }
				Else { $wellKnown = $false }
			}
			Return $wellKnown
		}
		Catch {
                Write-Log -Message "Failed to check SID. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
    			If (-not $ContinueOnError) {
				Throw "Failed to check SID.: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Test-WellKnownSID

#region Function Update-Desktop
Function Update-Desktop {
<#
.SYNOPSIS
	Refresh the Windows Explorer Shell, which causes the desktop icons and the environment variables to be reloaded.
.DESCRIPTION
	Refresh the Windows Explorer Shell, which causes the desktop icons and the environment variables to be reloaded.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Update-Desktop
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
			Write-Log -Message 'Refresh the Desktop and the Windows Explorer environment process block.' -Source ${CmdletName}
			[PackagingFramework.Explorer]::RefreshDesktopAndEnvironmentVariables()
		}
		Catch {
			Write-Log -Message "Failed to refresh the Desktop and the Windows Explorer environment process block. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to refresh the Desktop and the Windows Explorer environment process block: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Update-FolderPermission
Function Update-FolderPermission {
<#
.SYNOPSIS
	Change NTFS folders permissions.
.DESCRIPTION
	Add, remove, modify and delete NTFS folder permissions.
	The "Add" action will add permissions to the target.
	If "Add" will be used and the Trustee is already permitted the new permission will be append.
	The "Replace" action will replace the current permissions with the new permissions.
	The "Remove" action delete single permissions.
	The "Delete" action delete all permissions of the Trustee	
.PARAMETER Action
	The action to perform. Options: Add, Modify, Remove, Delete
.PARAMETER Path
	Path to the target folder.
.PARAMETER Trustee
	Name of the trustee.
.PARAMETER Permissions
	Permissions to set on folders
	Basic permissions are: FullControl,Modify,ReadAndExecute,ListDirectory,Read,Write
	Multiple permissions can be used! Delimiter is ","
	Further valid values for filesystem: https://msdn.microsoft.com/de-de/library/system.security.accesscontrol.filesystemrights(v=vs.110).aspx
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $false.
.EXAMPLE
	Update-FolderPermission -Action "Add" -Path "C:\temp" -Trustee "[Domainname]\[Groupname]" -Permissions "ReadAndExecute"
	Update-FolderPermission -Action "Replace" -Path "C:\temp" -Trustee "[Domainname]\[Groupname]" -Permissions "Read,Write"
	Update-FolderPermission -Action "Remove" -Path "C:\temp" -Trustee "[Domainname]\[Groupname]" -Permissions "Read"
	Update-FolderPermission -Action "Delete" -Path "C:\temp" -Trustee "[Domainname]\[Groupname]"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateSet('Add','Remove','Replace','Delete')]
		[string]$Action,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
   		[string]$Path,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Trustee,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Permissions,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $false
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		# Check if target path exist
			If (-not (Test-Path -LiteralPath $Path -PathType 'Container')) {
				[boolean]$ExitLoggingFunction = $true
				#  If directory not exist, write message to console
				If (-not $ContinueOnError) { 
					Write-Log -Message "Target path not found: [$Path]" -Severity 1 -Source ${CmdletName} 
				}
				Return
			} Else { $FolderExists = $true }
			
		# Check and Convert trustee
		Try {
			$NTAccountName = New-Object System.Security.Principal.NTAccount($Trustee)
			$AccountSID = $NTAccountName.Translate([System.Security.Principal.SecurityIdentifier])
		}
		Catch [System.Management.Automation.MethodInvocationException] {
			Try {
				$AccountSID = New-Object System.Security.Principal.SecurityIdentifier($Trustee)
				$NTAccountName = $AccountSID.Translate([System.Security.Principal.NTAccount])
			}
			Catch [System.Management.Automation.MethodInvocationException] {
				Write-Log -Message "Trustee not found: [$trustee]" -Severity 3 -Source ${CmdletName}
				$TrusteeExists = $false
				Return
			}
		}
		
		# Check correct permission syntax
		If ($Action -ieq "Delete") { $Permissions = "Read" }
		$AccessControl = [System.Security.AccessControl.FileSystemRights]
		$BuildInPerms = $AccessControl.DeclaredFields | Select Name
		$SplitPermissions = $Permissions.Split(",")
		$count = 0

		ForEach ($SplitPermission in $SplitPermissions) {    
			$PermissionSyntaxOK = $false
			ForEach ($BuildInPerm in $BuildInPerms) {
				[String]$BuildInPermission = $BuildInPerm.Name | Out-String
				$BuildInPermission = $BuildInPermission.Trim()
				If ($SplitPermission -ieq $BuildInPermission) {
					$count = $count + 1
				} 
			}
		}
		If ($SplitPermissions.Count -eq $count) { $PermissionSyntaxOK = $true } 
		Else {
			$PermissionSyntaxOK = $true
			Write-Log -Message "The used permission is not allowed: [$Permissions] - Skip setting permissions for file [$Path]" -Severity 2 -Source ${CmdletName}
		} 
		
		If($FolderExists -eq $true -and $PermissionSyntaxOK -eq $true -and $TrusteeExists -ne $false) { $ExecuteFolderPermissions = $True } Else { $ExecuteFolderPermissions = $False }
		
	}
	Process {
		Try {
			If($ExecuteFolderPermissions -eq $true) {
			
				# Get current permissions
				$permACL = Get-ACL "$Path"
				$currentPermissions = $permACL.Access | Where { $_.IdentityReference -eq $NTAccountName}
				$currentPermissions = ($currentPermissions.FileSystemRights -join ", " | Out-String)
				
				# Define ACL parameters
				If ($Action -ieq "Delete") { $Permissions = "Read" }
				$AccessPermissions = [System.Security.AccessControl.FileSystemRights]"$Permissions"
				$InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::"ContainerInherit" -bor [System.Security.AccessControl.InheritanceFlags]::"ObjectInherit"
				$PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
				$PermissionType = [System.Security.AccessControl.AccessControlType]::Allow
				$Trustee = New-Object System.Security.Principal.NTAccount("$NTAccountName")
				If ($Action -eq "Replace") {
					$AccessModification = New-Object system.security.AccessControl.AccessControlModification
					$AccessModification.value__ = 2
					$Modification = $True
				}
				
				# Create ACL String
				$ACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
					($Trustee, $AccessPermissions, $InheritanceFlag, $PropagationFlag, $PermissionType)
				
				# Get current ACL
				$ACL = Get-ACL "$Path"
				
				# Modify current ACL
				If ($Action -ieq "Add") { $ACL.AddAccessRule($ACE) }
				If ($Action -ieq "Delete") { $ACL.RemoveAccessRuleAll($ACE) }
				If ($Action -ieq "Replace") { $ACL.ModifyAccessRule($AccessModification, $ACE, [ref]$Modification) | Out-Null }
				If ($Action -ieq "Remove") { $ACL.RemoveAccessRule($ACE) }
				
				# Save new ACL
				Set-ACL "$Path" $ACL
				
				If ($Action -ieq "Replace") {
					Write-Log -Message "Permissions [$currentPermissions] replaced by [$Permissions] for [$NTAccountName] successfully in: [$Path]." -Severity 1 -Source ${CmdletName}
				}
				If ($Action -ieq "Add") {
					Write-Log -Message "Permission [$Permissions] added for [$NTAccountName] successfully to: [$Path]." -Severity 1 -Source ${CmdletName}
				}
				If ($Action -ieq "Remove") {
					Write-Log -Message "Permission [$Permissions] removed for [$NTAccountName] successfully to: [$Path]." -Severity 1 -Source ${CmdletName}
				}
				If ($Action -ieq "Delete") {
					Write-Log -Message "All permissions [$currentPermissions] deleted for [$NTAccountName] successfully in: [$Path]." -Severity 1 -Source ${CmdletName}
				}
			} Else { Write-Log -Message "Skip setting permissions for file [$Path]" -Severity 2 -Source ${CmdletName} }
		}
		Catch {
			Write-Log -Message "Failed to set permissions to [$Path]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to set permissions to [$Path]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Update-FilePermission
Function Update-FilePermission {
<#
.SYNOPSIS
	Change NTFS file permissions.
.DESCRIPTION
	Add, remove, modify and delete NTFS file permissions.
	The "Add" action will add permissions to the target file.
	If "Add" will be used and the Trustee is already permitted the new permission will be append.
	The "Replace" action will replace the current permissions with the new permissions.
	The "Remove" action delete single permissions.
	The "Delete" action delete all permissions of the Trustee	
.PARAMETER Action
	The action to perform. Options: Add, Modify, Remove, Delete
.PARAMETER Path
	Path to the target folder.
.PARAMETER Filename
	Name of the target file.
.PARAMETER Trustee
	Name of the trustee.
.PARAMETER Permissions
	Permissions to set on folders
	Basic permissions are: FullControl,Modify,ReadAndExecute,Read,Write
	Multiple permissions can be used! Delimiter is ","
	Further valid values for filesystem: https://msdn.microsoft.com/de-de/library/system.security.accesscontrol.filesystemrights(v=vs.110).aspx
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $false.
.EXAMPLE
	Update-FilePermission -Action "Add" -Path "C:\temp" -Filename "1.txt" -Trustee "[Domainname]\[Groupname]" -Permissions "ReadAndExecute"
	Update-FilePermission -Action "Replace" -Path "C:\temp" -Filename "1.txt" -Trustee "[Domainname]\[Groupname]" -Permissions "Read,Write"
	Update-FilePermission -Action "Remove" -Path "C:\temp" -Filename "1.txt" -Trustee "[Domainname]\[Groupname]" -Permissions "Read"
	Update-FilePermission -Action "Delete" -Path "C:\temp" -Filename "1.txt" -Trustee "[Domainname]\[Groupname]"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateSet('Add','Remove','Replace','Delete')]
		[string]$Action,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
   		[string]$Path,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
   		[string]$Filename,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Trustee,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Permissions,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $false
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		# Check if target path exist
		If (-not (Test-Path -LiteralPath "$Path\$Filename" -PathType 'Leaf')) {
			[boolean]$ExitLoggingFunction = $true
			#  If directory not exist, write message to console
			If (-not $ContinueOnError) { 
				Write-Log -Message "Target file not found: [$Path\$Filename]" -Severity 1 -Source ${CmdletName} 
			}
			Return
		} Else { $FileExists = $true }
			
		# Check and Convert trustee
		Try {
			$NTAccountName = New-Object System.Security.Principal.NTAccount($Trustee)
			$AccountSID = $NTAccountName.Translate([System.Security.Principal.SecurityIdentifier])
		}
		Catch [System.Management.Automation.MethodInvocationException] {
			Try {
				$AccountSID = New-Object System.Security.Principal.SecurityIdentifier($Trustee)
				$NTAccountName = $AccountSID.Translate([System.Security.Principal.NTAccount])
			}
			Catch [System.Management.Automation.MethodInvocationException] {
				Write-Log -Message "Trustee not found: [$trustee]" -Severity 3 -Source ${CmdletName}
				$TrusteeExists = $false
				Return
			}
		}
		
		# Check correct permission syntax
		If ($Action -ieq "Delete") { $Permissions = "Read" }
		$AccessControl = [System.Security.AccessControl.FileSystemRights]
		$BuildInPerms = $AccessControl.DeclaredFields | Select Name
		$SplitPermissions = $Permissions.Split(",")
		$count = 0

		ForEach ($SplitPermission in $SplitPermissions) {    
			$PermissionSyntaxOK = $false
			ForEach ($BuildInPerm in $BuildInPerms) {
				[String]$BuildInPermission = $BuildInPerm.Name | Out-String
				$BuildInPermission = $BuildInPermission.Trim()
				If ($SplitPermission -ieq $BuildInPermission) {
					$count = $count + 1
				} 
			}
		}
		If ($SplitPermissions.Count -eq $count) { $PermissionSyntaxOK = $true } 
		Else {
			$PermissionSyntaxOK = $false
			Write-Log -Message "The used permission is not allowed: [$Permissions] - Skip setting permissions for file [$Path\$Filename]" -Severity 2 -Source ${CmdletName}
		} 
		
		If($FileExists -eq $true -and $PermissionSyntaxOK -eq $true -and $TrusteeExists -ne $false) { $ExecuteFilePermissions = $True } Else { $ExecuteFilePermissions = $False }
		
	}
	Process {
		Try {
			If($ExecuteFilePermissions -eq $true) {
			
				# Get current permissions
				$permACL = Get-ACL "$Path"
				$currentPermissions = $permACL.Access | Where { $_.IdentityReference -eq $NTAccountName}
				$currentPermissions = ($currentPermissions.FileSystemRights -join ", " | Out-String)
				
				# Define ACL parameters
				If ($Action -ieq "Delete") { $Permissions = "Read" }
				$AccessPermissions = [System.Security.AccessControl.FileSystemRights]"$Permissions"
				$PermissionType = [System.Security.AccessControl.AccessControlType]::Allow
				$Trustee = New-Object System.Security.Principal.NTAccount("$NTAccountName")
				If ($Action -eq "Replace") {
					$AccessModification = New-Object system.security.AccessControl.AccessControlModification
					$AccessModification.value__ = 2
					$Modification = $True
				}
				
				# Create ACL String
				$ACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
					($Trustee, $AccessPermissions, $PermissionType)
				
				# Get current ACL
				$ACL = Get-ACL "$Path\$Filename"
				
				# Modify current ACL
				If ($Action -ieq "Add") { $ACL.AddAccessRule($ACE) }
				If ($Action -ieq "Delete") { $ACL.RemoveAccessRuleAll($ACE) }
				If ($Action -ieq "Replace") { $ACL.ModifyAccessRule($AccessModification, $ACE, [ref]$Modification) | Out-Null }
				If ($Action -ieq "Remove") { $ACL.RemoveAccessRule($ACE) }
				
				# Save new ACL
				Set-ACL "$Path\$Filename" $ACL
				
				If ($Action -ieq "Replace") {
					Write-Log -Message "Permissions [$currentPermissions] replaced by [$Permissions] for [$NTAccountName] successfully in: [$Path\$Filename]." -Severity 1 -Source ${CmdletName}
				}
				If ($Action -ieq "Add") {
					Write-Log -Message "Permission [$Permissions] added for [$NTAccountName] successfully to: [$Path\$Filename]." -Severity 1 -Source ${CmdletName}
				}
				If ($Action -ieq "Remove") {
					Write-Log -Message "Permission [$Permissions] removed for [$NTAccountName] successfully to: [$Path\$Filename]." -Severity 1 -Source ${CmdletName}
				}
				If ($Action -ieq "Delete") {
					Write-Log -Message "All Permissions [$currentPermissions] deleted for [$NTAccountName] successfully in: [$Path\$Filename]." -Severity 1 -Source ${CmdletName}
				}
			} Else { Write-Log -Message "Skip setting permissions for file [$Path\$Filename]" -Severity 2 -Source ${CmdletName} }
		} 
		Catch {
			Write-Log -Message "Failed to set permissions to [$Path\$Filename]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to set permissions to [$Path\$Filename]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Update-FrameworkInPackages
Function Update-FrameworkInPackages {
<#
.SYNOPSIS
	Update Packaging Framework files in Package folders
.DESCRIPTION
	Update Packaging Framework files in Package folders
.PARAMETER ModuleFolder
	The folder where your source moduel file are
.PARAMETER PackagesFolder
	The destination folder where your packages are stored
.EXAMPLE
	Update-FrameworkInPackages -ModuleFolder 'C:\Program Files\WindowsPowerShell\Modules' -PackagesFolder 'Y:\Packages\'
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[Cmdletbinding()]
	param
	( 
		[Parameter(Mandatory=$True,Position=0)]
		[ValidateNotNullorEmpty()]
		[String]$ModuleFolder,
		[Parameter(Mandatory=$True,Position=1)]
		[ValidateNotNullorEmpty()]
		[String]$PackagesFolder
	)
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	Process {
		Try {
				[Array]$FrameworkFolders = get-childitem $PackagesFolder -Filter PackagingFramework.psm1 -Recurse
				Foreach($FrameworkFolder in $FrameworkFolders)
				{
					Copy-item -Path "$ModuleFolder\PackagingFramework\*" -Destination $FrameworkFolder.DirectoryName -Verbose -Force 
					Copy-item -Path "$ModuleFolder\PackagingFrameworkExtension\*" -Destination $FrameworkFolder.DirectoryName -Verbose -Force 
				} 
		}
		Catch {
				Write-Log -Message "Failed to update packaging framework files for [$PackagesFolder]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
				Throw "Failed to update packaging framework files for [$PackagesFolder].: $($_.Exception.Message)"
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Update-FrameworkInPackages

#region Function Update-PrinterPermission
Function Update-PrinterPermission
{
<#
.SYNOPSIS
	Add or remove printer permissions
.DESCRIPTION
	Add or remove printer permissions
.PARAMETER Action
	The action to perform. Options: Add, Remove
.PARAMETER Printer
	Name of the printer.
.PARAMETER Trustee
	Name of the trustee.
.PARAMETER Permissions
	Permissions to set if Action is "Add". Valid values: ManagePrinters,ManageDocuments,Print,TakeOwnership,ReadPermissions,ChangePermissions,FullControl
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Update-PrinterPermission -Action "Add" -Printer "Testdrucker" -Trustee "[Domainname]\[Groupname]" -Permissions "FullControl"
	Update-PrinterPermission -Action "Remove" -Printer "Testdrucker" -Trustee "[Domainname]\[Groupname]"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateSet('Add', 'Remove')]
		[ValidateNotNullorEmpty()]
		[string]$Action,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]$Printer,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[string]$Trustee,
		[Parameter(Mandatory = $false)]
		[ValidateSet('ManagePrinters', 'ManageDocuments', 'Print', 'TakeOwnership', 'ReadPermissions', 'ChangePermissions', 'FullControl')]
		[ValidateNotNullorEmpty()]
		[string]$Permissions,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin
	{
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		# Check if printer object exist
		$printerexists = Get-Printer -Name "$Printer" -ErrorAction SilentlyContinue
		
		# Check and Convert trustee
		Try {
			$NTAccountName = New-Object System.Security.Principal.NTAccount($Trustee)
			$AccountSID = $NTAccountName.Translate([System.Security.Principal.SecurityIdentifier])
			}
		Catch [System.Management.Automation.MethodInvocationException] {
			Try {
				$AccountSID = New-Object System.Security.Principal.SecurityIdentifier($Trustee)
				$NTAccountName = $AccountSID.Translate([System.Security.Principal.NTAccount])
			}
			Catch [System.Management.Automation.MethodInvocationException] {
				Write-Log -Message "Trustee not found: [$trustee] - Skip setting permissions for printer [$Printer]" -Severity 2 -Source ${CmdletName}
				$TrusteeExists = $false
				Return
			}
		}
		
		If($printerexists -ne $null) { $ExecutePrinterPermissions = $true } 
		Else { 
			$ExecutePrinterPermissions = $false 
			Write-Log -Message "Printer [$Printer] not found - Skip setting permissions for printer [$Printer]" -Severity 2 -Source ${CmdletName}
		}
		
		If($ExecutePrinterPermissions = $true) { If($TrusteeExists -ne $false) { $ExecutePrinterPermissions = $true } }
		
		If($ExecutePrinterPermissions = $true) {
			If($Permissions -eq 'ManagePrinters' -or 'ManageDocuments' -or 'Print' -or 'TakeOwnership' -or 'ReadPermissions' -or 'ChangePermissions' -or 'FullControl' -or $null) {
				$ExecutePrinterPermissions = $true
			}
			Else {Write-Log -Message "The used permission is not allowed: [$Permissions] - Skip setting permissions for printer [$Printer]" -Severity 2 -Source ${CmdletName}}
		}
	}
	Process
	{
		Try
		{
			# Skip if printer not exists
			If($ExecutePrinterPermissions -ne $false -and $TrusteeExists -ne $false) {
				# Get current permissions of the choosen printer object
				$PrinterPermissionSDDL = Get-Printer -full -Name "$Printer" | select PrinterPermissionSDDL -ExpandProperty PermissionSDDL
				Write-Host $PrinterPermissionSDDL
				# Set and enumerate default values
				$isContainer = $false
				$isDS = $false
				$SecurityDescriptor = New-Object -TypeName `
												 Security.AccessControl.CommonSecurityDescriptor `
												 $isContainer, $isDS, $PrinterPermissionSDDL
				
				If ($Action -eq 'Add')
				{
					# Generate new Security Descriptor string
					switch ($Permissions)
					{
						"ManagePrinters" { $Permission = "983052" }
						"ManageDocuments" { $Permission = "983088" }
						"Print" { $Permission = "131080" }
						"TakeOwnership" { $Permission = "524288" }
						"ReadPermissions" { $Permission = "131072" }
						"ChangePermissions" { $Permission = "262144" }
						"FullControl" { $Permission = "268435456" }
					}
					#Write-Host "Permissions: $Permissions"
					# Generate new SDDL
					$SecurityDescriptor.DiscretionaryAcl.AddAccess(
						[System.Security.AccessControl.AccessControlType]::Allow,
						$AccountSID,
						$Permission,
						[System.Security.AccessControl.InheritanceFlags]::None,
						[System.Security.AccessControl.PropagationFlags]::None) | Out-Null
					
					
					$newSDDL = $SecurityDescriptor.GetSddlForm("All")
					Get-Printer -Name $Printer | Set-Printer -PermissionSDDL $newSDDL# -verbose
				}
				Else
				{
					$PermissionExist = $False
					Foreach ($SDDL in $SecurityDescriptor.DiscretionaryAcl)
					{
						If ($SDDL.SecurityIdentifier -match $AccountSID)
						{
							# found one ace_string to remove
							$PermissionExist = $True
							$SecurityDescriptor.DiscretionaryAcl.RemoveAccess(
								[System.Security.AccessControl.AccessControlType]::Allow,
								$SDDL.SecurityIdentifier,
								$SDDL.AccessMask,
								$SDDL.InheritanceFlags,
								$SDDL.PropagationFlags) | Out-Null
						}
					}
					
					If ($PermissionExist)
					{
						$newSDDL = $SecurityDescriptor.GetSddlForm("All")
						Get-Printer -Name $Printer | Set-Printer -PermissionSDDL $newSDDL#-verbose
					}
					Else
					{
						Write-Log -Message "Could not find the Account to remove from SDDL. `n$(Resolve-Error)" -Severity 2 -Source ${CmdletName}
						return $Null
					}
					
				}
			} Else { Write-Log -Message "Skip setting permissions for printer [$Printer]" -Severity 2 -Source ${CmdletName} }
		}
		Catch
		{
			Write-Log -Message "Failed to set new permission to printer. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError)
			{
				Throw "Failed to set new permission to printer: $($_.Exception.Message)"
			}
		}
	}
	End
	{
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion Function Update-PrinterPermission

#region Function Update-RegistryPermission
Function Update-RegistryPermission {
<#
.SYNOPSIS
	Change NTFS registry permissions.
.DESCRIPTION
	Add, remove, modify and delete NTFS file permissions.
	The "Add" action will add permissions to the target file.
	If "Add" will be used and the Trustee is already permitted the new permission will be append.
	The "Replace" action will replace the current permissions with the new permissions.
	The "Remove" action delete single permissions.
	The "Delete" action delete all permissions of the Trustee	
.PARAMETER Action
	The action to perform. Options: Add, Modify, Remove, Delete
.PARAMETER Key
	Path to the target folder.
.PARAMETER Trustee
	Name of the trustee.
.PARAMETER Permissions
	Permissions to set on folders
	Basic permissions are: FullControl,ReadKey
	Multiple permissions can be used!
	Further valid values for registry: https://msdn.microsoft.com/de-de/library/system.security.accesscontrol.registryrights(v=vs.110).aspx
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $false.
.EXAMPLE
	Update-RegistryPermission -Action "Add" -Key "HKEY_CURRENT_USER\Test\Test1" -Trustee "[Domainname]\[Groupname]" -Permissions "Read"
	Update-RegistryPermission -Action "Replace" -Key "HKEY_CURRENT_USER\Test\Test1" -Trustee "[Domainname]\[Groupname]" -Permissions "FullControl"
	Update-RegistryPermission -Action "Remove" -Key "HKEY_CURRENT_USER\Test\Test1" -Trustee "[Domainname]\[Groupname]" -Permissions "Read"
	Update-RegistryPermission -Action "Delete" -Key "HKEY_CURRENT_USER\Test\Test1" -Trustee "[Domainname]\[Groupname]"
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateSet('Add','Remove','Replace','Delete')]
		[string]$Action,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
   		[string]$Key,
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$Trustee,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullorEmpty()]
		[string]$Permissions,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $false
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		# Check input value is a registry key
		If ($Key.StartsWith('HK'))	{ 
			# Convert registry key to powershell usable format
			$RegKey = Convert-RegistryPath -Key "$key"
			Write-Log -Message "Convert registry key [$Key] to [$RegKey]" -Severity 1 -Source ${CmdletName}
			$isRegkey = $true 
		} Else { Write-Log -Message "No valid registry key: [$Key]" -Severity 3 -Source ${CmdletName}  }
		
		# Check if target path exist
		If ($isRegkey -eq $true) {
			If (-not (Test-Path -LiteralPath "$RegKey" -PathType 'Container')) {
				[boolean]$ExitLoggingFunction = $true
				#  If directory not exist, write message to console
				If (-not $ContinueOnError) { 
					Write-Log -Message "Target key not found: [$Key]" -Severity 3 -Source ${CmdletName} 
				}
				Return
			}
			Else { $RegkeyExists = $true }
		}
		
		# Check and Convert trustee
		Try {
			$NTAccountName = New-Object System.Security.Principal.NTAccount($Trustee)
			$AccountSID = $NTAccountName.Translate([System.Security.Principal.SecurityIdentifier])
		}
		Catch [System.Management.Automation.MethodInvocationException] {
			Try {
				$AccountSID = New-Object System.Security.Principal.SecurityIdentifier($Trustee)
				$NTAccountName = $AccountSID.Translate([System.Security.Principal.NTAccount])
			}
			Catch [System.Management.Automation.MethodInvocationException] {
				Write-Log -Message "Trustee not found: [$trustee]" -Severity 3 -Source ${CmdletName}
				$TrusteeExists = $false
				Return
			}
		}
		
		# Check correct permission syntax
		If ($Action -ieq "Delete") { $Permissions = "ReadKey" }
		$AccessControl = [System.Security.AccessControl.RegistryRights]
		$BuildInPerms = $AccessControl.DeclaredFields | Select Name
		$SplitPermissions = $Permissions.Split(",")
		$count = 0
		ForEach ($SplitPermission in $SplitPermissions) {    
			$PermissionSyntaxOK = $false
			ForEach ($BuildInPerm in $BuildInPerms) {
				[String]$BuildInPermission = $BuildInPerm.Name | Out-String
				$BuildInPermission = $BuildInPermission.Trim()
				If ($SplitPermission -ieq $BuildInPermission) {
					$count = $count + 1
				} 
			}
		}
		If ($SplitPermissions.Count -eq $count) { $PermissionSyntaxOK = $true } 
		Else {
			$PermissionSyntaxOK = $false
			Write-Log -Message "The used permission is not allowed: [$Permissions] - Skip setting permissions for regsitry key [$key]" -Severity 2 -Source ${CmdletName} 
		} 
		
		If($isRegkey -eq $true -and $RegkeyExists -eq $true -and $PermissionSyntaxOK -eq $true -and $TrusteeExists -ne $false) { $ExecuteRegistryPermissions = $True } Else { $ExecuteRegistryPermissions = $False }
	
	}
	Process {
		Try {
			If($ExecuteRegistryPermissions -eq $true) {
			
				# Convert registy key to needed format
				$RegPSDrive = $RegKey.TrimStart('Registry::')
				# Create Powershell drive because Get-ACL and Set-ACL bug
				New-PSDrive -Name "RegDrive" -PSProvider "Registry" -Root "$RegPSDrive" | Out-Null
				
				# Get current permissions
				$permACL = Get-ACL -Path 'RegDrive:'
				$currentPermissions = $permACL.Access | Where { $_.IdentityReference -eq $trustee}
				$currentPermissions = ($currentPermissions.RegistryRights | Out-String)
			
				# Define ACL parameters
				If ($Action -ieq "Delete") { $Permissions = "ReadKey" }
				$AccessPermissions = [System.Security.AccessControl.RegistryRights]"$Permissions"
				$InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::"ContainerInherit" -bor [System.Security.AccessControl.InheritanceFlags]::"ObjectInherit"
				$PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
				$PermissionType = [System.Security.AccessControl.AccessControlType]::Allow
				$Trustee = New-Object System.Security.Principal.NTAccount("$NTAccountName")
				If ($Action -eq "Replace") {
					$AccessModification = New-Object system.security.AccessControl.AccessControlModification
					$AccessModification.value__ = 2
					$Modification = $True
				}
			
				# Create ACL String
				$ACE = New-Object System.Security.AccessControl.RegistryAccessRule `
					($Trustee, $AccessPermissions, $InheritanceFlag, $PropagationFlag, $PermissionType)
			
				# Get current ACL
				$ACL = Get-ACL -Path 'RegDrive:'
			
				# Modify current ACL
				If ($Action -ieq "Add") { $ACL.AddAccessRule($ACE) }
				If ($Action -ieq "Delete") { $ACL.RemoveAccessRuleAll($ACE) }
				If ($Action -ieq "Replace") { $ACL.ModifyAccessRule($AccessModification, $ACE, [ref]$Modification) | Out-Null }
				If ($Action -ieq "Remove") { $ACL.RemoveAccessRule($ACE) }
			
				# Save new ACL
				Set-ACL -Path 'RegDrive:' -AclObject $ACL
						
				If ($Action -ieq "Replace") {
					Write-Log -Message "Permissions [$currentPermissions] replaced by [$Permissions] for [$NTAccountName] successfully in: [$Key]." -Severity 1 -Source ${CmdletName}
				}
				If ($Action -ieq "Add") {
					Write-Log -Message "Permission [$Permissions] added for [$NTAccountName] successfully to: [$Key]." -Severity 1 -Source ${CmdletName}
				}
				If ($Action -ieq "Remove") {
					Write-Log -Message "Permission [$Permissions] removed for [$NTAccountName] successfully to: [$Key]." -Severity 1 -Source ${CmdletName}
				}
				If ($Action -ieq "Delete") {
					Write-Log -Message "All Permissions [$currentPermissions] deleted for [$NTAccountName] successfully in: [$Key]." -Severity 1 -Source ${CmdletName}
				}
			
				# Remove Powershell drive
				Remove-PSDrive -Name "RegDrive"
			} Else { Write-Log -Message "Skip setting permissions for registry key [$Key]" -Severity 2 -Source ${CmdletName} }
		}
		Catch {
			Write-Log -Message "Failed to set permissions to [$Key]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to set permissions to [$Path]: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Update-SessionEnvironmentVariables
Function Update-SessionEnvironmentVariables {
<#
.SYNOPSIS
	Updates the environment variables for the current PowerShell session with any environment variable changes that may have occurred during script execution.
.DESCRIPTION
	Environment variable changes that take place during script execution are not visible to the current PowerShell session.
	Use this function to refresh the current PowerShell session with all environment variable settings.
.PARAMETER LoadLoggedOnUserEnvironmentVariables
	If script is running in SYSTEM context, this option allows loading environment variables from the active console user. If no console user exists but users are logged in, such as on terminal servers, then the first logged-in non-console user.
.PARAMETER ContinueOnError
	Continue if an error is encountered. Default is: $true.
.EXAMPLE
	Update-SessionEnvironmentVariables
.NOTES
	Created by ceterion AG
.LINK
	http://www.ceterion.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[Switch]$LoadLoggedOnUserEnvironmentVariables = $false,
		[Parameter(Mandatory=$false)]
		[ValidateNotNullOrEmpty()]
		[boolean]$ContinueOnError = $true
	)
	
	Begin {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		
		[scriptblock]$GetEnvironmentVar = {
			Param (
				$Key,
				$Scope
			)
			[Environment]::GetEnvironmentVariable($Key, $Scope)
		}
	}
	Process {
		Try {
			Write-Log -Message 'Refresh the environment variables for this PowerShell session.' -Source ${CmdletName}
			
			If ($LoadLoggedOnUserEnvironmentVariables -and $RunAsActiveUser) {
				[string]$CurrentUserEnvironmentSID = $RunAsActiveUser.SID
			}
			Else {
				[string]$CurrentUserEnvironmentSID = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
			}
			[string]$MachineEnvironmentVars = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
			[string]$UserEnvironmentVars = "Registry::HKEY_USERS\$CurrentUserEnvironmentSID\Environment"
			
			## Update all session environment variables. Ordering is important here: $UserEnvironmentVars comes second so that we can override $MachineEnvironmentVars.
			$MachineEnvironmentVars, $UserEnvironmentVars | Get-Item | Where-Object { $_ } | ForEach-Object { $envRegPath = $_.PSPath; $_ | Select-Object -ExpandProperty 'Property' | ForEach-Object { Set-Item -LiteralPath "env:$($_)" -Value (Get-ItemProperty -LiteralPath $envRegPath -Name $_).$_ } }
			
			## Set PATH environment variable separately because it is a combination of the user and machine environment variables
			[string[]]$PathFolders = 'Machine', 'User' | ForEach-Object { (& $GetEnvironmentVar -Key 'PATH' -Scope $_) } | Where-Object { $_ } | ForEach-Object { $_.Trim(';') } | ForEach-Object { $_.Split(';') } | ForEach-Object { $_.Trim() } | ForEach-Object { $_.Trim('"') } | Select-Object -Unique
			$env:PATH = $PathFolders -join ';'
		}
		Catch {
			Write-Log -Message "Failed to refresh the environment variables for this PowerShell session. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			If (-not $ContinueOnError) {
				Throw "Failed to refresh the environment variables for this PowerShell session: $($_.Exception.Message)"
			}
		}
	}
	End {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

#region Function Write-Log
Function Write-Log {
<#
.SYNOPSIS
	Write messages to a log file in CMTrace.exe compatible format or Legacy text file format.
.DESCRIPTION
	Write messages to a log file in CMTrace.exe compatible format or Legacy text file format and optionally display in the console.
.PARAMETER Message
	The message to write to the log file or output to the console.
.PARAMETER Severity
	Defines message type. When writing to console or CMTrace.exe log format, it allows highlighting of message type.
	Options: 1 = Information (default), 2 = Warning (highlighted in yellow), 3 = Error (highlighted in red)
.PARAMETER Source
	The source of the message being logged.
.PARAMETER ScriptSection
	The heading for the portion of the script that is being executed. Default is: $script:installPhase.
.PARAMETER LogType
	Choose whether to write a CMTrace.exe compatible log file or a Legacy text log file.
.PARAMETER LogFileDirectory
	Set the directory where the log file will be saved.
.PARAMETER LogFileName
	Set the name of the log file.
.PARAMETER MaxLogFileSizeMB
	Maximum file size limit for log file in megabytes (MB). Default is 10 MB.
.PARAMETER WriteHost
	Write the log message to the console.
.PARAMETER ContinueOnError
	Suppress writing log message to console on failure to write message to log file. Default is: $true.
.PARAMETER PassThru
	Return the message that was passed to the function
.PARAMETER DebugMessage
	Specifies that the message is a debug message. Debug messages only get logged if -LogDebugMessage is set to $true.
.PARAMETER LogDebugMessage
	Debug messages only get logged if this parameter is set to $true in the config file.
.EXAMPLE
	Write-Log -Message "Installing patch MS15-031" -Source 'Add-Patch' -LogType 'CMTrace'
.EXAMPLE
	Write-Log -Message "Script is running on Windows 8" -Source 'Test-ValidOS' -LogType 'Legacy'
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
		[AllowEmptyCollection()]
		[Alias('Text')]
		[string[]]$Message,
		[Parameter(Mandatory=$false,Position=1)]
		[ValidateRange(1,3)]
		[int16]$Severity = 1,
		[Parameter(Mandatory=$false,Position=2)]
		[ValidateNotNull()]
		[string]$Source = $PackagingFrameworkName,
		[Parameter(Mandatory=$false,Position=3)]
		[ValidateNotNullorEmpty()]
        [string]$ScriptSection = $Global:InstallPhase,
        [Parameter(Mandatory=$false,Position=4)]
		[ValidateSet('CMTrace','Legacy')]
		[string]$LogType = $Global:ConfigLogStyle,
		[Parameter(Mandatory=$false,Position=5)]
		[ValidateNotNullorEmpty()]
		[string]$LogFileDirectory = $Global:LogDir,
		[Parameter(Mandatory=$false,Position=6)]
		[ValidateNotNullorEmpty()]
		[string]$LogFileName = $Global:LogName,
		[Parameter(Mandatory=$false,Position=8)]
		[ValidateNotNullorEmpty()]
		[boolean]$WriteHost = $Global:ConfigLogWriteToHost,
		[Parameter(Mandatory=$false,Position=9)]
		[ValidateNotNullorEmpty()]
		[boolean]$ContinueOnError = $true,
		[Parameter(Mandatory=$false,Position=10)]
		[Switch]$PassThru = $false,
		[Parameter(Mandatory=$false,Position=11)]
		[Switch]$DebugMessage = $false,
		[Parameter(Mandatory=$false,Position=12)]
		[boolean]$LogDebugMessage = $Global:ConfigLogDebugMessage
	)
	
	Begin {
        ## Get the name of this function
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

		## Logging Variables
		#  Log file date/time
		[string]$LogTime = (Get-Date -Format 'HH:mm:ss.fff').ToString()
		[string]$LogDate = (Get-Date -Format 'MM-dd-yyyy').ToString()
		If (-not (Test-Path -LiteralPath 'variable:LogTimeZoneBias')) { [int32]$script:LogTimeZoneBias = [timezone]::CurrentTimeZone.GetUtcOffset([datetime]::Now).TotalMinutes }
		[string]$LogTimePlusBias = $LogTime + $script:LogTimeZoneBias
		#  Initialize variables
		[boolean]$ExitLoggingFunction = $false
		If (-not (Test-Path -LiteralPath 'variable:DisableLogging')) { $DisableLogging = $false }
		#  Check if the script section is defined
		[boolean]$ScriptSectionDefined = [boolean](-not [string]::IsNullOrEmpty($ScriptSection))

		

        #  Get the file name of the source script
		Try {
			If ($script:MyInvocation.Value.ScriptName) {
				[string]$ScriptSource = Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf -ErrorAction 'Stop'
			}
			Else {
				[string]$ScriptSource = Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf -ErrorAction 'Stop'
			}
		}
		Catch {
			$ScriptSource = ''
		}
		


		## Create script block for generating CMTrace.exe compatible log entry
		[scriptblock]$CMTraceLogString = {
			Param (
				[string]$lMessage,
				[string]$lSource,
				[int16]$lSeverity
			)
			"<![LOG[$lMessage]LOG]!>" + "<time=`"$LogTimePlusBias`" " + "date=`"$LogDate`" " + "component=`"$lSource`" " + "context=`"$([Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + "type=`"$lSeverity`" " + "thread=`"$PID`" " + "file=`"$ScriptSource`">"
		}
		
		## Create script block for writing log entry to the console
		[scriptblock]$WriteLogLineToHost = {
			Param (
				[string]$lTextLogLine,
				[int16]$lSeverity
			)
			If ($WriteHost) {
				#  Only output using color options if running in a host which supports colors.
				If ($Host.UI.RawUI.ForegroundColor) {
					Switch ($lSeverity) {
						3 { Write-Host -Object $lTextLogLine -ForegroundColor 'Red' -BackgroundColor 'Black' }
						2 { Write-Host -Object $lTextLogLine -ForegroundColor 'Yellow' -BackgroundColor 'Black' }
						1 { Write-Host -Object $lTextLogLine }
					}
				}
				#  If executing "powershell.exe -File <filename>.ps1 > log.txt", then all the Write-Host calls are converted to Write-Output calls so that they are included in the text log.
				Else {
					Write-Output -InputObject $lTextLogLine
				}
			}
		}
		
		## Exit function if it is a debug message and logging debug messages is not enabled in the config file
		If (($DebugMessage) -and (-not $LogDebugMessage)) { [boolean]$ExitLoggingFunction = $true; Return }
		## Exit function if logging to file is disabled and logging to console host is disabled
		If (($DisableLogging) -and (-not $WriteHost)) { [boolean]$ExitLoggingFunction = $true; Return }
		## Exit Begin block if logging is disabled
		If ($DisableLogging) { Return }
		## Exit function function if it is an [Initialization] message and the script has been relaunched

        
        
		## Create the directory where the log file will be saved
		If (-not (Test-Path -LiteralPath $LogFileDirectory -PathType 'Container')) {
			Try {
				$null = New-Item -Path $LogFileDirectory -Type 'Directory' -Force -ErrorAction 'Stop'
			}
			Catch {
				[boolean]$DisableLogging = $true
				#  If error creating directory, write message to console
				If (-not $ContinueOnError) {
					Write-Host -Object "[$LogDate $LogTime] [${CmdletName}] $ScriptSection :: Failed to create the log directory [$LogFileDirectory]. `n$(Resolve-Error)" -ForegroundColor 'Red'
				}
				Return
			}
		}
		
		## Assemble the fully qualified path to the log file
		[string]$LogFilePath = Join-Path -Path $LogFileDirectory -ChildPath $LogFileName
	}
	Process {
		## Exit function if logging is disabled
		If ($ExitLoggingFunction) { Return }
		
		ForEach ($Msg in $Message) {
			## If the message is not $null or empty, create the log entry for the different logging methods
			[string]$CMTraceMsg = ''
			[string]$ConsoleLogLine = ''
			[string]$LegacyTextLogLine = ''
			If ($Msg) {
				#  Create the CMTrace log message
				If ($ScriptSectionDefined) { [string]$CMTraceMsg = "[$ScriptSection] :: $Msg" }
				
				#  Create a Console and Legacy "text" log entry
				[string]$LegacyMsg = "[$LogDate $LogTime]"
				If ($ScriptSectionDefined) { [string]$LegacyMsg += " [$ScriptSection]" }
				If ($Source) {
					[string]$ConsoleLogLine = "$LegacyMsg [$Source] :: $Msg"
					Switch ($Severity) {
						3 { [string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Error] :: $Msg" }
						2 { [string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Warning] :: $Msg" }
						1 { [string]$LegacyTextLogLine = "$LegacyMsg [$Source] [Info] :: $Msg" }
					}
				}
				Else {
					[string]$ConsoleLogLine = "$LegacyMsg :: $Msg"
					Switch ($Severity) {
						3 { [string]$LegacyTextLogLine = "$LegacyMsg [Error] :: $Msg" }
						2 { [string]$LegacyTextLogLine = "$LegacyMsg [Warning] :: $Msg" }
						1 { [string]$LegacyTextLogLine = "$LegacyMsg [Info] :: $Msg" }
					}
				}
			}
			
			## Execute script block to create the CMTrace.exe compatible log entry
			[string]$CMTraceLogLine = & $CMTraceLogString -lMessage $CMTraceMsg -lSource $Source -lSeverity $Severity
			
			## Choose which log type to write to file
			If ($LogType -ieq 'CMTrace') {
				[string]$LogLine = $CMTraceLogLine
			}
			Else {
				[string]$LogLine = $LegacyTextLogLine
			}
			
			## Write the log entry to the log file if logging is not currently disabled
			If (-not $DisableLogging) {
				Try {
					$LogLine | Out-File -FilePath $LogFilePath -Append -NoClobber -Force -Encoding 'UTF8' -ErrorAction 'Stop'
				}
				Catch {
					If (-not $ContinueOnError) {
						Write-Host -Object "[$LogDate $LogTime] [$ScriptSection] [${CmdletName}] :: Failed to write message [$Msg] to the log file [$LogFilePath]. `n$(Resolve-Error)" -ForegroundColor 'Red'
					}
				}
			}
			
			## Execute script block to write the log entry to the console if $WriteHost is $true
			& $WriteLogLineToHost -lTextLogLine $ConsoleLogLine -lSeverity $Severity
		}
	}
	End { }
}
#endregion

#region Function Write-FunctionHeaderOrFooter
Function Write-FunctionHeaderOrFooter {
<#
.SYNOPSIS
	Write the function header or footer to the log upon first entering or exiting a function.
.DESCRIPTION
	Write the "Function Start" message, the bound parameters the function was invoked with, or the "Function End" message when entering or exiting a function.
	Messages are debug messages so will only be logged if LogDebugMessage option is enabled in config file.
.PARAMETER CmdletName
	The name of the function this function is invoked from.
.PARAMETER CmdletBoundParameters
	The bound parameters of the function this function is invoked from.
.PARAMETER Header
	Write the function header.
.PARAMETER Footer
	Write the function footer.
.EXAMPLE
	Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
.EXAMPLE
	Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
.NOTES
	Originaly from App Deployment Toolkit, adapted by ceterion AG
.LINK
	http://psappdeploytoolkit.com
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullorEmpty()]
		[string]$CmdletName,
		[Parameter(Mandatory=$true,ParameterSetName='Header')]
		[AllowEmptyCollection()]
		[hashtable]$CmdletBoundParameters,
		[Parameter(Mandatory=$true,ParameterSetName='Header')]
		[Switch]$Header,
		[Parameter(Mandatory=$true,ParameterSetName='Footer')]
		[Switch]$Footer
	)
	
	If ($Header) {
		Write-Log -Message 'Function Start' -Source ${CmdletName} -DebugMessage
		
		## Get the parameters that the calling function was invoked with
		[string]$CmdletBoundParameters = $CmdletBoundParameters | Format-Table -Property @{ Label = 'Parameter'; Expression = { "[-$($_.Key)]" } }, @{ Label = 'Value'; Expression = { $_.Value }; Alignment = 'Left' } -AutoSize -Wrap | Out-String
		If ($CmdletBoundParameters) {
			Write-Log -Message "Function invoked with bound parameter(s): `n$CmdletBoundParameters" -Source ${CmdletName} -DebugMessage
		}
		Else {
			Write-Log -Message 'Function invoked without any bound parameters.' -Source ${CmdletName} -DebugMessage
		}
	}
	ElseIf ($Footer) {
		Write-Log -Message 'Function End' -Source ${CmdletName} -DebugMessage
	}
}
#endregion

## Export functions, aliases and variables
Export-ModuleMember -Function Add-Font, Add-Path, Convert-Base64, ConvertFrom-AAPIni, ConvertFrom-Ini, ConvertFrom-IniFiletoObjectCollection, ConvertTo-Ini, ConvertTo-NTAccountOrSID, Copy-File, Disable-TerminalServerInstallMode, Edit-StringInFile, Enable-TerminalServerInstallMode, Exit-Script, Expand-Variable, Get-FileVerb, Get-EnvironmentVariable, Get-FileVersion, Get-FreeDiskSpace, Get-HardwarePlatform, Get-IniValue, Get-InstalledApplication, Get-LoggedOnUser, Get-Path, Get-Parameter, Get-PendingReboot, Get-RegistryKey, Get-ServiceStartMode, Get-WindowTitle, Import-RegFile, Initialize-Script, Install-MSUpdates, Install-MultiplePackages, Install-SCCMSoftwareUpdates, Invoke-FileVerb, Invoke-Encryption, Invoke-RegisterOrUnregisterDLL, Invoke-SCCMTask, New-File, New-Folder, New-LayoutModificationXML, New-MsiTransform, New-Package, New-Shortcut, Remove-EnvironmentVariable, Remove-File, Remove-Folder, Remove-Font, Remove-MSIApplications, Remove-Path, Remove-RegistryKey, Resolve-Error, Send-Keys, Set-ActiveSetup, Set-AutoAdminLogon, Set-EnvironmentVariable, Set-Inheritance, Set-IniValue, Set-InstallPhase, Set-PinnedApplication, Set-RegistryKey, Set-ServiceStartMode, Show-DialogBox, Show-HelpConsole, Start-MSI, Start-NSISWrapper, Start-Program, Start-ServiceAndDependencies, Stop-ServiceAndDependencies, Test-MSUpdates, Test-Package, Test-PackageName, Test-Ping, Test-RegistryKey, Test-ServiceExists, Update-Desktop, Update-FilePermission, Update-FolderPermission, Update-FrameworkInPackages, Update-PrinterPermission, Update-RegistryPermission, Update-SessionEnvironmentVariables, Write-FunctionHeaderOrFooter, Write-Log