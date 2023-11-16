(import ./example :as ex)

(def rng
  (if-let [seed (dyn :random-seed)]
    (math/rng seed)
    (math/rng)))

(defn make-gen
  [gen-fn]
  (fn [] (gen-fn)))

(defn constant
  [value]
  (make-gen (fn [] value)))

(comment

  (def gen-pi
    (constant math/pi))

  (gen-pi)
  # =>
  math/pi

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
  @[math/pi math/pi math/pi math/pi math/pi]

  )

(defn int-between
  [low high]
  (make-gen (fn []
              (+ low
                 (math/rng-int rng (inc (- high low)))))))

(comment

  (let [low 1
        high 5]
    (all |(<= low $ high)
         (sample (int-between low high))))
  # =>
  true

  (def ages
    (int-between 0 100))

  (sample ages)

  (all |(<= 0 $ 100)
       (sample ages))
  # =>
  true

  )

# instead of implementing both `map` and `mapN`, went for making a
# single variadic `mapn`
(defn mapn
  [f & gens]
  (make-gen (fn []
              (def gen-results
                (seq [gen :in gens] (gen)))
              (f ;gen-results))))

(def letters
  (mapn string/from-bytes
        (int-between (chr "a") (chr "z"))))

(comment

  (< "a" "z")
  # =>
  true

  (all |(<= "a" $ "z")
       (sample letters))
  # =>
  true

  )

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

  (all valid-simple-name (sample simple-names))
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

  (all |(and (valid-simple-name (get $ :name))
             (valid-age (get $ :age)))
    (sample persons))
  # =>
  true

  )

(defn bind
  [f gen]
  (make-gen (fn []
              (def a-gen (f (gen)))
              (a-gen))))

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

  (let [result (sample lists-of-person)]
    (and (= n-samples-default
            (length result))
         (all |(<= min-list-len (length $) max-list-len)
              result)
         (all (fn [person-list]
                (all |(valid-person $)
                     person-list))
              result)))
  # =>
  true

  )

(comment

  (defn for-all-1
    [gen prop]
    (mapn prop gen))

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

  (def sort-by-age-1
    (for-all-1 lists-of-person
               (fn [in-persons]
                 (ex/is-valid in-persons
                              (ex/sort-by-age in-persons)))))

  (sample sort-by-age-1)
  # =>
  @[true true true true true]

  (def wrong-sort-by-age-1
    (for-all-1 lists-of-person
               (fn [in-persons]
                 (ex/is-valid in-persons
                              (ex/wrong-sort-by-age in-persons)))))

  # XXX: how to express "possible there is a false value in here"...
  (sample wrong-sort-by-age-1)

  (def n-tests-default 100)

  (defn test-1
    [prop]
    (var all-passed true)
    (for i 0 n-tests-default
      (when (not (prop))
        (printf "Fail: at test %d\n" i)
        (set all-passed false)
        (break)))
    (when all-passed
      (printf "Success: %d tests passed.\n" n-tests-default)))

  (test-1 sort-by-age-1)

  (test-1 wrong-sort-by-age-1)

  (defn for-all-2
    [gen prop]
    (bind (fn [x]
            (def result (prop x))
            (if (boolean? result)
              (constant result)
              result))
          gen))

  (def sum-of-list-2
    (for-all-2
      (list-of (int-between -10 10))
      (fn [l]
        #(printf "l: %n" l)
        (for-all-2 (int-between -10 10)
                   (fn [i]
                     #(print "i: " i)
                     (def left
                       (reduce (fn [acc elt] (+ acc elt i))
                               0 l))
                     (def right
                       (+ ;l (* (length l) i)))
                     #(printf "left: %d right: %d" left right)
                     (= left right))))))

  (sample sum-of-list-2)
  # =>
  @[true true true true true]

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

(defn test
  [prop]
  (var all-passed true)
  (for i 0 n-tests-default
    (def result (prop))
    (when (not (get result :is-success))
      (printf "Fail: at test %d with arguments %n\n"
              i (get result :arguments))
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
