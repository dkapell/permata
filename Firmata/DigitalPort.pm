package Firmata::DigitalPort;

use strict;
use warnings;
use Carp;

use Firmata::Constants;
use Firmata::DigitalPin;

sub new {
    my $that = shift;
    my ( $device, $port, $pwm_list ) = @_;
    my %args = (
        Device      => $device,
        Port_Number => $port,
        Active      => 0,
        Pins        => [],
    );
    my $class = ref($that) || $that;
    my $self = {%args};

    bless $self, $class;
    foreach my $i ( 0 .. 7 ) {
        push(
            @{ $self->{'Pins'} },
            new Firmata::DigitalPin( $device, $self, $i,
                $pwm_list->{$port}{$i} )
        );
    }
    return $self;
}

sub info {
    my $self = shift;
    return "Digital Port " . $self->{'Port_Number'};
}

sub set_active {
    my $self = shift;
    my ($active) = @_;

    $self->{'Active'} = $active;

    my $message = chr( REPORT_DIGITAL_PORTS + $self->{'Port_Number'} );
    $message .= chr($active);

    my $bytes = $self->{'Device'}->write($message);
    carp("Write failed") unless ($bytes);
    carp("Write incomplete") unless ( $bytes == length($message) );

}

sub get_active {
    my $self = shift;
    return $self->{'Active'};
}

sub get_port_number {
    my $self = shift;
    return $self->{'Port_Number'};
}

sub set_value {
    my $self = shift;
    my ($mask) = @_;
    foreach my $pin ( @{ $self->{'Pins'} } ) {
        if ( $pin->get_mode() == PIN_MODES->{DIGITAL_INPUT} ) {
            $pin->set_value( ( $mask & ( 1 << $pin . get_pin_number() ) ) > 1 );
        }
    }

    sub write {
        my $self = shift;
        my $mask = 0;
        foreach my $pin ( @{ $self->{'Pins'} } ) {
            if ( $pin->get_mode() == PIN_MODES->{DIGITAL_OUTPUT} ) {
                if ( $pin->get_value() == 1 ) {
                    $mask |= 1 << $pin->get_pin_number();
                }
            }
        }
        my $message = chr( DIGITAL_MESSAGE + $self->{'Port_Number'} );
        $message .= chr( $mask % 128 );
        $message .= chr( $mask >> 7 );
        $self->{'Device'}->write($message);
    }

    return $self->{'Value'};
}

1;