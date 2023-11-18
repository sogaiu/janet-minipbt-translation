# janet-minipbt-translation

A translation into Janet of parts of
[MiniPBT](https://github.com/kurtschelfthout/substack-pbt) -- code
from a series of articles about property-based-testing by
kurtschelfthout.

## Motivation

I've thought for some time that it would be nice to have an
appropriate generative testing library for Janet.  I thought to port
[Hypothesis](https://github.com/HypothesisWorks/hypothesis) but after
trying to understand its source and related papers on a number of
occasions, eventually put things on hold as I did not reach a point
where felt I understood it well enough to go through with trying to
implement (and maintain) it.

Somewhat later, I came across a series of articles about
property-based testing in which the author was kind enough to build up
three simple implementations (with working code even!).

The first two were based on familiar approaches [1] but the third one
in the article series was unfamiliar.  Allegedly, it was even simpler
to understand than Hypothesis and there seemed to be some hope of
delivering decent enough results.

This repository is primarily about a Janet translation of the code in
this "new found" approach.

## Some Details

The approach of interest was covered in the [Random All the Way
Down](https://getcode.substack.com/p/property-based-testing-6-random-all)
article (the sixth in the series) and the file,
[random-based.janet](random-based.janet), contains a translation
attempt.

There is also another file, [vintage.janet](vintage.janet), which is a
translation of code from the second article, [The Essentials of
Vintage
QuickCheck](https://getcode.substack.com/p/-property-based-testing-2-the-essentials).
This is included for comparison purposes and might be a better
starting point for understanding as it's simpler and its code has a
fair bit of overlap with what's in `random-based.janet`.

## Suggestions

If this repository and/or the related ideas are of interest, I
recommend reading at least the first two articles of the series
(starting with [this
one](https://getcode.substack.com/p/property-based-testing-1-what-is))
plus the sixth one, and then either attempting your own translation or
taking a look at what's in this repository.

Alternatively (or additionally), you might take a look at the [Random
testing](https://github.com/AnthonyLloyd/CsCheck#Random-testing) parts
of [CsCheck](https://github.com/AnthonyLloyd/CsCheck) -- the library
that inspired the sixth article.

## Credits

Many thanks go out to the following folks:

* AnthonyLoyd - author of CsCheck, the library that the sixth article
  in the series was inspired by.
* DRMacIver - creator of Hypothesis, the system I studied (and applied
  successfully) but failed to understand well enough to translate.
* kurtschelfthout - author of article series, related code, and
  [FsCheck](https://github.com/fscheck/FsCheck).

## Footnotes

[1] The three implementations are inspired by:

  * [QuickCheck](https://github.com/nick8325/quickcheck)
  * [Hypothesis](https://github.com/HypothesisWorks/hypothesis)
  * [CsCheck](https://github.com/AnthonyLloyd/CsCheck)

