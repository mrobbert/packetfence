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
		my $onbootIface;

		open(my $fh, "<", $ifaceFile)
			or die "cannot open < $ifaceFile: $!";
		foreach (my @lines = <$fh>) {
			if ($_ =~ /ONBOOT=YES/im) {
				$onbootIface = 1;	
			}
		}
		if (defined ($onbootIface) && $onbootIface == 1) {
			print color 'green';
			print "Interface $ifaceFile OK \n";
			print color 'reset';
		} else {
			print color 'red';
            print "Interface $ifaceFile not started on boot \n";
            print color 'reset';
		}
	}
}


=item * logrotateCheck - Checks PacketFence lograte configuration 

=cut

sub logrotateCheck {
	my $logrotateFile = '/etc/logrotate.d/packetfence';
	my ($copytruncate,$weekly,$daily,$rotation,$delaycompress);

	open(my $fh, "<", $logrotateFile)
		or die "cannot open < $logrotateFile: $!";
	foreach (my @lines = <$fh>) {
		print $_;
		if ($_ =~ /weekly/im) {
			print color 'blue';
			print $_;
	        print color 'reset';
		}
		if ($_ =~ /daily/im) {
			print color 'blue';
			print $_;
	        print color 'reset';
		}
		if ($_ =~ /rotate/im) {
			print color 'blue';
			print $_;
	        print color 'reset';
		}
		if ($_ =~ /delaycompress/im) {
			print color 'red';
	        print "Your backlog will wait 1 rotation before be compressed ! \n";
	        print color 'reset';
		} else {
			print color 'green';
			print "Delaycompress is disable\n";
			print color 'reset';
		}
		if ($_ =~ /copytruncate/im) {
			print color 'green';
			print "Copytruncate is enable\n";
			print color 'reset';
			last;
		} else {
			print color 'red';
			print "Copytruncate is disable !";
			print color 'reset';
			last;
		}
	}
}

logrotateCheck();
#ifaceCheck ();
#baseToolsCheck ();
