param(
    [switch]$recursive,
    [switch]$help
)

function DeleteFile {
    param (
        $path_to_file
    )
    [System.IO.File]::Delete($path_to_file)
}

function DeleteDirectory {
    param (
        $path_to_dir
    )
    [System.IO.Directory]::Delete($path_to_dir)
}

function RecursiveDelete {
    param (
        [string]$path_to_dir,
        [datetime]$date_to_delete,
        [bool]$is_recursive
    )
    
    if ($is_recursive) {
        foreach($dir in [System.IO.Directory]::GetDirectories($path_to_dir)) {
            $count_ogj_inside = RecursiveDelete $dir $date_to_delete $is_recursive
            if ($count_ogj_inside -le 0) {
                DeleteDirectory $dir
            }
        }
    }
    
    foreach ($file in [System.IO.Directory]::GetFiles($path_to_dir)) {
        if ([System.IO.File]::GetCreationTime($file) -le $date_to_delete) {
            DeleteFile $file
        }
    }
    
    $files_in_dir = ([System.IO.Directory]::GetFiles($path_to_dir)).Count
    $subdirs_in_dir = ([System.IO.Directory]::GetDirectories($path_to_dir)).Count
    
    return ($files_in_dir + $subdirs_in_dir)
}


# Program start
if ($help) {
    "Deletes files that are older than date."
    ""
    "delete_older.ps1 <path> -<time parameter>"
    "<path>     -- path to directory"
    '   Example: "D:\dir"'
    "-<time parameter>  -- older or more by that time from current time"
    "  format: <T><N>..."
    "   <T>   -- time interval"
    "     Y - years, M - months, d - days, H - hours, i - minutes, s - seconds"
    "   <N>   -- number of that time interval"
    "     Any positive integer"
    "   Example: -Y2M3d4H5  -- delete files that are created 2 years, 3 month, 4 days and 5 hours ago or more from current date."
    ""
    "Additional params:"
    "    -recursive  -- also delete from directories inside"
    exit
}

if ($args.Count -eq 0) {
    "-help  -- to get help"
    exit
}

$path_to_delete = $args[0]
$date_diff = $args[1]

if (-not $path_to_delete -or -not $date_diff) {
    "Parameters are not defined"
    exit
} 

$time_parsed = @()
$date_diff =  $date_diff.Substring(1, $date_diff.Length-1)

$max_it = 9
while ($date_diff -match "(\D+\d+)"  -and $max_it -ge 0) {
    $time_parsed += $Matches[0]
    $date_diff = $date_diff.Replace($Matches[0], "")
    $max_it -= 1
}

if ($time_parsed.Count -eq 0 -or -$date_diff.Length -ne 0) {
    "Unexpected or too long sequence in time parameter: $date_diff"
    "Parsed: $time_parsed"
    exit
}

$date_less_to_delete = [datetime]::Now
foreach ($time_part in $time_parsed) {
    if ($time_part -match "(?<type>\D+)(?<num>\d+)") {
        $minus_num = -[int]$matches.num
        switch ($matches.type) {
            "Y" { $date_less_to_delete = $date_less_to_delete.AddYears($minus_num) }
            "M" { $date_less_to_delete = $date_less_to_delete.AddMonths($minus_num) }
            "d" { $date_less_to_delete = $date_less_to_delete.AddDays($minus_num) }
            "H" { $date_less_to_delete = $date_less_to_delete.AddHours($minus_num) }
            "i" { $date_less_to_delete = $date_less_to_delete.AddMinutes($minus_num) }
            "s" { $date_less_to_delete = $date_less_to_delete.AddSeconds($minus_num) }
            Default {
                "Unexpected time parameter: $_"
                exit
            }
        }
    }
}

[void](RecursiveDelete $path_to_delete $date_less_to_delete $recursive)
