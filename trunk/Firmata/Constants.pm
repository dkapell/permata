package Firmata::Constants;
require Exporter;

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (
    'all' => [ qw(
    )]);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(  
    DIGITAL_MESSAGE ANALOG_MESSAGE
    REPORT_ANALOG_PIN REPORT_DIGITAL_PORTS START_SYSEX SET_DIGITAL_PIN_MODE END_SYSEX REPORT_VERSION SYSTEM_RESET
    PIN_MODES
    DEBUG
);

our $VERSION = '1';

# Constants
use constant {
    DIGITAL_MESSAGE        => 0x90, # send data for a digital pin
    ANALOG_MESSAGE         => 0xE0,  # send data for a analog pin
};

use constant {
    REPORT_ANALOG_PIN      => 0xC0, # enable analog input by pin #
    REPORT_DIGITAL_PORTS   => 0xD0, # enable digital input by port pair
    START_SYSEX            => 0xF0, # start a MIDI SysEx message
    SET_DIGITAL_PIN_MODE   => 0xF4, # set a digital pin to INPUT or OUTPUT
    END_SYSEX              => 0xF7, # end a MIDI SysEx message
    REPORT_VERSION         => 0xF9, # report firmware version
    SYSTEM_RESET           => 0xFF, # reset from MIDI
};

use constant PIN_MODES => {
    UNAVAILABLE            => -1,
    DIGITAL_INPUT          => 0,
    DIGITAL_OUTPUT         => 1,
    DIGITAL_PWM            => 2,
};

use constant DEBUG => 0;

1;