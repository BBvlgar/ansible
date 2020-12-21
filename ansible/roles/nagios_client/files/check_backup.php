#!/usr/bin/php
<?php

date_default_timezone_set('Europe/Berlin');

$exitHostCode = 0;

if( sizeof($argv) > 1 ) {
    $hostname = $argv[1];
} else {
    exit(1);
}

// GET Credentials

$credentials = file('/etc/bareos/bareos-dir.d/catalog/MyCatalog.conf');

foreach ($credentials as $credential) {
    if(strpos($credential, 'dbname') !== false) {
        $dbName = trim(explode("=",$credential)[1]);
    }
    if(strpos($credential, 'dbuser') !== false) {
        $dbUser = trim(explode("=",$credential)[1]);
    }
    if(strpos($credential, 'dbpassword') !== false) {
        $dbPassword = trim(explode("=",$credential)[1]);
    }
}



$pgconn = pg_connect("host=localhost port=5432 dbname=".$dbName." user=".$dbUser." password=".$dbPassword);
//$pgconn = pg_connect("host=bareos-db port=5432 dbname=bareos_bak user=postgres password=ThisIsMySecretDBp4ssw0rd");

$hours = 24;        // check successful jobs within <hours> period
$opt_critical = 1;  // number of successful jobs for not returning critical
$opt_warning = 2;   // number of successful jobs for not returning warning
$opt_errors = 0;    // number of jobs' errors for not returning warning

$dateStart = date("Y-m-d H:i:s");
$dateEnd   = date('Y-m-d H:i:s', strtotime("-$hours hour",strtotime($dateStart)));

// Get Job Names
$shortHostname = explode('.', $hostname)[0];
$sqlQuery = "SELECT Name from Job WHERE Name LIKE '$shortHostname-%' GROUP BY Name";

$result = pg_query($pgconn, $sqlQuery);
$hostJobs = array();

if (pg_num_rows($result) > 0) {
    while ($obj = pg_fetch_object($result)) {
        $hostJobs[] = $obj;
    }

    pg_free_result($result);
}

if($hostJobs === null || count($hostJobs) === 0) {
    exit(-1);
}

foreach ($hostJobs as $hostJob) {
    $message = "";
    $state = "OK";
    $exitCode = 0;

    $sqlQuery = "SELECT 
                  JobErrors as \"errors\", 
                  Job.JobId, 
                  Job.JobStatus,  
                  string_agg(Log.LogText, ', ' order by Log.logid) as \"LogText\", 
                  Job.JobFiles AS \"files\", 
                  Job.JobBytes AS \"size\" 
                 FROM Job LEFT JOIN Log on Job.JobId = Log.JobId 
                 WHERE 
                  Name = '$hostJob->name' AND 
                  EndTime <= '$dateStart' AND 
                  EndTime >= '$dateEnd'
                 GROUP BY Job.JobId, Job.JobErrors, Job.JobStatus, Job.JobFiles, Job.JobBytes 
                 ORDER By Job.JobId";

    $result = pg_query($pgconn, $sqlQuery);

    if (pg_num_rows($result) > 0) {
        $job = pg_fetch_object($result);
        pg_free_result($result);
    } else {
        echo "no job found";
        exit(1);
    }


    if( $job->errors > $opt_errors ) {
        $state = 'WARNING';
        $exitCode = 1;
    }

    if( $job->errors > $opt_critical ) {
        $state = 'CRITICAL';
        $exitCode = 2;
    }

    $message .= ", ". $job->errors ." job errors";

    $sqlQuery_runningJob = "SELECT JobId FROM Job WHERE (Name='$hostJob->name') AND (JobStatus='R');";
    $result_runningJob = pg_query($pgconn, $sqlQuery_runningJob);

    if(pg_num_rows($result_runningJob) > 0) {
        $state = 'WARNING';
        $exitCode = 1;
        $message .= ", job is still running";
    }

    pg_free_result($result_runningJob);


    $sqlQuery_lastJob = "SELECT MAX(Job.JobId) AS \"jobId\" FROM Job WHERE Name = '$hostJob->name' AND EndTime <= '$dateStart' AND EndTime >= '$dateEnd';";
    $result_lastJob = pg_query($pgconn, $sqlQuery_lastJob);
    $lastJob_Id = "";

    $fileMessage = "";

    if (pg_num_rows($result_lastJob) > 0) {
        $lastJob_Id = pg_fetch_object($result_lastJob)->jobId;
        pg_free_result($result_lastJob);

        $sqlQuery_lastFile = "SELECT Path.Path, file.name FROM File, Path WHERE File.JobId = $lastJob_Id AND Path.PathId = File.PathId AND File.name != '' ORDER BY file.fileindex desc LIMIT 1;";
        $result_lastFile = pg_query($pgconn, $sqlQuery_lastFile);

        if (pg_num_rows($result_lastFile) > 0) {
            $lastFile = pg_fetch_object($result_lastFile);
            pg_free_result($result_lastFile);

            $lastFile = $lastFile->path . $lastFile->name;
            $fileMessage = "Sample file from last succ. backup within $hours" . "h = $lastFile";
        } else {
            $fileMessage = "Nothing backed up in last backup within $hours" . " hours";
        }
    }
    $size       = $job->size;
    $size       = floor(($size / 1024 / 1024));

    $jobStatus = "";
    switch ($job->jobstatus) {
        case "T":
            $jobStatus = "Terminated normally";
            break;
        case "W":
            $jobStatus = "Terminated with warnings";
            break;
        case "R":
            $jobStatus = "Running";
            break;
        case "A":
            $jobStatus = "Canceled by the user";
            break;
        case "f":
            $jobStatus = "Fatal error";
            break;
        default:
            $jobStatus = "Not defined";
    }

    echo "$state: $jobStatus ( $hostJob->name ) with $job->files files and $size" . "MB$message. " . $fileMessage . "\n";

    if($exitHostCode < $exitCode) {
        $exitHostCode = $exitCode;
    }

}
pg_close($pgconn);
exit($exitHostCode);
