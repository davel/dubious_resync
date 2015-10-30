#!/usr/bin/perl
# vim:ts=4:shiftwidth=4:expandtab:

use strict;
use warnings;

open(my $raid_fh, "<", "/dev/md4") or die $!;
open(my $bad_fh, "<", "/dev/sdd1") or die $!;
open(my $old_fh, "<", "/dev/sdf1") or die $!;

my $block_size = 4096;
while (my $line = <>) {
    if ($line =~ /(\d+) to (\d+)/) {
        my ($last_good, $next_good) = ($1, $2);
        my $bad_blocks = $next_good-$last_good-$block_size;
        print "last_good=$last_good, next_good=$next_good, blocks=$bad_blocks\n";
        sysseek($raid_fh, $last_good+4096, 0) or die $!;
        sysseek($old_fh, $last_good+4096, 0) or die $!;

        sysread($raid_fh, my $raid_dump, $bad_blocks)==$bad_blocks or die "flailed read: $!";
        sysread($old_fh,  my $old_dump, $bad_blocks)==$bad_blocks or die "flailed read: $!";
        if ($raid_dump eq $old_dump) {
            print "No need for action: $line";
        }
        else {
            print "Still dubious: $line";
        }
    }
}


