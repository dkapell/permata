package Firmata::DigitalPort;
require Exporter;

use strict;
use warnings;
use Carp;
use Firmata::DigitalPin;

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

use constant PWM_PINS => {9=>1, 10=>1, 11=>1};


sub new {
    my $that = shift;
    my ($device, $port) = @_;
    my %args = (
        Device      => $device,
        Port_Number => $port,
        Active      => 0,
        Pins        => [],
    );
    my $class = ref($that) || $that;
    my $self  = { %args };

    bless $self, $class;
    foreach my $i (0..7){
        push(@{$self->{'Pins'}}, new Firmata::DigitalPin($device, $self, $i));
    }
    return $self;
}

sub info{
    my $self = shift;
    return "Digital Port " . $self->{'Port_Number'};
}

sub set_active{
    my $self = shift;
    my ($active) = @_;
    $self->{'Active'} = $active;
    my $message = chr(REPORT_DIGITAL_PORTS + $self->{'Port_Number'});
    $message .= chr($active);
    my $bytes = $self->{'Device'}->write($message);
    carp ("Write failed")       unless ($bytes);
    carp ("Write incomplete")   unless ($bytes == length($message));

}

sub get_active{
    my $self = shift;
    return $self->{'Active'};
}

sub get_port_number{
    my $self = shift;
    return $self->{'Port_Number'};
}

sub set_value{
    my $self = shift;
    my ($mask) = @_;
    foreach my $pin (@{$self->{'Pins'}}){
    if ($pin->get_mode() == DIGITAL_INPUT){
        $pin->set_value(($mask & (1 << $pin.get_pin_number())) > 1)
    }
}

sub write{
    my $self = shift;
    my $mask = 0;
    foreach my $pin (@{$self->{'Pins'}}){
        if ($pin->get_mode() == DIGITAL_OUTPUT){
            if ($pin->get_value() == 1){
                $mask |= 1 << $pin->get_pin_number();
            }
        }
    }
    my $message = chr(DIGITAL_MESSAGE + $self->{'Port_Number'});
    $message .= chr($mask % 128);
    $message .= chr($mask >> 7);
    $self->{'Device'}->write($message);
}

    return $self->{'Value'};
}
