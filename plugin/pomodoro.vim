" Vim plugin for keeping track of uninterrupted time worked
" Last Change:      2019 Sep 07
" Maintainer:       Niko Steinhoff <niko.steinhoff@gmail.com>
" License:          This file is placed in the public domain.

command! PomodoroToggle call pomodoro#toggle()
command! PomodoroStatus call pomodoro#settings()

call pomodoro#enable()
