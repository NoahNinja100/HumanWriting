#Requires AutoHotkey v2.0

StopTyping := false
Paused := false
ProgressGui := ""
ProgressBar := ""
TypingSpeed := 45
TypoChance := 7
UseProgressBar := true
EstimatedTime := 0
TimeRemaining := 0
StartTime := 0
CallingSound := "johnpork.wav"

; --- Create the Menu Bar ---
MyMenu := MenuBar()

MainMenu := Menu()
MainMenu.Add("Main", ShowMainTab)

KeybindMenu := Menu()
KeybindMenu.Add("View Keybinds", ShowKeybindTab)

SettingsMenu := Menu()
SettingsMenu.Add("Settings", ShowSettingsTab)

MyMenu.Add("&Main", MainMenu)
MyMenu.Add("&Keybinds", KeybindMenu)
MyMenu.Add("&Settings", SettingsMenu)

; --- Create the Main GUI Window ---
MyGui := Gui()
MyGui.MenuBar := MyMenu
MyGui.Title := "Human Writing Replicator"
MyGui.SetFont("s10", "Segoe UI")

; GUI Controls
MainControls := []

txt1 := MyGui.Add("Text", "x20 y20", "Selected File:")
MainControls.Push(txt1)

SelectedFileBox := MyGui.Add("Edit", "x20 y45 w300 r1 ReadOnly", "No file selected.")
MainControls.Push(SelectedFileBox)

BrowseBtn := MyGui.Add("Button", "x330 y43 w80", "Browse...")
BrowseBtn.OnEvent("Click", BrowseFile)
MainControls.Push(BrowseBtn)

WriteBtn := MyGui.Add("Button", "x415 y43 w80", "Write")
WriteBtn.OnEvent("Click", WriteFileWithCtrlJ)
MainControls.Push(WriteBtn)

txt2 := MyGui.Add("Text", "x20 y95", "Text to Write:")
MainControls.Push(txt2)

FileContentsBox := MyGui.Add("Edit", "x20 y120 w390 r10 ReadOnly")
MainControls.Push(FileContentsBox)

TextStats := MyGui.Add(
    "Text",
    "x420 y120 w120 h80",
    "Characters: 0`nWords: 0`nParagraphs: 0"
)
MainControls.Push(TextStats)

KeybindControls := []

KeybindControls.Push(
    MyGui.Add("Text",
        "x20 y20 Hidden",
        "Available Keybinds")
)

KeybindControls.Push(
    MyGui.Add("Text",
        "x20 y60 Hidden",
        "Esc - Stop typing completely`n`n"
      . "P - Pause/Resume typing`n`n")
)

SettingsControls := []

SpeedLabel := MyGui.Add(
    "Text",
    "x20 y20 w250 Hidden",
    "Typing Speed: " . TypingSpeed . " (Lower = Faster)"
)
SettingsControls.Push(SpeedLabel)

SpeedSlider := MyGui.Add(
    "Slider",
    "x20 y45 w250 Range10-100 ToolTip Hidden",
    TypingSpeed
)
SpeedSlider.OnEvent("Change", UpdateSpeed)
SettingsControls.Push(SpeedSlider)


TypoLabel := MyGui.Add(
    "Text",
    "x20 y90 w150 Hidden",
    "Typo Chance: " . TypoChance . "%"
)
SettingsControls.Push(TypoLabel)

TypoSlider := MyGui.Add(
    "Slider",
    "x20 y115 w250 Range0-20 ToolTip Hidden",
    TypoChance
)
TypoSlider.OnEvent("Change", UpdateTypoChance)
SettingsControls.Push(TypoSlider)


ProgressCheck := MyGui.Add(
    "CheckBox",
    "x20 y190 Hidden",
    "Enable Progress Bar"
)
ProgressCheck.Value := UseProgressBar
ProgressCheck.OnEvent("Click", ToggleProgress)
SettingsControls.Push(ProgressCheck)

SplashGui := Gui("+AlwaysOnTop -Caption +Border")
SplashGui.Color := "White"
SplashGui.SetFont("s14 Bold", "Segoe UI")

; BIG image (auto keeps ratio, much larger width)
Logo := SplashGui.Add("Picture", "x20 y20 w300 h-1", "porkwin.png")

; text centered under it
SplashGui.Add("Text", "x20 y+10 w300 Center", "Made By Porkwin")

; let AHK size window to fit content properly
SplashGui.Show("AutoSize Center")

SoundPlay(CallingSound)

SetTimer(ShowMainGui, -2000)

; STOP KEY

Esc::
{
    global StopTyping
    StopTyping := true
}

; PAUSE / RESUME KEY

p::
{
    global Paused, PauseGui

    if (!Paused)
    {
        Paused := true

        PauseGui := Gui("+AlwaysOnTop -MinimizeBox")
        PauseGui.Title := "Paused"
        PauseGui.SetFont("s12", "Segoe UI")
        PauseGui.Add("Text", "w220 Center", "Typing is paused.`n`nPress P to resume.")
        PauseGui.Show("AutoSize Center")
    }
    else
    {
        Paused := false

        if IsSet(PauseGui)
            PauseGui.Destroy()
    }
}

; --- Progress Bar Window ---
ProgressGui := Gui("+AlwaysOnTop -MinimizeBox +ToolWindow")
ProgressGui.Title := "Writing Progress"
ProgressGui.SetFont("s10", "Segoe UI")

ProgressBar := ProgressGui.Add("Progress", "w300 h25", 0)
ProgressText := ProgressGui.Add("Text", "w300 Center", "0%")
TimeText := ProgressGui.Add("Text", "w300 Center", "Time Remaining: Calculating...")

ProgressGui.Hide()

; --- Functions ---

ShowMainGui(*) {
    global SplashGui, MyGui

    SoundPlay("*-1") ; stops currently playing sound

    SplashGui.Destroy()
    MyGui.Show("w520 h300 Center")
}

; Function to browse for a text file
BrowseFile(*) {
    global FilePath, FileContents, SelectedFileBox, FileContentsBox, TextStats

    FilePath := FileSelect(3, , "Select a Text File", "Text Documents (*.txt)")
    if (FilePath = "")
        return

    SelectedFileBox.Value := FilePath
    FileContents := FileRead(FilePath)

    FileContentsBox.Value := FileContents
	characters := StrLen(FileContents)

	words := 0
	if (FileContents != "")
    words := StrSplit(Trim(FileContents), A_Space).Length

	paragraphs := 0
	if (FileContents != "")
		paragraphs := StrSplit(FileContents, "`n").Length

	TextStats.Value :=
		"Characters: " . characters
		. "`nWords: " . words
		. "`nParagraphs: " . paragraphs
}

; Function to write the text to the active window
WriteFileWithCtrlJ(*) {
    global FileContents, StopTyping, Paused, TimeText, EstimatedTime, StartTime
	
	StopTyping := false
	Paused := false

    if (FileContents = "") {
        MsgBox("Please select a file first!", "Error", "IconX")
        return
    }

	CountdownGui := Gui("+AlwaysOnTop -MinimizeBox +ToolWindow")
	CountdownGui.Title := "Starting..."
	CountdownGui.SetFont("s14 Bold", "Segoe UI")

	CountdownText := CountdownGui.Add("Text", "w250 Center", "Starting in 5...")
	CountdownGui.Show("AutoSize Center")

	Loop 5
	{
		CountdownText.Value := "Starting in " . (6 - A_Index) . "..."
		Sleep(1000)
	}

	CountdownGui.Destroy()
	
    SetKeyDelay(350, 350)

    len := StrLen(FileContents)
	i := 1
	
	StartTime := A_TickCount
	
	; Calculate estimated typing time
	EstimatedTime := (len * TypingSpeed) / 1000

	; Add extra time for typos and thinking pauses
	EstimatedTime += (len * (TypoChance / 100)) * 0.8
	EstimatedTime += (len / 25) * 0.4
	
	if (UseProgressBar)
		ProgressGui.Show("AutoSize Center NA")

    while (i <= len && !StopTyping) {
        while (Paused && !StopTyping)
            Sleep(50)
		
		char := SubStr(FileContents, i, 1)

		if (char = "`r")
		{
			i++
			continue
		}

        ; chance to make a typo
        if (Random(1, 100) <= TypoChance) {
            wrongChar := Chr(Random(97, 122)) ; random lowercase letter

            SendText(wrongChar)
            Sleep(Random(80, 180))

            ; "real human correction"
            Send("{Backspace}")
            Sleep(Random(50, 120))

            SendText(char)
        } else {
            SendText(char)
        }

        Sleep(Random(TypingSpeed - 15, TypingSpeed + 15))

        ; occasional thinking pause
        if (Random(1, 100) <= 4) {
            Sleep(Random(200, 600))
        }

        i++

		if (UseProgressBar)
		{
			progress := Round((i / len) * 100)

			ProgressBar.Value := progress
			ProgressText.Value := progress "% Complete"

			remaining := EstimatedTime * (1 - (progress / 100))

			minutes := Floor(remaining / 60)
			seconds := Floor(Mod(remaining, 60))

			TimeText.Value := "Time Remaining: " . minutes . "m " . seconds . "s"
		}
    }
	
	ProgressGui.Hide()

	if (StopTyping)
	{
		MsgBox("Typing stopped!", "Stopped")
	}
	else
	{
		elapsed := (A_TickCount - StartTime) / 1000

		minutes := Floor(elapsed / 60)
		seconds := Floor(Mod(elapsed, 60))

		CompleteGui := Gui("+AlwaysOnTop -MinimizeBox +ToolWindow")
		CompleteGui.Title := "Complete!"
		CompleteGui.SetFont("s12 Bold", "Segoe UI")

		CompleteGui.Add(
			"Text",
			"w250 Center",
			"Writing Complete!`n`nTime Taken: "
			. minutes . "m "
			. seconds . "s"
		)

		CompleteGui.Show("AutoSize Center")

		Sleep(3000)
		CompleteGui.Destroy()
	}
}

; --- Tab Switching Functions ---

ShowMainTab(*)
{
    global MainControls, KeybindControls, SettingsControls

    for ctrl in KeybindControls
        ctrl.Visible := false

    for ctrl in SettingsControls
        ctrl.Visible := false

    for ctrl in MainControls
        ctrl.Visible := true
}

ShowKeybindTab(*)
{
    global MainControls, KeybindControls, SettingsControls

    for ctrl in MainControls
        ctrl.Visible := false

    for ctrl in SettingsControls
        ctrl.Visible := false

    for ctrl in KeybindControls
        ctrl.Visible := true
}

ShowSettingsTab(*)
{
    global MainControls, KeybindControls, SettingsControls

    for ctrl in MainControls
        ctrl.Visible := false

    for ctrl in KeybindControls
        ctrl.Visible := false

    for ctrl in SettingsControls
        ctrl.Visible := true
}

; --- Settings Functions ---

UpdateSpeed(*)
{
    global SpeedSlider, TypingSpeed, SpeedLabel

    TypingSpeed := SpeedSlider.Value
    SpeedLabel.Text := "Typing Speed: " . TypingSpeed . " (Lower = Faster)"
}


UpdateTypoChance(*)
{
    global TypoSlider, TypoChance, TypoLabel

    TypoChance := TypoSlider.Value
    TypoLabel.Text := "Typo Chance: " . TypoChance . "%"
}


ToggleProgress(*)
{
    global ProgressCheck, UseProgressBar

    UseProgressBar := ProgressCheck.Value
}

; Close the app properly
GuiClose(*) {
    ExitApp
}