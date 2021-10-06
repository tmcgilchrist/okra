Lint can read from a file:

  $ cat > err.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - Do it
  > EOF
  $ okra lint err.md
  Error(s) in file err.md:
  
  In KR "Everything is great":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]

It can also read from stdin:

  $ okra lint < err.md
  Error(s) in input stream:
  
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
  $ okra lint < ok.md
