#!/usr/bin/perl

=head1 NAME

system-health-report

=head1 SYNOPSIS

system-health-report module

=head1 DESCRIPTION

Creates state health report of you PacketFence server

=cut

use strict;
use warnings;

use Term::ANSIColor;

=head1 SUBROUTINES

=over

=cut

=item * baseToolsCheck - Checks basic tools installation status

=cut

sub baseToolsCheck {
	# Base TOOLware list
	my @basetoolsList = ("ntp", "screen", "vim", "tcpdump", "nmap", "openldap-clients", "openssh-clients",
	"wget", "man", "lynx", "telnet", "git", "tig", "sysstat");
	
	foreach (@basetoolsList) {
		my $resultCmd;
		
		$resultCmd	= `rpm -q $_`;
		
	 	if ( $resultCmd =~ /is not installed/ ) {
			print color 'red';
			print $resultCmd;
		} else {
			print color 'reset';
			print $resultCmd;
		}
	}
}

=item * getIfaceList - List the interface directory to get interfaces list

=cut

sub getIfaceList {
	# list of available interface on system
	my $dir = '/etc/sysconfig/network-scripts/';
    my @ifaceList;

    opendir(DIR, $dir) or die $!;

	while (my $file = readdir(DIR)) {
		# Use a regular expression to ignore non network interface file
		next if ($file !~ m/^ifcfg-/) or ($file =~ m/^ifcfg-lo$/);
		push (@ifaceList, $dir.$file);
    }
	return @ifaceList;
}

=item * ifaceCheck - Checks basic configuration of network interfaces

=cut

sub ifaceCheck {
	my @ifaceList =	getIfaceList ();
	
	foreach (@ifaceList) {
		my $ifaceFile = $_;

		open(my $fh, "<", $ifaceFile)
			or die "cannot open < $ifaceFile: $!";
		foreach (my @lines = <$fh>) {
			if ($_ =~ /ONBOOT=YES/i) {
				print "$ifaceFile \n";
			}
		}
	}
	print color 'green';
	print "All interfaces clear \n";
	print color 'reset';
}

ifaceCheck ();
#baseToolsCheck ();
