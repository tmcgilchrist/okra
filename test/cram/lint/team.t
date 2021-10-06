Team reports
------------

Examples of valid ones:

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

Errors are not ignored outside the ignored section

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
