package Zaaksysteem::DB::Component::ZaaktypeFase;

use Moose;
use Data::FormValidator::Results;
use Data::Dumper;
use Zaaksysteem::Constants qw/ZAAKSYSTEEM_CONSTANTS/;

extends qw/DBIx::Class/;

sub validate_kenmerken {
    my $self        = shift;
    my $data        = shift;
    my $options     = shift;

    my $profile = $self->_build_kenmerken_validatie_profile($options, $data);

    return Data::FormValidator::Results->new($profile, $data);
}

sub _build_kenmerken_validatie_profile {
    my $self        = shift;
    my $options     = shift;
    my $data        = shift;

    my $profile     = {
        required            => [],
        optional            => [qw/
            npc-email
            npc-telefoonnummer
            npc-mobiel
        /],
        constraint_methods  => {
            'npc-email'             => qr/^.+?\@.+\.[a-z0-9]{2,}$/,
            'npc-telefoonnummer'    => qr/^[\d\+]{6,15}$/,
            'npc-mobiel'            => qr/^[\d\+]{6,15}$/,
        },
        msgs                => {
            'format'    => '%s',
            'missing'   => 'Veld is verplicht.',
            'invalid'   => 'Veld is niet correct ingevuld.',
            'constraints' => {
                '(?-xism:^[\d\+]{6,15}$)'         => 'Nummer zonder spatie (e.g: +312012345678)',
            }
        },
    };

    my $kenmerken   = $self->zaaktype_kenmerken->search(
        {},
        {
            prefetch    => 'bibliotheek_kenmerken_id'
        }
    );

#warn Dumper $data;
    while (my $kenmerk = $kenmerken->next) {
        next unless $kenmerk->bibliotheek_kenmerken_id;

#        warn Dumper "type: " . $kenmerk->type;
#        if($kenmerk->type eq 'option') {
#            my $key =  ($options->{with_prefix} ? 'kenmerk_id_' : '') . $kenmerk->bibliotheek_kenmerken_id->id;
#            my $value =  $data->{$key};
#            warn "value: " . Dumper $value;
#        }
        
        if (
            $options &&
            $options->{ignore_undefined} &&
            !defined($data->{
                    ($options->{with_prefix}
                        ? 'kenmerk_id_'
                        : ''
                    ) . $kenmerk->bibliotheek_kenmerken_id->id
            })
        ) {
            next;
        }

        my $kenmerk_id  = ($options && $options->{with_prefix}
            ? 'kenmerk_id_'
            : ''
        ) . $kenmerk->bibliotheek_kenmerken_id->id;

        if ($kenmerk->value_mandatory) {
            push(@{ $profile->{required} }, $kenmerk_id);
        } else {
            push(@{ $profile->{optional} }, $kenmerk_id);
        }
    }

    return $profile;
}

1;
