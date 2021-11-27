; Mostly from: https://github.com/stroebjo/autohotkey-windows-mac-keyboard
; some parts from: https://gist.github.com/ascendbruce/677c3169259c975259045f905cd889d6
; some own
; to get this to run on startup
; 1. install AutoHotKey https://www.autohotkey.com
; 2. run in command promt with admin rights to create shortcut (check users on win and wsl, and wsl machine name)
;    mklink "C:\Users\npaho\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\maclike.ahk" "\\wsl.localhost\Ubuntu\home\nipsuli\code\important\dotfiles\windows\maclike.ahk"
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; --------------------------------------------------------------
; Nipsulis default mappings
; --------------------------------------------------------------

; No one needs caps lock, not even on non custom keyboards
Capslock::Esc

; I use US layout but need ä and ö from time to time
!a::Send, {asc 0228}
!o::Send, {asc 0246}

; --------------------------------------------------------------
; NOTES
; --------------------------------------------------------------
; ! = ALT
; ^ = CTRL
; + = SHIFT
; # = WIN

; --------------------------------------------------------------
; Mac-like screenshots in Windows (requires Windows 10 Snip & Sketch)
; --------------------------------------------------------------

; Capture entire screen with CMD/WIN + SHIFT + 3
#+3::send #{PrintScreen}

; Capture portion of the screen with CMD/WIN + SHIFT + 4
#+4::#+s

; --------------------------------------------------------------
; OS X system shortcuts
; --------------------------------------------------------------

; Make Ctrl + S work with cmd (windows) key
#s::Send, ^s

; Selecting
#a::Send, ^a

; Copying
#c::Send, ^c

; Pasting
#v::Send, ^v

; Cutting
#x::Send, ^x

; Opening
#o::Send ^o

; Finding
#f::Send ^f

; Undo
#z::Send ^z

; Redo
#y::Send ^y

; New tab
#t::Send ^t

; close tab
#w::Send ^w

; Close windows (cmd + q to Alt + F4)
#q::Send !{F4}

; Remap Windows + Tab to Alt + Tab.
; Lwin & Tab::AltTab

; minimize windows
;# m::WinMinimize,a

; secondary tab change
#+]::Send {Ctrl Down}{Tab Down}{Tab Up}{Ctrl Up}
#+[::Send {Ctrl Down}{Shift Down}{Tab Down}{Tab Up}{Shift Up}{Ctrl Up}
