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
