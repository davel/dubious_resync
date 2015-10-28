#!/usr/bin/perl
# vim:ts=4:shiftwidth=4:expandtab:

use strict;
use warnings;

open(my $raid_fh, "<", "/dev/md4") or die $!;
open(my $bad_fh, "<", "/dev/sdd1") or die $!;
open(my $old_fh, "<", "/dev/sdf1") or die $!;

my $last_read=-1;
my $last_read_buf;
my $ptr = 0;
my $block_size = 512;
my $bad_chunk;

while ($ptr<(1943748544*1024)) {
	sysseek($bad_fh, $ptr, 0) or die $!;
    if (sysread($bad_fh, my $bad_buf, $block_size)==$block_size) {
        if ($bad_chunk) {
            sysseek($raid_fh, $last_read, 0) or die $!;
            sysread($raid_fh, my $raid_last_good, $block_size)==$block_size or die "could not read from raid: $!";
            sysseek($old_fh, $last_read, 0) or die $!;
            sysread($old_fh, my $old_last_good, $block_size)==$block_size or die "could not read from old: $!";

            sysseek($raid_fh, $ptr, 0) or die $!;
            sysread($raid_fh, my $raid_next_good, $block_size)==$block_size or die "could not read from raid: $!";
            sysseek($old_fh, $ptr, 0) or die $!;
            sysread($old_fh, my $old_next_good, $block_size)==$block_size or die "could not read from old: $!";

            if ($last_read_buf eq $raid_last_good && $last_read_buf eq $old_last_good && $bad_buf eq $raid_next_good && $bad_buf eq $old_next_good) {
                print "Good to recover $last_read to $ptr\n";
            }
            else {
                print "Dubious to recover $last_read to $ptr\n";
            }
        }

        $bad_chunk = undef;
        $last_read = $ptr;
        $last_read_buf = $bad_buf;
    }
    else {
        print "At $ptr found $!\n";
        $bad_chunk = 1;
    }

    $ptr += $block_size;
}
