(defn sort-by-age
  [a-list]
  (sorted-by |(get $ :age) a-list))

(comment

  (sort-by-age [{:age 5 :name "alice"}
                {:age 6 :name "bob"}
                {:age 3 :name "charlie"}
                {:age 2 :name "dan"}])
  # =>
  @[{:age 2 :name "dan"}
    {:age 3 :name "charlie"}
    {:age 5 :name "alice"}
    {:age 6 :name "bob"}]

  )

(defn wrong-sort-by-age
  [a-list]
  (sorted a-list))

(comment

  (def original
    [{:age 5 :name "alice"}
     {:age 6 :name "bob"}
     {:age 3 :name "charlie"}])

  # expressed this way instead of explicitly to avoid being broken by
  # changes to janet's hashing
  (wrong-sort-by-age original)
  # =>
  (sort (array ;original))

  )

(defn list-same-length
  [list-a list-b]
  (= (length list-a)
     (length list-b)))

(comment

  (list-same-length [:a :b :c]
                    [0 1 2])
  # =>
  true

  (list-same-length []
                    [0 1 2 3])
  # =>
  false

  )

(defn list-sorted
  [a-list]
  (var result true)
  (for i 0 (dec (length a-list))
    (when (> (get a-list i) (get a-list (inc i)))
      (set result false)
      (break)))
  result)

(comment

  (list-sorted [:b :a :c])
  # =>
  false

  (list-sorted [0 1 7 8])
  # =>
  true

  (list-sorted [])
  # =>
  true

  (list-sorted [11 11 11])
  # =>
  true

  (list-sorted [:ant :bee :zebra :walrus])
  # =>
  false

  )

(defn list-sorted-by-key
  [a-list a-key]
  (var result true)
  (for i 0 (dec (length a-list))
    (when (> (get-in a-list [i a-key])
             (get-in a-list [(inc i) a-key]))
      (set result false)
      (break)))
  result)

(comment

  (list-sorted-by-key [{:age 11 :name "arnold"}
                       {:age 35 :name "bettie"}
                       {:age 90 :name "charly"}]
                      :age)
  # =>
  true

  (list-sorted-by-key [{:age 11 :name "arnold"}
                       {:age 35 :name "bettie"}
                       {:age 90 :name "charly"}]
                      :name)
  # =>
  true

  (list-sorted-by-key [{:age 35 :name "bettie"}
                       {:age 11 :name "arnold"}
                       {:age 90 :name "charly"}]
                      :name)
  # =>
  false

  )

(defn list-same-members
  [list-a list-b]
  (deep= (tabseq [mem :in list-a]
           mem true)
         (tabseq [mem :in list-b]
           mem true)))

(comment

  (list-same-members [0 1 2 8]
                     [0 2 8 1])
  # =>
  true

  (list-same-members [1 2]
                     [1 2 1])
  # =>
  true

  (list-same-members []
                     [0])
  # =>
  false

  (list-same-members []
                     [])
  # =>
  true

  (list-same-members [1 2 3]
                     [1 2 9])
  # =>
  false

  (list-same-members [1 2 3]
                     [1 2])
  # =>
  false

  )

(defn is-valid
  [in-list out-list]
  (and (list-same-length in-list out-list)
       (list-sorted-by-key out-list :age)
       (list-same-members in-list out-list)))

(comment

  (is-valid [{:age 35 :name "bettie"}
             {:age 11 :name "arnold"}
             {:age 90 :name "charly"}]
            [{:age 11 :name "arnold"}
             {:age 35 :name "bettie"}
             {:age 90 :name "charly"}])
  # =>
  true

  (is-valid [{:age 35 :name "bettie"}
             {:age 11 :name "arnold"}
             {:age 90 :name "charly"}]
            [{:age 90 :name "charly"}
             {:age 11 :name "arnold"}
             {:age 35 :name "bettie"}])
  # =>
  false

  )

