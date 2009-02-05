package Firmata::DigitalPin;

use strict;
use warnings;
use Carp;

use Firmata::Constants;

sub new {
    my $that = shift;
    my ($device, $port, $pin_number, $pwm) = @_;
    my %args = (
        Device    => $device,
        Port      => $port,
        Pin_Number => $pin_number,
        Value     => 0,
        Mode      => PIN_MODES->{DIGITAL_INPUT},
        PWM       => $pwm
    );
    my $class = ref($that) || $that;
    my $self  = { %args };

    bless $self, $class;
    return $self;
}

sub info{
    my $self = shift;
    return "Digital Pin " . $self->{'Pin_Number'};
}

sub set_mode{
    my $self = shift;
    my ($mode) = @_;
    # Set the mode of operation for the pin
    # Argument
    # mode, takes a value of:   DIGITAL_INPUT
    #                           DIGITAL_OUTPUT
    #                           DIGITAL_PWM
    if ($mode == PIN_MODES->{DIGITAL_PWM} and not $self->{'PWM'}){
        croak ("Digital pin " . $self->_get_board_pin_number() . " does not have PWM capabilities");
    }
    if ($self->{Mode} == PIN_MODES->{UNAVAILABLE}){
        croak ("Cannot set mode for pin " . $self->_get_board_pin_number());
    }
    $self->{'Mode'} = $mode;
    my $command = chr(SET_DIGITAL_PIN_MODE);
    $command .= chr($self->_get_board_pin_number());
    $command .= chr($mode);
    #print "would write \"$command\" to device\n";
    my $bytes = $self->{'Device'}->write($command);
    carp ("Write failed")       unless ($bytes);
    carp ("Write incomplete")   unless ($bytes == length($command));

}

sub get_mode{
    my $self = shift;
    return $self->{'Mode'};
}

sub get_pin_number{
    my $self = shift;
    return $self->{'Pin_Number'};
}

sub get_value{
    my $self = shift;
    return $self->{'Value'};
}

sub _get_board_pin_number{
    my $self = shift;
    return ($self->{'Port'}->get_port_number() * 8) + $self->{'Pin_Number'};
}

sub set_value {
    my $self = shift;
    my ($value) = @_;
    $self->{Value} = $value;
}

sub read {
    my $self = shift;
    if ($self->{'Mode'} == PIN_MODES->{UNAVAILABLE}){
        croak ("Cannot read pin " . $self->_get_board_pin_number());
    }
    return $self->{'Value'};
}

sub write {
# Output a voltage to the pin
# Argument: value.  boolean if in output mode, float from 0 to 1 if PWM.
    my $self = shift; 
    my ($value) = @_;
    if ($self->{'Mode'} == PIN_MODES->{UNAVAILABLE}){
        croak ("Cannot write to pin " . $self->_get_board_pin_number());

    } elsif ($self->{'Mode'} == PIN_MODES->{DIGITAL_INPUT}){
        croak ("Digital pin " . $self->_get_board_pin_number(). " is not an output");

    } elsif($value != $self->read()){
        $self->{'Value'} = $value;
        if ($self->{'Mode'} == PIN_MODES->{DIGITAL_OUTPUT}){
            $self->{'Port'}->write();
        } elsif ($self->{'Mode'} == PIN_MODES->{DIGITAL_PWM}){
            $value = int($value * 255);
            my $message = chr(ANALOG_MESSAGE + $self->_get_board_pin_number());
            $message .= chr($value % 128);
            $message .= chr($value >> 7);
            my $bytes = $self->{'Device'}->write($message);
            carp ("Write failed")       unless ($bytes);
            carp ("Write incomplete")   unless ($bytes == length($message));

        }
    }
        
}

1;
