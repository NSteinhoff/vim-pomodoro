" Vim plugin for keeping track of uninterrupted time worked
" Last Change:      2019 Sep 07
" Maintainer:       Niko Steinhoff <niko.steinhoff@gmail.com>
" License:          This file is placed in the public domain.


let s:sessions = []
let s:session_minutes = 25
let s:break_minutes = 5

function! s:duration_minutes(duration)
    return a:duration / 60
endfunction

function! s:duration_seconds(duration)
    return a:duration % 60
endfunction

function! s:duration_time(duration)
    let min = s:duration_minutes(a:duration)
    let sec = s:duration_seconds(a:duration)
    return [min, sec]
endfunction

function! s:start_session(start_time)
    let session = {}
    let session.id = len(s:sessions) + 1
    let session.start = a:start_time
    let session.last = a:start_time
    let session.duration = 0
    let session.notified = -1

    call add(s:sessions, session)
    echomsg "Starting session number ".session.id." of ".s:session_minutes." minutes."
    return session
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
    let since_last = s:duration_minutes(a:now - session.last)
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
    let now = localtime()
    let session = s:latest_or_new(now)

    let session.last = now
    let session.duration = session.last - session.start
    let session.notified = s:notify_break(session)
endfunction

function! s:rjust(len, s, fill)
    let strlen = strdisplaywidth(a:s)
    if strlen > a:len
        return a:s
    else
        return repeat(a:fill, a:len - strlen).a:s
    endif
endfunction

function! s:ljust(len, s, fill)
    let strlen = strdisplaywidth(a:s)
    if strlen > a:len
        return a:s
    else
        return a:s.repeat(a:fill, a:len - strlen)
    endif
endfunction

function! s:elapsed(session)
    let total = s:duration_minutes(a:session.duration)
    return min([total, s:session_minutes])
endfunction

function! s:overtime(session)
    let total = s:duration_minutes(a:session.duration)
    return max([total - s:session_minutes, 0])
endfunction

function! s:remaining(session)
    let total = s:duration_minutes(a:session.duration)
    return max([s:session_minutes - total, 0])
endfunction

function! s:progress_bar(session)
    return repeat('=', s:elapsed(a:session)).repeat('.', s:remaining(a:session)).repeat('!', s:overtime(a:session))
endfunction

function! s:display_duration(session)
    let elapsed = s:elapsed(a:session)
    let overtime = s:overtime(a:session)
    let overtimestr = overtime ? "+".overtime : ""
    return elapsed.overtimestr." min"
endfunction

function! s:display_interval(session)
    let start = strftime("%T", a:session.start)
    let end = strftime("%T", a:session.last)
    return '['.start.' -> '.end.']'
endfunction

function! s:display_session(session)
    let id = s:rjust(5, a:session.id, " ")
    let duration =  s:ljust(12, s:display_duration(a:session), " ")
    let interval = s:display_interval(a:session)
    let bar = s:progress_bar(a:session)

    return id.":\t".duration."\t".interval."\t".bar
endfunction

function! pomodoro#settings()
    echo "Pomodoro Settings:"
    echo "\tSession:    ".s:session_minutes." min"
    echo "\tBreak:      ".s:break_minutes." min"
    if s:has_sessions()
        echo "---"
        let session = s:latest_session(localtime())
        let [min, sec] = s:duration_time(session.duration)
        echo "You are ".min." minutes ".sec." seconds into session number ".session.id."."
        echo "---"
        echo "\nSessions:"
        for session in s:sessions
            echo s:display_session(session)
        endfor
    endif
endfunction

function! pomodoro#sessions()
    return s:sessions
endfunction
