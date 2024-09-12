Lint can read from a file:

  $ cat > err.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - Do it
  > EOF
  $ okra lint err.md
  File "err.md", line 3:
  Error: In objective "Everything is great (E1)":
         No time entry found. Each objective must be followed by '- @... (x days)'
  [1]

It can also read from stdin:

  $ okra lint < err.md
  File "<stdin>", line 3:
  Error: In objective "Everything is great (E1)":
         No time entry found. Each objective must be followed by '- @... (x days)'
  [1]

If everything is fine, nothing is printed and it exits with 0:

  $ cat > ok.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a (5 days)
  >   - Do it
  > EOF

  $ okra lint ok.md
  [OK]: ok.md
  $ okra lint < ok.md
  [OK]: <stdin>

When errors are found in several files, they are all printed:

  $ cat > err2.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a
  >   - Do it
  > EOF
  $ okra lint err.md err2.md
  File "err2.md", line 4:
  Error: In objective "Everything is great (E1)":
         Invalid time entry "@a" found.
          Accepted formats are:
          - '@username (X days)' where X must be a multiple of 0.125
          - '@username (X hours)' where X must be a multiple of 1
          Multiple time entries must be comma-separated.
  File "err.md", line 3:
  Error: In objective "Everything is great (E1)":
         No time entry found. Each objective must be followed by '- @... (x days)'
  [1]

A warning is emitted when the generated report contains placeholder text:

  $ cat > err.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a (1 day)
  >   - Work Item 1
  > EOF
  $ okra lint err.md
  File "err.md", line 5:
  Error: Placeholder text detected. Replace with actual activity.
  [1]
