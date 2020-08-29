#!/usr/bin/perl -w

##	This program is free software: you can redistribute it and/or modify
##	it under the terms of the GNU General Public License as published by
##	the Free Software Foundation, either version 3 of the License, or
##	(at your option) any later version.
##
##	This program is distributed in the hope that it will be useful,
##	but WITHOUT ANY WARRANTY; without even the implied warranty of
##	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##	GNU General Public License for more details.
##
##	You should have received a copy of the GNU General Public License
##	along with check_bacula.pl.  If not, see <http://www.gnu.org/licenses/>.

# Submitted:
# Julian Hein			NETWAYS GmbH
# Managing Director		Deutschherrnstr. 47a
# Fon.0911/92885-0		D-90429 Nürnberg
# Fax.0911/92885-31					
# jhein@netways.de		www.netways.de	

# Modified:
# Silver Salonen <silver@serverock.ee>

# version 0.3 (07.Feb.2013)
# * if required job count is 1 and the job is still running, issue warning instead of critical
# * move quering SQL into subroutine 'sql_exec'

# version 0.2 (21.Jan.2013)
# * implement checking error of BeforeJob and AfterJob from job log

# version 0.1 (16.Jan.2013)
# * implement checking total number of jobs' errors

# version 0.0.3 (07.May.2007)
# * fix typo 'successfull' -> 'successful'
# * add $sqlUsername and $sqlDB variables

# version 0.0.2 (05.May.2006)
# * implement print_usage()
# * implement print_help()
# * add variable $sqlPassword for setting MySQL-password
# * add variable $progVers for showing it in case of -V

use strict;
use POSIX;
use File::Basename;
use DBI;
use Getopt::Long;
use Config::Simple;
use vars qw(
	$opt_help
	$opt_job
	$opt_critical
	$opt_warning
	$opt_hours
	$opt_errors
	$opt_before
	$opt_after
	$opt_usage
	$opt_version
	$opt_running
	$out
	$sql_query
	$date_start
	$date_stop
	$state
	$count
	$errors
	$jobid
	$joblog
	$files
	$size
	$sampleFile
	$sampleJobId
	$msg
	$dbh
	$sth
);
		
sub print_help();
sub print_usage();
sub get_now();
sub get_date;

my $cfg = new Config::Simple();
$cfg->read('/etc/nagios/bacula.credentials');

my $progname = basename($0);
my $progVers = "0.3";
my $sqlDB = $cfg->param("name");
my $sqlUsername = $cfg->param("user");
my $sqlPassword = $cfg->param("password");
my $sqlHost = $cfg->param("host");

my %ERRORS = (
	'UNKNOWN'	=>	'-1',
	'OK'		=>	'0',
	'WARNING'	=>	'1',
	'CRITICAL'	=>	'2'
);

Getopt::Long::Configure('bundling');
GetOptions (
	"c=s"	=> \$opt_critical,	"critical=s"	=>	\$opt_critical,
	"w=s"	=> \$opt_warning,	"warning=s"		=>	\$opt_warning,
	"H=s"	=> \$opt_hours,		"hours=s"		=>	\$opt_hours,
	"j=s"	=> \$opt_job,		"job=s"			=>	\$opt_job,
	"e=s"	=> \$opt_errors,	"errors=s"		=>	\$opt_errors,
	"b"		=> \$opt_before,	"beforescript"	=>	\$opt_before,
	"a"		=> \$opt_after,		"afterscript"	=>	\$opt_after,
	"r"		=> \$opt_running,	"running"		=>	\$opt_running,
	"h"		=> \$opt_help,		"help"			=>	\$opt_help,
								"usage"			=>	\$opt_usage,
	"V"		=> \$opt_version,	"version"		=>	\$opt_version
) || die "Try '$progname --help' for more information.\n";

sub print_help() {
	print "\n";
	print "If Bacula holds its MySQL-data behind password, you have to manually enter the password into the script as variable \$sqlPassword.\n";
	print "And be sure to prevent everybody from reading it!\n";
	print "\n";
	print "Options:\n";
	print "H	check successful jobs within <hours> period\n";
	print "c	number of successful jobs for not returning critical\n";
	print "w	number of successful jobs for not returning warning\n";
	print "e	number of jobs' errors for not returning warning\n";
	print "b	check ClientRunBeforeJob error status and return warning in the case\n";
	print "a	check ClientRunAfterJob error status and return warning in the case\n";
	print "r	in case of 1 required job issue warning if the job is still running\n";
	print "j	name of the job to check (case-sensitive)\n";
	print "h	show this help\n";
	print "V	print script version\n";
}

sub print_usage() {
	print "Usage: $progname -H <hours> -c <critical> -w <warning> -j <job-name> [ -e <errors> ] [ -b ] [ -a ] [ -r ] [ -h ] [ -V ]\n";
}

sub get_now() {
	my $now = defined $_[0] ? $_[0] : time;
	my $out = strftime("%Y-%m-%d %X", localtime($now));
	return($out);
}

sub get_date {
	my $day = shift;
	my $now = defined $_[0] ? $_[0] : time;
	my $new = $now - ((60*60*1) * $day);
	my $out = strftime("%Y-%m-%d %X", localtime($new));
	return ($out);
}

sub sql_exec {
	$sth = $dbh->prepare($sql_query) or die "Error preparing statemment",$dbh->errstr;
	$sth->execute;
	return ($sth->fetchrow_array());
}

if ($opt_help) {
	print_usage();
	print_help();
	exit $ERRORS{'UNKNOWN'};
}

if ($opt_usage) {
	print_usage();
	exit $ERRORS{'UNKNOWN'};
}

if ($opt_version) {
	print "$progname $progVers\n";
	exit $ERRORS{'UNKNOWN'};
}


if ($opt_job && $opt_warning && $opt_critical) {
	my $dsn = "DBI:mysql:database=$sqlDB;host=$sqlHost";
	$dbh = DBI->connect( $dsn,$sqlUsername,$sqlPassword ) or die "Error connecting to: '$dsn': $DBI::errstr\n";
	
	if ($opt_hours) {
		$date_stop = get_date($opt_hours);
	}
	else {
		$date_stop = '1970-01-01 01:00:00';
	}
	
	$date_start = get_now();
	$sql_query = "SELECT SUM(JobErrors) AS 'errors', COUNT(*) AS 'count', Job.JobId, Job.JobStatus, Log.LogText, Job.JobFiles AS 'files', Job.JobBytes AS 'size' FROM Job LEFT JOIN Log on Job.JobId = Log.JobId WHERE (Name='$opt_job') AND (JobStatus='T') AND (EndTime <> '') AND ((EndTime <= '$date_start') AND (EndTime >= '$date_stop'));";
	my @job_stats = sql_exec();
	$errors = $job_stats[0];
	$count = $job_stats[1];
	$jobid = $job_stats[2];
	$joblog = $job_stats[3];
	$files = $job_stats[5];
	$size = $job_stats[6];
	$size = floor(($size / 1024 / 1024));
	$state = 'OK';
	$msg = "";

	# Get latest successful job for sample file display
	$sql_query = "SELECT MAX(Job.JobId) AS 'jobid' FROM Job WHERE (Name='$opt_job') AND (JobStatus='T') AND (EndTime <> '') AND ((EndTime <= '$date_start') AND (EndTime >= '$date_stop'));";
	my @tmp_stats = sql_exec();
	$sampleJobId = $tmp_stats[0];

	# Get last saved file as a sample
	$sql_query = "SELECT Path.Path,Filename.Name AS 'filename' FROM File,Filename,Path WHERE File.JobId='$sampleJobId' AND Filename.FilenameId=File.FilenameId AND Path.PathId=File.PathId AND Filename.Name != '' ORDER BY Path.Path desc;";
	my @file_stats = sql_exec();
	if (defined($file_stats[0]) && defined($file_stats[1])) {
		if (length($file_stats[0]) > 0 && length($file_stats[1]) > 0) {
			$sampleFile = $file_stats[0] . $file_stats[1];
		}
	}

	if (defined $opt_errors) {
		if ($errors > $opt_errors)
			{ $state = 'WARNING' }
		$msg .= ", $errors job errors";
	}
	if (defined $opt_before && $joblog && $joblog =~ "BeforeJob returned non-zero status") {
		$state = 'WARNING';
		$msg .= ", Runscript BeforeJob of job $jobid exited abnormally";
	}
	if (defined $opt_after && $joblog && $joblog =~ "AfterJob returned non-zero status") {
		$state = 'WARNING';
		$msg .= ", Runscript AfterJob of job $jobid exited abnormally";
	}
	if ($count < $opt_warning)
		{ $state = 'WARNING' }
	if ($count < $opt_critical) {
		if (defined $opt_running && $opt_critical == 1) {
			# check whether the job is running?
			$sql_query = "SELECT COUNT(*) AS 'count' FROM Job WHERE (Name='$opt_job') AND (JobStatus='R');";
			my @job_stats = sql_exec();
			if ($job_stats[0] && $job_stats[0] > 0) {
				$state = 'WARNING';
				$msg .= ", job is still running";
			}
			else
				{ $state = 'CRITICAL'; }
		}
		else
			{ $state = 'CRITICAL'; }
	}

	my $sampleFileMsg = "";
	if (defined($sampleFile) ) {
		$sampleFileMsg = "Sample file from last succ. backup within $opt_hours" . "h = $sampleFile";
	}
	else {
		$sampleFileMsg = "Nothing backed up in last backup within $opt_hours" . " hours";
	}

	print "$state: $count successful jobs with $files files and $size" . "MB$msg. " . $sampleFileMsg . "\n";
	exit $ERRORS{$state};
	$dbh->disconnect();
}
else {
	print_usage();
}
