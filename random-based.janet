(import ./example :as ex)

(def rng
  (if-let [seed (dyn :random-seed)]
    (math/rng seed)
    (math/rng)))

(defn make-gen
  [gen-fn]
  (fn [&opt min-size]
    (gen-fn min-size)))

(defn constant
  [value]
  (make-gen (fn [_] [value 0])))

(comment

  (def gen-pi
    (constant math/pi))

  (gen-pi)
  # =>
  [math/pi 0]

  )

(def n-samples-default 5)

(defn sample
  [gen &opt n-values]
  (default n-values n-samples-default)
  (seq [i :range [n-values]]
    (gen)))

(comment

  (def gen-pi
    (constant math/pi))

  (sample gen-pi)
  # =>
  @[[math/pi 0] [math/pi 0] [math/pi 0] [math/pi 0] [math/pi 0]]

  )

(defn dec-size
  [min-size decrease]
  (when (nil? min-size)
    (break nil))
  #
  (def smaller (- min-size decrease))
  #(printf "smaller: %n" smaller)
  (when (neg? smaller)
    (error [:size-exceeded min-size decrease smaller]))
  #
  smaller)

(defn int-between
  [low high]
  (defn zig-zag
    [i]
    (if (neg? i)
      (dec (* -2 i))
      (* 2 i)))
  #
  (make-gen (fn [&opt min-size]
              #(printf "min-size: %n" min-size)
              (def value
                (+ low
                   (math/rng-int rng (inc (- high low)))))
              #(printf "value: %n" value)
              (def size (zig-zag value))
              #(printf "size: %n" size)
              (dec-size min-size size)
              [value size])))

(comment

  (let [low 1
        high 5]
    (all |(<= low (first $) high)
         (sample (int-between low high))))
  # =>
  true

  (def ages
    (int-between 0 100))

  (sample ages)

  (all |(<= 0 (first $) 100)
       (sample ages))
  # =>
  true

  )

# instead of implementing both `map` and `mapN`, went for making a
# single variadic `mapn`
(defn mapn
  [f & gens]
  (make-gen (fn [&opt min-size]
              (def results @[])
              (var size-acc 0)
              (var cur-min-size min-size)
              (each gen gens
                (def [result size] (gen cur-min-size))
                (set cur-min-size (dec-size cur-min-size size))
                (array/push results result)
                (+= size-acc size))
              #
              [(f ;results) size-acc])))

(def letters
  (mapn string/from-bytes
        (int-between (chr "a") (chr "z"))))

(comment

  (< "a" "z")
  # =>
  true

  (all |(<= "a" (first $) "z")
       (sample letters))
  # =>
  true

  )

(defn bind
  [f gen]
  (make-gen (fn [&opt min-size]
              (def [result-outer size-outer] (gen min-size))
              (def new-min-size (dec-size min-size size-outer))
              (def [result-inner size-inner]
                ((f result-outer) new-min-size))
              (def size (+ size-inner size-outer))
              [result-inner size])))

(defn list-of-length
  [n gen]
  (def n-gens
    (seq [i :range [n]] gen))
  (mapn (fn [& args] @[;args])
        ;n-gens))

(comment

  (def simple-name-length 6)

  (def simple-names
    (mapn string/join
          (list-of-length simple-name-length letters)))

  (<= "a" "j" "z")
  # =>
  true

  (defn valid-simple-name
    [name]
    (and (= simple-name-length (length name))
         (all (fn [char]
                (<= (chr "a") char (chr "z")))
              name)))

  (valid-simple-name "hermes")
  # =>
  true

  (all |(valid-simple-name (first $))
       (sample simple-names))
  # =>
  true

  (def [min-age max-age] [0 100])

  (def ages
    (int-between min-age max-age))

  (defn valid-age
    [age]
    (<= min-age age max-age))

  (valid-age 88)
  # =>
  true

  (def persons
    (mapn (fn [name age] {:name name :age age})
          simple-names
          ages))

  (all |(let [person (first $)]
          (and (valid-simple-name (get person :name))
               (valid-age (get person :age))))
    (sample persons))
  # =>
  true

  )

(def [min-list-len max-list-len] [0 10])

(defn list-of
  [gen]
  (bind (fn [l] (list-of-length l gen))
        (int-between min-list-len max-list-len)))

(comment

  (def simple-name-length 6)

  (def simple-names
    (mapn string/join
          (list-of-length simple-name-length letters)))

  (def [min-age max-age] [0 100])

  (def ages
    (int-between min-age max-age))

  (def persons
    (mapn (fn [name age] {:name name :age age})
          simple-names
          ages))

  (sample persons)

  (defn valid-simple-name
    [name]
    (and (= simple-name-length (length name))
         (all (fn [char]
                (<= (chr "a") char (chr "z")))
              name)))

  (defn valid-age
    [age]
    (<= min-age age max-age))

  (defn valid-person
    [person]
    (and (valid-simple-name (get person :name))
         (valid-age (get person :age))))

  (def lists-of-person
    (list-of persons))

  (sample lists-of-person)

  (let [result (sample lists-of-person)]
    (and (= n-samples-default
            (length result))
         (all |(<= min-list-len (length $) max-list-len)
              result)
         (all (fn [[person-list _]]
                (all |(valid-person $)
                     person-list))
              result)))
  # =>
  true

  )

(defn for-all
  [gen prop]
  (bind (fn [x]
          (def result (prop x))
          (if (boolean? result)
            (constant @{:is-success result
                        :arguments [x]})
            (mapn (fn [y]
                    (merge y
                           {:arguments [x ;(get y :arguments)]}))
                  result)))
        gen))

(def n-tests-default 100)

(def n-smaller-default 100_000)

(defn test
  [prop]
  (defn find-smaller
    [min-result min-size]
    (var skipped 0)
    (var not-shrunk 0)
    (var shrunk 0)
    (var cur-min-size min-size)
    (var cur-result min-result)
    (while (and (<= (+ skipped not-shrunk shrunk) n-smaller-default)
                (pos? cur-min-size))
      (try
        (do
          (def [result size] (prop cur-min-size))
          (cond
            (>= size cur-min-size)
            (++ skipped)
            #
            (not (get result :is-success))
            (do
              (++ shrunk)
              (set cur-result result)
              (set cur-min-size size))
            #
            (++ not-shrunk)))
        ([e]
          # XXX
          (++ skipped))))
    (printf "Shrinking: gave up at arguments %n"
            (get cur-result :arguments))
    (printf "%n %n %n %n" skipped not-shrunk shrunk cur-min-size))
  #
  (var all-passed true)
  (for i 0 n-tests-default
    (def [result size] (prop))
    (when (not (get result :is-success))
      (printf "Fail: at test %d with arguments %n\n"
              i (get result :arguments))
      (find-smaller result size)
      (set all-passed false)
      (break)))
  (when all-passed
    (printf "Success: %d tests passed.\n" n-tests-default)))

(comment

  (sample (list-of letters))

  (def wrong
    (for-all (list-of letters)
             (fn [l]
               (deep= l (reverse l)))))

  (test wrong)

  (def rev-of-rev
    (for-all (list-of letters)
             (fn [l]
               (deep= l (reverse (reverse l))))))

  (test rev-of-rev)

  (def sum-of-list
    (for-all (list-of (int-between -10 10))
             (fn [l]
               (for-all (int-between -10 10)
                        (fn [i]
                          (def left
                            (reduce (fn [acc elt] (+ acc elt i))
                                    0 l))
                          (def right
                            (+ ;l (* (length l) i)))
                          (= left right))))))

  (test sum-of-list)

  (def simple-name-length 6)

  (def simple-names
    (mapn string/join
          (list-of-length simple-name-length letters)))

  (def [min-age max-age] [0 100])

  (def ages
    (int-between min-age max-age))

  (def persons
    (mapn (fn [name age] {:name name :age age})
          simple-names
          ages))

  (def lists-of-person
    (list-of persons))

  (def prop-sort-by-age
    (for-all lists-of-person
             (fn [in-persons]
               (ex/is-valid in-persons (ex/sort-by-age in-persons)))))

  (test prop-sort-by-age)

  (def prop-wrong-sort-by-age
    (for-all lists-of-person
             (fn [in-persons]
               (ex/is-valid in-persons (ex/wrong-sort-by-age in-persons)))))

  (test prop-wrong-sort-by-age)

  )
