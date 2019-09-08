let s:session_minutes = 25
let s:break_minutes = 5

function! s:duration_minutes(duration)
    return a:duration / 60
endfunction

function! s:duration_seconds(duration)
    return a:duration % 60
endfunction

function! s:start_session(start_time)
    let session = {}
    let session.id = len(s:sessions) + 1
    let session.start = a:start_time
    let session.last = a:start_time
    let session.duration = 0
    let session.notified = 0
    let session.scheduled = s:session_minutes
    let session.break = s:break_minutes

    call add(s:sessions, session)
    echomsg "Starting session number ".session.id." of ".session.scheduled." minutes."
    return session
endfunction

function! s:latest_session(now)
    if s:has_sessions()
        return s:sessions[-1]
    else
        " The first time around, create the sessions variable
        " and start the first session.
        let s:sessions = []
        return s:start_session(a:now)
endfunction

function! s:has_sessions()
    if exists('s:sessions')
        return len(s:sessions) > 0
    else
        return 0
    endif
endfunction

function! s:latest_or_new(now)
    let session = s:latest_session(a:now)
    let since_last = s:duration_minutes(a:now - session.last)
    if since_last >= session.break
        return s:start_session(a:now)
    else
        return session
    endif
endfunction

function! s:notify(session)
    if !a:session.notified
        echomsg "Session over, time to take a break!"
        let a:session.notified = 1
    else
        if localtime() % 3 == 0
            call s:echo_overtime(a:session)
        endif
    endif
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

function! s:total(session)
    return s:duration_minutes(a:session.duration)
endfunction

function! s:elapsed(session)
    let total = s:total(a:session)
    return min([total, a:session.scheduled])
endfunction

function! s:overtime(session)
    let total = s:total(a:session)
    return max([total - a:session.scheduled, 0])
endfunction

function! s:remaining(session)
    let total = s:total(a:session)
    return max([a:session.scheduled - total, 0])
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

function! s:display_sessions()
    if s:has_sessions()
        echo "\n---"
        let session = s:latest_session(localtime())
        let min = s:duration_minutes(session.duration)
        let sec = s:duration_seconds(session.duration)
        echo "You are ".min." minutes ".sec." seconds into session number ".session.id."."
        echo "---"
        echo "\nSessions:"
        for session in s:sessions
            echo s:display_session(session)
        endfor
    endif
endfunction

function! s:enabled()
    return exists('#pomodoro#CursorHold')
endfunction

function! pomodoro#sessions()
    return s:sessions
endfunction

function! s:echo_overtime(session)
    let overtime = s:overtime(a:session)
    if overtime > 0
        echo repeat('!', overtime)
    endif
endfunction

function! pomodoro#ping()
    try
        let now = localtime()
        let session = s:latest_or_new(now)

        let session.last = now
        let session.duration = session.last - session.start
        if s:total(session) >= session.scheduled
            call s:notify(session)
        endif
    catch
        let msg = "Error during 'ping' (".v:exception."). Disabling pomodoro!"
        echo pomodoro#disable(msg)
    endtry
endfunction

function! pomodoro#settings()
    echo "Pomodoro Settings:"
    echo "\tSession:    ".s:session_minutes." min"
    echo "\tBreak:      ".s:break_minutes." min"
    if s:enabled()
        echo "\t[enabled]"
    else
        echo "\t[disabled]"
    endif
    call s:display_sessions()
endfunction

function! pomodoro#disable(...)
    aug pomodoro
        au!
    aug END
    return a:0 > 0 ? a:1 : "Pomodoro disabled"
endfunction

function! pomodoro#enable(...)
    aug pomodoro
        au!
        au CursorHold * call pomodoro#ping()
    aug END
    return a:0 > 0 ? a:1 : "Pomodoro enabled"
endfunction

function! pomodoro#toggle()
    if s:enabled()
        echo pomodoro#disable()
    else
        echo pomodoro#enable()
    endif
endfunction
