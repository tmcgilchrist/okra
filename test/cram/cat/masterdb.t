Master DB
---------

When `--okr-db` is passed, metadata is fixed.

  $ cat > okrs.csv << EOF
  > id,title,objective,status,schedule,lead,team,category,project
  > KR1,Actual title,Actual objective,,,,,,Actual project
  > EOF

  $ okra cat --okr-db=okrs.csv << EOF
  > # Wrong project
  > 
  > ## Wrong objective
  > 
  > - Wrong title (KR1)
  >   - @a (1 day)
  >   - Did all the things
  > EOF
  okra: [WARNING] Title for KR "KR1" does not match title in database:
  - "Wrong title"
  - "Actual title"
  okra: [WARNING] Objective for KR "KR1" does not match objective in database:
  - "Wrong objective"
  - "Actual objective"
  okra: [WARNING] Project for KR "KR1" does not match project in database:
  - "Wrong project"
  - "Actual project"
  # Actual project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things
