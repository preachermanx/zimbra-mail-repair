#!/usr/bin/perl
 
use Getopt::Long;
GetOptions ('file=s' => \$file,
                                                                                                                                                                                                'newmboxnum=s' => \$newmboxnum,
                                                                                                                                                                                                'unexpectedblobpath=s' => \$unexpectedblobpath,
                                                                                                                                                                                                'emailaddress=s' => \$email,
                                                'outfile=s' => \$outfile,
                                                'errorfile=s' => \$errorfile,
                                                'help' => \$help);
if ($outfile)
{
        open(OUTFILE, ">$outfile");
}
if ($errorfile)
{
        open(ERRORFILE, ">$errorfile");
}                                      
if ($help)
{
        usage();
}
elsif (!$file)
{
        print "Must specify filename.\n\n";
        usage();
        exit;
}
elsif (!-e $file)
{
        print "File does not exist!\n\n";
        usage();
        exit;
}
elsif (!$newmboxnum)
{
                                print "Must specify the new mailbox number!\n\n";
                                usage();
                                exit;
}
elsif (!$email)
{
                                print "Must specify users email address!\n\n";
                                usage();
                                exit;
}
#elsif (!$unexpectedblobpath)
#{
#                               print "Must specify the path to move unexpected blobs to!\n\n";
#                               usage();
#                               exit;
#}
else
{
        #print "File $file exists. Continuing...\n";
        open(FILE, "<$file");
        @blobs = <FILE>;
        $importblobs="";
        for ($i=0;$i<=$#blobs;$i++)
        {
                if ($blobs[$i] =~ "Checking")
                {
                        ($chk,$mbox,$mailbox) = split(/\s/,$blobs[$i]);
                        print "Examining data for mailbox $mailbox\n";
                        next;
                }
                chop($blobs[$i]);
                if ($blobs[$i] =~ "blob not found")
                {
                        # get rid of : blob not found.
                        ($line) = split(/:/,$blobs[$i]);
                        # get rid of commas
                        $line =~ s/,//g;
                        ($txt,$mbox,$txt,$item,$txt,$rev,$txt,$vol,$path) = split(/\s/,$line);
                        ($null,$opt,$zimbra,$storepath,$num1,$mbox,$msg,$num2,$blob) = split(/\//,$path);
                        #print "$mailbox: $mbox\titem: $item\trev: $rev\tvolume: $vol\tpath: $path\tstore path: $storepath\n";
                        $newstorepath = $storepath;
                        $newstorepath =~ s/$storepath/store/g;
                        $makepath = '/' . $opt . '/' . $zimbra . '/' . $storepath . '/' . $num1 . '/' . $mbox . '/' . $msg . '/' . $num2;
                        $restorepath = '/' . $opt . '/' . $zimbra . '/' . $newstorepath . '/' . $num1 . '/' . $newmboxnum . '/' . $msg . '/' . $num2 . '/' . $blob;
                        #print "$restorepath\t$path\n";
                        # copy restored data to the right place if both the restore path exists and the destination doesn't
                        # eliminates copying data that's already been restored, or that previously existed
                        if (-e $restorepath) #&& !-e $path)
                        {
                                if (!-e $makepath)
                                {
                                        print "creating $makepath\n";
                                        system("mkdir -p $makepath");
                                }
                                if ($outfile)
                                {
                                        print OUTFILE "copying $restorepath to $path\n";
                                }
                                else
                                {
                                        $pct = ($i/$#blobs) * 100;
                                        print "copying $restorepath to $path [$i/$#blobs] [$pct%]\n";
                                        system("cp $restorepath $path");
                                }
                        }
                        elsif (!$restorepath)
                        {
                                if ($errorfile)
                                {
                                        print ERRORFILE "ERROR: $restorepath does not exist!\n";
                                }
                                else
                                {
                                        print "ERROR: $restorepath does not exist!\n";
                                }
                        }
                }
                elsif ($blobs[$i] =~ "unexpected blob")
                {
                       
                        # get rid of : unexpected blob...
                        ($line) = split(/:/,$blobs[$i]);
                        # get rid of commas
                        $line =~ s/,//g;
                                                ($txt,$mbox,$txt,$vol,$path) = split(/\s/,$line);
                        print "Adding $path to lists of blobs to import\n";
                        $importblobs .= "addMessage /Inbox $path\n";
                }
                else
                {
                        print "unknown entry!\n";
                       
                }
        }
        print "Writing list of blobs to import to /tmp/importblobs.txt.\n";
        open(IMPORT, "> /tmp/importblobs.txt") || die "Failed to write /tmp/importblobs.txt!\n";
        print IMPORT $importblobs;
        close(IMPORT);
        print "Importing blobs from /tmp/importblobs.txt\n";
        system("zmmailbox -z -m $email < /tmp/importblobs.txt");
        print "Completed importing blobs.\n";
}
     
sub usage()
{
        print "Usage:\n\n$0\t --file <filename> --newmboxnum <number> --email <email> [ --outfile <filename> | --errorfile <filename> ]\n\n";
        print "\t--file <filename>\tOriginal ICS File to analyze\n";
        print "\t--newmboxnum <new mailbox number>\tNew Mailbox Number\n";
        print "\t--email <email address>\tEmail Address of mailbox\n";
        #print "\t--unexpectedblobpath <pathname>\tPath to place unexpected blobs\n";
        print "\t--outfile <filename>\tFile to store good ICS entries\n";
        print "\t--errorfile <filename>\tFile to store bad ICS entires\n";
}
