' Launches one of the hub's PowerShell scripts with no console window at all.
' Usage: wscript.exe run_hidden.vbs <script.ps1> [extra args]
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set args = WScript.Arguments
If args.Count = 0 Then WScript.Quit 1

dir = fso.GetParentFolderName(WScript.ScriptFullName)
script = args(0)
If Not fso.FileExists(script) Then script = dir & "\" & script

cmd = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & script & """"
For i = 1 To args.Count - 1
    cmd = cmd & " " & args(i)
Next

sh.CurrentDirectory = dir
sh.Run cmd, 0, False
