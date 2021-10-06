Test_valid_eng_report

  $ okra lint --engineer eng1.acc

Test_invalid_eng_report

Test that errors in include section are detected even if the rest is ignored.

  $ okra lint --engineer eng1.rej
  Error(s) in file eng1.rej:
  
  In KR "This is a KR (KRID)":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]

Valid team reports

  $ okra lint --team team1.acc
  $ okra lint --team team2.acc
  $ okra lint --team team3.acc

Test_invalid_team_report
Test that it doesn't ignore errors outside the ignored section

  $ okra lint --team team1.rej
  Error(s) in file team1.rej:
  
  Line 10: Single space used for indentation (' - text'). Remove or replace by 2 or more spaces.
  1 formatting errors found. Parsing aborted.
  [1]

Types of errors

No KR ID found:

  $ okra lint no-kr1.rej
  Error(s) in file no-kr1.rej:
  
  In KR "This is a KR":
    No KR ID found. KRs should be in the format "This is a KR (PLAT123)", where PLAT123 is the KR ID. For KRs that don't have an ID yet, use "New KR".
  [1]
  $ okra lint no-title1.rej
  Error(s) in file no-title1.rej:
  
  [1]
  $ okra lint no-work1.rej
  Error(s) in file no-work1.rej:
  
  In KR "This is a KR (KRID)":
    No work items found. This may indicate an unreported parsing error. Remove the KR if it is without work.
  [1]
  $ okra lint no-time1.rej
  Error(s) in file no-time1.rej:
  
  In KR "This is a KR":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]
  $ okra lint multitime1.rej
  Error(s) in file multitime1.rej:
  
  In KR "This is a KR":
    Multiple time entries found. Only one time entry should follow immediately after the KR.
  [1]

Format errors

  $ okra lint format1.rej
  Error(s) in file format1.rej:
  
  Line 5: + used as bullet point, this can confuse the parser. Only use - as bullet marker.
  1 formatting errors found. Parsing aborted.
  [1]
  $ okra lint format2.rej
  Error(s) in file format2.rej:
  
  Line 1: Space found before title marker #. Start titles in first column.
  1 formatting errors found. Parsing aborted.
  [1]
  $ okra lint format3.rej
  Error(s) in file format3.rej:
  
  Line 3: Single space used for indentation (' - text'). Remove or replace by 2 or more spaces.
  1 formatting errors found. Parsing aborted.
  [1]

Invalid time

  $ okra lint invalid-time1.rej
  Error(s) in file invalid-time1.rej:
  
  In KR "@eng1 (1 day), eng2 (2 days)":
    Invalid time entry found. Format is '- @eng1 (x days), @eng2 (x days)'
  [1]
  $ okra lint invalid-time2.rej
  Error(s) in file invalid-time2.rej:
  
  In KR "@eng1 (1 day); @eng2 (2 days)":
    Invalid time entry found. Format is '- @eng1 (x days), @eng2 (x days)'
  [1]
  $ okra lint invalid-time3.rej
  Error(s) in file invalid-time3.rej:
  
  In KR "@eng1 (1 day) @eng2 (2 days)":
    Invalid time entry found. Format is '- @eng1 (x days), @eng2 (x days)'
  [1]

Valid time

  $ okra lint valid-time1.acc
