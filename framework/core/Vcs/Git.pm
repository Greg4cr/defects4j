#-------------------------------------------------------------------------------
# Copyright (c) 2014-2015 René Just, Darioush Jalali, and Defects4J contributors.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#-------------------------------------------------------------------------------

=pod

=head1 NAME

Vcs/Git.pm -- Concrete Vcs instance for Git.

=head1 DESCRIPTION

This module provides all specific configurations and methods for the Git Vcs.

=cut
package Vcs::Git;

use warnings;
use strict;
use Vcs;
use Constants;

our @ISA = qw(Vcs);

sub _checkout_cmd {
    @_ == 3 or die $ARG_ERROR;
    my ($self, $revision, $work_dir) = @_;
    return "git clone $self->{repo} ${work_dir} 2>&1 && cd $work_dir && git checkout $revision 2>&1";
}

sub _apply_cmd {
    @_ >= 3 or die $ARG_ERROR;
    my ($self, $work_dir, $patch_file, $path) = @_;
    # Path to patch directory within the working directory
    $path = $path // ".";
    return "git --work-tree=$work_dir apply --unsafe-paths --directory=$work_dir/$path $patch_file 2>&1";
}

sub _diff_cmd {
    @_ >= 3 or die $ARG_ERROR;
    my ($self, $rev1, $rev2, $path) = @_;
    $path = defined $path ? ":$path" : "";
    return "git --git-dir=$self->{repo} diff ${rev1}$path ${rev2}$path";
}

# This helps define whether rev2 comes after another rev1
sub comes_before {
    @_ == 3 or die $ARG_ERROR;
    my ($self, $rev1, $rev2) = @_;
    my $log = `git --git-dir=$self->{repo} log -n 1 ${rev1}^..${rev2}`;
    die unless $? == 0;
    return $log eq '' ? 0 : 1;
}


1;

=pod

=head1 SEE ALSO

F<Vcs.pm>

=cut

