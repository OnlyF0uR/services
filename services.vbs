Set shell = CreateObject("Shell.Application")
script = WScript.ScriptFullName
scriptPath = Left(script, InStrRev(script, "\")) & "services.ps1"
shell.ShellExecute "powershell.exe", "-NoExit -ExecutionPolicy Bypass -File """ & scriptPath & """", "", "runas", 1
