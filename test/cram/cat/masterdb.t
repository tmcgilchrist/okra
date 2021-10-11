Master DB
---------

When `--okr-db` is passed, metadata is fixed.

  $ cat > okrs.csv << EOF
  > id,title,objective,status,schedule,lead,team,category,project
  > KR1,Actual title,Actual objective,,,,,,Actual project
  > Kr2,Actual title 2,Actual objective,,,,,,Actual project
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

Instead of a KR ID, it is possible to put "New KR".
In that case, metadata is preserved.

  $ okra cat --okr-db=okrs.csv << EOF
  > # Actual project
  > 
  > ## Actual objective
  > 
  > - Actual title (KR1)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > # Another project
  > 
  > ## Another objective
  > 
  > - Something else (New KR)
  >   - @a (1 day)
  >   - Did all the things
  > EOF
  # Actual project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things
  
  # Another project
  
  ## Another objective
  
  - Something else (New KR)
    - @a (1 day)
    - Did all the things

If KR ID is "New KR", look for title in database to get real KR ID.

  $ okra cat --okr-db=okrs.csv << EOF
  > # Actual project
  > 
  > ## Actual objective
  > 
  > - Actual title (New KR)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > EOF
  okra: [WARNING] KR ID updated from unspecified to "KR1" :
  - "Actual title"
  - "Actual title"
  # Actual project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things

Use same case for KR ID as in database.

  $ okra cat --okr-db=okrs.csv << EOF
  > # Actual project
  > 
  > ## Actual objective
  > 
  > - Actual title (kr1)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > - Actual title 2 (KR2)
  >   - @b (1 day)
  >   - Did more of the things
  > 
  > EOF
  # Actual project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things
  
  - Actual title 2 (Kr2)
    - @b (1 day)
    - Did more of the things
