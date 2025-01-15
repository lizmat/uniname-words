[![Actions Status](https://github.com/lizmat/uniname-words/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/uniname-words/actions) [![Actions Status](https://github.com/lizmat/uniname-words/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/uniname-words/actions) [![Actions Status](https://github.com/lizmat/uniname-words/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/uniname-words/actions)

NAME
====

uniname-words - look for words in unicode character names

SYNOPSIS
========

```raku
use uniname-words;

say uniname-words.elems;  # 262166

say .uniname for uniname-words<love>;
# LOVE HOTEL
# LOVE LETTER
# I LOVE YOU HAND SIGN

say .uniname for uniname-words(<left bracket>);
```

DESCRIPTION
===========

The `uniname-words` distribution exports a single subroutine: `uniname-words`. When called without a parameter, it returns a `Map` with each word (/w+) from the unicode database (active at installation of the module) as a key (in lowercase), and an `int32` array of the codepoints that have that word in their name, as the value.

All Unicode reserved codepoints are available under the `reserved` key: the rest of the name can be deduced from the codepoint value.

When the `uniname-words` sub is called with one or more arguments, they are considered to be words to return the codepoints of: these can be specified as a `Str` or as a `Regex`. Given words will be automatically lowercased to be checked. An optional `:partial` named argument can be specified to return the codepoints of words that partially match.

By default, if more than one word has been specified, **all** words must occur in the unicode name to be included. An optional `:any` named argument can be specified that **any** of the specified words should occur.

uw
==

This module also install a command-line utility `uw`, that takes one or more words, and the `--partial` and `--any` parameters, just like the `uniname-words` sub does, and lists the names of the selected code points on STDOUT. It also additionally takes a `--hex` parameter (to just see the hexadecimal values), a `--name` parameter (to just see the names) and/or a `--char` (to just see a rendition). These 3 parameters can also be mixed in any combination.

un
==

This module also install a command-line utility `un`, that takes one or more strings, and lists the names of the code points of these strings on STDOUT. It also additionally takes a `--hex` parameter (to just see the hexadecimal values), a `--name` parameter (to just see the names) and/or a `--char` (to just see a rendition). These 3 parameters can also be mixed in any combination.

INSTALLATION NOTE
=================

Installing (or running this module for the first time after a runtime update) may take up to a minute (or possibly more on slower machines) because the entire unicode database is *then* checked, allowing it to remain up-to-date across versions of the run-time.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/uniname-words . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2021, 2022, 2023, 2024, 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

