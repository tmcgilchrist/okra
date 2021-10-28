Master DB
---------

When `--okr-db` is passed, metadata is fixed.

  $ cat > okrs.csv << EOF
  > id,title,objective,status,schedule,lead,team,category,project
  > KR1,Actual title,Actual objective,active,,,,,Actual project
  > Kr2,Actual title 2,Actual objective,active,,,,,Actual project
  > KR3,Dropped KR,Actual objective,dropped,,,,,Actual project
  > KR4,Unscheduled KR,Actual objective,unscheduled,,,,,Actual project
  > KR5,Missing status KR,Actual objective,,,,,,Actual project
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

If KR ID is "No KR", look for title in database to get real KR ID.

  $ okra cat --okr-db=okrs.csv << EOF
  > # Actual project
  > 
  > ## Actual objective
  > 
  > - Actual title (No KR)
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

Warn when using KRs that are not active or missing status

  $ okra cat --okr-db=okrs.csv << EOF
  > # Actual project
  > 
  > ## Actual objective
  > 
  > - Dropped KR (KR3)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > - Unscheduled KR (KR4)
  >   - @b (1 day)
  >   - Did more of the things
  > 
  > - Missing status KR (KR5)
  >   - @b (1 day)
  >   - Did more of the things
  > 
  > EOF
  okra: [WARNING] Work logged on KR marked as "Dropped": "Dropped KR" ("KR3")
  okra: [WARNING] Work logged on KR marked as "Unscheduled": "Unscheduled KR" ("KR4")
  okra: [WARNING] Work logged on KR with no status set, status should be Active: "Missing status KR" ("KR5")
  # Actual project
  
  ## Actual objective
  
  - Dropped KR (KR3)
    - @a (1 day)
    - Did all the things
  
  - Unscheduled KR (KR4)
    - @b (1 day)
    - Did more of the things
  
  - Missing status KR (KR5)
    - @b (1 day)
    - Did more of the things
