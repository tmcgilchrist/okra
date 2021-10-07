Types of errors
---------------

No KR ID found:

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  Error(s) in input stream:
  
  In KR "This is a KR":
    No KR ID found. KRs should be in the format "This is a KR (PLAT123)", where PLAT123 is the KR ID. For KRs that don't have an ID yet, use "New KR".
  [1]

  $ okra lint << EOF
  > - This is a KR (KR123)
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  Error(s) in input stream:
  
  [1]

No work items found:

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KRID)
  >   - @eng1 (1 day)
  > EOF
  Error(s) in input stream:
  
  In KR "This is a KR (KRID)":
    No work items found. This may indicate an unreported parsing error. Remove the KR if it is without work.
  [1]

No time entry found:

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR12)
  >   - My work
  >   - @eng1 (1 day)
  > EOF
  Error(s) in input stream:
  
  In KR "This is a KR":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]

Multiple time entries:

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR12)
  >   - @eng1 (1 day)
  >   - My work
  >   - @eng2 (2 days)
  >   - More work
  > EOF
  Error(s) in input stream:
  
  In KR "This is a KR":
    Multiple time entries found. Only one time entry should follow immediately after the KR.
  [1]

Format errors

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KRID)
  >   - @eng1 (1 day)
  >   + My work
  > EOF
  Error(s) in input stream:
  
  Line 5: + used as bullet point, this can confuse the parser. Only use - as bullet marker.
  1 formatting errors found. Parsing aborted.
  [1]
  $ okra lint << EOF
  >  # Title
  > 
  > - This is a KR (KRID)
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  Error(s) in input stream:
  
  Line 1: Space found before title marker #. Start titles in first column.
  1 formatting errors found. Parsing aborted.
  [1]
  $ okra lint << EOF
  > # Title
  > 
  >  - This is a KR (KRID)
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  Error(s) in input stream:
  
  Line 3: Single space used for indentation (' - text'). Remove or replace by 2 or more spaces.
  1 formatting errors found. Parsing aborted.
  [1]
