#!/usr/bin/perl
use Modern::Perl;
use GD;
use File::Basename;

# color palette
our %colors = (
                "FF0000" => ">", "800000" => "<",
                "00FF00" => "+", "008000" => "-",
                "0000FF" => ".", "000080" => ",",
                "FFFF00" => "[", "808000" => "]",
                "00FFFF" => "c", "008080" => "cc",
              );
our @dp = qw/r d l u/;
our @list;

my $dpval = 0;
my ($cy, $cx) = (0,0);
my $bail = 1;
my $program = "";
my $pos;
my $dir;
my $char;

my $im;

my $image = shift;

if (!$image) {
    my $prog = basename($0);
    
    print "USAGE\n";
    print "  $prog [options] imagefile\n\n";
    print "DESCRIPTION\n";
    print "  BrainLoller Interpreter written in Perl\n\n";
    print "OPTIONS\n";
    print "OPERANDS\n";
    print "FILES\n";
    print "EXAMPLES\n";
    
    exit(1);
}

if ($image =~ m/\S+\.png$/i) {
    $im = newFromPng GD::Image($image);
} elsif ($image =~ m/\S+\.gif$/i) {
    $im = newFromGif GD::Image($image);
} else {
    print "Error: Unsupported Image Format\n";
    exit(1);
}

my ($w, $h) = $im->getBounds();

# create 2D list of colors
extractcolors($im, $w, $h);

# clean list
sanitize();

# begin interpretation
while ($bail) {
    $pos = $list[$cy][$cx];
    
    if (!valid($cy, $cx)) {
        $bail--;
        next;
    }
    
    $char = $colors{$pos};
    
    if ($char ~~ "c") {
        direction(1);
    } elsif ($char ~~ "cc") {
        direction(int("-1"));
    } else {
        if ($colors{$pos}) { $program .= $char; }
    }
    
    $dir = $dp[$dpval];
    ($cy, $cx) = getNext($cy, $cx, $dir);
}

#print "Result is : $program\n";

system("perl bf.pl \"$program\"");

#==================SUBROUTINES==========================

#----------------------------
#-------Initialization-------
#----------------------------

##\
 # Acquires color information from image and stores in 2D list
 #
 # param: $im:   GD image
 # param: $w:    Image width
 # param: $h:    Image height
 #/
sub extractcolors {
    my ($im, $w, $h) = @_;
    
    for (my $x = 0; $x < $w; $x++) {
        for (my $y = 0; $y < $h; $y++) {
            $list[$y][$x] = rgbtohex($im->rgb($im->getPixel($x,$y)));
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
    
    if ($y < 0 || $y >= @list || $x < 0 || $x >= @{$list[0]}) {
        $out = 0;
    }
    
    return $out;
}