my
module uniname-words:ver<10.0.2>:auth<zef:lizmat> { }  # just for mi6

use nqp;

my %uniname-words := BEGIN {
    note "The unicode database is being inspected, this may take a while.";

    my int32 @reserved;
    my $uniname-words := nqp::hash('reserved',@reserved);

    for 0..0x10FFFF -> int32 $cp {
        my $uniname := $cp.uniname;
        if $uniname.starts-with('<reserved') {
            nqp::push_i(@reserved,$cp);
        }
        else {
            for $uniname.comb(/ \w+ /) -> str $word {
                nqp::push_i(
                  nqp::ifnull(
                    nqp::atkey($uniname-words,$word),
                    nqp::bindkey($uniname-words,$word,my int32 @)
                  ),
                  $cp
                );
            }
        }
    }

    nqp::p6bindattrinvres(
      nqp::create(Map),Map,'$!storage',$uniname-words
    )
}

my sub uniname-words(--> Map:D) is export { %uniname-words }

=begin pod

=head1 NAME

uniname-words - look for words in unicode character names

=head1 SYNOPSIS

=begin code :lang<raku>

use uniname-words;

say uniname-words.elems;  # 262166

say .uniname for uniname-words<LOVE>;
# LOVE HOTEL
# LOVE LETTER
# I LOVE YOU HAND SIGN

=end code

=head1 DESCRIPTION

uniname-words is a utility library that exports a single
subroutine: C<uniname-words>.  This returns a C<Map> with each
word (/w+) from the unicode database (active at installation
of the module) as a key, and an C<int32> array of the codepoints
that have that word in their name, as the value.

All Unicode reserved codepoints are available under the C<reserved>
key: the rest of the name can be deduced from the codepoint value.

=head1 INSTALLATION NOTE

Installing (or running this module for the first time after a
runtime update) may take up to a minute (or possibly more on
slower machines) because the entire unicode database is *then*
checked, allowing it to remain up-to-date across versions of the
run-time.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/uniname-words . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
