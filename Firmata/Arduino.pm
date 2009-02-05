package Firmata::Arduino;

use strict;
use warnings;
use Carp;

use Firmata::Constants;
use Firmata::AnalogPin;
use Firmata::DigitalPort;

# Unique to Arduino.  Change for implimenting other hardware.

use constant PWM_PINS => {
    0 => {0=>0, 1=>0, 2=>0, 3=>1, 4=>0, 5=>1, 6=>1, 7=>0},
    1 => {0=>0, 1=>1, 2=>1, 3=>1, 4=>0, 5=>0, 6=>0, 7=>0}, 
}; 

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
    
    $self->initialize(); # Build pin tree
    $self->iterate();    # Get data
    return $self;
}

sub initialize{
    my $self = shift;
    
    foreach my $i (0..5) {
        push (@{$self->{'Analog'}}, new Firmata::AnalogPin($self->{'Device'}, $i));
    }
    foreach my $i (0..1){
        push (@{$self->{'DigitalPorts'}}, new Firmata::DigitalPort($self->{'Device'}, $i, PWM_PINS));
    }
    $self->{'DigitalPorts'}[0]{'Pins'}[0]->set_mode(PIN_MODES->{UNAVAILABLE});  # TX and RX
    $self->{'DigitalPorts'}[0]{'Pins'}[1]->set_mode(PIN_MODES->{UNAVAILABLE});  # Are dangerous to use
    
    $self->{'DigitalPorts'}[1]{'Pins'}[6]->set_mode(PIN_MODES->{UNAVAILABLE});  # Not available
    $self->{'DigitalPorts'}[1]{'Pins'}[7]->set_mode(PIN_MODES->{UNAVAILABLE});  # on Arduino
    
    # Build convience array
    push ( @{$self->{'Digital'}}, @{$self->{'DigitalPorts'}[0]{'Pins'}});
    push ( @{$self->{'Digital'}}, @{$self->{'DigitalPorts'}[1]{'Pins'}}[0..5]);
}

sub pin_modes{
    # Returns the list of pin modes
    my $self = shift;
    return keys %{PIN_MODES()};
}

sub get_digital_pin{
    # returns a pin object
    my $self = shift;
    my ($pin) = @_;
    return $self->{'Digital'}[$pin];
}

sub get_analog_pin{
    # returns a pin object
    my $self = shift;
    my ($pin) = @_;
    return $self->{'Analog'}[$pin];
}

sub set_digital_pin_mode {
    my $self = shift;
    my ($pin, $mode) = @_;
    if ($mode == PIN_MODES->{UNAVAILABLE}){
        my $active = 0;
        # look for active pins in the port
        foreach my $dpin (@{$self->{'DigitalPorts'}[$pin >> 3 ]{Pins}}){
            $active++ if ($dpin->get_mode() != PIN_MODES->{UNAVAILABLE});
        }
        unless($active){ # Turn off port if no active pins
            $self->{'DigitalPorts'}[ $pin >> 3 ]->set_active(0) || return 0;
        }
                
    } else {
        # Turn on port
        $self->{'DigitalPorts'}[ $pin >> 3 ]->set_active(1) || return 0;
    }
    # Set pin mode
    $self->{'Digital'}[$pin]->set_mode($mode)           || return 0;
    return 1;
}

sub read_digital_pin{
    my $self = shift;
    my ($pin) = @_;
    return $self->{'Digital'}[$pin]->read();
}

sub write_digital_pin{
    my $self = shift;
    my ($pin, $value) = @_;
    return $self->{'Digital'}[$pin]->write($value);
}

sub activate_analog_pin {
    my $self = shift;
    my ($pin) = @_;
    $self->{'Analog'}[$pin]->set_active(1);
}

sub read_analog_pin{
    my $self = shift;
    my ($pin) = @_;
    return $self->{'Analog'}[$pin]->read();
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

1;