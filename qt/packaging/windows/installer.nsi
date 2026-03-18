; AgentsBoard Windows Installer (NSIS)
!define APPNAME "AgentsBoard"
!define VERSION "0.9.0"

Name "${APPNAME}"
OutFile "AgentsBoard-${VERSION}-setup.exe"
InstallDir "$PROGRAMFILES64\${APPNAME}"

Section "Install"
    SetOutPath $INSTDIR
    File "agentsboard-qt.exe"
    File "AgentsBoardCoreFFI.dll"
    File /r "Qt6*.dll"

    ; Create start menu shortcut
    CreateDirectory "$SMPROGRAMS\${APPNAME}"
    CreateShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\agentsboard-qt.exe"

    ; Create uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\agentsboard-qt.exe"
    Delete "$INSTDIR\AgentsBoardCoreFFI.dll"
    Delete "$INSTDIR\Qt6*.dll"
    Delete "$INSTDIR\uninstall.exe"
    RMDir /r "$SMPROGRAMS\${APPNAME}"
    RMDir "$INSTDIR"
SectionEnd
