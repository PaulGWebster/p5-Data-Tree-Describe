package Data::Tree::Describe;

=head1 NAME

Data::Tree::Describe - Create annotated versions of complex data trees

=head1 WARNING

This module is in active development and has been uploaded simply as part of a 
standard and automated release procedure.

If you have any ideas for what would be helpful to implement, please contact the 
author!

=head1 SYNOPSIS

=for comment Small howto

    use Data::Tree::Describe;

    my $data_object = {test=>['some','stuff']};

    my $described_tree = Data::Tree::Describe->new($data_object);

=head1 DESCRIPTION

=for comment The module's description.

This module was originally developed for data trees or objects created from 
json::maybexs, though it technically will work on any perl data tree.

The module is fairly heavy processing wise and recursively iterates through a 
tree determining the type for every node as well as other handy attributes such
as how many children are in any HASH or ARRAY type. 

=cut

# Internal perl
use v5.30.0;
use feature 'say';

# Internal perl modules (core)
use strict;
use warnings;

# Internal perl modules (core,recommended)
use utf8;
use open qw(:std :utf8);
use experimental qw(signatures);

# External modules
use Carp qw(cluck longmess shortmess);

# Version of this software
our $VERSION = '0.004';

# Primary code block
sub new($class,$input = {}) {

    my $self = bless {
        source  =>  $input,
        paths   =>  []
    }, $class;

    $self->{tree} = $self->describe_node($input);

    return $self; 
}

sub describe_node($self,$tree,$stash = {}) {
    my $type    =   ref($tree) ? ref($tree) : 'ELEMENT';

    my @json_path       =   ();
    if ($stash->{path}) {
        @json_path  =   @{delete $stash->{path}};
    }

    # Handle booleans more nicely, I imagine there are more of these to deal with
    if ($type eq 'JSON::PP::Boolean')   { 
        $type = 'BOOLEAN';
    }

    if      ($type eq 'HASH')   {
        $stash->{_count}    =   scalar(keys %{$tree});
        foreach my $child (keys %{$tree})   { 
            my @passed_path             =   (@json_path,$child);
            $stash->{_data}->{$child}   =
                $self->describe_node($tree->{$child},{ path=>[@passed_path] });
        }
    }
    elsif   ($type eq 'ARRAY')  {
        my $index = 0;
        $stash->{_count}    =   scalar(@{$tree});
        foreach my $child (@{$tree})        {
            my @passed_path             =   (@json_path,$index++);
            # You can have unnamed HASH elements within an ARRAY
            # For this we will change the hash-memory-reference to simply HASH
            if (ref($child) eq 'HASH') {
                $stash->{_data}->{HASH}     =
                    $self->describe_node($child,{ path=>[@passed_path] });
            }
            else {
                $stash->{_data}->{$child}   =
                    $self->describe_node($child,{ path=>[@passed_path] });
            }
        }
    }

    $stash->{_type}     =   $type;
    $stash->{_key}      =   $json_path[-1];
    $stash->{_path}     =   [@json_path];

    push(@{$self->{paths}},[$stash->{_path},$type]);

    return $stash;
}


=head1 CORROSPONDANCE

Regarding bugs, featuire requests, patches, forks or other please view 
the project on github here L<https://github.com/PaulGWebster/p5-Data-Tree-Describe>

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
