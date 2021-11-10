  define buffer fileBuf for _file.
  define buffer tablestatBuf for _tablestat.
  
  define variable outToScreen as logical initial true no-undo.
  define variable outFile as character no-undo.
  define variable totReads as decimal format ">>>,>>>,>>>,>>9" label "Total Reads" no-undo.
  define variable i as integer no-undo.
  define variable lastSampleTime as decimal format ">>>,>>>,>>>,>>>,>>>,>>>,>>>,>>>,>>9.99" label "Duration(secs)" no-undo.
  define variable currentTime as character no-undo.
  
  define temp-table tblReads no-undo
    field tableName   as character format "x(20)" column-label "Table Name"
    field tableID     as integer
    field reads       as decimal format ">>,>>>,>>>,>>>,>>9" column-label "Total Reads"
    field recentReads as decimal  format ">>,>>>,>>>,>>>,>>9" column-label "Recent Reads"
    index i1 is unique primary tableID
    index i2 recentReads descending reads descending.
  
  for each fileBuf no-lock where
           fileBuf._file-num > 0 and 
           fileBuf._file-num < 32767:
    create tblReads.
    assign tblReads.tableName  = fileBuf._file-name
           tblReads.tableID    = fileBuf._file-num
           tblReads.reads       = 0
           tblReads.recentReads = 0.
  end.
  
  pause 0 before-hide.
  
  if etime >= 9 * exp(10,35) then
    do:
      lastSampleTime = 9 * exp(10,35) + 1.
      etime(yes).
    end.
  else
    lastSampleTime = etime(yes).
     
  message "Output to screen?" view-as alert-box 
          buttons yes-no-cancel update outToScreen.
          
  if outToScreen = ? then return.
    
  if outToScreen = no then
    do:
      outFile = "/los_logs/ampreads" + string(today,"999999") + replace(string(time,"HH:MM:SS"),":","") + ".txt" .
      output to value(outFile).
      put unformatted "date^currentTime^tblReads.tableName^tblReads.recentReads^tblReads.reads" skip.
      output close.
    end.
              
  do while true:
    for each tablestatBuf no-lock: 
      
      find tblReads exclusive-lock where 
           tblReads.tableID = tablestatBuf._tablestat-id no-error.
      
      if not available tblReads then 
        next.
  
      if tblReads.reads <> tablestatBuf._tablestat-read then 
        assign tblReads.recentReads = tablestatBuf._tablestat-read - tblReads.reads
               tblReads.reads       = tablestatBuf._tablestat-read.
      else 
        assign tblReads.recentReads = 0.  
    end.  /* for each tablestatBuf */
    
    assign i        = 0
           totReads = 0.
  
    if etime >= 9 * exp(10,35) then
    do:
       lastSampleTime = (9 * exp(10,35) + 10) / 1000.
       etime(yes).
    end.
    else
       lastSampleTime = etime(yes) / 1000.
       
    if outToScreen  then
    do:
      display lastSampleTime with 1 col width 75 frame tot.
      for each tblReads no-lock by recentReads descending with frame x:
        if (i = 0 or i < frame x:down) then  
          display tblReads.tableName tblReads.recentReads tblReads.reads with frame x.
  
        assign i        = i + 1
               totReads = totReads + tblReads.recentReads.
      end.
        
      display totReads with frame tot.
      pause message "Ready...".
    end.
    else
    do:
      currentTime = string(time,"HH:MM").
      output to value(outFile) append.
      for each tblReads no-lock by recentReads descending:
        put unformatted today "^" currentTime "^" tblReads.tableName "^" tblReads.recentReads "^" tblReads.reads skip.
  
        assign i        = i + 1
               totReads = totReads + tblReads.recentReads.
      end.
      
      output close.
      pause 300 no-message.
    end.
  end.
