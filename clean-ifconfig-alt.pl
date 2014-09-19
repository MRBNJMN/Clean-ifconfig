#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: clean-ifconfig.pl
#
#        USAGE: ./clean-ifconfig.pl  
#
#  DESCRIPTION: Parser for Unix ifconfig output
#
#      OPTIONS: -e
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Ben Wheeler, bwheeler@altair.com
# ORGANIZATION: 
#      VERSION: 0.9.0
#      CREATED: 14-09-16 02:46:29 PM
#     REVISION: ---
#===============================================================================

use 5.010;
use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;

# -e will be used to display "extended" information that's not typically useful
my $extended = '';
my $help = '';
GetOptions ('e|extended' => \$extended, 'h|help' => \$help);

pod2usage( -verbose => 1 ) if $help;

open my $ifconfig_fh, '-|', 'ifconfig' or die "Cannot pipe from ifconfig: $!"; # Filehandle to read the ifconfig process

my %devices;
my $deviceName;

# Data capture and storage
while (<$ifconfig_fh>) {
	if (/(?<deviceName>^\w+)/) { $deviceName = $+{deviceName}; }	
	if (/Link encap:(?<frameType>Ethernet|Local Loopback)/) { $devices{$deviceName}->{"Frame Type"} = $+{frameType}; } # Frame type (allows Ethernet or Local Loopback)
	if (/HWaddr (?<mac>\w+\:\w+\:\w+\:\w+\:\w+\:\w+)/) { $devices{$deviceName}->{"MAC Address"} = $+{mac}; } # MAC address
	if (/inet addr:(?<ipv4>\d+\.\d+\.\d+\.\d+)/) { $devices{$deviceName}->{"IPv4 Address"} = $+{ipv4}; } # IPv4 address
	if (/Bcast:(?<bcast>\d+\.\d+\.\d+\.\d+)/) { $devices{$deviceName}->{"Broadcast Address"} = $+{bcast}; } # Broadcast Address
	if (/Mask:(?<mask>\d+\.\d+\.\d+\.\d+)/) { $devices{$deviceName}->{"Network Mask"} = $+{mask}; } # Network Mask
	if (/inet6 addr: (?<ipv6>[a-z0-9:\/]+)/) { $devices{$deviceName}->{"IPv6 Address"} = $+{ipv6}; } # IPv6 Address
	if (/Scope:(?<scope>\w+)/) { $devices{$deviceName}->{"Scope"} = $+{scope}; } # Interface scope
	if (/\s+(?<statusFlags>(\w.+?))  MTU/) { $devices{$deviceName}->{"Status Flags"} = $+{statusFlags}; } # Status flags (ON, RUNNING, LOOPBACK, BROADCAST, MULTICAST, NOTRAILERS)
	if (/MTU:(?<mtu>\d+)/ && $extended)  { $devices{$deviceName}->{"MTU"} = $+{mtu}; } # Maximum Transmission Unit
	if (/Metric:(?<metric>\d+)/ && $extended)  { $devices{$deviceName}->{"Metric"} = $+{metric}; } # Metric
	if (/RX packets:(?<rxPackets>\d+) errors:(?<rxErrors>\d+) dropped:(?<rxDropped>\d+) overruns:(?<rxOverruns>\d+) frame:(?<rxFrame>\d+)/ && $extended) { 
		$devices{$deviceName}->{"RX Packets"} = $+{rxPackets}; # RX Packets
		$devices{$deviceName}->{"RX Errors"} = $+{rxErrors}; # RX Errors
		$devices{$deviceName}->{"RX Dropped"} = $+{rxDropped}; # RX Dropped
		$devices{$deviceName}->{"RX Overruns"} = $+{rxOverruns}; # RX Overruns
		$devices{$deviceName}->{"RX Frame"} = $+{rxFrame}; # RX Frame
	}
	if (/TX packets:(?<txPackets>\d+) errors:(?<txErrors>\d+) dropped:(?<txDropped>\d+) overruns:(?<txOverruns>\d+) carrier:(?<txCarrier>\d+)/ && $extended) { 
		$devices{$deviceName}->{"TX Packets"} = $+{txPackets}; # TX Packets
		$devices{$deviceName}->{"TX Errors"} = $+{txErrors}; # TX Errors
		$devices{$deviceName}->{"TX Dropped"} = $+{txDropped}; # TX Dropped
		$devices{$deviceName}->{"TX Overruns"} = $+{txOverruns}; # TX Overruns
		$devices{$deviceName}->{"TX Carrier"} = $+{txCarrier}; # TX Carrier
	}
	if (/collisions:(?<txCollisions>\d+) txqueuelen:(?<txQueue>\d+)/ && $extended) {
		$devices{$deviceName}->{"TX Collisions"} = $+{txCollisions}; # TX Collisions
		$devices{$deviceName}->{"TX Queue Length"} = $+{txQueue}; # TX Queue Length
	}
	if (/RX bytes:(?<rxBytes>[0-9]+) \((?<rxFormatted>[0-9\.]+ .?B)\)\s+TX bytes:(?<txBytes>[0-9]+) \((?<txFormatted>[0-9\.]+ .?B)\)/) {
		$devices{$deviceName}->{"RX Bytes"} = $+{rxBytes}; # RX byte value
		$devices{$deviceName}->{"RX Formatted"} = $+{rxFormatted}; # RX byte value formatted
		$devices{$deviceName}->{"TX Bytes"} = $+{txBytes}; # TX byte value
		$devices{$deviceName}->{"TX Formatted"} = $+{txFormatted}; # TX byte value formatted
	}
	if (/Interrupt:(?<interrupt>[0-9]+)/ && $extended) { $devices{$deviceName}->{"Interrupt"} = $+{interrupt}; } # IRQ value
	if (/Base address:(?<baseAddress>[0-9x]+)/ && $extended) { $devices{$deviceName}->{"Base Address"} = $+{baseAddress}; } # Base address
}

print "\n";

# Array iteration
for my $href (sort byRXdesc keys %devices) { # Processes each device one at a time
	# Status flag display. This will allow for status flags to be displayed with no line breaks in between, regardless of which are present
	my @status; # Holds all status flag messages
	
	my $s0; # UP and RUNNING
    $s0 = "Interface is ";
	$s0 .= "NOT " if ($devices{$href}->{"Status Flags"} !~ "UP"); # Add NOT if the interface is not UP
	$s0 .= "UP";
	$s0 .= " and RUNNING" if ($devices{$href}->{"Status Flags"} =~ "RUNNING"); # Add "and RUNNING" if the interface is active
	push @status, $s0;

	my $s1; # LOOPBACK
	if ($devices{$href}->{"Status Flags"} =~ "LOOPBACK") {
		$s1 = "Interface operates in LOOPBACK";
		push @status, $s1;
	}

	my $s2; # BROADCAST
	if ($devices{$href}->{"Status Flags"} =~ "BROADCAST") {
		$s2 = "Interface handles BROADCAST packets";
		push @status, $s2;
	}

	my $s3; # MULTICAST
	if ($devices{$href}->{"Status Flags"} =~ "MULTICAST") {
		$s3 = "Interface handles MULTICAST packets";
		push @status, $s3;
	}
	
	my $s4; # NOTRAILERS
	if ($devices{$href}->{"Status Flags"} =~ "NOTRAILERS") {
		$s4 = "Interface operates with NOTRAILERS";
		push @status, $s4;
	}
	
	# Device and parameter printing. Defaults to "Not Defined" if not present
	print "* * * * * * * * * * * * * * * * * * * * * * $href ($devices{$href}->{'Frame Type'}) * * * * * * * * * * * * * * * * * * * * * *\n"; # Device name and type
	printf "  IPv4 Address:\t\t%-40s$status[0]\n", $devices{$href}->{'IPv4 Address'} // "Not Defined"; # IPv4 address, followed by first status message
	printf "  IPv6 Address:\t\t%-40s", $devices{$href}->{'IPv6 Address'} // "Not Defined"; # IPv6 address...
	if ($status[1]) { print "$status[1]\n"; } else { print "\n"; } # ...followed by second status message (if present)
	printf "  Broadcast Address:\t%-40s", $devices{$href}->{'Broadcast Address'} // "Not Defined"; # Broadcast address...
	if ($status[2]) { print "$status[2]\n"; } else { print "\n"; } # ...followed by third status message (if present)
	printf "  Network Mask:\t\t%-40s", $devices{$href}->{'Network Mask'} // "Not Defined"; # Network mask...
	if ($status[3]) { print "$status[3]\n"; } else { print "\n"; } # ...followed by fourth status message (if present)
	printf "  MAC Address:\t\t%-40s", $devices{$href}->{'MAC Address'} // "Not Defined"; # MAC address...
	if ($status[4]) { print "$status[4]\n"; } else { print "\n"; } # ...followed by fifth status message (if present)
	printf "  MTU:\t\t\t%-40s\n", $devices{$href}->{'MTU'} // "Not Defined" if $extended; # Maximum transmission unit (extended only)
	printf "  Scope:\t\t%-40s\n", $devices{$href}->{'Scope'} // "Not Defined" if $extended; # Scope (extended only)
	printf "  Metric:\t\t%-40s\n", $devices{$href}->{'Metric'} // "Not Defined" if $extended; # Metric (extended only)
	printf "  IRQ Value:\t\t%-40s\n", $devices{$href}->{'Interrupt'} // "Not Defined" if $extended; # IRQ (extended only)
	printf "  Base Address:\t\t%-40s\n", $devices{$href}->{'baseAddress'} // "Not Defined" if $extended; # Base address (extended only)
	print "\n";
	# RX and TX values are displayed side-by-side
	printf "  RX Bytes:\t\t%-40s", $devices{$href}->{'RX Bytes'} . " ($devices{$href}->{'RX Formatted'})" // "Not Defined"; # RX bytes and formatted total
	printf "TX Bytes:\t\t%s\n", $devices{$href}->{'TX Bytes'} . " ($devices{$href}->{'TX Formatted'})" // "Not Defined"; # TX bytes and formatted total
	printf "     Packets:\t\t%-40s", $devices{$href}->{'RX Packets'} // "Not Defined" if $extended; # RX packets (extended only)
	printf "   Packets:\t\t%s\n", $devices{$href}->{'TX Packets'} // "Not Defined" if $extended; # TX packets (extended only)
	printf "     Errors:\t\t%-40s", $devices{$href}->{'RX Errors'} // "Not Defined" if $extended; # RX errors (extended only)
	printf "   Errors:\t\t%s\n", $devices{$href}->{'TX Errors'} // "Not Defined" if $extended; # TX errors (extended only)
	printf "     Dropped:\t\t%-40s", $devices{$href}->{'RX Dropped'} // "Not Defined" if $extended; # RX dropped (extended only)
	printf "   Dropped:\t\t%s\n", $devices{$href}->{'TX Dropped'} // "Not Defined" if $extended; # TX dropped (extended only)
	printf "     Overruns:\t\t%-40s", $devices{$href}->{'RX Overruns'} // "Not Defined" if $extended; # RX overruns (extended only)
	printf "   Overruns:\t\t%s\n", $devices{$href}->{'TX Overruns'} // "Not Defined" if $extended; # TX overruns (extended only)
	printf "     Frame:\t\t%-40s", $devices{$href}->{'RX Frame'} // "Not Defined" if $extended; # RX frame (extended only)
	printf "   Carrier:\t\t%s\n", $devices{$href}->{'TX Carrier'} // "Not Defined" if $extended; # TX carrier (extended only)
	printf "\t\t\t\t\t\t\t\t" if $extended; # Tabs to line up with TX
	printf "   Collisions:\t\t%s\n", $devices{$href}->{'TX Collisions'} // "Not Defined" if $extended; # TX collisions (extended only)
	printf "\t\t\t\t\t\t\t\t" if $extended; # Tabs to line up with TX
	printf "   Queue Length:\t%s\n", $devices{$href}->{'TX Queue Length'} // "Not Defined" if $extended; # TX queue length (extended only)
	print "\n";
}

# Set a sort method to sort by RX Bytes (desc) and sort @devices
sub byRXdesc { ($devices{$b}->{"RX Bytes"} <=> $devices{$a}->{"RX Bytes"}) }

__END__

=head1 USAGE

  ./clean-ifconfig.pl [OPTION]

=head1 OPTIONS

  -e, --extended	Display extended output 
  -h, --help		Display help


