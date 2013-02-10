#!/usr/bin/perl

##############################################################################
#
#  A simple perl script that is used to automate downloading releases that
#  are usually posted in the cracker/anonymous/etc announcements, such as 
#  database dumps, which are posted on paste websites such as pastebin, 
#  privatepaste, pastesite, etc.
#
#  At the moment this script is currently used for conducting research related 
#  to cybersecurity and the spread of information and leaks/hacks through various
#  channels such as paste websites.
#
#  This script currently supports only several paste websites that I was focusing
#  my attention on for the purpose of my research, but if there are other sites 
#  which also become popular I will add support for those as well.
#
#
#  Copyright (C) 2013, gnu-user
#  All rights reserved.
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################
use warnings;

my $paste_list;
my $download_dir;
my $cur_line;
my $file_name;
my $link;
my $download_hash;
my $logfile = "leaked_db.log";

# User agent and header data to post when downloading files
my $user_agent = 'Mozilla/5.0 (Windows NT 5.1; rv:10.0.2) Gecko/20100101 Firefox/10.0.2';
my @headers = ( 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Encoding: gzip, deflate',
                'Connection: keep-alive',
                'Referer: '
              );

# User must specify the path to the file with leaked DB's to download
if (@ARGV < 2)
{
    die "You must provide the path to the paste file and"
        ." a directory to store the downloaded files in!";
}

# Set the file containing all the paste site links and download dir
$paste_list = $ARGV[0];
$download_dir = $ARGV[1];

# Open the file and get the links to the files to download
unless (-e $paste_list && -d $download_dir)
{
    die "$paste_list or $download_dir does not exist, provide a valid path!";
}


# Parse the file and download each item in the file
open($paste_list, "< $paste_list");
while (<$paste_list>)
{
    $cur_line = $_;

    # Download files from privatepaste
    if ($cur_line =~ /^.*(http[s]?:\/\/privatepaste\.com\/(\w+))\s*/)
    {
        $link = "https://privatepaste.com/download/$2";
        print "Downloading file from: $link\n";
        system("wget --verbose -U 'Mozilla/5.0 (Windows NT 5.1; rv:10.0.2) Gecko/20100101 Firefox/10.0.2' $link -P $download_dir/ >> $logfile 2>&1");
    }

    # Download files from pastesite
    if ($cur_line =~ /^.*(http[s]?:\/\/pastesite\.com\/(\w+))\s*/)
    {
        $file_name = "paste_$2.txt";
        $link = "http://pastesite.com/download/$file_name";
        
        # Get the content of the download confirm page
        my $download_confirm = `cd $download_dir > /dev/null && curl --cookie-jar cjar -A '$user_agent' $link`;
        
        # Get the downloadConfirm hash to download the file
        foreach my $line (split('\n', $download_confirm)) 
        {
            if ($line =~ /^.*value="([A-Za-z0-9]{40})"\s+name="downloadConfirm">.*/)
            {
                $download_hash = $1;
                print "Downloading file from: $link\n";
                system("cd $download_dir > /dev/null && curl --cookie cjar -A '$user_agent' "
                       ."-H '$headers[0]' -H '$headers[1]' -H '$headers[2]' -H '$headers[3]$link' "
                       ."--data 'downloadConfirm=$download_hash' -o $file_name $link >> $logfile 2>&1");
                last;
            }
        }
    }
}
close($paste_list);
