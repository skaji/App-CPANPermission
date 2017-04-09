package App::CPANPermission;
use strict;
use warnings;

our $VERSION = '0.001';

use CPAN::Meta::YAML ();
use HTTP::Tinyish;
use JSON::PP ();

sub new {
    my ($class, %args) = @_;
    bless {
        http => HTTP::Tinyish->new,
        cpanmetadb => 'http://cpanmetadb.plackperl.org/v1.0/package',
        metacpan => 'https://fastapi.metacpan.org/v1/permission',
        %args,
    }, $class;
}

sub get_permission_for {
    my ($self, $module) = @_;
    my $wantarray = wantarray;
    my $err;
    (my $meta, $err) = $self->_get_cpanmetadb($module);
    if ($meta) {
        (my $permission, $err) = $self->_get_metacpan(@{$meta->{provides}});
        if ($permission) {
            my $res = {distfile => $meta->{distfile}, permission => $permission};
            return $wantarray ? ($res, undef) : $res;
        }
    }
    return $wantarray ? (undef, $err) : undef;
}

sub _get_cpanmetadb {
    my ($self, $module) = @_;
    my $url = "$self->{cpanmetadb}/$module";
    my $res = $self->{http}->get($url);
    return (undef, "$res->{status} $res->{reason}, $url") unless $res->{success};
    my $yaml = CPAN::Meta::YAML->read_string($res->{content})->[0];
    return (+{
        distfile => $yaml->{distfile},
        provides => [sort keys %{$yaml->{provides}}],
    }, undef)
}

sub _get_metacpan {
    my ($self, @module) = @_;
    my $payload = {
        query => { bool => { should => [ map +{term => {module_name => $_}}, @module ] } },
        size  => scalar @module,
    };
    my $url = "$self->{metacpan}/_search";
    my $res = $self->{http}->post($url, {content => JSON::PP::encode_json($payload)});
    return (undef, "$res->{status} $res->{reason}, $url") unless $res->{success};
    my $json = JSON::PP::decode_json($res->{content});
    my @hit = map $_->{_source}, @{$json->{hits}{hits}};
    if (@hit < @module) {
        my %miss = map { $_ => 1 } @module;
        delete $miss{$_->{module_name}} for @hit;
        push @hit, map +{ module_name => $_ }, keys %miss;
    }
    @hit = sort { $a->{module_name} cmp $b->{module_name} } @hit;
    return (\@hit, undef);
}

1;
__END__

=encoding utf-8

=head1 NAME

App::CPANPermission - Blah blah blah

=head1 SYNOPSIS

  use App::CPANPermission;

  my $app = App::CPANPermission->new;
  my ($res, $err) = $app->get_permission_for("Plack");
  die $err if $err;

=head1 DESCRIPTION

App::CPANPermission is

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
