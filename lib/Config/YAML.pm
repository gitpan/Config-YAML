package Config::YAML;

# $Id: YAML.pm 18 2004-10-01 19:46:51Z mdxi $

use warnings;
use strict;
use YAML;

=head1 NAME

Config::YAML - Simple configuration automation

=head1 Version

Version 1.0

=cut

our $VERSION = '1.0';

=head1 Synopsis

Config::YAML is a wrapper around the YAML module which makes reading
and writing configuration files simple. Handling multiple config files
(e.g. system and per-user, or a gallery app with per-directory
configuration) is a snap.

    use Config::YAML;

    # create Config::YAML object with any desired initial options
    # parameters; load system config; set alternate output file
    my $c = Config::YAML->new( config => "/usr/share/foo/globalconf",
                               output => "~/.foorc",
                               param1 => value1,
                               param2 => value2,
                               ...
                               paramN => valueN,
                             );

    # integrate user's own config
    $c->read("~/.foorc");

    # integrate command line args using Getopt::Long
    $rc = GetOptions ( $c,
                       'param1|p!',
                       'param2|P',
                       'paramN|n',
                     );

    # Write configuration state to disk
    $c->write;

    # simply get params back for use...
    do_something() unless $c->{param1};
    # or get them more OO-ly if that makes you feel better
    do_something_else() if $c->get('param2');

=cut




=head1 Methods

=head2 new

Creates a new Config::YAML object.

    my $c = Config::YAML->new( config => initial_config, 
                               output => <output_config>
                             );

The C<initial_config> argument is required, and specifies the file to
be read in during object creation. The C<output_config> file argument,
which specifies the file to write config data to, is optional and
defaults to the value of C<initial_config>.

For the sake of convenience, Config::YAML doesn't try to strictly
enforce its object-orientation. Values read from YAML files are stored
as values (scalar, arrayref, hashref) directly in the object hashref,
and are accessed as: C<< $c->{scalar} >> or C<< $c->{array}[idx] >> or
C<< $c->{hash}{key} >> (and so on down your data structure). 

By the same token, any desired configuration defaults can be passed as
arguments to the constructor.

    my $c = Config::YAML->new( config => "~/.foorc",
                               foo => "bar",
                               baz => "quux"
                             );

All internal state variables follow the C<_name> convention, so do
yourself a favor and don't make config variables with underscores as
their first character.

=cut

sub new {
    my ($class, %args) = @_;

    my $self = bless { _infile    => $args{config} || die("Can't create Config::YAML object with no config file.\n"),
                       _outfile   => $args{output} || $args{config},
                     }, $class;

    delete @args{qw(config output)};

    @{%{$self}}{keys %args} = values %args;

    $self->read;
    return $self;
}

=head2 get

Returns the value of a parameter

    print $c->get('foo');

Provided for people who are skeeved by treating an object as a plain
old hashref part of the time.

=cut

sub get {
    my ($self, $arg) = @_;
    return $self->{$arg};
}

=head2 set

Sets the value of a parameter

    print $c->set('foo',1);

Provided for people who are skeeved by treating an object as a plain
old hashref part of the time.

=cut

sub set {
    my ($self, $key, $val) = @_;
    $self->{$key} = $val;
}

=head2 fold

Provides a mechanism for the integration of configuration data from
any source...

    $c->fold(\%data);

...as long as it ends up in a hash.

=cut

sub fold {
    my ($self, $data) = @_;
    @{%{$self}}{keys %{$data}} = values %{$data};
}

=head2 read

Imports a YAML-formatted config file.

    $c->read('/usr/share/fooapp/fooconf');

C<read()> is called at object creation and imports the file specified
by the C<< new(config=>) >> parameter, so there is no need to call it
manually unless you have multiple config files.

=cut

sub read {
    my ($self, $file) = @_;
    $self->{_infile} = $file if $file;

    my $yaml;

    open(FH,'<',$self->{_infile}) or die "Can't open $self->{_infile}; $!\n";
    while (<FH>) {
        next if m/^\-{3,}/;
        next if m/^#/;
        next if m/^$/;
        $yaml .= $_;
    }
    close(FH);

    my $tmpyaml = Load($yaml);
    @{%{$self}}{keys %{$tmpyaml}} = values %{$tmpyaml}; # woo, hash slice
}

=head2 write

Dump current configuration state to a YAML-formatted flat file.

    $c->write;

=cut

sub write {
    my $self = shift;
    my %tmpyaml;

    # strip out internal state parameters
    while(my($k,$v) = each%{$self}) {
        $tmpyaml{$k} = $v unless ($k =~ /^_/);
    }

    # write data out to file
    open(FH,'>',$self->{_outfile}) or die "Can't open $self->{_outfile}: $!\n";
    print FH Dump(\%tmpyaml);
    close(FH);
}




=head2 TODO

The ability to delineate "system" and "user" level configuration,
enabling the output of write() to consist only of data from the user's
own init files and command line arguments might be nice.

=head1 Author

Shawn Boyette (C<< <mdxi@cpan.org> >>); original implementation by
Kirrily "Skud" Robert (as YAML::ConfigFile).

=head1 Bugs

=over

=item

Config::YAML ignores the YAML document separation string (C<--->)
because it has no concept of multiple targets for the data coming from
a config file.

=back

Please report any bugs or feature requests to
C<bug-yaml-configfile@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 Copyright & License

Copyright 2004 Shawn Boyette, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; # End of Config::YAML
