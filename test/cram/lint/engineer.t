Engineer reports
----------------

This is a valid one:

  $ okra lint --engineer << EOF
  > # Projects
  > 
  > - Project1 (KR1)
  > - Project2 (KR2)
  > 
  > This is not formatted.
  > 
  > # Last week
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day)
  >   - My work
  > 
  > # Activity
  > 
  > More unformatted text.
  > EOF
  [OK]: input stream

Errors in include section are detected even if the rest is ignored.

  $ okra lint --engineer << EOF
  > # Projects
  > 
  > - Project1 (KR1)
  > - Project2 (KR2)
  > 
  > This is not formatted.
  > 
  > # Last week
  > 
  > - This is a KR (KRID)
  >   - (1 day)
  >   - My work
  > 
  > # Activity
  > 
  > More unformatted text.
  > EOF
  [ERROR(S)]: input stream
  
  In KR "This is a KR (KRID)":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]
