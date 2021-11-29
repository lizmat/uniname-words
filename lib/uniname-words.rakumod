# The main "database"
my $words;
my %uniname-words := BEGIN {
    use nqp;
    note "The unicode database is being inspected, this may take a while.";

    my int32 @reserved;
    my $uniname-words := nqp::hash('reserved',@reserved);

    for 0..0x10FFFF -> int32 $cp {
        my $uniname := $cp.uniname;
        if $uniname.starts-with('<reserved') {
            nqp::push_i(@reserved,$cp);
        }
        else {
            for $uniname.comb(/ \w+ /).unique -> str $word {
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

    my $map := nqp::p6bindattrinvres(
      nqp::create(Map),Map,'$!storage',$uniname-words
    );

    $words = ' ' ~ $map.keys.sort.join(' ') ~ ' ';

    $map
}

# Return the word(s) of which the given string is a part
my sub string2words($string) {
    my $STRING := $string.trim.uc;
    my int $index;
    my str @words;
    while $words.index($STRING,$index) -> int $this {  # cannot be 0
        my int $left  = $words.rindex(' ',$this) + 1;
        my int $right = $words.index(' ', $this);
        @words.push: $words.substr($left, $right - $left);
        $index = $right + 1;
    }
    @words
}
my sub strings2words(@strings) {
    @strings.map({ string2words($_).Slip }).unique
}

my proto sub uniname-words(|) is export {*}
my multi sub uniname-words() { %uniname-words }

my multi sub uniname-words(Str:D $word) {
    %uniname-words{$word.uc} // my int32 @
}
my multi sub uniname-words(+@words, :$any) {
    my int32 @seen;
    if $any {
        @seen = @words.map({ .Slip with %uniname-words{.uc} }).unique;
    }
    elsif @words.map({ .uc if $_ }) -> @WORDS {
        my %seen is Bag = @WORDS.map: { .Slip with %uniname-words{$_} }
        my $nr-words := @WORDS.elems;
        @seen = %seen.map({ .key if .value == $nr-words });
    }
    @seen.sort
}
my multi sub uniname-words(Str:D $word, :$partial!) {
    if $word && $partial {
        my $WORD := $word.uc;
        my int32 @seen = string2words($word).map: {
            %uniname-words{$_}.Slip
        }
        @seen.sort
    }
    else {
        uniname-words($word)
    }
}
my multi sub uniname-words(+@words, :$partial!, :$any) {
    if $partial {
        my int32 @seen;
        if @words.map({ .uc if $_ }) -> @WORDS {
            if $any {
                @seen = strings2words(@WORDS).map(-> $KEY {
                    %uniname-words{$KEY}.Slip
                }).unique;
            }
            else {
                my %seen is Bag = strings2words(@WORDS).map: -> $KEY {
                    %uniname-words{$KEY}.Slip
                }
                my $nr-words  := @WORDS.elems;
                my $all-WORDS := @WORDS.all;
                @seen = %seen.map: {
                    .key
                      if .value == $nr-words
                      && .key.uniname.contains($all-WORDS)
                }
            }
        }
        @seen.sort
    }
    else {
        uniname-words(@words, :$any)
    }
}

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

say .uniname for uniname-words(<left bracket>);

=end code

=head1 DESCRIPTION

uniname-words is a utility library that exports a single subroutine:
C<uniname-words>.  When called without a parameter, it returns a C<Map>
with each word (/w+) from the unicode database (active at installation
of the module) as a key, and an C<int32> array of the codepoints
that have that word in their name, as the value.

All Unicode reserved codepoints are available under the C<reserved>
key: the rest of the name can be deduced from the codepoint value.

When the C<uniname-words> sub is called with one or more arguments,
they are considered to be words to return the codepoints of.  Given
words will be automatically uppercased to be checked.  An optional
C<:partial> named argument can be specified to return the codepoints
of words that partially match.

By default, if more than one word has been specified, B<all> words must
occur in the unicode name to be included.  An optional C<:any> named
argument can be specified that B<any> of the specified words should occur.

=head1 uw

This module also install a command-line utility C<uw>, that takes one
or more words, and the C<--partial> and C<--any> parameters, just like
the C<uniname-words> sub does, and lists the names of the selected
code points on STDOUT.  It also additionally takes a C<--verbose>
parameter which will also output the codepoint value and a rendering
of the codepoint (if possible).

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
