#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ColorButton.ahk

configFile := A_ScriptDir "\MAC.ini"
OnExit SaveConfigOnExit
targetWinDefault := "Wabbajack.exe"
scanDelay := 700
postClickDelay := 1500
afterClickMouseX := 20
afterClickMouseY := 20
scanStartTick := 0
elapsedText := ""

running := false
clickCount := 0
buttonImages := []
toggleHotkey := "F8"
scanTimerFn := ScanForButton

SetTitleMatchMode 2
CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

mainGui := Gui("+Resize", "Modlist Automated Clicker")
mainGui.SetFont("s10", "Segoe UI")
mainGui.BackColor := "222531"
mainGui.SetFont("s10 cFFFFFF", "Segoe UI")

; LEFT COLUMN
mainGui.AddText("xm ym", "Target executable:")
targetEdit := mainGui.AddEdit("xm y+8 w200 Background59555b cFFFFFF", targetWinDefault)
testTargetBtn := mainGui.AddButton("x+10 yp-2 w50 h28 Background59555b", "Test")

mainGui.AddText("xm y+10", "Toggle hotkey:")
hotkeyEdit := mainGui.AddEdit("xm y+5 w80 Background59555b cFFFFFF", toggleHotkey)
applyHotkeyBtn := mainGui.AddButton("x+10 yp-2 w110 h28", "Change hotkey")

mainGui.AddText("xm y+20", "Search interval (ms):")
intervalEdit := mainGui.AddEdit("x+10 yp-3 w80 Number Background59555b cFFFFFF", "300")

notificationsChk := mainGui.AddCheckBox("xm y+10 Checked ", "Enable notifications")

toggleBtn := mainGui.AddButton("xm y+15 w250 h32", "Start")
exitBtn := mainGui.AddButton("xm y+5 w120 h32", "Exit")
infoBtn := mainGui.AddButton("x+10 yp w120 h32", "Info")

mainGui.AddText("xm y280", "Elapsed:")
elapsedLabel := mainGui.AddText("x+5 yp w230", "00:00:00")
statusText := mainGui.AddText("xm y+10 w220", "Stopped")
mainGui.AddText("xm y+10", "Clicks:")
clickText := mainGui.AddText("x+5 yp w40", "0")

; RIGHT COLUMN
mainGui.AddText("x320 ym", "Selected PNG:")
selectPngBtn := mainGui.AddButton("x320 y+5 w130 h30", "Add PNG file(s)")
removeBtn := mainGui.AddButton("x+10 yp w140 h30", "Remove selected")
mainGui.AddText("x+30 yp+5", "Variation:")
variationEdit := mainGui.AddEdit("x+10 yp-3 w50 Number Background59555b cFFFFFF", "40")

lv := mainGui.AddListView("x320 y+16 w504 r12 +Grid -Multi", ["Name", "Path", "Variation"])
lv.ModifyCol(1, 140) ; Name
lv.ModifyCol(2, 280) ; Path
lv.ModifyCol(3, 80)  ; Variation
lv.Opt("+Background59555b")

moveUpBtn := mainGui.AddButton("x+10 yp w50 h32", "Up")
moveDownBtn := mainGui.AddButton("xp y+10 w50 h32", "Down")

; CALL FUNCTIONS
selectPngBtn.OnEvent("Click", (*) => SelectAndAddPng())
removeBtn.OnEvent("Click", (*) => RemoveSelected())
toggleBtn.OnEvent("Click", (*) => ToggleRun())
applyHotkeyBtn.OnEvent("Click", (*) => ApplyHotkeyFromGui())
exitBtn.OnEvent("Click", (*) => ExitScript())
infoBtn.OnEvent("Click", (*) => ShowInfo())
mainGui.OnEvent("Close", (*) => ExitApp())
mainGui.OnEvent("Close", MainGui_Close)
mainGui.OnEvent("Escape", MainGui_Close)
testTargetBtn.OnEvent("Click", (*) => TestTargetWindow())
moveUpBtn.OnEvent("Click", (*) => MoveSelectedPng(-1))
moveDownBtn.OnEvent("Click", (*) => MoveSelectedPng(1))

; SETTING COLORS (THANK YOU NIKOLA!)
selectPngBtn.SetColor("67449e", "fff5cc")
removeBtn.SetColor("67449e", "fff5cc")
toggleBtn.SetColor("67449e", "fff5cc")
applyHotkeyBtn.SetColor("67449e", "fff5cc")
exitBtn.SetColor("67449e", "fff5cc")
infoBtn.SetColor("67449e", "fff5cc")
testTargetBtn.SetColor("67449e", "fff5cc")
moveUpBtn.SetColor("67449e", "fff5cc")
moveDownBtn.SetColor("67449e", "fff5cc")

ApplyToggleHotkey(toggleHotkey)
UpdateStatus()
LoadConfig()
mainGui.Show("w900 h370")
ShowTipGui("Helper ready`nToggle hotkey: " toggleHotkey, 1500)

Esc::ExitScript()

SelectAndAddPng() {
    global lv, buttonImages, variationEdit

    selectedFiles := FileSelect("M3", , "Choose PNG image(s)", "PNG Images (*.png)")
    if (selectedFiles.Length = 0)
        return

    variation := IntegerOrDefault(variationEdit.Text, 40)
    variation := Clamp(variation, 0, 255)

    addedCount := 0

    for selectedFile in selectedFiles {
        if !FileExist(selectedFile)
            continue

        SplitPath selectedFile, &fileName

        buttonImages.Push({
            name: fileName,
            file: selectedFile,
            variation: variation
        })

        lv.Add("", fileName, selectedFile, variation)
        addedCount += 1
    }

    if (addedCount > 0) {
        UpdateStatus()
        ShowTipGui("Added " addedCount " PNG file(s)`nVariation: " variation, 1400)
    }
}

RemoveSelected(*) {
    global lv, buttonImages

    row := lv.GetNext(0)
    if !row {
        ShowTipGui("No row selected", 1000)
        return
    }

    ; Safe because only single-select is enabled.
    buttonImages.RemoveAt(row)
    lv.Delete(row)

    UpdateStatus()
    ShowTipGui("Selected row removed", 1000)
}

ToggleRun(*) {
    global running, buttonImages, toggleBtn, scanTimerFn
    global scanStartTick

    if running {
        running := false
        SetTimer(scanTimerFn, 0)
        SetTimer(UpdateElapsedTimer, 0)
        toggleBtn.Text := "Start"
        UpdateStatus("Stopped")
        ShowTipGui("Scanning stopped", 1000)
		SaveConfig()
        return
    }
	else { 
	SaveConfig() 
	}

    if buttonImages.Length = 0 {
		MsgBox "No valid PNG files found in the list.", "Cannot start", "Icon!"
		return
    }

    running := true
    scanStartTick := A_TickCount
    SetTimer(scanTimerFn, scanDelay)
    SetTimer(UpdateElapsedTimer, 1000)
    toggleBtn.Text := "Stop"
    UpdateStatus("Running")
    ShowTipGui("Scanning started", 1000)
}

ApplyHotkeyFromGui(*) {
    global hotkeyEdit
    newHotkey := Trim(hotkeyEdit.Text)

    if (newHotkey = "") {
        ShowTipGui("Hotkey cannot be blank", 1200)
        return
    }

    if ApplyToggleHotkey(newHotkey) {
        ShowTipGui("Toggle hotkey set to: " newHotkey, 1300)
    } else {
        ShowTipGui("Failed to set hotkey: " newHotkey, 1400)
    }
}

ApplyToggleHotkey(newHotkey) {
    global toggleHotkey

    try {
        if (toggleHotkey != "")
            Hotkey(toggleHotkey, "Off")
    }

    try {
        Hotkey(newHotkey, ToggleRun, "On")
        toggleHotkey := newHotkey
        return true
    } catch {
        return false
    }
}

ScanForButton() {
    global running, targetEdit, buttonImages, clickCount, clickText, statusText
    global postClickDelay, afterClickMouseX, afterClickMouseY, scanDelay, scanTimerFn
	scanInterval := Integer(intervalEdit.Value)
	
    if !running
        return

	exeName := Trim(targetEdit.Text)
	if (exeName = "") {
		UpdateStatus("Target executable is blank")
		return
	}
	targetWinLocal := "ahk_exe " exeName
	
	if !WinExist(targetWinLocal) {
		running := false
		SetTimer(scanTimerFn, 1000)
		toggleBtn.Text := "Start"
		UpdateStatus("Error: target window not found")
		ShowTipGui("Target window not found.", 1500)
		return
	}
	
	if !WinActive(targetWinLocal) {
		WinActivate(targetWinLocal)
		return
	}
	
    left := 0
    top := 0
    right := 1400
    bottom := 1100

    for img in buttonImages {
        if !FileExist(img.file)
            continue

        if ImageSearch(&foundX, &foundY, left, top, right, bottom, "*" img.variation " " img.file) {
            Click foundX + 20, foundY + 10
            clickCount += 1
            clickText.Text := clickCount

            if (scanInterval < 50){
				scanInterval := 50
				Sleep scanInterval
            }
			MouseMove afterClickMouseX, afterClickMouseY, 0

            UpdateStatus("Matched: " img.name)
            ShowTipGui("Clicked: " img.name "`nCount: " clickCount, 1300)

            SetTimer(scanTimerFn, 0)
            Sleep postClickDelay
            if running
                SetTimer(scanTimerFn, scanDelay)
            return
        }
    }

    UpdateStatus("Running - no match")
}

UpdateStatus(customText := "") {
    global statusText, clickText, running, buttonImages, clickCount, toggleHotkey

    status := customText
    if (status = "")
        status := running ? "Running" : "Stopped"

    statusText.Text := status " | Images: " buttonImages.Length ""
    clickText.Text := clickCount
}

IntegerOrDefault(value, fallback) {
    try {
        return Integer(Trim(value))
    } catch {
        return fallback
    }
}

Clamp(value, min, max) {
    if (value < min)
        return min
    if (value > max)
        return max
    return value
}

ShowTipGui(text, duration := 1200) {
    global notificationsChk
    static tipGui := 0

    if IsObject(notificationsChk) && !notificationsChk.Value
        return

    try {
        if IsObject(tipGui)
            tipGui.Destroy()
    }

    tipGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    tipGui.BackColor := "1E1E1E"
    tipGui.MarginX := 16
    tipGui.MarginY := 12
    tipGui.SetFont("s18 cFFFFFF", "Segoe UI")
    tipGui.AddText("w460", text)
    tipGui.Show("NoActivate x20 y20 AutoSize")

    SetTimer(HideTip, -duration)

    HideTip() {
        try tipGui.Destroy()
    }
}

UpdateElapsedTimer() {
    global running, scanStartTick, elapsedLabel

    if !running || !scanStartTick
        return

    elapsedMs := A_TickCount - scanStartTick
    elapsedLabel.Text := FormatElapsed(elapsedMs)
}

FormatElapsed(ms) {
    totalSeconds := Floor(ms / 1000)
    hours := Floor(totalSeconds / 3600)
    minutes := Floor(Mod(totalSeconds, 3600) / 60)
    seconds := Mod(totalSeconds, 60)
    return Format("{:02}:{:02}:{:02}", hours, minutes, seconds)
}

TestTargetWindow() {
    global targetEdit

    exeName := Trim(targetEdit.Text)
    if (exeName = "") {
        MsgBox "Target executable is blank.", "Target test", "Icon!"
        return
    }

    targetWin := "ahk_exe " exeName

    if !WinExist(targetWin) {
        MsgBox "Target window not found:`n" targetWin, "Target test", "Icon!"
        return
    }

    if !WinActive(targetWin) {
        MsgBox "Target window exists but is not active:`n" targetWin, "Target test", "Iconi"
        return
    }

    MsgBox "Target window exists and is active:`n" targetWin, "Target test", "Iconi"
}

MoveSelectedPng(direction) {
    global lv, buttonImages

    row := lv.GetNext()
    if !row
        return

    newRow := row + direction
    if (newRow < 1 || newRow > buttonImages.Length)
        return

    temp := buttonImages[row]
    buttonImages[row] := buttonImages[newRow]
    buttonImages[newRow] := temp

    RefreshPngListView()

    lv.Modify(newRow, "Select Focus")
}

RefreshPngListView() {
    global lv, buttonImages

    lv.Delete()

    for item in buttonImages
        lv.Add("", item.name, item.file, item.variation)
}

LoadConfig() {
    global configFile
    global targetEdit, hotkeyEdit, notificationsChk, variationEdit, intervalEdit
    global buttonImages, lv

    targetEdit.Value := IniRead(configFile, "Settings", "TargetExe", "")
    hotkeyEdit.Value := IniRead(configFile, "Settings", "ToggleHotkey", "F8")
    notificationsChk.Value := IniRead(configFile, "Settings", "Notifications", 1)
    variationEdit.Value := IniRead(configFile, "Settings", "DefaultVariation", 40)
    intervalEdit.Value := IniRead(configFile, "Settings", "SearchInterval", 300)

    buttonImages := []
    count := IniRead(configFile, "Images", "Count", 0)

    Loop count {
        line := IniRead(configFile, "Images", "Image" A_Index, "")
        if (line = "")
            continue

        parts := StrSplit(line, "|")
        if (parts.Length >= 3) {
            buttonImages.Push({
                name: parts[1],
                file: parts[2],
                variation: Integer(parts[3])
            })
        }
    }

    RefreshPngListView()
}

SaveConfig() {
    global configFile
    global targetEdit, hotkeyEdit, notificationsChk, variationEdit, intervalEdit
    global buttonImages

    IniWrite(targetEdit.Value, configFile, "Settings", "TargetExe")
    IniWrite(hotkeyEdit.Value, configFile, "Settings", "ToggleHotkey")
    IniWrite(notificationsChk.Value, configFile, "Settings", "Notifications")
    IniWrite(variationEdit.Value, configFile, "Settings", "DefaultVariation")
    IniWrite(intervalEdit.Value, configFile, "Settings", "SearchInterval")

    try IniDelete(configFile, "Images")

    IniWrite(buttonImages.Length, configFile, "Images", "Count")

    Loop buttonImages.Length {
        item := buttonImages[A_Index]
        IniWrite(item.name "|" item.file "|" item.variation, configFile, "Images", "Image" A_Index)
    }
}

SaveConfigOnExit(ExitReason, ExitCode) {
    try SaveConfig()
}

MainGui_Close(*) {
    SaveConfig()
    ExitApp
}


ShowInfo() {
    msg :=
    (
    "Modlist Automated Clicker`n`n"
    
    "How to use:`n"
    "1. Capture screenshots of button(s) that the program will be looking for.`n"
    "2. Click 'Add PNG file(s)' and choose screenshots you'd like to use.`n"
    "3. Set the variation value or leave it as is.`n"
    "4. Press Start or use the toggle hotkey to begin scanning.`n"
	"3. If buttons are not detected, add/modify the PNG(s) or change variation value.`n`n"

    "Notes:`n"
    "- Images are checked from top to bottom in the list.`n"
	"- Try not to resize Wabbajack, otherwise it might have trouble detecting buttons.`n"
    "- Variation controls how much image color difference is tolerated.`n"
    "- The mouse is moved away after each click to avoid hover color changes.`n"
    "- Esc exits the script at any time.`n`n"
	
	"ver 1.0, Questor"
    )

    MsgBox msg, "About Modlist Automated Clicker", "Iconi"
}

ExitScript() {
    global clickCount
    ShowTipGui("Exiting...`nTotal clicks: " clickCount, 3000)
    Sleep 1000
    ExitApp
}