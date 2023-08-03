Aggregate
---------

Engineer reports are aggregated correctly

  $ cat > eng1.md << EOF
  > # Last Week
  > 
  > - A Kr (KR123)
  >   - @eng1 (1.5 days)
  >   - Some work
  > 
  > - A new KR (New KR)
  >   - @eng1 (1 days)
  >   - Some work
  > 
  > - Work without a KR (No KR)
  >   - @eng1 (0.5 days)
  >   - Little bit of work
  > 
  > EOF

  $ cat > eng2.md << EOF
  > # Last Week
  > 
  > - A Kr (KR123)
  >   - @eng2 (1.5 days)
  >   - Some work
  > 
  > - A new KR, but different title (New KR)
  >   - @eng2 (1 days)
  >   - Some work
  > 
  > - Work without a KR (No KR)
  >   - @eng2 (1.0 days)
  >   - Small bit of work
  > 
  > EOF

  $ cat > okrs.csv << EOF
  > id,title,objective,status,schedule,lead,team,category,project
  > KR1,Actual title,Actual objective,active,,,,,Actual project
  > Kr2,Actual title 2,Actual objective,active,,,,,Actual project
  > KR3,Dropped KR,Actual objective,dropped,,,,,Actual project
  > KR123,Missing status KR,Actual objective,,,,,,Actual project
  > EOF

  $ cat eng1.md eng2.md | okra cat --engineer
  # Last Week
  
  - A Kr (KR123)
    - @eng1 (1.5 days), @eng2 (1.5 days)
    - Some work
    - Some work
  
  - A new KR (New KR)
    - @eng1 (1 day)
    - Some work
  
  - A new KR, but different title (New KR)
    - @eng2 (1 day)
    - Some work
  
  - Work without a KR (No KR)
    - @eng1 (0.5 days), @eng2 (1 day)
    - Little bit of work
    - Small bit of work
