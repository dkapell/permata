package Firmata::Arduino;
require Exporter;

use strict;
use warnings;
use Carp;

use Firmata::AnalogPin;
use Firmata::DigitalPort;

if ($^O =~ /win/i){
    require Win32::SerialPort;
} else {
    require Device::SerialPort;
}

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
    my ($serial_port, $attr) = @_;
    my %args = (
        Serial_Port => $serial_port,
        Quiet=> 1,
        Firmata_Version => undef,
        ref $attr ? %$attr : (),
        Digital => [],
        Analog => [],
        DigitalPorts =>[],
    );
    unless ($args{'Serial_Port'}){
        croak("Must specify a serial port");
    }
    if ($^O =~ /win/i){
        $args{'Device'} =  new Win32::SerialPort($args{'Serial_Port'}, $args{'Quiet'}) or croak ("Can't open port $serial_port");
    } else {
        $args{'Device'} =  new Device::SerialPort($args{'Serial_Port'}, $args{'Quiet'}) or croak ("Can't open port $serial_port");
    }
    $args{'Device'}->baudrate(115200);
    $args{'Device'}->read_char_time(0);
    $args{'Device'}->read_const_time(200);
    $args{'Device'}->alias("Arduino on port $serial_port");

    my $class = ref($that) || $that;
    my $self  = { %args };

    bless $self, $class;
    sleep 2;
    
    $self->initialize();
    $self->iterate();
    return $self;
}

sub initialize{
    my $self = shift;
    
    foreach my $i (0..5) {
        push (@{$self->{'Analog'}}, new Firmata::AnalogPin($self->{'Device'}, $i));
    }
    foreach my $i (0..1){
        push (@{$self->{'DigitalPorts'}}, new Firmata::DigitalPort($self->{'Device'}, $i));
    }
    $self->{'DigitalPorts'}[0]{'Pins'}[0]->set_mode(UNAVAILABLE);
    $self->{'DigitalPorts'}[0]{'Pins'}[1]->set_mode(UNAVAILABLE);
    $self->{'DigitalPorts'}[1]{'Pins'}[6]->set_mode(UNAVAILABLE);
    $self->{'DigitalPorts'}[1]{'Pins'}[7]->set_mode(UNAVAILABLE);
    
    push ( @{$self->{'Digital'}}, @{$self->{'DigitalPorts'}[0]{'Pins'}});
    push ( @{$self->{'Digital'}}, @{$self->{'DigitalPorts'}[1]{'Pins'}}[0..5]);
}

sub info {
    my $self = shift;
    return "Firmata::Arduino: " . $self->{'Serial_Port'};
}

sub iterate {
    my $self = shift;
    my ( $bytes, $data) = $self->{'Device'}->read(1);
    if ( 1 == $bytes && $data ne ""){
        $self->_process_input(ord($data));
    }
}

sub _process_input{
    my $self = shift;
    my ($data) = @_;
    if ($data < 0xF0){
        #Multibyte
        my $message = $data & 0xF0;
        if ($message == DIGITAL_MESSAGE){
            my $port_number = $data & 0x0F;
            #Digital in
            my $lsb = "";
            my $msb = "";
            while ($lsb eq ""){
                my $bytes = undef;
                ($bytes, $lsb) = $self->{'Device'}->read(1);
                carp ("Read failed") unless (1 == $bytes);
            }
            while ($msb eq ""){
                my $bytes = undef;
                ($bytes, $msb) = $self->{'Device'}->read(1);
                carp ("Read failed") unless (1 == $bytes);
            }
            $lsb = ord($lsb);
            $msb = ord($msb);
            $self->{'DigitalPorts'}[$port_number]->set_value($msb << 7 | $lsb);

        } elsif ($message == ANALOG_MESSAGE){
            my $pin_number = $data & 0x0f;
            my $lsb = "";
            my $msb = "";
            while ($lsb eq ""){
                my $bytes = undef;
                ($bytes, $lsb) = $self->{'Device'}->read(1);
                carp ("Read failed") unless (1 == $bytes);
            }
            while ($msb eq ""){
                my $bytes = undef;
                ($bytes, $msb) = $self->{'Device'}->read(1);
                carp ("Read failed") unless (1 == $bytes);
            }
            $lsb = ord($lsb);
            $msb = ord($msb);
            my $value = ($msb << 7 | $lsb ) /1023;
            $self->{'Analog'}[$pin_number]->set_value($value);
        }
    } elsif ($data == REPORT_VERSION){
        my ($bytes, $minor, $major) = ();
        ($bytes, $minor) = $self->{'Device'}->read(1);
        carp ("Read failed") unless (1 == $bytes);
        ($bytes, $major) = $self->{'Device'}->read(1);
        carp ("Read failed") unless (1 == $bytes);

        $self->{'Firmata_Version'} = ord($major) . ord($minor);
    }
}

sub get_firmata_version{
    my $self = shift;
    return $self->{'Firmata_Version'};
}

sub DESTROY{
    my $self = shift;
    $self->{'Device'}->close();
    undef $self->{'Device'};
}
