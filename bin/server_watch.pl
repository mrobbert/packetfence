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

 weekly
 rotate 52
 missingok
 compress
 delaycompress
 su pf pf
 copytruncate

=cut

sub logrotateCheck {
	my $logrotateFile = '/etc/logrotate.d/packetfence';
	#my ($copytruncate,$weekly,$daily,$rotation,$delaycompress);
	
	open(my $fh, "<", $logrotateFile)
		or die "cannot open < $logrotateFile: $!";
	my @lines = <$fh>;
	foreach (@lines) {
		my $line = $_;
		if ($line =~ /weekly/i) {
			print color 'blue';
			print "The rotation time unit is: weekly \n";
	        print color 'reset';
		}
		if ($line =~ /daily/i) {
			print color 'blue';
			print "The rotation time unit is daily \n";
	        print color 'reset';
		}
		if ($line =~ /rotate ([0-9].*)/i) {
			my $rotate = $1;
			print color 'blue';
			print "The rotation happens each $rotate rotation time unit \n";
	        print color 'reset';
		}
		if ($line =~ /delaycompress/i) {
			print color 'red';
	        print "Your backlog will wait 1 rotation before be compressed ! \n";
	        print color 'reset';
		}
		if ($line =~ /copytruncate/i) {
			print color 'green';
			print "Copytruncate is enable \n";
			print color 'reset';
		}
	}
}

=item * startupServices - Check of PacketFence required service are right set up
chkconfig --list | egrep "iptables|ntpd |drbd|mysqld|corosync|pacemaker|smb|winbind|memcached|crond|monit|packetfence "
corosync        0:off   1:off   2:on    3:on    4:on    5:on    6:off
crond           0:off   1:off   2:on    3:on    4:on    5:on    6:off
drbd            0:off   1:off   2:off   3:off   4:off   5:off   6:off
iptables        0:off   1:off   2:off   3:off   4:off   5:off   6:off
memcached       0:off   1:off   2:off   3:off   4:off   5:off   6:off
monit           0:off   1:off   2:off   3:off   4:off   5:off   6:off
mysqld          0:off   1:off   2:off   3:off   4:off   5:off   6:off
ntpd            0:off   1:off   2:on    3:on    4:on    5:on    6:off
monit           0:off   1:off   2:off   3:off   4:off   5:off   6:off
packetfence     0:off   1:off   2:off   3:off   4:off   5:off   6:off
smb             0:off   1:off   2:off   3:on    4:on    5:on    6:off
winbind         0:off   1:off   2:off   3:on    4:on    5:on    6:off
=cut

sub startupServices {
	my ($resultCmd, @services, @lines);
	@services=("iptables", "ntpd", "drbd", "mysqld", "corosync", "pacemaker", "smb", "winbind", "memcached", "crond", "monit", "packetfence");
	$resultCmd  = `chkconfig --list`;
	@lines = split(/^/m, $resultCmd);
	
	foreach (@lines) {
		my $line = $_;
		f
	}
	if ($resultCmd =~ /corosync/mi) {
		print color 'green';
		print "The rotation time unit is: weekly \n";
		print color 'reset';
	}
}

=item * vmtoolsCheck - Checks if the server is a VM and if the vmtools are installed and running.

=cut

sub vmtoolsCheck {

}


#### Run sub
#baseToolsCheck ();
#ifaceCheck ();
#logrotateCheck();
startupServices ();
#vmtoolsCheck ();
