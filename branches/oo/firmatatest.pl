#!/usr/bin/perl -w
use strict;

#use lib '/d/eclipse/workspace/permata'; #used for testing

use Firmata::Arduino;

my $device = $ARGV[0];
my $mode = $ARGV[1];
my $pin = $ARGV[2];

unless ($pin){
    usage();
}

sub usage{
    print <<EOF;
Usage $0 <port> <mode> <pin>
Available Modes: 
    1      Digital Input
    2      Digital Output
    3      PWM
    4      Analog Input
    
EOF
    exit(0);
}

my $arduino = Firmata::Arduino->new($device) or die "Failed to create device on port $device";

if ($mode == 1){
    $arduino->set_digital_pin_mode($pin, "DIGITAL_INPUT")or die "Could not activate digital pin $pin, exiting";
    
} elsif ($mode == 2){
    $arduino->set_digital_pin_mode($pin, "DIGITAL_OUTPUT") or die "Could not activate digital pin $pin, exiting";
    
}elsif ($mode == 3){
    $arduino->set_digital_pin_mode($pin, "DIGITAL_PWM") or die "Could not activate digital pin $pin, exiting";
    
}elsif ($mode == 4) {
    $arduino->activate_analog_pin($pin) or die "Could not activate analog pin $pin, exiting";
} else {
    print "Invalid mode $mode\n\n";
    usage();
}

my $last_value = 0;

while (1){
    $arduino->iterate();
    if ($mode == 1){
        # Digital Input
        my $value = $arduino->read_digital_pin($pin);
        
        unless ($value == $last_value){
            $last_value = $value;
            if ($value == 1){
                print "Digital Pin $pin is high\n";
            } else {
                print "Digital Pin $pin is low\n";
            }
        }
    } elsif ($mode == 2){
        #Digital Output
        #Alter the value every second
        $arduino->write_digital_pin($pin, (time % 2));
    } elsif ($mode == 3){
        #Digital PWM
        #Alter the value every second
        my $value = (int(time() %32))/32;
        $arduino->write_digital_pin($pin, $value);
        
    } elsif ($mode == 4){
        #Analog Input
        my $value = $arduino->read_analog_pin($pin);
        
        unless ($value == $last_value){
            $last_value = $value;
            print "Analog pin value is $value\n";
        }
    }
}


