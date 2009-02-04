#!/usr/bin/perl -w
use strict;

use Firmata::Arduino;

my $device = $ARGV[0];

my $arduino = Firmata::Arduino->new($device) or die "Failed to create device on port $device";

#digital output

my $pin = 10;
$arduino->{'DigitalPorts'}[$pin >> 3]->set_active(1);

$arduino->{'Digital'}[$pin]->set_mode(Firmata::Arduino::DIGITAL_PWM);

while (1){
    my $value = (int(time() %32))/32;
    $arduino->{'Digital'}[$pin]->write($value);
}


