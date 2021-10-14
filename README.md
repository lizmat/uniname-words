[![Actions Status](https://github.com/lizmat/uniname-words/workflows/test/badge.svg)](https://github.com/lizmat/uniname-words/actions)

NAME
====

uniname-words - look for words in unicode character names

SYNOPSIS
========

```raku
use uniname-words;

say uniname-words.elems;  # 262166

say .uniname for uniname-words<LOVE>;
# LOVE HOTEL
# LOVE LETTER
# I LOVE YOU HAND SIGN
```

DESCRIPTION
===========

uniname-words is a utility library that exports a single subroutine: `uniname-words`. This returns a `Map` with each word (/w+) from the unicode database (active at installation of the module) as a key, and an `int32` array of the codepoints that have that word in their name, as the value.

All Unicode reserved codepoints are available under the `reserved` key: the rest of the name can be deduced from the codepoint value.

INSTALLATION NOTE
=================

Installing (or running this module for the first time after a runtime update) may take up to a minute (or possibly more on slower machines) because the entire unicode database is *then* checked, allowing it to remain up-to-date across versions of the run-time.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/uniname-words . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

