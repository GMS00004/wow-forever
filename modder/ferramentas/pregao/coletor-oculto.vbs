' coletor-oculto.vbs - lancador sem janela do coletor de precos (coletar-foto.mjs).
' Uso: wscript.exe //B //Nologo coletor-oculto.vbs "<node.exe>" "<coletar-foto.mjs>"
' Roda o node com o script, sem janela, esperando terminar. Se o script nao existir, sai em silencio.
Option Explicit

Dim sh, fso, q, node, script, cmd
q = Chr(34)

If WScript.Arguments.Count < 2 Then WScript.Quit 0
node = WScript.Arguments(0)
script = WScript.Arguments(1)

Set fso = CreateObject("Scripting.FileSystemObject")
If Not fso.FileExists(script) Then WScript.Quit 0

Set sh = CreateObject("WScript.Shell")
cmd = q & node & q & " " & q & script & q
sh.Run cmd, 0, True
WScript.Quit 0
