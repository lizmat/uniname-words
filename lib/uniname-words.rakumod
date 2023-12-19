
# The main "database"
my $words;
my %uniname-words := BEGIN {
    use nqp;

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
                    nqp::atkey($uniname-words,nqp::lc($word)),
                    nqp::bindkey($uniname-words,nqp::lc($word),my int32 @)
                  ),
                  $cp
                );
            }
        }
    }

    my $map := nqp::p6bindattrinvres(
      nqp::create(Map),Map,'$!storage',$uniname-words
    );

    # this *must* be an assignment, as this runs in a BEGIN block
    $words = "\0" ~ $map.keys.sort.join("\0") ~ "\0";

    $map
}

# Return the word(s) of which the given string is a part
my sub string2words($STRING) {
    my $string := $STRING.trim.lc;
    my int $index;
    my str @words;
    while $words.index($string,$index) -> int $this {  # cannot be 0
        my int $left  = $words.rindex("\0",$this) + 1;
        my int $right = $words.index("\0", $this);
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
    %uniname-words{$word.lc} // my int32 @
}
my multi sub uniname-words(+@WORDS, :$any) {
    my int32 @seen;
    if $any {
        @seen = @WORDS.map({ .Slip with uniname-words(.lc) }).unique;
    }
    elsif @WORDS.map({ $_ ~~ Regex ?? $_ !! $_ ?? .lc !! Empty }) -> @words {
        my %seen is Bag = @words.map: { .Slip with uniname-words($_) }
        my $nr-words := @words.elems;
        @seen = %seen.map({ .key if .value == $nr-words });
    }
    @seen.sort
}
my multi sub uniname-words(Str:D $WORD, :$partial!) {
    if $WORD && $partial {
        my $word := $WORD.lc;
        my int32 @seen;
        @seen.append($_) for string2words($word).map: { %uniname-words{$_} }
        @seen.sort
    }
    else {
        uniname-words($WORD)
    }
}
my multi sub uniname-words(+@WORDS, :$partial!, :$any) {
    if $partial {
        my int32 @seen;
        if @WORDS.map({ .lc if $_ }) -> @words {
            if $any {
                @seen = strings2words(@words).map({
                    %uniname-words{$_}.Slip
                }).unique;
            }
            else {
                my %seen is Bag = strings2words(@words).map: {
                    %uniname-words{$_}.Slip
                }
                my $nr-words  := @words.elems;
                my $all-words := @words.all;
                @seen = %seen.map: {
                    .key
                      if .value == $nr-words
                      && .key.uniname.lc.contains($all-words)
                }
            }
        }
        @seen.sort
    }
    else {
        uniname-words(@WORDS, :$any)
    }
}

my $match;
my multi sub uniname-words(Regex:D $regex) {
    without $match {
        use nqp;
        use Map::Match:ver<0.0.4>:auth<zef:lizmat>;
        $match := nqp::create(Map::Match);
        nqp::bindattr($match,Map::Match,'%!map',%uniname-words);
        nqp::bindattr($match,Map::Match,'$!keys',nqp::decont($words));
    }

    my int32 @seen;
    @seen.append($_) for $match.AT-KEY($regex.raku.lc.EVAL);
    @seen.sort
}


=begin pod

=head1 NAME

uniname-words - look for words in unicode character names

=head1 SYNOPSIS

=begin code :lang<raku>

use uniname-words;

say uniname-words.elems;  # 262166

say .uniname for uniname-words<love>;
# LOVE HOTEL
# LOVE LETTER
# I LOVE YOU HAND SIGN

say .uniname for uniname-words(<left bracket>);

=end code

=head1 DESCRIPTION

uniname-words is a utility library that exports a single subroutine:
C<uniname-words>.  When called without a parameter, it returns a C<Map>
with each word (/w+) from the unicode database (active at installation
of the module) as a key (in lowercase), and an C<int32> array of the
codepoints that have that word in their name, as the value.

All Unicode reserved codepoints are available under the C<reserved>
key: the rest of the name can be deduced from the codepoint value.

When the C<uniname-words> sub is called with one or more arguments,
they are considered to be words to return the codepoints of:  these
can be specified as a C<Str> or as a C<Regex>.  Given words will be
automatically lowercased to be checked.  An optional C<:partial> named
argument can be specified to return the codepoints of words that partially
match.

By default, if more than one word has been specified, B<all> words must
occur in the unicode name to be included.  An optional C<:any> named
argument can be specified that B<any> of the specified words should occur.

=head1 uw

This module also install a command-line utility C<uw>, that takes one
or more words, and the C<--partial> and C<--any> parameters, just like
the C<uniname-words> sub does, and lists the names of the selected
code points on STDOUT.  It also additionally takes a C<--hex> parameter
(to just see the hexadecimal values), a C<--name> parameter (to just see
the names) and/or a C<--char> (to just see a rendition).  These 3 parameters
can also be mixed in any combination.

=head1 un

This module also install a command-line utility C<un>, that takes one
or more strings, and lists the names of the code points of these strings
on STDOUT. It also additionally takes a C<--hex> parameter (to just see the
hexadecimal values), a C<--name> parameter (to just see the names) and/or
a C<--char> (to just see a rendition).  These 3 parameters can also be mixed
in any combination.

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

If you like this module, or what I’m doing more generally, committing to a
L<small sponsorship|https://github.com/sponsors/lizmat/>  would mean a great
deal to me!

=head1 COPYRIGHT AND LICENSE

Copyright 2021, 2022, 2023 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
