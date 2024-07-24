(-> ["janet"
     "./juat/janet-usages-as-tests/make-and-run-tests.janet"
     # specify file and/or directory paths relative to project root
     "example.janet"
     "random-based.janet"
     "vintage.janet"
     ]
    (os/execute :p)
    os/exit)

