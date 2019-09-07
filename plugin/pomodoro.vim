" Vim plugin for keeping track of uninterrupted time worked
" Last Change:      2019 Sep 07
" Maintainer:       Niko Steinhoff <niko.steinhoff@gmail.com>
" License:          This file is placed in the public domain.

command! PomodoroPing call pomodoro#ping()
command! PomodoroInfo call pomodoro#settings()

augroup pomodoro
    au CursorHold * call pomodoro#ping()
augroup END
