Test_valid_eng_report

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

Test_invalid_eng_report

Test that errors in include section are detected even if the rest is ignored.

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
  Error(s) in input stream:
  
  In KR "This is a KR (KRID)":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]

Valid team reports

  $ okra lint --team << EOF
  > # OKR updates
  > 
  > - This is not properly formatted.
  > - New KR: Test
  > 
  > # This is a title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  $ okra lint --team << EOF
  > # This is a title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  $ okra lint --team << EOF
  > # This is a title
  > 
  > ## Another title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day), @eng2 (2.5 days), @eng3 (4 days)
  >   - My work
  >   - More work
  > EOF

Test_invalid_team_report
Test that it doesn't ignore errors outside the ignored section

  $ okra lint --team << EOF
  > # OKR updates
  > 
  > - This is not properly formatted.
  > - New KR: Test
  > 
  > # This is a title
  > 
  > - This is a KR (KRID)
  >   - @eng1 (1 day)
  >  - My work
  > EOF
  Error(s) in input stream:
  
  Line 10: Single space used for indentation (' - text'). Remove or replace by 2 or more spaces.
  1 formatting errors found. Parsing aborted.
  [1]

Types of errors

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

Invalid time

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day), eng2 (2 days)
  >   - My work
  > EOF
  Error(s) in input stream:
  
  In KR "@eng1 (1 day), eng2 (2 days)":
    Invalid time entry found. Format is '- @eng1 (x days), @eng2 (x days)'
  [1]
  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day); @eng2 (2 days)
  >   - My work
  > EOF
  Error(s) in input stream:
  
  In KR "@eng1 (1 day); @eng2 (2 days)":
    Invalid time entry found. Format is '- @eng1 (x days), @eng2 (x days)'
  [1]
  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day) @eng2 (2 days)
  >   - My work
  > EOF
  Error(s) in input stream:
  
  In KR "@eng1 (1 day) @eng2 (2 days)":
    Invalid time entry found. Format is '- @eng1 (x days), @eng2 (x days)'
  [1]

Valid time

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (.5 day)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (.5 days)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (0.5 days)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (0.5 day)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (0.1 days), @eng1 (.5 day)
  >   - My work
  > EOF
