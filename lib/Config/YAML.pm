package Config::YAML;

# $Id: YAML.pm 28 2004-11-15 01:53:05Z mdxi $

use warnings;
use strict;
use YAML;

=head1 NAME

Config::YAML - Simple configuration automation

=head1 VERSION

Version 1.28

=cut

our $VERSION = '1.28';

=head1 SYNOPSIS

Config::YAML is a somewhat object-oriented wrapper around the YAML
module which makes reading and writing configuration files
simple. Handling multiple config files (e.g. system and per-user, or a
gallery app with per-directory configuration) is a snap.

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




=head1 METHODS

=head2 new

Creates a new Config::YAML object.

    my $c = Config::YAML->new( config => initial_config, 
                               output => output_config
                             );

The C<config> parameter is required, and must be the first parameter
given. It specifies the file to be read in during object creation. If
the second parameter is C<output>, then it is used to specify the file
to which configuration data will later be written out.  This
positional dependancy makes it possible to have another C<config>
and/or C<output> parameter passed to the constructor, which will
receive no special treatment.

Initial configuration values can be passed as parameters to the
constructor:

    my $c = Config::YAML->new( config => "~/.foorc",
                               foo    => "abc",
                               bar    => "xyz",
                               baz    => [ 1, 2, 3 ],
                             );

All internal state variables follow the C<_name> convention, so do
yourself a favor and don't pass parameters with underscores as their
first character.

=cut

sub new {
    my $class = shift;
    my %priv  = ();
    my %args  = ();

    die("Can't create Config::YAML object with no config file.\n") if ($_[0] ne "config");
    shift; $priv{config} = shift;
    if (@_ && ($_[0] eq "output")) { shift; $priv{output} = shift; }

    my $self = bless { _infile    => $priv{config},
                       _outfile   => $priv{output}   || $priv{config},
                     }, $class;

    %args = @_;
    @{%{$self}}{keys %args} = values %args;

    $self->read;
    return $self;
}

=head2 get

For the sake of convenience, Config::YAML doesn't try to strictly
enforce its object-orientation. Values read from YAML files are stored
as parameters directly in the object hashref, and are accessed as

    $c->{scalar}
    $c->{array}[idx]
    $c->{hash}{key}

and so on down your data structure. 

However, the method C<get> is provided for people who are skeeved by
treating an object as a plain old hashref part of the time.

C<get> returns the value of a parameter

    print $c->get('foo');

If the parameter requested is something other than a scalar, a
reference to it will be returned.

=cut

sub get {
    my ($self, $arg) = @_;
    return $self->{$arg};
}

=head2 set

Also provided is a C<set> method, which can be used to set the value
of a single parameter:

    $c->set('foo',1);
    $c->set('bar',"While I pondered, weak and weary...");

    my @paints = qw( oil acrylic tempera );
    $c->set('paints', \@paints);

=cut

sub set {
    my ($self, $key, $val) = @_;
    $self->{$key} = $val;
}

=head2 fold

The C<fold> method provides a mechanism for the integration of
configuration data from any source...

    $c->fold(\%data);

...as long as it's been previously munged into a hash.

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

The file to be written is specified in the constructor call. See the
C<new> method documentation for details.

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




=head1 AUTHOR

Shawn Boyette (C<< <mdxi@cpan.org> >>)

Original implementation by Kirrily "Skud" Robert (as
C<YAML::ConfigFile>).

=head1 TODO

=over

=item

Builtin parameter type/value checking would be cool.

=item

The ability to delineate "system" and "user" level configuration,
enabling the output of C<write> to consist only of data from the user's
own init files and command line arguments might be nice.

=back

=head1 BUGS

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

=head1 COPYRIGHT & LICENSE

Copyright 2004 Shawn Boyette, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; # End of Config::YAML
