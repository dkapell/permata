package Firmata::DigitalPin;
require Exporter;

use strict;
use warnings;
use Carp;

#use Device::SerialPort;

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (
    'all' => [ qw(
    )]);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '1';

# Constants
# Message Command Bytes
use constant DIGITAL_MESSAGE        => 0x90; # send data for a digital pin
use constant ANALOG_MESSAGE         => 0xE0;  # send data for a analog pin

use constant REPORT_ANALOG_PIN      => 0xC0; # enable analog input by pin #
use constant REPORT_DIGITAL_PORTS   => 0xD0; # enable digital input by port pair
use constant START_SYSEX            => 0xF0; # start a MIDI SysEx message
use constant SET_DIGITAL_PIN_MODE   => 0xF4; # set a digital pin to INPUT or OUTPUT
use constant END_SYSEX              => 0xF7; # end a MIDI SysEx message
use constant REPORT_VERSION         => 0xF9; # report firmware version
use constant SYSTEM_RESET           => 0xFF; # reset from MIDI

# Pin modes
use constant UNAVAILABLE            => -1;
use constant DIGITAL_INPUT          => 0;
use constant DIGITAL_OUTPUT         => 1;
use constant DIGITAL_PWM            => 2;

use constant PWM_PINS => {3=>1, 5=>1, 6=>1, 9=>1, 10=>1, 11=>1};


sub new {
    my $that = shift;
    my ($device, $port, $pin_number) = @_;
    my %args = (
        Device    => $device,
        Port      => $port,
        Pin_Number => $pin_number,
        Value     => 0,
        Mode      => DIGITAL_INPUT,
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
    if ($mode == DIGITAL_PWM and not exists PWM_PINS->{$self->_get_board_pin_number()}){
        croak ("Digital pin " . $self->_get_board_pin_number() . " does not have PWM capabilities");
    }
    if ($self->{Mode} == UNAVAILABLE){
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
    if ($self->{'Mode'} == UNAVAILABLE){
        croak ("Cannot read pin " . $self->_get_board_pin_number());
    }
    return $self->{'Value'};
}

sub write {
# Output a voltage to the pin
# Argument: value.  boolean if in output mode, float from 0 to 1 if PWM.
    my $self = shift; 
    my ($value) = @_;
    if ($self->{'Mode'} == UNAVAILABLE){
        croak ("Cannot write to pin " . $self->_get_board_pin_number());

    } elsif ($self->{'Mode'} == DIGITAL_INPUT){
        croak ("Digital pin " . $self->_get_board_pin_number(). " is not an output");

    } elsif($value != $self->read()){
        $self->{'Value'} = $value;
        if ($self->{'Mode'} == DIGITAL_OUTPUT){
            $self->{'Port'}->write();
        } elsif ($self->{'Mode'} == DIGITAL_PWM){
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


