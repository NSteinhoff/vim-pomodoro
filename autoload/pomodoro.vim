" Vim plugin for keeping track of uninterrupted time worked
" Last Change:      2019 Sep 07
" Maintainer:       Niko Steinhoff <niko.steinhoff@gmail.com>
" License:          This file is placed in the public domain.


let s:sessions = []
let s:session_minutes = 25
let s:break_minutes = 5

function! s:duration_minutes(duration)
    return a:duration[0] / 60
endfunction

function! s:start_session(start_time)
    let session = {}
    let session.id = len(s:sessions) + 1
    let session.start = a:start_time
    let session.last = a:start_time
    let session.duration = reltime(a:start_time, a:start_time)
    let session.notified = -1

    call add(s:sessions, session)
    echomsg "Starting session number ".session.id." of ".s:session_minutes." minutes."
    return session
endfunction

function! s:is_break(session, now)
    let session = s:latest_session(a:now)
    let since_last = s:duration_minutes(reltime(session.last, a:now))
endfunction

function! s:latest_session(now)
    if s:has_sessions()
        return s:sessions[-1]
    else
        return s:start_session(a:now)
endfunction

function! s:has_sessions()
    return len(s:sessions) > 0
endfunction

function! s:latest_or_new(now)
    let session = s:latest_session(a:now)
    let since_last = s:duration_minutes(reltime(session.last, a:now))
    if since_last >= s:break_minutes
        return s:start_session(a:now)
    else
        return session
    endif
endfunction

function! s:notify_break(session)
    let overtime = s:duration_minutes(a:session.duration) - s:session_minutes
    if overtime > a:session.notified
        echomsg "Session over, time to take a break!"
        return overtime
    else
        return a:session.notified
    endif
endfunction

function! pomodoro#ping()
    let now = reltime()
    let session = s:latest_or_new(now)

    let session.last = now
    let session.duration = reltime(session.start, session.last)
    let session.notified = s:notify_break(session)
endfunction

function! pomodoro#settings()
    echo "Pomodoro Settings:"
    echo "\tSession:    ".s:session_minutes." min"
    echo "\tBreak:      ".s:break_minutes." min"
    echo "---"
    let session = s:latest_session(reltime())
    echo "You are ".s:duration_minutes(session.duration)." minutes into session number ".session.id."."
    echo "---"
    if s:has_sessions()
        echo "\nSessions:"
        for session in s:sessions
            let overdue = session.notified > 0 ? " (".session.notified." overdue)" : ""
            echo "\t"session.id.":\t"s:duration_minutes(session.duration)" min".overdue
        endfor
    endif
endfunction

function! pomodoro#sessions()
    return s:sessions
endfunction
