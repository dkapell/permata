package Firmata::AnalogPin;

use strict;
use warnings;
use Carp;

use Firmata::Constants;
our $VERSION = '1';

sub new {
    my $that = shift;
    my ($device, $pin_number) = @_;
    my %args = (
        Device   => $device,
        PinNumber=> $pin_number,
        Active => 0,
        Value => -1,
    );
    my $class = ref($that) || $that;
    my $self  = { %args };

    bless $self, $class;
    return $self;
}

sub info{
    my $self = shift;
    return "Analog Input " . $self->{'PinNumber'};
}

sub set_active{
    my $self = shift;
    my ($active) = @_;
    $self->{'Active'} = $active;
    my $message = chr(REPORT_ANALOG_PIN + $self->{'PinNumber'});
    $message .= chr($self->{'Active'});
    my $bytes = $self->{Device}->write($message);
    carp ("Write failed")       unless ($bytes);
    carp ("Write incomplete")   unless ($bytes == length($message));
}

sub get_active{
    my $self = shift;
    return $self->{'Active'};
}

sub set_value{
    my $self = shift;
    my ($value) = @_;
    $self->{'Value'} = $value;
}

sub read{
    my $self = shift;
    print "Reading Analog pin " . $self->{'PinNumber'} . "\n" if DEBUG; 
    return $self->{'Value'};
}


