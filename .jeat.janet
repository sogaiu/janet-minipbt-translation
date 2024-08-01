(defn init
  []
  {# describes what to test - file and dir paths
   :jeat-target-spec
   ["example.janet"
    "random-based.janet"
    "vintage.janet"]
   # describes what to skip - file paths only
   #:jeat-exclude-spec
   #[]
   })
