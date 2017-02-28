#!/usr/bin/perl
use Modern::Perl;
use GD;
use POSIX qw/ceil/;
use File::Basename;
no warnings 'experimental::smartmatch';

# color palette
our %colors = (
                "FF0000" => ">", "800000" => "<",
                "00FF00" => "+", "008000" => "-",
                "0000FF" => ".", "000080" => ",",
                "FFFF00" => "[", "808000" => "]",
                "00FFFF" => "c", "008080" => "cc",
                "000000" => "b",
              );
our @dp = qw/r d l u/;
our @list;
our @prog;

my $dpval = 0;
my ($cy, $cx) = (0,0);
my $bail = 1;
my $program = "";
my $pos;
my $dir;
my $char;

my $im;
our $tr;

my $image = shift;

if (!$image) {
    my $prog = basename($0);
    
    print "USAGE\n";
    print "  $prog imagefile OR progfile\n\n";
    print "DESCRIPTION\n";
    print "  BrainLoller Interpreter written in Perl\n\n";
    print "OPTIONS\n";
    print "OPERANDS\n";
    print "  imagefile  path to input image file\n";
    print "  or\n";
    print "  progfile  Brainfuck program to be translated\n\n";
    print "FILES\n";
    print "  Output files written to current directory\n";
    print "  Translation filename is progfile-bf.png\n\n";
    print "EXAMPLES\n";
    print "  $prog ./Examples/cat.png\n";
    print "  $prog hello.png\n";
    print "  $prog fizzbuzz.bf";
    
    exit(1);
}

if ($image =~ m/\S+\.png$/i) {
    $im = newFromPng GD::Image($image);
} elsif ($image =~ m/\S+\.gif$/i) {
    $im = newFromGif GD::Image($image);
} elsif ($image =~ m/\S+\.bf$/i) {
    @prog = convert($image);
    
    print "Codel size (in px): ";
    chomp(my $cod = <>);
    print "Image Width (in codel): ";
    chomp(my $wid = <>);
    
    translate($cod, $wid);
    endTrans($image);
    
    exit(0);
} else {
    print "Error: Unsupported Image Format\n";
    exit(1);
}

my ($w, $h) = $im->getBounds();

# create 2D list of colors
extractcolors($im, $w, $h, codelsize($im, $w, $h));

# clean list
sanitize();

# begin interpretation
while ($bail) {
    $pos = $list[$cy][$cx];
    
    if (!valid($cy, $cx)) { $bail--; next; }
    
    $char = $colors{$pos};
    
    if ($char ~~ "c") {
        direction(1);
    } elsif ($char ~~ "cc") {
        direction(-1);
    } else {
        if ($colors{$pos}) { $program .= $char; }
    }
    
    $dir = $dp[$dpval];
    ($cy, $cx) = getNext($cy, $cx, $dir);
}

print "Result is : $program\n";

system ("perl bf.pl \"$program\"");

#==================SUBROUTINES==========================

#----------------------------
#-------Initialization-------
#----------------------------

##\
 # Calculates codel size of input image file
 #
 # param: $im: GD image
 # param: $w:  Image width
 # param: $h:  Image height
 #
 # return: codel size
 #/
sub codelsize {
    my ($im, $w, $h) = @_;
    my $store = 0;
    my $count;

    foreach my $y (0 .. $h - 1) {
        $count = 1;
        
        foreach my $x (0 .. $w - 1) {
            my $first = $im->getPixel($x, $y);
            my $second = $im->getPixel($x + 1, $y);
            
            if ($first == $second) {
                $count++;
            } else {
                if (!$store || $count <= $store) { $store = $count; }
                $count = 1;
            }
        }
        
        if ($store == 1) { last; }
    }
    return $store;
}

##\
 # Acquires color information from image and stores in 2D list
 #
 # param: $im:   GD image
 # param: $w:    Image width
 # param: $h:    Image height
 #/
sub extractcolors {
    my ($im, $w, $h, $size) = @_;
    
    for (my $x = 0; $x < $w; $x+= $size) {
        for (my $y = 0; $y < $h; $y+= $size) {
            $list[$y / $size][$x / $size] = rgbtohex($im->rgb($im->getPixel($x,$y)));
        }
    }
}

##\
 # Attempts to sanitize input image by converting colors not matching palette
 # to valid colors - Otherwise, treat as black
 #/
sub sanitize {
    my $temp;
    
    foreach my $y (0 .. @list - 1) {
        foreach my $x (0 .. @{$list[0]} - 1) {
            if (exists $colors{$list[$y][$x]}) { next; }
        
            # attempts to fix color
            $temp = closestcolor($list[$y][$x]);
            
            if (not exists $colors{$temp}) { $temp = "000000"; }
            
            $list[$y][$x] = $temp;
        }
    }
}

#----------------------------
#--------Primary Loop--------
#----------------------------

##\
 # Given 1 or -1, change direction clockwise or counterclockwise
 #
 # param: $val: direction change
 #/
sub direction {
    my ($val) = @_;
    
    if ($val < 0) {
        $dpval = ($dpval + $val < 0) ? 3 : $dpval + $val;
    } else {
        $dpval = ($dpval + $val) % 4;
    }
}

##\
 # Gets coordinates of next codel given color coordinates and direction
 #
 # param: $y:   y coordinate of color
 # param: $x:   x coordinate of color
 # param: $dir: direction
 #
 # return: tuple of next color coordinates
 #/
sub getNext {
    my ($y, $x, $dir) = @_;
    
    for ($dir) {
        when ('r') { $x++; }
        when ('d') { $y++; }
        when ('l') { $x--; }
        when ('u') { $y--; }
    }
    
    return ($y, $x);
}

#----------------------------
#--------Translation---------
#----------------------------

##\
 # Collects all program instructions into array
 #
 # param: $file: name of input file
 #
 # return: @out: array of program instructions
 #/
sub convert {
    my ($file) = @_;
    my @out;
    
    open (FILE, '<', $file) or die("Can't open $file: $!\n");
    while (<FILE>) {
        my $temp = $_;
        for (0 .. length($temp) - 1) {
            my $char = substr($temp, 0, 1);
            $temp = substr($temp, 1);
                
            if ($char =~ m/[\>\<\+\-\.\,\[\]]/) { push(@out, $char); }
        }
    }
    close (FILE);
    
    return @out;
}

##\
 # Translates Brainfuck program into Brainloller image
 #
 # param: $cod: size of codels in image
 # param: $width: codel width of image
 #/
sub translate {
    my ($cod, $width) = @_;
    
    my $w = $cod * $width;
    my $h = $cod * ceil(scalar(@prog) / ($width - 2));
    
    my $proptr = 0;
    my $x = 0;
    my $y = 0;
    my $dpv = 0;
    my $dir = $dp[$dpv];
    
    $tr = new GD::Image($w, $h);
    $tr->filledRectangle(0, 0, $w, $h, $tr->colorResolve(getColor('b')));
    my $color;
    
    my @tsil;
    while (1) {
        if ($proptr == scalar @prog) { last; }
        my $c = $prog[$proptr];
        
        if ($x == 0 && $y > 0) {
            $tsil[$y][$x] = "cc";
            $dpv = ($dpv - 1) % @dp;
        } elsif ($x == $width - 1) {
            $tsil[$y][$x] = "c";
            $dpv = ($dpv + 1) % @dp;
        } else {
            $tsil[$y][$x] = $c;
            $proptr++;
        }
        
        $dir = $dp[$dpv];
        ($y, $x) = getNext($y, $x, $dir);
    }
    
    # Separate for rectangle-drawing issues
    for my $a (0 .. @tsil - 1) {
        for my $b (0 .. @{$tsil[0]} - 1) {
            if (defined $tsil[$a][$b]) {
                $color = $tr->colorResolve(getColor($tsil[$a][$b]));
            } else {
                $color = $tr->colorResolve(getColor('b'));
            }
            $tr->filledRectangle($b * $cod, $a * $cod, ($b + 1) * $cod, ($a + 1) * $cod, $color);
        }
    }
}

##\
 #
 #/
sub endTrans {
    my ($image) = @_;
    
    $image =~ /(\S+)\./;
    $image = $1 . "-bf.png";
    
    open (OUT, '>', $image) or die ("Can't create $image: $!\n");
    binmode (OUT);
    print OUT $tr->png;
    close (OUT);
}

##\
 #
 #/
sub getColor {
    my ($char) = @_;
    
    for my $i (keys %colors) {
        if ($colors{$i} eq $char) {
            return hextorgb($i);
        }
    }
    
    return hextorgb("000000");
}

#----------------------------
#-----------Util-------------
#----------------------------

##\
 # Determines closest color to valid colors within a threshold
 #
 # param: $col: color in hex value
 #
 # return: hex value of closest color
 #/
sub closestcolor {
    my ($col) = @_;
    
    my @rgb = hextorgb($col);
    
    for my $i (0 .. @rgb - 1) {
        if (255 - $rgb[$i] <= 10)      { $rgb[$i] = 255; next; }
        if (abs(10 - $rgb[$i]) <= 10)  { $rgb[$i] =   0; next; }
        if (abs(128 - $rgb[$i]) <= 10) { $rgb[$i] = 128; next; }
    }
    
    my $out = rgbtohex($rgb[0], $rgb[1], $rgb[2]);
    
    return $out;
}

##\
 # Converts RGB color to hex
 #
 # param: $r: red color in RGB
 # param: $g: green color in RGB
 # param: $b: blue color in RGB
 #
 # return: string of hex value
 #/
sub rgbtohex {
    my ($r, $g, $b) = @_;
    return sprintf("%02X%02X%02X", $r, $g, $b);
}

##\
 # Converts hex color to RGB
 #
 # param: $s: hex value of color
 #
 # return: triple of RGB values
 #/
sub hextorgb {
    my ($s) = @_;
    my $r = hex(substr($s, 0, 2));
    my $g = hex(substr($s, 2, 2));
    my $b = hex(substr($s, 4));
    
    return ($r, $g, $b);
}

##\
 # Checks validity of color given coordinates
 # out of bounds
 #
 # param: $y: y coordinate of color
 # param: $x: x coordinate of color
 #
 # return: boolean(0,1)
 #/
sub valid {
    my ($y, $x) = @_;
    my $out = 1;
    
    if ($y < 0 || $y >= @list || $x < 0 || $x >= @{$list[0]} || $list[$y][$x] ~~ "000000") {
        $out = 0;
    }
    
    return $out;
}