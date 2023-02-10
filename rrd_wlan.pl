#!/usr/bin/perl
#
# copyright Martin Pot 2003-2005
# http://martybugs.net/wireless/rrdtool/
#
# rrd_wlan.pl

use RRDs;

# define location of rrdtool databases
my $rrd = '/var/lib/rrd';
# define location of images
my $img = '/var/www/html/rrdtool';

# process data for each interface (add/delete as required)
# Lembre se de dá permissão de escrita na /var/www/html
# Lembre se de dá permissão de escrita na /var/lib/rrd
# 	sudo chmod a+w $PASTA
&ProcessInterface("wlan0", "CsF tp1 link");

sub ProcessInterface
{
# process wireless interface
# inputs: $_[0]: interface name (ie, eth0/eth1/eth2)
#         $_[1]: interface description

	# get wireless link details
	my $snr = `iwconfig $_[0]|grep Quality|cut -d"=" -f2|cut -d"/" -f1`;
	my $signal = `iwconfig $_[0]|grep Signal|cut -d":" -f2| cut -d "=" -f3 | cut -d " " -f1`;
	#my $noise = `iwconfig $_[0]|grep Signal|cut -d":" -f3|cut -d" " -f1`;
	my $noise = -256;
	#my $rate = `iwconfig $_[0]|grep Rate|cut -d"M" -f1|cut -d"=" -f2`;
	my $rate = `iwconfig $_[0]|grep Rate|cut -d"M" -f1|cut -b20-23`;

	# remove eol chars
	chomp($snr);
	chomp($signal);
	chomp($noise);
	chomp($rate);
	# chop off any trailing spaces
	$rate =~ s/ //g;

	print "$snr\n";
	print "$signal\n";
	print "$noise\n";
	print "$rate\n";

	print "$_[0] link stats: snr: $snr dB, signal: $signal dBm, noise: $noise dBm, rate: $rate Mbits/s\n";

	# if rrdtool database doesn't exist, create it
	if (! -e "$rrd/w$_[0].rrd")
	{
		print "creating rrd database for $_[0] interface...\n";
		RRDs::create "$rrd/w$_[0].rrd",
			"DS:snr:GAUGE:600:0:60",
			"DS:signal:GAUGE:600:-256:0",
			"DS:noise:GAUGE:600:-256:0",
			"DS:rate:GAUGE:600:0:100",
			"RRA:AVERAGE:0.5:1:576",
			"RRA:AVERAGE:0.5:6:672",
			"RRA:AVERAGE:0.5:24:732",
			"RRA:AVERAGE:0.5:144:1460";
		if ($ERROR = RRDs::error) { print "$0: failed to create rrd: $ERROR\n"; }
	}

	# insert values into rrd
	print "updating...\n";
	RRDs::update "$rrd/w$_[0].rrd",
		"-t", "snr:signal:noise:rate",
		"N:$snr:$signal:$noise:$rate";
	if ($ERROR = RRDs::error) { print "$0: failed to insert data into rrd: $ERROR\n"; }

	# create traffic graphs
	&CreateGraphs($_[0], "day", $_[1]);
	&CreateGraphs($_[0], "week", $_[1]);
	&CreateGraphs($_[0], "month", $_[1]);
	&CreateGraphs($_[0], "year", $_[1]);
}

sub CreateGraphs
{
# creates graph
# inputs: $_[0]: interface name (ie, eth0/eth1/eth2/ppp0)
#         $_[1]: interval (ie, day, week, month, year)
#         $_[2]: interface description

	# generate SNR graph
	RRDs::graph "$img/$_[0]-snr-$_[1].png",
		"-s -1$_[1]",
		"-t", "SNR :: $_[0] $_[2]",
		"-h", "80", "-w", "600",
		"-a", "PNG",
		"-y", "1:2",
		"-v", "dB",
		"-l", "0",
		"DEF:snr=$rrd/w$_[0].rrd:snr:AVERAGE",
		"LINE2:snr#0000FF:SNR",
		"GPRINT:snr:MIN:     Min\\: %2lf",
		"GPRINT:snr:MAX: Max\\: %2lf",
		"GPRINT:snr:AVERAGE: Avg\\: %4lf",
		"GPRINT:snr:LAST: Current\\: %2lf dB\\n";
	if ($ERROR = RRDs::error) { print "$0: unable to generate SNR graph: $ERROR\n"; }

	# generate signal/noise graph
	RRDs::graph "$img/$_[0]-sig-$_[1].png",
		"-s -1$_[1]",
		"-t", "Signal & Noise :: $_[0] $_[2]",
		"-h", "80", "-w", "600",
		"-a", "PNG",
		"-y", "2:2",
		"-v", "dBm",
		"DEF:signal=$rrd/w$_[0].rrd:signal:AVERAGE",
		"DEF:noise=$rrd/w$_[0].rrd:noise:AVERAGE",
		"LINE2:signal#11EE11:Signal",
		"GPRINT:signal:MIN:  Min\\: %4lf",
		"GPRINT:signal:MAX: Max\\: %4lf",
		"GPRINT:signal:AVERAGE: Avg\\: %6lf",
		"GPRINT:signal:LAST: Current\\: %4lf dBm\\n",
		"LINE2:noise#FF0000:Noise",
		"GPRINT:noise:MIN:   Min\\: %4lf",
		"GPRINT:noise:MAX: Max\\: %4lf",
		"GPRINT:noise:AVERAGE: Avg\\: %6lf",
		"GPRINT:noise:LAST: Current\\: %4lf dBm\\n";
	if ($ERROR = RRDs::error) { print "$0: unable to generate signal/noise graph: $ERROR\n"; }

	# generate link rate graph
	RRDs::graph "$img/$_[0]-rate-$_[1].png",
		"-s -1$_[1]",
		"-t", "Link Rate :: $_[0] $_[2]",
		"-h", "80", "-w", "600",
		"-a", "PNG",
		"-y", "2:1",
		"-l", "0", "-u", "12", "--rigid",
		"-v", "Mbits/s",
		"DEF:rate=$rrd/w$_[0].rrd:rate:AVERAGE",
		"LINE2:rate#0000FF:Link Rate",
		"GPRINT:rate:MIN:  Min\\: %4.1lf",
		"GPRINT:rate:MAX: Max\\: %4.1lf",
		"GPRINT:rate:AVERAGE: Avg\\: %4.1lf",
		"GPRINT:rate:LAST: Current\\: %4.1lf Mbits/s\\n";
	if ($ERROR = RRDs::error) { print "$0: unable to generate link rate graph: $ERROR\n"; }
}
