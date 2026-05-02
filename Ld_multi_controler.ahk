#NoEnv
SetBatchLines, -1
SetKeyDelay, -1
SetControlDelay, -1
#SingleInstance, Force

if not A_IsAdmin
{
   Run *RunAs "%A_ScriptFullPath%"
   ExitApp
}

Global LD_List := []
Global KeyStates := {}
Global IsSyncing := 0

Gui, Add, Text, x10 y15 w280 vStatusText, 상태: 대기 중 (앱플레이어 찾기를 눌러주세요)
Gui, Add, Button, x10 y40 w135 h35 gFindLD, 1. 앱플레이어 찾기
Gui, Add, Button, x155 y40 w135 h35 gToggleSync vSyncBtn Disabled, 2. 동기화 시작 (F3)
Gui, Show, , LD 멀티 컨트롤러
return

FindLD:
    LD_List := []
    WinGet, idList, List, ahk_class LDPlayerMainFrame
    
    Loop, % idList
    {
        this_id := idList%A_Index%
        LD_List.Push(this_id)
    }
    
    if (LD_List.Length() < 2) {
        MsgBox, 48, 알림, % "실행 중인 LD플레이어가 2개 이상 필요합니다.`n(현재 " LD_List.Length() "개 발견됨)"
        GuiControl, Disable, SyncBtn
        GuiControl, , StatusText, % "상태: 앱플레이어 부족 (" LD_List.Length() "개 발견됨)"
    } else {
        MsgBox, 64, 알림, % "총 " LD_List.Length() "개의 LD플레이어를 찾았습니다!`n(모든 LD플레이어 창 크기를 동일하게 맞춰주세요.)"
        GuiControl, Enable, SyncBtn
        GuiControl, , StatusText, % "상태: 준비 완료 (" LD_List.Length() "개 연결됨)"
    }
return

F3::
ToggleSync:
    if (LD_List.Length() < 2)
        return

    IsSyncing := !IsSyncing
    if (IsSyncing) {
        GuiControl, , SyncBtn, 2. 동기화 정지 (F3)
        GuiControl, , StatusText, 상태: 동기화 동작 중... (키 + 마우스)
        RegisterSyncKeys("On")
    } else {
        GuiControl, , SyncBtn, 2. 동기화 시작 (F3)
        GuiControl, , StatusText, 상태: 동기화 정지됨
        RegisterSyncKeys("Off")
    }
return

RegisterSyncKeys(State) {
    KeysToSync := [ "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"
                             , "0","1","2","3","4","5","6","7","8","9"
                             , "-", "=", "[", "]", "\", ";", "'", ",", ".", "/", "``"
                             , "Space", "Enter", "Backspace"
                             , "Up", "Down", "Left", "Right" ]

    for index, key in KeysToSync {
        Hotkey, ~*%key%, HandleKeyDown, %State% UseErrorLevel
        Hotkey, ~*%key% Up, HandleKeyUp, %State% UseErrorLevel
    }
    
    Hotkey, ~*LButton, HandleMouseDown, %State% UseErrorLevel
    Hotkey, ~*LButton Up, HandleMouseUp, %State% UseErrorLevel

}

HandleMouseDown:
    Critical
    if (!IsSyncing)
        return
    CoordMode, Mouse, Window
    MouseGetPos, mX, mY, ActiveHwnd
    
    if (!IsLDWindow(ActiveHwnd))
        return

    if (KeyStates["LButton"])
        return
    KeyStates["LButton"] := 1

    for index, target_id in LD_List {
        if (target_id != ActiveHwnd) {
            SendMouseToLD(target_id, mX, mY, "Down")
        }
    }
return

HandleMouseUp:
    Critical
    if (!IsSyncing)
        return
        
    CoordMode, Mouse, Window
    MouseGetPos, mX, mY, ActiveHwnd
    
    if (!IsLDWindow(ActiveHwnd))
        return

    KeyStates["LButton"] := 0

    for index, target_id in LD_List {
        if (target_id != ActiveHwnd) {
            SendMouseToLD(target_id, mX, mY, "Up")
        }
    }
return

SendMouseToLD(target_id, mx, my, Status) {
    lparam := mx | ((my - 32) << 16)
    if (Status = "Down")
        PostMessage, 0x201, 1, % lparam, TheRender, % "ahk_id " target_id
    else if (Status = "Up")
        PostMessage, 0x202, 0, % lparam, TheRender, % "ahk_id " target_id
}

HandleKeyDown:
    Critical
    if (!IsSyncing)
        return
    
    ActiveHwnd := WinActive("A")
    if (!IsLDWindow(ActiveHwnd))
        return

    KeyName := StrReplace(StrReplace(A_ThisHotkey, "~*"), " Up")
    if (KeyStates[KeyName])
        return
    KeyStates[KeyName] := 1
    
    SyncKeyToBackgroundLD(ActiveHwnd, KeyName, "Down")
return

HandleKeyUp:
    Critical
    if (!IsSyncing)
        return
        
    ActiveHwnd := WinActive("A")
    if (!IsLDWindow(ActiveHwnd))
        return
        
    KeyName := StrReplace(StrReplace(A_ThisHotkey, "~*"), " Up")
    KeyStates[KeyName] := 0
    
    SyncKeyToBackgroundLD(ActiveHwnd, KeyName, "Up")
return

SyncKeyToBackgroundLD(ActiveHwnd, KeyName, Status) {
    global LD_List
    for index, target_id in LD_List {
        if (target_id != ActiveHwnd) {
            SendKeyToLD(target_id, KeyName, Status)
        }
    }
}

SendKeyToLD(target_id, Key, Status) {
    KeyName := GetKeyName(Key)
    w := GetKeyVK(KeyName)
    SC := GetKeySC(KeyName)
    
    if (Status = "Down")
        PostMessage, 0x100, w, 1|SC<<16|0<<30|0<<31, TheRender, % "ahk_id " target_id
    else if (Status = "Up")
        PostMessage, 0x101, w, 1|SC<<16|1<<30|1<<31, TheRender, % "ahk_id " target_id
}

IsLDWindow(ActiveHwnd) {
    global LD_List
    for i, hwnd in LD_List {
        if (hwnd == ActiveHwnd)
            return True
    }
    return False
}

GuiClose:
ExitApp
