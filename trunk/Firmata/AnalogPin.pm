package Firmata::AnalogPin;
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

use constant PWM_PINS => (9,10,11);


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
    return $self->{'Value'};
}


