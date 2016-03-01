#!/usr/bin/perl
use Modern::Perl;
use Data::Dumper;
use Getopt::Std;
use File::Basename;

my @prog;
my @tape;
my %opt = ();

# cmd parameters
getopts('fsl:', \%opt);

my $buffer = "";
my $bail = 1;
my $memptr = 0;
my $proptr = 0;

my $file = shift;

if (!$file) {
    my $prog = basename($0);
    
    print "USAGE\n";
    print "  $prog [options] textfile OR progtext\n\n";
    print "DESCRIPTION\n";
    print "  Brainfck Interpreter written in Perl\n\n";
    print "OPTIONS\n";
    print "  -f        Produce Flat version of input program\n";
    print "  -s        Tape Cell Storage cap at 255 (overflow) (default: unlimited)\n";
    print "  -l [int]  Tape Length (default: unlimited)\n\n";
    print "OPERANDS\n";
    print "  textfile  path to input text file\n";
    print "  or\n";
    print "  progtext  Literal String of Program Instructions\n\n";
    print "FILES\n";
    print "  Output files (-f,-s,...) written to current directory\n";
    print "  Flat (-f) filename is textfile-flat.bf\n\n";
    print "EXAMPLES\n";
    print "  $prog ./Examples/cat.bf\n";
    print "  $prog -f triangle.bf\n";
    print "  $prog -s -l 20 one.bf\n";
    print "  $prog \",[.,]\"\n";
    
    exit(1);
}

@prog = ($file =~ m/[<>\[\]]/) ? convert($file) : reduce($file);

if ($opt{f}) { outprog($file); }

while ($bail) {
    # termination condition
    if ($proptr >= @prog) { $bail--; next; }
    
    my $char = $prog[$proptr];
    
    for ($char) {
        when ('>') { shiftright(); }
        when ('<') { shiftleft();  }
        when ('+') { increment();  }
        when ('-') { decrement();  }
        when (',') { input();      }
        when ('.') { output();     }
        when ('[') { loopstart();  }
        when (']') { loopend();    }
    }
    
    $proptr++;
}

#==================SUBROUTINES==========================

#----------------------------
#--------Instructions--------
#----------------------------

##\
 # Shifts memptr right
 #/
sub shiftright {
    $memptr++;
    if ($opt{l} && $memptr == $opt{l}) { $memptr = 0; }
}

##\
 # Shifts memptr left unless at the left end of tape
 #/
sub shiftleft {
    if ($memptr == 0) {
        if ($opt{l}) { $memptr = $opt{l} - 1; }
    } else {
        $memptr--;
    }
}

##\
 # Increments value of cell at memptr
 #/
sub increment {
    $tape[$memptr]++;
    if ($opt{s} && $tape[$memptr] > 254) { $tape[$memptr] = 0; }
}

##\
 # Decrements value of cell at memptr
 #/
sub decrement {
    $tape[$memptr]--;
    if ($opt{l} && $tape[$memptr] < 0) { $tape[$memptr] = 254; }
}

##\
 # Requests input from user
 # Stores input in buffer, saves first char to cell at memptr
 #/
sub input {
    my $val;

    if ($buffer) {
        $val = ord substr($buffer, 0, 1);
        $tape[$memptr] = $val;
        $buffer = substr($buffer, 1);
    } else {
        print "?";
        $val = <>;

        if (not defined $val) {
            print "ERROR: input not found";
        } else {
            $buffer = $val . chr(0);
            $val = ord substr($buffer, 0, 1);
            $buffer = substr($buffer, 1);

            $tape[$memptr] = $val;
        }
    }
}

##\
 # Prints ASCII value of cell at memptr
 #/
sub output { print chr $tape[$memptr]; }

##\
 # Skip loop to matching right bracket if cell at memptr is zero
 #/
sub loopstart {
    if (!$tape[$memptr]) {
        my $count = 1;
        my $cnt = $proptr;

        for my $i ($proptr + 1 .. @prog - 1) {
            if ($prog[$i] ~~ '[') { $count++; }
            if ($prog[$i] ~~ ']') { $count--; }
            $cnt++;

            if ($count == 0) { last; }
        }

        $proptr = $cnt;
    }
}

##\
 # Backtrack to matching left bracket if cell at memptr is not zero
 #/
sub loopend {
    if ($tape[$memptr]) {
        my $count = 1;
        my $cnt = $proptr - 1;

        while ($cnt > 0) {
            if ($prog[$cnt] ~~ ']') { $count++; }
            if ($prog[$cnt] ~~ '[') { $count--; }

            if ($count == 0) { last; }
            $cnt--;
        }

        $proptr = $cnt;
    }
}

#----------------------------
#-----------Util-------------
#----------------------------

##\
 # Saves contents of program array to file
 #
 # param: $file: name of input file
 # param: $prog: name of program array
 #/
sub outprog {
    my ($file) = @_;
    if ($file =~ m/[<>\[\]]/) { $file = "cmdout.bf"; }
    
    $file =~ s/(\S+)\..*$/$1/;
    open (OUT, '>', "$file-flat.bf") or die ("Cannot open $file-flat.bf: $!\n");
    
    for my $i (@prog) { print OUT $i; }
    
    close (OUT);
}

##\
 # Collects all program instructions into array
 #
 # param: $file: name of input file
 #
 # return: @out: array of program instructions
 #/
sub reduce {
    my ($file) = @_;
    my @out;
    
    open (FILE, '<', $file) or die("Can't open $file: $!\n");
    while (<FILE>) { push(@out, convert($_)); }
    close (FILE);
    
    return @out;
}

##\
 # Converts Instruction String into array
 #
 # param: $file: string containing program Instructions
 #
 # return: $out: array of program instructions
 #/
sub convert {
    my ($file) = @_;
    my @out;
    
    for (0 .. length($file) - 1) {
        my $char = substr($file, 0, 1);
        $file = substr($file, 1);
            
        if ($char =~ m/[\>\<\+\-\.\,\[\]]/) { push(@out, $char); }
    }
    
    return @out;
}