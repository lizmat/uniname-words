# The main "database"
my $words;
my %uniname-words := BEGIN {
    use nqp;

    my int32 @reserved;
    my $uniname-words := nqp::hash('reserved',@reserved);

    for 0..0x10FFFF -> int32 $cp {  # UNCOVERABLE
        my $uniname := $cp.uniname;
        if $uniname.starts-with('<reserved') {  # UNCOVERABLE
            nqp::push_i(@reserved,$cp);
        }
        else {
            for $uniname.comb(/ \w+ /).unique -> str $word {  # UNCOVERABLE
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
    $words = "\0" ~ $map.keys.sort.join("\0") ~ "\0";  # UNCOVERABLE

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
        $index = $right + 1;  # UNCOVERABLE
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
        use Map::Match:ver<0.0.8+>:auth<zef:lizmat>;
        $match := nqp::create(Map::Match);  # UNCOVERABLE
        nqp::bindattr($match,Map::Match,'%!map',%uniname-words);
        nqp::bindattr($match,Map::Match,'$!keys',nqp::decont($words));
    }

    my int32 @seen;
    @seen.append($_) for $match.AT-KEY($regex.raku.lc.EVAL);
    @seen.sort
}

# vim: expandtab shiftwidth=4
