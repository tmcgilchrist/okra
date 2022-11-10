
Team Lint example

  $ okra team lint -C admin/ -W 40.41 --conf ./conf.yml
  === My Team === 
    + Engineer 1
      + Report week 40: Complete ✅
      + Report week 41: Complete ✅
      + Report week 42: Not found ❌
    + Engineer 2
      + Report week 40: Not found ❌
      + Report week 41: Lint error ⚠️
                        Line 4: + used as bullet point, this can confuse the parser. Only use - as bullet marker.
                        Line 5: + used as bullet point, this can confuse the parser. Only use - as bullet marker.
                        2 formatting errors found. Parsing aborted.
      + Report week 42: Not found ❌
