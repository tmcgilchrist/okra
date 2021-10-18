Lint can read from a file:

  $ cat > err.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - Do it
  > EOF
  $ okra lint err.md
  [ERROR(S)]: file err.md
  
  In KR "Everything is great":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]

It can also read from stdin:

  $ okra lint < err.md
  [ERROR(S)]: input stream
  
  In KR "Everything is great":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]

If everything is fine, nothing is printed and it exits with 0:

  $ cat > ok.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a (1 day)
  >   - Do it
  > EOF

  $ okra lint ok.md
  [OK]: file ok.md
  $ okra lint < ok.md
  [OK]: input stream

When errors are found in several files, they are all printed:

  $ cat > err2.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a
  >   - Do it
  > EOF
  $ okra lint err.md err2.md
  [ERROR(S)]: file err.md
  
  In KR "Everything is great":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [ERROR(S)]: file err2.md
  
  In KR "@a":
    Invalid time entry found. Format is '- @eng1 (x days), @eng2 (x days)'
  [1]
