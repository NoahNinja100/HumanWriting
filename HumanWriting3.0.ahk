#Requires AutoHotkey v2.0

DllCall("LoadLibrary", "Str", "Msftedit.dll", "Ptr")
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
EvilMode := false
UseDoubleSpace := true
UseCommonLetterSpeed := true
UseWarmup := false

; ==============================
; CLEAN BORDERLESS GUI
; ==============================

MyGui := Gui("-Caption +Border +MinimizeBox")
MyGui.BackColor := "1E1E1E"
MyGui.SetFont("s10 cFFFFFF", "Segoe UI")

; --- Custom Title Bar ---
TitleBar := MyGui.Add("Text", "x0 y0 w580 h42 Background1E1E1E cFFFFFF", "  Human Writing Replicator")
TitleBar.SetFont("s14 Bold cFFFFFF", "Segoe UI")
TitleBar.OnEvent("Click", DragWindow)

MinBtn := MyGui.Add("Button", "x595 y7 w35 h28", "—")
CloseBtn := MyGui.Add("Button", "x635 y7 w35 h28", "X")

MinBtn.OnEvent("Click", (*) => MyGui.Minimize())
CloseBtn.OnEvent("Click", (*) => ExitApp())

; ==============================
; SIDEBAR
; ==============================

Sidebar := MyGui.Add("GroupBox", "x15 y60 w130 h340 cFFFFFF", "")

MainTabBtn := MyGui.Add("Button", "x30 y95 w100 h35", "MAIN")
MainTabBtn.OnEvent("Click", ShowMainTab)

KeybindTabBtn := MyGui.Add("Button", "x30 y145 w100 h35", "KEYBINDS")
KeybindTabBtn.OnEvent("Click", ShowKeybindTab)

SettingsTabBtn := MyGui.Add("Button", "x30 y195 w100 h35", "SETTINGS")
SettingsTabBtn.OnEvent("Click", ShowSettingsTab)

; ==============================
; MAIN TAB
; ==============================

MainControls := []

MainTitle := MyGui.Add("Text", "x175 y60 w350 h25 cFFFFFF", "Human Writing Replicator")
MainTitle.SetFont("s11 Bold cFFFFFF", "Segoe UI")
MainControls.Push(MainTitle)

FileLabel := MyGui.Add("Text", "x175 y100 cFFFFFF", "Selected File")
MainControls.Push(FileLabel)

SelectedFileBox := MyGui.Add("Edit", "x175 y125 w300 h25 ReadOnly", "No file selected.")
MainControls.Push(SelectedFileBox)

BrowseBtn := MyGui.Add("Button", "x485 y123 w80 h30", "Browse")
BrowseBtn.OnEvent("Click", BrowseFile)
MainControls.Push(BrowseBtn)

WriteBtn := MyGui.Add("Button", "x575 y123 w80 h30", "Write")
WriteBtn.OnEvent("Click", WriteFileWithCtrlJ)
MainControls.Push(WriteBtn)

FileContentsBox := MyGui.Add(
    "Edit",
    "x175 y175 w480 h150 ReadOnly VScroll -HScroll Wrap cFFFFFF Background303030"
)
MainControls.Push(FileContentsBox)

TextStats := MyGui.Add("Text", "x175 y340 w250 h70 cFFFFFF", "Characters: 0`nWords: 0`nParagraphs: 0")
MainControls.Push(TextStats)

; ==============================
; KEYBINDS TAB
; ==============================

KeybindControls := []

KeyTitle := MyGui.Add("Text", "x175 y65 w350 h30 Hidden cFFFFFF", "Keyboard Controls")
KeyTitle.SetFont("s12 Bold cFFFFFF", "Segoe UI")
KeybindControls.Push(KeyTitle)

Keys := MyGui.Add("Text", "x175 y115 w400 Hidden cFFFFFF", "ESC  - Stop typing completely`n`nP  - Pause / Resume typing")
KeybindControls.Push(Keys)

; ==============================
; SETTINGS TAB
; ==============================

SettingsControls := []

SpeedLabel := MyGui.Add("Text", "x175 y70 w300 Hidden cFFFFFF", "Typing Speed: " . TypingSpeed . " (Lower = Faster)")
SettingsControls.Push(SpeedLabel)

SpeedSlider := MyGui.Add("Slider", "x175 y100 w300 Range10-100 Hidden", TypingSpeed)
SpeedSlider.OnEvent("Change", UpdateSpeed)
SettingsControls.Push(SpeedSlider)

TypoLabel := MyGui.Add("Text", "x175 y155 w300 Hidden cFFFFFF", "Typo Chance: " . TypoChance . "%")
SettingsControls.Push(TypoLabel)

TypoSlider := MyGui.Add("Slider", "x175 y185 w300 Range0-20 Hidden", TypoChance)
TypoSlider.OnEvent("Change", UpdateTypoChance)
SettingsControls.Push(TypoSlider)

; Start live slider updates
SetTimer(LiveSliderUpdate, 50)

ProgressCheck := MyGui.Add("CheckBox", "x175 y240 Hidden cFFFFFF", "Enable Progress Bar")
ProgressCheck.Value := UseProgressBar
ProgressCheck.OnEvent("Click", ToggleProgress)
SettingsControls.Push(ProgressCheck)

EvilModeCheck := MyGui.Add("CheckBox", "x175 y275 Hidden cFFFFFF", "Enable Evil Mode")
EvilModeCheck.Value := EvilMode
EvilModeCheck.OnEvent("Click", ToggleEvilMode)
SettingsControls.Push(EvilModeCheck)

WarmupCheck := MyGui.Add("CheckBox", "x175 y310 Hidden cFFFFFF", "Enable Warmup Typing")
WarmupCheck.Value := UseWarmup
WarmupCheck.OnEvent("Click", ToggleWarmup)
SettingsControls.Push(WarmupCheck)

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

    SoundPlay("*-1")
    SplashGui.Destroy()

    ShowMainTab()
    MyGui.Show("w680 h420 Center")
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

    len := StrLen(FileContents)
	i := 1
	
	StartTime := A_TickCount
	WarmupActive := true
	
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
		
		; Evil Mode
		if (EvilMode && Random(1, 100) <= 1) {
			Mistakes := [
				"bbc",
				"nigger",
			]

			Mistake := Mistakes[Random(1, Mistakes.Length)]

			SendText(Mistake)
			Sleep(Random(50, 150))

			Loop StrLen(Mistake) {
				Send("{Backspace}")
				Sleep(Random(20, 50))
			}

    Sleep(Random(50, 120))
}

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

			; Occasional double space mistake
			if (UseDoubleSpace && char = " " && Random(1,300) = 1) {
				SendText(" ")
				Sleep(Random(50,100))
			}
		}

        ; Character-based typing speed variation
		Delay := Random(TypingSpeed - 15, TypingSpeed + 15)

		if (char = "." || char = "!" || char = "?") {
			; Pause after sentence endings
			Delay += Random(300, 650)
		}
		else if (char = "," || char = ";" || char = ":") {
			; Small pause for commas and similar punctuation
			Delay += Random(100, 300)
		}
		else if (char = " ") {
			; Slight pause between words
			Delay += Random(20, 80)
		}
		else if (char = "`n") {
			; Bigger pause for new paragraphs
			Delay += Random(400, 900)
		}
		else if (RegExMatch(char, "[A-Z]")) {
			; Slight hesitation before capital letters
			Delay += Random(50, 150)
		}

		; Faster typing on common letters
		if (UseCommonLetterSpeed && char ~= "[etaoinshrdlu]") {
			Delay -= Random(5, 20)
		}

		; Warmup period at the beginning
		if (UseWarmup && WarmupActive) {
			Delay += Random(50, 150)

			if (i > 100)
				WarmupActive := false
		}

		; Random typing rhythm changes
		if (Random(1,100) <= 10) {
			Delay += Random(-30,80)
		}
		
		Sleep(Max(Delay, 10))

        ; occasional thinking pause
        if (Random(1, 100) <= 2) {
            Sleep(Random(50, 150))
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

ShowMainTab(*) {
    global MainControls, KeybindControls, SettingsControls

    for ctrl in MainControls
        ctrl.Visible := true

    for ctrl in KeybindControls
        ctrl.Visible := false

    for ctrl in SettingsControls
        ctrl.Visible := false
}



ShowKeybindTab(*) {
    global MainControls, KeybindControls, SettingsControls

    for ctrl in MainControls
        ctrl.Visible := false

    for ctrl in KeybindControls
        ctrl.Visible := true

    for ctrl in SettingsControls
        ctrl.Visible := false
}



ShowSettingsTab(*) {
    global MainControls, KeybindControls, SettingsControls

    for ctrl in MainControls
        ctrl.Visible := false

    for ctrl in KeybindControls
        ctrl.Visible := false

    for ctrl in SettingsControls
        ctrl.Visible := true
}

; --- Settings Functions ---

UpdateSpeed(*) {
    global SpeedSlider, TypingSpeed, SpeedLabel

    TypingSpeed := SpeedSlider.Value
    SpeedLabel.Text := "Typing Speed: " . TypingSpeed . " (Lower = Faster)"
}

UpdateTypoChance(*) {
    global TypoSlider, TypoChance, TypoLabel

    TypoChance := TypoSlider.Value
    TypoLabel.Text := "Typo Chance: " . TypoChance . "%"
}

ToggleProgress(*) {
    global ProgressCheck, UseProgressBar

    UseProgressBar := ProgressCheck.Value
}

ToggleEvilMode(*) {
    global EvilModeCheck, EvilMode
    EvilMode := EvilModeCheck.Value
}

ToggleWarmup(*) {
    global WarmupCheck, UseWarmup
    UseWarmup := WarmupCheck.Value
}

DragWindow(*) {
    DllCall("ReleaseCapture")
    PostMessage(0xA1, 2,,, "A")
}

LiveSliderUpdate() {
    global SpeedSlider, TypoSlider
    global TypingSpeed, TypoChance
    global SpeedLabel, TypoLabel

    if !IsSet(SpeedSlider) || !IsSet(TypoSlider)
        return

    TypingSpeed := SpeedSlider.Value
    TypoChance := TypoSlider.Value

    SpeedLabel.Text := "Typing Speed: " . TypingSpeed . " (Lower = Faster)"
    TypoLabel.Text := "Typo Chance: " . TypoChance . "%"
}

; Close the app properly

GuiClose(*) {
    ExitApp
}