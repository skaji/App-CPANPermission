package App::CPANPermission::Table;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = bless {line => []}, $class;
    $self->add(@_) if @_;
    $self;
}

sub add {
    my ($self, @field) = @_;
    push @{$self->{line}}, \@field;
}

sub stringify {
    my $self = shift;
    my $max = [];
    for my $l (@{$self->{line}}) {
        for my $i (0..$#$l) {
            $max->[$i] = length($l->[$i]) if ($max->[$i] ||= 0) < length($l->[$i]);
        }
    }
    my $format = (join " ", map { "%-${_}s" } @$max) . "\n";
    join "", map { sprintf $format, @$_ } @{$self->{line}};
}

1;
