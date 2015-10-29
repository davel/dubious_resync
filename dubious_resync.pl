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
my $block_size = 4096;
my $bad_chunk;

while ($ptr<(1943748544*1024)) {
    sysseek($bad_fh, $ptr, 0) or die $!;
    if (sysread($bad_fh, my $bad_buf, $block_size)==$block_size) {
        if ($bad_chunk) {
            # Read unreadable chunk along with the blocks either side.
            my $chunk_from_old = $ptr-$last_read+$block_size;
            print "$chunk_from_old $ptr $block_size\n";

            sysseek($raid_fh, $last_read, 0) or die $!;
            sysread($raid_fh, my $raid_chunk, $chunk_from_old)==$chunk_from_old or die "could not read from raid: $!";
            sysseek($old_fh,  $last_read, 0) or die $!;
            sysread($old_fh, my $old_chunk,   $chunk_from_old)==$chunk_from_old or die "could not read from old: $!";

            if ($raid_chunk eq $old_chunk) {
                print "Chunk from $last_read to $ptr on raid matches old, no need to fix?\n";
	    }
            elsif ($last_read_buf eq substr($raid_chunk, 0, $block_size) && $last_read_buf eq substr($old_chunk, 0, $block_size) && $bad_buf eq substr($raid_chunk, -$block_size, $block_size) && $bad_buf eq substr($old_chunk, -$block_size, $block_size)) {
                if (substr($raid_chunk, $block_size, $chunk_from_old-$block_size*2) eq ("\x00" x ($chunk_from_old-$block_size*2))) {
                    print "Good to recover $last_read to $ptr\n";
                }
                else {
                    print "Appears to have been written to: $last_read to $ptr\n";
                }
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
