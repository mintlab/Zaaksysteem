package Zaaksysteem::Constants;

use strict;
use warnings;

use DateTime;
use Scalar::Util qw/blessed/;
use Data::Dumper;

use utf8;

require Exporter;
our @ISA        = qw/Exporter/;
our @EXPORT     = qw/
    ZAAKSYSTEEM_CONSTANTS
    ZAAKSYSTEEM_NAMING
    ZAAKSYSTEEM_OPTIONS
    ZAAKTYPE_DB_MAP

    ZAAKTYPE_PREFIX_SPEC_KENMERK
    ZAAKTYPE_KENMERKEN_ZTC_DEFINITIE
    ZAAKTYPE_KENMERKEN_DYN_DEFINITIE

    GEGEVENSMAGAZIJN_GBA_PROFILE
    GEGEVENSMAGAZIJN_GBA_ADRES_EXCLUDES

    GEGEVENSMAGAZIJN_KVK_PROFILE
    GEGEVENSMAGAZIJN_KVK_RECHTSVORMCODES

    ZAAKSYSTEEM_AUTHORIZATION_ROLES
    ZAAKSYSTEEM_AUTHORIZATION_PERMISSIONS

    SJABLONEN_EXPORT_FORMATS

    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_DIGID
    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEDRIJFID
    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_GBA
    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_KVK
    ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEHANDELAAR

    ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_HIGH
    ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_MEDIUM
    ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_LATE

    ZAAKSYSTEEM_STANDAARD_KENMERKEN
    ZAAKSYSTEEM_STANDAARD_KOLOMMEN
    ZAAKSYSTEEM_BETROKKENE_KENMERK
    ZAAKSYSTEEM_BETROKKENE_SUB

    ZAAKSYSTEEM_LOGGING_LEVELS
    LOGGING_COMPONENT_ZAAK
    LOGGING_COMPONENT_NOTITIE
    LOGGING_COMPONENT_BETROKKENE
    LOGGING_COMPONENT_KENMERK
    LOGGING_COMPONENT_DOCUMENT

    LDAP_DIV_MEDEWERKER

    DEFAULT_KENMERKEN_GROUP_DATA

    ZAKEN_STATUSSEN
    ZAKEN_STATUSSEN_DEFAULT

    SEARCH_QUERY_SESSION_VAR
    SEARCH_QUERY_TABLE_NAME

    ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM
    ZAAKSYSTEEM_CONTACTKANAAL_BALIE

    VALIDATION_CONTACT_DATA

    ZAAK_CREATE_PROFILE
    ZAAKTYPE_DEPENDENCY_IDS
    ZAAKTYPE_DEPENDENCIES

    BETROKKENE_RELATEREN_PROFILE
    BETROKKENE_RELATEREN_MAGIC_STRING_SUGGESTION

    ZAAK_WIJZIG_VERNIETIGINGSDATUM_PROFILE

    PARAMS_PROFILE_MESSAGES_SUB

    ZAAKSYSTEEM_NAAM
    ZAAKSYSTEEM_OMSCHRIJVING
    ZAAKSYSTEEM_LEVERANCIER
    ZAAKSYSTEEM_STARTDATUM
    ZAAKSYSTEEM_LICENSE
    PARAMS_PROFILE_DEFAULT_MSGS
/;

### DO NOT FREAKING TOUCH ;)
### {
use constant ZAAKSYSTEEM_GM_AUTHENTICATEDBY_DIGID       => 'digid';
use constant ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEDRIJFID   => 'bedrijfid';
use constant ZAAKSYSTEEM_GM_AUTHENTICATEDBY_GBA         => 'gba';
use constant ZAAKSYSTEEM_GM_AUTHENTICATEDBY_KVK         => 'kvk';
use constant ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEHANDELAAR => 'behandelaar';

use constant ZAAKTYPE_PREFIX_SPEC_KENMERK   => 'spec';

use constant ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_MEDIUM      => 0.2;
use constant ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_HIGH        => 0.1;
use constant ZAAKSYSTEEM_ZAAK_URGENTIE_PERC_LATE        => 1;

use constant ZAAKSYSTEEM_LOGGING_LEVEL_DEBUG            => 'debug';
use constant ZAAKSYSTEEM_LOGGING_LEVEL_INFO             => 'info';
use constant ZAAKSYSTEEM_LOGGING_LEVEL_WARN             => 'warn';
use constant ZAAKSYSTEEM_LOGGING_LEVEL_ERROR            => 'error';
use constant ZAAKSYSTEEM_LOGGING_LEVEL_FATAL            => 'fatal';

use constant ZAAKSYSTEEM_LOGGING_LEVELS                 => {
    ZAAKSYSTEEM_LOGGING_LEVEL_DEBUG     => 1,
    ZAAKSYSTEEM_LOGGING_LEVEL_INFO      => 2,
    ZAAKSYSTEEM_LOGGING_LEVEL_WARN      => 3,
    ZAAKSYSTEEM_LOGGING_LEVEL_ERROR     => 4,
    ZAAKSYSTEEM_LOGGING_LEVEL_FATAL     => 5
};

use constant LOGGING_COMPONENT_ZAAK         => 'zaak';
use constant LOGGING_COMPONENT_NOTITIE      => 'notitie';
use constant LOGGING_COMPONENT_BETROKKENE   => 'betrokkene';
use constant LOGGING_COMPONENT_KENMERK      => 'kenmerk';
use constant LOGGING_COMPONENT_DOCUMENT     => 'document';

use constant ZAKEN_STATUSSEN                => [ qw/new open stalled resolved deleted/ ];
use constant ZAKEN_STATUSSEN_DEFAULT        => 'new';

use constant ZAAKSYSTEEM_NAAM               => 'zaaksysteem.nl';
use constant ZAAKSYSTEEM_OMSCHRIJVING       => 'Het zaaksysteem.nl is een '
                                                .'complete oplossing '
                                                .'(all-in-one) voor '
                                                .'gemeenten om de '
                                                .'dienstverlening te '
                                                .'verbeteren.';
use constant ZAAKSYSTEEM_LEVERANCIER        => 'Mintlab B.V.';
use constant ZAAKSYSTEEM_STARTDATUM         => '01-10-2009';
use constant ZAAKSYSTEEM_LICENSE            => 'EUPL';

### } END DO NOT FREAKING TOUCH

use constant ZAAKSYSTEEM_NAMING     => {
    TRIGGER_EXTERN                              => 'extern',
    TRIGGER_INTERN                              => 'intern',
    AANVRAGER_TYPE_NATUURLIJK_PERSOON           => 'natuurlijk_persoon',
    AANVRAGER_TYPE_NATUURLIJK_PERSOON_NA        => 'natuurlijk_persoon_na',
    AANVRAGER_TYPE_NIET_NATUURLIJK_PERSOON      => 'niet_natuurlijk_persoon',
    AANVRAGER_TYPE_NIET_NATUURLIJK_PERSOON_NA   => 'niet_natuurlijk_persoon_na',
    AANVRAGER_TYPE_MEDEWERKER                   => 'medewerker',
    AANVRAGER_ADRES_TYPE_ADRES                  => 'aanvrager_adres',
    AANVRAGER_ADRES_TYPE_ANDERS                 => 'anders',
    WEBFORM_TOEGANG                             => 'webform_toegang',
    WEBFORM_AUTHENTICATIE_AAN                   => 'authenticatie',
    WEBFORM_AUTHENTICATIE_OPTIONEEL             => 'optie',
    HANDELINGSINITIATOR_AANGAAN                 => 'aangaan',
    HANDELINGSINITIATOR_AANGEVEN                => 'aangeven',
    HANDELINGSINITIATOR_AANMELDEN               => 'aanmelden',
    HANDELINGSINITIATOR_AANVRAGEN               => 'aanvragen',
    HANDELINGSINITIATOR_AFKOPEN                 => 'afkopen',
    HANDELINGSINITIATOR_AFMELDEN                => 'afmelden',
    HANDELINGSINITIATOR_INDIENEN                => 'indienen',
    HANDELINGSINITIATOR_INSCHRIJVEN             => 'inschrijven',
    HANDELINGSINITIATOR_MELDEN                  => 'melden',
    HANDELINGSINITIATOR_OPZEGGEN                => 'opzeggen',
    HANDELINGSINITIATOR_REGISTREREN             => 'registreren',
    HANDELINGSINITIATOR_RESERVEREN              => 'reserveren',
    HANDELINGSINITIATOR_STELLEN                 => 'stellen',
    HANDELINGSINITIATOR_VOORDRAGEN              => 'voordragen',
    HANDELINGSINITIATOR_VRAGEN                  => 'vragen',
    HANDELINGSINITIATOR_ONTVANGEN               => 'ontvangen',
    HANDELINGSINITIATOR_AANSCHRIJVEN            => 'aanschrijven',
    HANDELINGSINITIATOR_VASTSTELLEN             => 'vaststellen',
    HANDELINGSINITIATOR_VERSTUREN               => 'versturen',
    HANDELINGSINITIATOR_UITVOEREN               => 'uitvoeren',
    HANDELINGSINITIATOR_OPSTELLEN               => 'opstellen',
    HANDELINGSINITIATOR_STARTEN                 => 'starten',
    BESLUITTYPE_COLLEGEBESLUIT                  => 'collegebesluit',
    BESLUITTYPE_RAADSBESLUIT                    => 'raadsbesluit',
    BESLUITTYPE_MANDAATBESLUIT                  => 'mandaatbesluit',
    OPENBAARHEID_OPENBAAR                       => 'openbaar',
    OPENBAARHEID_GESLOTEN                       => 'gesloten',
    TERMS_TYPE_KALENDERDAGEN                    => 'kalenderdagen',
    TERMS_TYPE_WEKEN                            => 'weken',
    TERMS_TYPE_WERKDAGEN                        => 'werkdagen',
    TERMS_TYPE_EINDDATUM                        => 'einddatum',
    RESULTAATTYPE_VERLEEND                      => 'verleend',
    RESULTAATTYPE_TOEGEKEND                     => 'toegekend',
    RESULTAATTYPE_AFGEWEZEN                     => 'afgewezen',
    RESULTAATTYPE_VERWERKT                      => 'verwerkt',
    RESULTAATTYPE_GEGROND                       => 'gegrond',
    RESULTAATTYPE_ONGEGROND                     => 'ongegrond',
    RESULTAATTYPE_GEWEIGERD                     => 'geweigerd',
    RESULTAATTYPE_NIETNODIG                     => 'niet nodig',
    RESULTAATTYPE_ONTVANKELIJK                  => 'ontvankelijk',
    RESULTAATTYPE_NIETONTVANKELIJK              => 'niet ontvankelijk',
    RESULTAATTYPE_NIETVASTGESTELD               => 'niet vastgesteld',
    RESULTAATTYPE_VASTGESTELD                   => 'vastgesteld',
    RESULTAATTYPE_INGETROKKEN                   => 'ingetrokken',
    RESULTAATTYPE_OPGELOST                      => 'opgelost',
    RESULTAATTYPE_OPGEZEGD                      => 'opgezegd',
    RESULTAATTYPE_VOORLOPIG_VERLEEND            => 'voorlopig verleend',
    RESULTAATTYPE_VOORLOPIG_TOEGEKEND           => 'voorlopig toegekend',
    RESULTAATTYPE_AFGESLOTEN                    => 'afgesloten',
    RESULTAATTYPE_GEGUND                        => 'gegund',
    RESULTAATTYPE_VERNIETIGD                    => 'vernietigd',
    RESULTAATTYPE_GEANNULEERD                   => 'geannuleerd',
    RESULTAATINGANG_VERVALLEN                   => 'vervallen',
    RESULTAATINGANG_ONHERROEPELIJK              => 'onherroepelijk',
    RESULTAATINGANG_AFHANDELING                 => 'afhandeling',
    RESULTAATINGANG_VERWERKING                  => 'verwerking',
    RESULTAATINGANG_GEWEIGERD                   => 'geweigerd',
    RESULTAATINGANG_VERLEEND                    => 'verleend',
    RESULTAATINGANG_GEBOORTE                    => 'geboorte',
    RESULTAATINGANG_EINDE_DIENSTVERBAND         => 'einde-dienstverband',
    DOSSIERTYPE_DIGITAAL                        => 'digitaal',
    DOSSIERTYPE_FYSIEK                          => 'fysiek',
};


use constant ZAAKSYSTEEM_OPTIONS    => {
    'RESULTAATINGANGEN'   => [
        ZAAKSYSTEEM_NAMING->{RESULTAATINGANG_VERVALLEN},
        ZAAKSYSTEEM_NAMING->{RESULTAATINGANG_ONHERROEPELIJK},
        ZAAKSYSTEEM_NAMING->{RESULTAATINGANG_AFHANDELING},
        ZAAKSYSTEEM_NAMING->{RESULTAATINGANG_VERWERKING},
        ZAAKSYSTEEM_NAMING->{RESULTAATINGANG_GEWEIGERD},
        ZAAKSYSTEEM_NAMING->{RESULTAATINGANG_VERLEEND},
        ZAAKSYSTEEM_NAMING->{RESULTAATINGANG_GEBOORTE},
        ZAAKSYSTEEM_NAMING->{RESULTAATINGANG_EINDE_DIENSTVERBAND},
    ],
    'DOSSIERTYPE'       => [
        ZAAKSYSTEEM_NAMING->{DOSSIERTYPE_DIGITAAL},
        ZAAKSYSTEEM_NAMING->{DOSSIERTYPE_FYSIEK}
    ],
    'BEWAARTERMIJN'     => {
        62      => '3 maanden',
        365     => '1 jaar',
        184     => '1,5 jaar',
        730     => '2 jaar',
        1095    => '3 jaar',
        1460    => '4 jaar',
        1825    => '5 jaar',
        2190    => '6 jaar',
        2555    => '7 jaar',
        2920    => '8 jaar',
        3285    => '9 jaar',
        3650    => '10 jaar',
        4015    => '11 jaar',
        4380    => '12 jaar',
        4745    => '13 jaar',
        5110    => '14 jaar',
        5475    => '15 jaar',
        7300    => '20 jaar',
        10950   => '30 jaar',
        14600   => '40 jaar',
        40150   => '110 jaar',
        99999   => 'Bewaren',
    },
    WEBFORM_AUTHENTICATIE   => [
        ZAAKSYSTEEM_NAMING->{WEBFORM_AUTHENTICATIE_AAN},
        ZAAKSYSTEEM_NAMING->{WEBFORM_AUTHENTICATIE_OPTIONEEL},
    ],
    TRIGGERS                => [
        ZAAKSYSTEEM_NAMING->{TRIGGER_EXTERN},
        ZAAKSYSTEEM_NAMING->{TRIGGER_INTERN},
    ],
    AANVRAGERS_INTERN       => [
        ZAAKSYSTEEM_NAMING->{AANVRAGER_TYPE_NATUURLIJK_PERSOON},
        ZAAKSYSTEEM_NAMING->{AANVRAGER_TYPE_NATUURLIJK_PERSOON_NA},
        ZAAKSYSTEEM_NAMING->{AANVRAGER_TYPE_NIET_NATUURLIJK_PERSOON},
        ZAAKSYSTEEM_NAMING->{AANVRAGER_TYPE_NIET_NATUURLIJK_PERSOON_NA},
    ],
    AANVRAGERS_EXTERN       => [
        ZAAKSYSTEEM_NAMING->{AANVRAGER_TYPE_MEDEWERKER},
    ],
    AANVRAGER_ADRES_TYPEN   => [
        ZAAKSYSTEEM_NAMING->{AANVRAGER_ADRES_TYPE_ADRES},
        ZAAKSYSTEEM_NAMING->{AANVRAGER_ADRES_TYPE_ANDERS},
    ],
    HANDELINGSINITIATORS    => [
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_AANGEVEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_AANMELDEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_AANVRAGEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_AFKOPEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_AFMELDEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_INDIENEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_INSCHRIJVEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_MELDEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_RESERVEREN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_STELLEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_VOORDRAGEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_VRAGEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_ONTVANGEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_AANSCHRIJVEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_VASTSTELLEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_UITVOEREN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_OPSTELLEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_STARTEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_OPZEGGEN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_AANGAAN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_REGISTREREN},
        ZAAKSYSTEEM_NAMING->{HANDELINGSINITIATOR_VERSTUREN},
        ],
    BESLUITTYPEN            => [
        ZAAKSYSTEEM_NAMING->{BESLUITTYPE_COLLEGEBESLUIT},
        ZAAKSYSTEEM_NAMING->{BESLUITTYPE_RAADSBESLUIT},
        ZAAKSYSTEEM_NAMING->{BESLUITTYPE_MANDAATBESLUIT},
    ],
    OPENBAARHEDEN           => [
        ZAAKSYSTEEM_NAMING->{OPENBAARHEID_OPENBAAR},
        ZAAKSYSTEEM_NAMING->{OPENBAARHEID_GESLOTEN},
    ],
    RESULTAATTYPEN          => [
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_VERLEEND},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_TOEGEKEND},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_AFGEWEZEN},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_VERWERKT},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_GEGROND},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_ONGEGROND},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_GEWEIGERD},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_NIETNODIG},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_ONTVANKELIJK},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_NIETONTVANKELIJK},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_NIETVASTGESTELD},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_INGETROKKEN},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_OPGELOST},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_VASTGESTELD},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_OPGEZEGD},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_VOORLOPIG_VERLEEND},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_VOORLOPIG_TOEGEKEND},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_AFGESLOTEN},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_GEGUND},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_VERNIETIGD},
        ZAAKSYSTEEM_NAMING->{RESULTAATTYPE_GEANNULEERD},
    ],
};


use constant ZAAKTYPE_DB_MAP    => {
    'kenmerken'                     => {
        'id'            => 'id',
        'naam'          => 'key',
        'label'         => 'label',
        'type'          => 'value_type',
        'omschrijving'  => 'description',
        'help'          => 'help',
        #'value'         => 'value'             # Value of kenmerken_values
                                                # FOR: ztc
#        'magicstring'   => 'magicstring',
    },
    'kenmerken_values'              => {
        'value'         => 'value',
    },
};

use constant ZAAKTYPE_KENMERKEN_ZTC_DEFINITIE   => [
    {
        'naam'          => 'zaaktype_id',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'zaaktype_nid',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'zaaktype_naam',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'zaaktype_code',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'categorie_naam',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'categorie_id',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'mogelijke_aanvragers',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'trigger',
        'in_node'       => 1,
    },
    {
        'naam'          => 'webform_authenticatie',
        'in_node'       => 1,
    },
    {
        'naam'          => 'adres_relatie',
        'in_node'       => 1,
    },
    {
        'naam'          => 'handelingsinitiator'
    },
    {
        'naam'          => 'iv3_categorie',
    },
    {
        'naam'          => 'grondslag',
    },
    {
        'naam'          => 'selectielijst',
    },
    {
        'naam'          => 'afhandeltermijn',
    },
    {
        'naam'          => 'afhandeltermijn_type',
    },
    {
        'naam'          => 'servicenorm',
    },
    {
        'naam'          => 'servicenorm_type',
    },
    {
        'naam'          => 'besluittype',
    },
    {
        'naam'          => 'openbaarheid',
    },
    {
        'naam'          => 'procesbeschrijving',
    },
];

use constant ZAAKTYPE_KENMERKEN_DYN_DEFINITIE   => [
    {
        'naam'          => 'status',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'bag_items',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'streefafhandeldatum',
    },
    {
        'naam'          => 'contactkanaal',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'behandelaar',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'zaakeigenaar',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'aanvrager',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'org_eenheid',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'aanvrager_verificatie',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'aanvrager_geslachtsnaam',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'aanvrager_naam',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'aanvrager_telefoon',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'aanvrager_mobiel',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'aanvrager_email',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'registratiedatum',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'afhandeldatum',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'vernietigingsdatum',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'besluit',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'bezwaar',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'locatie',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'depend_info',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'vroegtijdig_info',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'registratiedatum',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'urgentiedatum_high',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'urgentiedatum_medium',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'route_ou_role',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'opgeschort_info',
        'in_rt_only'    => 1,
    },
    {
        'naam'          => 'resultaat',
        'in_rt_only'    => 1,
    },
];

use constant 'GEGEVENSMAGAZIJN_GBA_ADRES_EXCLUDES'     => [qw/
    straatnaam
    huisnummer
    postcode
    huisnummertoevoeging
    huisletter
    woonplaats
    functie_adres
    gemeente_code
/];

use constant PARAMS_PROFILE_MESSAGES_SUB                => sub {
    my $dfv     = shift;
    my $rv      = {};

    for my $missing ($dfv->missing) {
        $rv->{$missing}  = 'Veld is verplicht.';
    }
    for my $missing ($dfv->invalid) {
        $rv->{$missing}  = 'Veld is niet correct ingevuld.';
    }

    return $rv;
};

use constant 'GEGEVENSMAGAZIJN_GBA_PROFILE'     => {
    'required'      => [qw/
        straatnaam
        huisnummer
        postcode

        burgerservicenummer
        geslachtsnaam
        geslachtsaanduiding
        geboortedatum
    /],
    'optional'      => [qw/
        voornamen
        huisnummertoevoeging
        huisletter
        woonplaats
        geboorteplaats
        geboorteland
        a_nummer

        voorletters
        voorvoegsel
        nationaliteitscode1
        nationaliteitscode2
        nationaliteitscode3
        geboortegemeente_omschrijving
        geboorteregio
        aanhef_aanschrijving
        voorletters_aanschrijving
        voornamen_aanschrijving
        naam_aanschrijving
        voorvoegsel_aanschrijving
        burgerlijke_staat
        indicatie_gezag
        indicatie_curatele
        indicatie_geheim
        aanduiding_verblijfsrecht
        datum_aanvang_verblijfsrecht
        datum_einde_verblijfsrecht
        aanduiding_soort_vreemdeling
        land_vanwaar_ingeschreven
        land_waarnaar_vertrokken
        adres_buitenland1
        adres_buitenland2
        adres_buitenland3
        nnp_ts
        hash
        import_datum
        adres_id
        email
        telefoon
        geboortegemeente
        authenticated
        authenticatedby

        aanduiding_naamgebruik
        functie_adres
        onderzoek_persoon
        onderzoek_persoon_ingang
        onderzoek_persoon_einde
        onderzoek_persoon_onjuist
        onderzoek_huwelijk
        onderzoek_huwelijk_ingang
        onderzoek_huwelijk_einde
        onderzoek_huwelijk_onjuist
        onderzoek_overlijden
        onderzoek_overlijden_ingang
        onderzoek_overlijden_einde
        onderzoek_overlijden_onjuist
        onderzoek_verblijfplaats
        onderzoek_verblijfplaats_ingang
        onderzoek_verblijfplaats_einde
        onderzoek_verblijfplaats_onjuist

        datum_overlijden

        partner_a_nummer
        partner_voorvoegsel
        partner_geslachtsnaam
        partner_burgerservicenummer
        datum_huwelijk
        datum_huwelijk_ontbinding

        gemeente_code
    /],
    constraint_methods => {
        'geslachtsaanduiding'   => qr/^[MV]$/,
    },
    field_filters     => {
        'burgerservicenummer'   => sub {
            my ($field) = @_;

            return $field if length($field) == 9;

            return sprintf("%09d", $field);
        },
        'postcode'    => sub {
            my ($field) = @_;

            $field = uc($field);
            $field =~ s/\s*//g;

            return $field;
        },
        'huisnummer'    => sub {
            my ($field) = @_;

            return undef unless $field =~ /^\d+$/;

            return $field;
        },
        'huisnummertoevoeging'    => sub {
            my ($field) = @_;

            return undef unless $field =~ /^[\w\d\s-]+$/;

            return $field;
        },
        'geboortedatum'             => sub {
            my ($field) = @_;

            return undef unless $field =~ /^[\d-]+$/;

            if ($field =~ /^\d{8}$/) {
                my ($year, $month, $day) = $field =~ /^(\d{4})(\d{2})(\d{2})$/;

                $month  = 1 if $month    < 1;
                $day    = 1 if $day      < 1;

                my $dt;

                eval {
                    $dt      = DateTime->new(
                        'year'          => $year,
                        'month'         => $month,
                        'day'           => $day,
                        #'time_zone'     => 'Europe/Amsterdam',
                    );
                };

                if ($@) {
                    $dt = undef;
                }

                return $dt;
            } elsif ($field =~ /^(\d{2})-(\d{2})-(\d{4})$/) {
                my ($day, $month, $year) = $field =~
                    /^(\d{2})-(\d{2})-(\d{4})$/;

                $month  = 1 if $month    < 1;
                $day    = 1 if $day      < 1;

                my $dt;

                eval {
                    $dt      = DateTime->new(
                        'year'          => $year,
                        'month'         => $month,
                        'day'           => $day,
                        #'time_zone'     => 'Europe/Amsterdam',
                    );
                };

                if ($@) {
                    $dt = undef;
                }

                return $dt;
            }

            return undef;
        },
        'geslachtsaanduiding'       => sub {
            my ($field) = @_;

            return $field unless $field =~ /^[mMvV]$/;

            return uc($field);
        },
        'partner_burgerservicenummer' => sub {
            my ($field) = @_;

            return '' if $field =~ /^[0 ]+$/;

            return $field;
        },
    },
    msgs                => sub {
        my $dfv     = shift;
        my $rv      = {};

        for my $missing ($dfv->missing) {
            $rv->{$missing}  = 'Veld is verplicht.';
        }
        for my $missing ($dfv->invalid) {
            $rv->{$missing}  = 'Veld is niet correct ingevuld.';
        }

        return $rv;
    }
};

use constant GEGEVENSMAGAZIJN_KVK_PROFILE   => {
    required => [ qw/
        dossiernummer
        subdossiernummer

        hoofdvestiging_dossiernummer
        hoofdvestiging_subdossiernummer

        handelsnaam

        vestiging_adres
        vestiging_straatnaam
        vestiging_huisnummer
        vestiging_postcode
        vestiging_postcodewoonplaats
        vestiging_woonplaats

    /],
    optional => [ qw/
        fulldossiernummer
        vorig_dossiernummer
        vorig_subdossiernummer

        vestiging_huisnummertoevoeging

        rechtsvorm
        telefoonnummer
        surseance
        kamernummer

        correspondentie_adres
        correspondentie_straatnaam
        correspondentie_huisnummer
        correspondentie_huisnummertoevoeging
        correspondentie_postcodewoonplaats
        correspondentie_postcode
        correspondentie_woonplaats

        hoofdactiviteitencode
        nevenactiviteitencode1
        nevenactiviteitencode2

        werkzamepersonen

        contact_naam
        contact_aanspreektitel
        contact_voorletters
        contact_geslachtsnaam
        contact_voorvoegsel
        contact_geslachtsaanduiding

        email
    /],
    constraint_methods => {
        'dossiernummer'                     => qr/^\d{8}$/,
        'subdossiernummer'                  => qr/^\d{4}$/,
        'hoofdvestiging_dossiernummer'      => qr/^\d{8}$/,
        'hoofdvestiging_subdossiernummer'   => qr/^\d{4}$/,

        'handelsnaam'                       => qr/^.{0,45}$/,
        'rechtsvorm'                        => qr/^\d{0,3}$/,

        'hoofdactiviteitencode'             => qr/^\d{0,6}$/,
        'nevenactiviteitencode1'            => qr/^\d{0,6}$/,
        'nevenactiviteitencode2'            => qr/^\d{0,6}$/,

        'vestiging_adres'                   => qr/^.{0,30}$/,
        'vestiging_straatnaam'              => qr/^.{0,25}$/,
        'vestiging_huisnummer'              => qr/^\d{0,6}$/,
        'vestiging_huisnummertoevoeging'    => qr/^.{0,12}$/,
        'vestiging_postcodewoonplaats'      => qr/^.{0,30}$/,
        'vestiging_postcode'                => qr/^[\d]{4}[\w]{2}$/,
        'vestiging_woonplaats'              => qr/^.{0,24}$/,

        'correspondentie_adres'                 => qr/^.{0,30}$/,
        'correspondentie_straatnaam'            => qr/^.{0,25}$/,
        'correspondentie_huisnummer'            => qr/^.{0,6}$/,
        'correspondentie_huisnummertoevoeging'  => qr/^.{0,12}$/,
        'correspondentie_postcodewoonplaats'    => qr/^.{0,30}$/,
        'correspondentie_postcode'              => qr/^[\d]{4}[\w]{2}$/,
        'correspondentie_woonplaats'            => qr/^.{0,24}$/,
    },
    defaults => {
        vestiging_adres => sub {
            my ($dfv) = @_;

            return
                $dfv->get_filtered_data->{'vestiging_straatnaam'} . ' ' .
                $dfv->get_filtered_data->{'vestiging_huisnummer'} .
                ($dfv->get_filtered_data->{'vestiging_huisnummertoevoeging'}
                    ?  ' ' .  $dfv->get_filtered_data->{'vestiging_huisnummertoevoeging'}
                    : ''
                );
        },
        vestiging_postcodewoonplaats => sub {
            my ($dfv) = @_;

            return
                $dfv->get_filtered_data->{'vestiging_postcode'} . ' ' .
                $dfv->get_filtered_data->{'vestiging_woonplaats'};
        },
        correspondentie_adres => sub {
            my ($dfv) = @_;

            return
                $dfv->get_filtered_data->{'correspondentie_straatnaam'} . ' ' .
                $dfv->get_filtered_data->{'correspondentie_huisnummer'} .
                ($dfv->get_filtered_data->{'correspondentie_huisnummertoevoeging'}
                    ?  ' ' .  $dfv->get_filtered_data->{'correspondentie_huisnummertoevoeging'}
                    : ''
                );
        },
#        telefoonnummer => sub {
#            my ($dfv) = @_;
#
#            return
#                ($dfv->get_input_data->{'telefoonnummer_netnummer'} || '') . '-' .
#                ($dfv->get_input_data->{'telefoonnummer_nummer'} || '');
#        },
        fulldossiernummer => sub {
            my ($dfv) = @_;

            return
                $dfv->get_filtered_data->{'dossiernummer'} .
                $dfv->get_filtered_data->{'subdossiernummer'};
        },
        correspondentie_postcodewoonplaats => sub {
            my ($dfv) = @_;

            return unless (
                $dfv->get_filtered_data->{'correspondentie_postcode'} &&
                $dfv->get_filtered_data->{'correspondentie_woonplaats'}
            );

            return
                $dfv->get_filtered_data->{'correspondentie_postcode'} . ' ' .
                $dfv->get_filtered_data->{'correspondentie_woonplaats'};
        },
        subdossiernummer => '0001',
        hoofdvestiging_dossiernummer => sub {
            return $_[0]->get_filtered_data->{dossiernummer};
        },
        hoofdvestiging_subdossiernummer => sub {
            return $_[0]->get_filtered_data->{subdossiernummer} || '0001';
        },

    },
    field_filters     => {
        'werkzamepersonen'  => sub {
            my ($field) = @_;

            $field =~ s/^0*//;

            return $field;
        },
        'kamernummer'  => sub {
            my ($field) = @_;

            $field =~ s/^0*//;

            return $field;
        },
        'rechtsvorm'  => sub {
            my ($field) = @_;

            $field =~ s/^0*//;

            return $field;
        },
        'vestiging_huisnummer'  => sub {
            my ($field) = @_;

            $field =~ s/^0*//;

            return $field;
        },
        'surseance'  => sub {
            my ($field) = @_;

            if (lc($field) eq 'y') {
                return 1;
            } else {
                return 0;
            }

            return $field;
        },
        'telefoonnummer'  => sub {
            my ($field) = @_;

            $field =~ s/\-//;
            $field =~ s/ //;

            return substr($field, 0, 10);
        },
        'vestiging_postcode'    => sub {
            my ($field) = @_;

            $field = uc($field);
            $field =~ s/\s*//g;

            return $field;
        },
        'correspondentie_postcode'    => sub {
            my ($field) = @_;

            $field = uc($field);
            $field =~ s/\s*//g;

            return $field;
        },
    }
};

use constant GEGEVENSMAGAZIJN_KVK_RECHTSVORMCODES   => {
    '01'    => 'Eenmanszaak',
    '02'    => 'Eenmanszaak met meer dan één eigenaar',
    '03'    => 'N.V./B.V. in oprichting op A-formulier',
    '05'    => 'Rederij',
    '07'    => 'Maatschap',
    11    => 'Vennootschap onder firma',
    12    => 'N.V/B.V. in oprichting op B-formulier',
    21    => 'Commanditaire vennootschap met een beherend vennoot',
    22    => 'Commanditaire vennootschap met meer dan één beherende vennoot',
    23    => 'N.V./B.V. in oprichting op D-formulier',
    40    => 'Rechtspersoon in oprichting',
    41    => 'Besloten vennootschap met gewone structuur',
    42    => 'Besloten vennootschap blijkens statuten structuurvennootschap',
    51    => 'Naamloze vennootschap met gewone structuur',
    52    => 'Naamloze vennootschap blijkens statuten structuurvennootschap',
    53    => 'Naamloze vennootschap beleggingsmaatschappij met veranderlijk kapitaal',
    54    => 'Naamloze vennootschap beleggingsmaatschappij met veranderlijk kapitaal blijkens statuten structuurvennootschap',
    55    => 'Europese naamloze vennootschap (SE) met gewone structuur',
    56    => 'Europese naamloze vennootschap (SE) blijkens statuten structuurvennootschap',
    61    => 'Coöperatie U.A. met gewone structuur',
    62    => 'Coöperatie U.A. blijkens statuten structuurcoöperatie',
    63    => 'Coöperatie W.A. met gewone structuur',
    64    => 'Coöperatie W.A. blijkens statuten structuurcoöperatie',
    65    => 'Coöperatie B.A. met gewone structuur',
    66    => 'Coöperatie B.A. blijkens statuten structuurcoöperatie',
    70    => 'Vereniging van eigenaars',
    71    => 'Vereniging met volledige rechtsbevoegdheid',
    72    => 'Vereniging met beperkte rechtsbevoegdheid',
    73    => 'Kerkgenootschap',
    74    => 'Stichting',
    81    => 'Onderlinge waarborgmaatschappij U.A. met gewone structuur',
    82    => 'Onderlinge waarborgmaatschappij U.A. blijkens statuten structuuronderlinge',
    83    => 'Onderlinge waarborgmaatschappij W.A. met gewone structuur',
    84    => 'Onderlinge waarborgmaatschappij W.A. blijkens statuten structuuronderlinge',
    85    => 'Onderlinge waarborgmaatschappij B.A. met gewone structuur',
    86    => 'Onderlinge waarborgmaatschappij B.A. blijkens statuten structuuronderlinge',
    88    => 'Publiekrechtelijke rechtspersoon',
    89    => 'Privaatrechtelijke rechtspersoon',
    91    => 'Buitenlandse rechtsvorm met hoofdvestiging in Nederland',
    92    => 'Nevenvest. met hoofdvest. in buitenl.',
    93    => 'Europees economisch samenwerkingsverband',
    94    => 'Buitenl. EG-venn. met onderneming in Nederland',
    95    => 'Buitenl. EG-venn. met hoofdnederzetting in Nederland',
    96    => 'Buitenl. op EG-venn. lijkende venn. met onderneming in Nederland',
    97    => 'Buitenl. op EG-venn. lijkende venn. met hoofdnederzetting in Nederland',

    ### BUSSUM SPECIFIC
    201    => 'Coöperatie',
    202    => 'Vereniging',
};

### Contactkanalen
use constant ZAAKSYSTEEM_CONTACTKANAAL_BALIE        => 'balie';
use constant ZAAKSYSTEEM_CONTACTKANAAL_TELEFOON     => 'telefoon';
use constant ZAAKSYSTEEM_CONTACTKANAAL_POST         => 'post';
use constant ZAAKSYSTEEM_CONTACTKANAAL_EMAIL        => 'email';
use constant ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM      => 'webformulier';
use constant ZAAKSYSTEEM_CONTACTKANAAL_BEHANDELAAR  => 'behandelaar';

### Hoofd en deelzaken
use constant ZAAKSYSTEEM_SUBZAKEN_DEELZAAK          => 'deelzaak';
use constant ZAAKSYSTEEM_SUBZAKEN_GERELATEERD       => 'gerelateerd';
use constant ZAAKSYSTEEM_SUBZAKEN_VERVOLGZAAK       => 'vervolgzaak';

use constant ZAAKSYSTEEM_CONSTANTS  => {
    'zaaksysteem_about' => [ qw/
        applicatie
        omschrijving
        leverancier
        versie
        licentie
        startdatum
    /],
    'mimetypes'         => {
        'default'                                   => 'icon-txt-32.gif',
        'dir'                                       => 'icon-folder-32.gif',
        'application/msword'                        => 'icon-doc-32.gif',
        'application/pdf'                           => 'icon-pdf-32.gif',
        'application/msexcel'                       => 'icon-xls-32.gif',
        'application/vnd.ms-excel'                  => 'icon-xls-32.gif',
        'application/vnd.ms-powerpoint'             => 'icon-ppt-32.gif',
        'text/email'                                => 'icon-email-32.gif',
        'image/jpeg'                                => 'icon-jpg-32.gif',
        'application/vnd.oasis.opendocument.text'   => 'icon-odt-32.gif',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'icon-doc-32.gif',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'icon-ppt-32.gif',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'icon-xls-32.gif',
    },
    'zaken_statussen'   => ZAKEN_STATUSSEN,
    'contactkanalen'    => [
        ZAAKSYSTEEM_CONTACTKANAAL_BEHANDELAAR,
        ZAAKSYSTEEM_CONTACTKANAAL_BALIE,
        ZAAKSYSTEEM_CONTACTKANAAL_TELEFOON,
        ZAAKSYSTEEM_CONTACTKANAAL_POST,
        ZAAKSYSTEEM_CONTACTKANAAL_EMAIL,
        ZAAKSYSTEEM_CONTACTKANAAL_WEBFORM,
    ],
    'subzaken_deelzaak'         => ZAAKSYSTEEM_SUBZAKEN_DEELZAAK,
    'subzaken_gerelateerd'      => ZAAKSYSTEEM_SUBZAKEN_GERELATEERD,
    'subzaken_vervolgzaak'      => ZAAKSYSTEEM_SUBZAKEN_VERVOLGZAAK,
    'authenticatedby'   => {
        'digid'         => ZAAKSYSTEEM_GM_AUTHENTICATEDBY_DIGID,
        'bedrijfid'     => ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEDRIJFID,
        'behandelaar'   => ZAAKSYSTEEM_GM_AUTHENTICATEDBY_BEHANDELAAR,
        'gba'           => ZAAKSYSTEEM_GM_AUTHENTICATEDBY_GBA,
        'kvk'           => ZAAKSYSTEEM_GM_AUTHENTICATEDBY_KVK
    },
    'mail_rcpt' => {
        'aanvrager'     => {
            naam            => 'Aanvrager',
        },
        'coordinator'   => {
            naam            => 'Coordinator',
        },
        'behandelaar'   => {
            naam            => 'Behandelaar',
            in_status       => 1,
        },
        'overig'        => {
            naam            => 'Overig',
            in_status       => 1,
        },
    },
    'zaaktype'  => {
        'zt_trigger'    => {
            extern  => 'Extern',
            intern  => 'Intern',
        },
        'betrokkenen'   => {
            'niet_natuurlijk_persoon'       => 'Niet natuurlijk persoon',
            'niet_natuurlijk_persoon_na'    => 'Niet natuurlijk persoon (Ongeauthoriseerd)',
            'natuurlijk_persoon'            => 'Natuurlijk persoon',
            'natuurlijk_persoon_na'         => 'Natuurlijk persoon (Ongeauthoriseerd)',
            'medewerker'                    => 'Behandelaar',
            'org_eenheid'                   => 'Organisatorische eenheid',
        },
        'deelvervolg_eigenaar'  => {
            'behandelaar'   => {
                'label'     => 'Behandelaar van de huidige zaak',
            },
            'aanvrager'     => {
                'label'     => 'Aanvrager van de huidige zaak',
            },
        }
    },
    'veld_opties'       => {
        'text'      => {
            'label'         => 'Tekstveld',
            'rt'            => 'Freeform-1',
            'allow_multiple_instances' => 1,
            'allow_default_value' => 1,
        },
        'image_from_url'      => {
            'label'         => 'Afbeelding (URL)',
            'rt'            => 'Freeform-1',
            'allow_multiple_instances' => 0,
            'allow_default_value' => 1,
        },
        'text_uc'      => {
            'label'         => 'Tekstveld (HOOFDLETTERS)',
            'rt'            => 'Freeform-1',
            'allow_multiple_instances' => 1,
            'allow_default_value' => 1,
        },
        'numeric'       => {
            'label'         => 'Numeriek',
            'rt'            => 'Freeform-1',
            'constraint'    => qr/^\d*$/,
            'allow_multiple_instances' => 1,
            'allow_default_value' => 1,
        },
        'valuta'        => {
            'label'         => 'Valuta',
            'rt'            => 'Freeform-1',
            'constraint'    => qr/^[\d,.]*$/,
            'allow_multiple_instances' => 0,
            'allow_default_value' => 1,
        },
        'valutain'  => {
            'label'         => 'Valuta (inclusief BTW)',
            'rt'            => 'Freeform-1',
            'type'          => 'valuta',
            'options'       => {
                'btwin'         => 1,
            },
            'constraint'    => qr/^[\d,.]*$/,
            'allow_multiple_instances' => 0,
            'allow_default_value' => 1,
        },
        'valutaex'  => {
            'label'         => 'Valuta (exclusief BTW)',
            'rt'            => 'Freeform-1',
            'type'          => 'valuta',
            'options'       => {
                'btwex'         => 1,
            },
            'constraint'    => qr/^[\d,.]*$/,
            'allow_multiple_instances' => 0,
            'allow_default_value' => 1,
        },
        'date'      => {
            'label'         => 'Datum',
            'rt'            => 'Freeform-1',
            'type'          => 'datetime',
            'allow_multiple_instances' => 0,
            'allow_default_value' => 1,
        },
        'googlemaps'    => {
            'label'         => 'Adres (Google Maps)',
            'rt'            => 'Freeform-1',
            'allow_default_value' => 0,
        },
        'textarea'    => {
            'label'         => 'Groot tekstveld',
            'rt'            => 'Freeform-1',
            'allow_multiple_instances' => 1,
            'allow_default_value' => 1,
        },
        'option'    => {
            'multiple'      => 1,
            'label'         => 'Enkelvoudige keuze',
            'rt'            => 'Freeform-1',
            'rtmultiple'    => 0,
            'allow_default_value' => 1,
        },
        'select'    => {
            'multiple'      => 1,
            'label'         => 'Keuzelijst',
            'rt'            => 'Freeform-1',
            'rtmultiple'    => 0,
            'allow_multiple_instances' => 1,
            'allow_default_value' => 1,
        },
        'checkbox'  => {
            'multiple'      => 1,
            'label'         => 'Meervoudige keuze',
            'rt'            => 'Freeform-0',
            'rtmultiple'    => 1,
            'allow_default_value' => 0,
        },
        'file'  => {
            'label'         => 'Document',
            'allow_default_value' => 0,
        },
        'bag_straat_adres'  => {
            'label'         => 'Adres (dmv straatnaam) (BAG)',
            'rt'            => 'Freeform-1',
            'can_zaakadres'  => 1,
            'allow_default_value' => 0,
            'trigger'       => sub {
                my ($c, $newvalue, $attrobject, $veldoptie) = @_;

                my $rttriggertag = $c->model('Gegevens::Bag')
                    ->get_rt_kenmerk_trigger($newvalue);

                if ($veldoptie->{bag_zaakadres}) {
                    if (!UNIVERSAL::isa($attrobject->bag_items, 'ARRAY')) {
                        $attrobject->bag_items([$rttriggertag]);
                    } else {
                        $attrobject->bag_items([ @{ $attrobject->bag_items },
                            $rttriggertag ]
                        );
                    }
                }

                return $rttriggertag;
            },
            'filter'        => sub {
                my ($c, $value) = @_;

                return $c->model('Gegevens::Bag')
                    ->remove_rt_kenmerk_trigger($value);
            }
        },
        'bag_straat_adressen'  => {
            'multiple'      => 1,
            'label'         => 'Adressen (dmv straatnaam) (BAG)',
            'rt'            => 'Freeform-0',
            'rtmultiple'    => 1,
            'can_zaakadres'  => 1,
            'allow_default_value' => 0,
            'trigger'       => sub {
                my ($c, $newvalue, $attrobject, $veldoptie) = @_;

                my $rttriggertag = $c->model('Gegevens::Bag')
                    ->get_rt_kenmerk_trigger($newvalue);

                if ($veldoptie->{bag_zaakadres}) {
                    if (!UNIVERSAL::isa($attrobject->bag_items, 'ARRAY')) {
                        $attrobject->bag_items([$rttriggertag]);
                    } else {
                        $attrobject->bag_items([ @{ $attrobject->bag_items },
                            $rttriggertag ]
                        );
                    }
                }

                return $rttriggertag;
            },
            'filter'        => sub {
                my ($c, $value) = @_;

                return $c->model('Gegevens::Bag')
                    ->remove_rt_kenmerk_trigger($value);
            }
        },
        'bag_adres'  => {
            'label'         => 'Adres (BAG)',
            'rt'            => 'Freeform-1',
            'can_zaakadres'  => 1,
            'allow_default_value' => 0,
            'trigger'       => sub {
                my ($c, $newvalue, $attrobject, $veldoptie) = @_;

                my $rttriggertag = $c->model('Gegevens::Bag')
                    ->get_rt_kenmerk_trigger($newvalue);

                if ($veldoptie->{bag_zaakadres}) {
                    if (!UNIVERSAL::isa($attrobject->bag_items, 'ARRAY')) {
                        $attrobject->bag_items([$rttriggertag]);
                    } else {
                        $attrobject->bag_items([ @{ $attrobject->bag_items },
                            $rttriggertag ]
                        );
                    }
                }

                return $rttriggertag;
            },
            'filter'        => sub {
                my ($c, $value) = @_;

                my $cleanvalue = $c->model('Gegevens::Bag')
                    ->remove_rt_kenmerk_trigger($value);

                return $cleanvalue;

                ## BELOW DEPREACTED
                return '' unless $cleanvalue;

                return $c->model('Gegevens::Bag')
                    ->bag_human_view_by_id($cleanvalue);
            }
        },
        'bag_adressen'  => {
            'label'         => 'Adressen (BAG)',
            'rt'            => 'Freeform-0',
            'multiple'      => 1,
            'rtmultiple'    => 1,
            'can_zaakadres'  => 1,
            'allow_default_value' => 0,
            'trigger'       => sub {
                my ($c, $newvalue, $attrobject, $veldoptie) = @_;

                my $rttriggertag = $c->model('Gegevens::Bag')
                    ->get_rt_kenmerk_trigger($newvalue);

                if ($veldoptie->{bag_zaakadres}) {
                    if (!UNIVERSAL::isa($attrobject->bag_items, 'ARRAY')) {
                        $attrobject->bag_items([$rttriggertag]);
                    } else {
                        $attrobject->bag_items([ @{ $attrobject->bag_items },
                            $rttriggertag ]
                        );
                    }
                }

                return $rttriggertag;
            },
            'filter'        => sub {
                my ($c, $value) = @_;

                my $cleanvalue = $c->model('Gegevens::Bag')
                    ->remove_rt_kenmerk_trigger($value);

                return $cleanvalue;

                ## BELOW DEPREACTED
                return '' unless $cleanvalue;

                return $c->model('Gegevens::Bag')
                    ->bag_human_view_by_id($cleanvalue);
            }
        },
        'bag_openbareruimte'  => {
            'label'         => 'Straat (BAG)',
            'rt'            => 'Freeform-1',
            'can_zaakadres' => 1,
            'allow_default_value' => 0,
            'trigger'       => sub {
                my ($c, $newvalue, $attrobject, $veldoptie) = @_;

                my $rttriggertag = $c->model('Gegevens::Bag')
                    ->get_rt_kenmerk_trigger($newvalue);

                if ($veldoptie->{bag_zaakadres}) {
                    if (!UNIVERSAL::isa($attrobject->bag_items, 'ARRAY')) {
                        $attrobject->bag_items([$rttriggertag]);
                    } else {
                        $attrobject->bag_items([ @{ $attrobject->bag_items },
                            $rttriggertag ]
                        );
                    }
                }

                return $rttriggertag;
            },
            'filter'        => sub {
                my ($c, $value) = @_;

                my $cleanvalue = $c->model('Gegevens::Bag')
                    ->remove_rt_kenmerk_trigger($value);

                return $cleanvalue;

                ## BELOW DEPREACTED
                return '' unless $cleanvalue;

                return $c->model('Gegevens::Bag')
                    ->bag_human_view_by_id($cleanvalue);
            }
        },
        'bag_openbareruimtes'  => {
            'label'         => 'Straten (BAG)',
            'rt'            => 'Freeform-0',
            'rtmultiple'    => 1,
            'can_zaakadres'  => 1,
            'allow_default_value' => 0,
            'trigger'       => sub {
                my ($c, $newvalue, $attrobject, $veldoptie) = @_;

                my $rttriggertag = $c->model('Gegevens::Bag')
                    ->get_rt_kenmerk_trigger($newvalue);

                if ($veldoptie->{bag_zaakadres}) {
                    if (!UNIVERSAL::isa($attrobject->bag_items, 'ARRAY')) {
                        $attrobject->bag_items([$rttriggertag]);
                    } else {
                        $attrobject->bag_items([ @{ $attrobject->bag_items },
                            $rttriggertag ]
                        );
                    }
                }

                return $rttriggertag;
            },
            'filter'        => sub {
                my ($c, $value) = @_;

                my $cleanvalue = $c->model('Gegevens::Bag')
                    ->remove_rt_kenmerk_trigger($value);

                return $cleanvalue;

                ## BELOW DEPREACTED
                return '' unless $cleanvalue;

                return $c->model('Gegevens::Bag')
                    ->bag_human_view_by_id($cleanvalue);
            }
        },
    },
    'document'      => {
        'categories'        => [qw/
            Advies
            Afbeelding
            Audio
            Begroting
            Beleidsnota
            Besluit
            Bewijsstuk
            Brief
            Contract
            E-mail
            Envelop
            Factuur
            Formulier
            Foto
            Legitimatie
            Memo
            Offerte
            Presentatie
            Procesverbaal
            Projectplan
            Rapport
            Tekening
            Uittreksel
            Verslag
            Video
            Anders
        /],
        'types'             => {
            file        => {},
            mail        => {},
            dir         => {},
            sjabloon    => {},
        },
        'sjabloon'  => {
            'export_types'  => {
                'odt'   => {
                    mimetype    => 'application/vnd.oasis.opendocument.text',
                    label       => 'OpenDocument',
                },
                'pdf'   => {
                    mimetype    => 'application/pdf',
                    label       => 'PDF',
                },
                'doc'   => {
                    mimetype    => 'application/msword',
                    label       => 'MS Word',
                }
            },
        },
    },
    'authorisation' => {
        'roles'         => {
            'admin'         => 'Functioneel beheerder',
            'manager'       => 'Afdelingshoofd',
            'behandelaar'   => 'Behandelaar',
        },
        'rechten'       => {
            'zaak_read'     => {
                label => 'Mag zaken bekijken'
            },
            'zaak_create'   => { label => 'Mag zaken aanmaken'},
            'zaak_edit'     => { label => 'Mag zaken behandelen'},
            'zaak_move'     => {
                label => 'Mag zaken verdelen',
            },
            'zaak_admin'    => { label => 'Mag zaken beheren'},
            'notes_add'     => { label => 'Mag notities toevoegen'},
        },
    },
    'kvk_rechtsvormen'          => GEGEVENSMAGAZIJN_KVK_RECHTSVORMCODES,
    'kvk_rechtsvormen_enabled'  => [qw/
        01
        07
        11
        21
        41
        51
        55
        70
        73
        74
        88
        201
        202
    /],
};

use constant ZAAKSYSTEEM_AUTHORIZATION_PERMISSIONS => {
    'admin'                     => {
        'label'             => 'Administrator',
        'is_systeem_recht'  => 0,
    },
    'gebruiker'                 => {
        'label'             => 'Gebruiker',
        'is_systeem_recht'  => 0,
    },
    'dashboard'                 => {},
    'zaak_intake'               => {},
    'documenten_intake'         => {},
    'zaak_eigen'                => {},
    'zaak_afdeling'             => {},
    'search'                    => {},
    'plugin_mgmt'               => {},
    'contact_nieuw'             => {},
    'contact_search'            => {},
    'beheer_kenmerken_admin'    => {},
    'beheer_sjablonen_admin'    => {},
    'beheer_gegevens_admin'     => {},
    'beheer_zaaktype_admin'     => {},
    'beheer_plugin_admin'       => {},
    'vernietigingslijst'        => {},
    'zaak_add'                  => {
        'label'             => 'Mag zaak aanmaken',
        'deprecated'        => 1,
    },
    'zaak_edit'                  => {
        'label'             => 'Mag zaken behandelen',
        'is_systeem_recht'  => 1,
    },
    'zaak_read'                  => {
        'label'             => 'Mag zaken raadplegen',
        'is_systeem_recht'  => 1,
    },
    'zaak_beheer'                  => {
        'label'             => 'Mag zaken beheren',
        'is_systeem_recht'  => 1,
    },
#    'zaak_edit'                 => {
#        'label'             => 'Mag zaken behandelen (wijzigen)',
#        'is_systeem_recht'  => 1,
#    },
#    'zaak_volgende_status'      => {
#        'label'             => 'Mag zaak naar volgende status zetten',
#        'is_systeem_recht'  => 1,
#    },
#    'zaak_vorige_status'        => {
#        'label'             => 'Mag zaak naar vorige status zetten',
#        'is_systeem_recht'  => 1,
#    },
#    'zaak_behandelaar_edit'     => {
#        'label'             => 'Mag behandelaar wijzigen',
#        'is_systeem_recht'  => 1,
#    },
#    'zaak_coordinator_edit'     => {
#        'label'             => 'Mag coordinator wijzigen',
#        'is_systeem_recht'  => 1,
#    },
#    'zaak_aanvrager_edit'       => {
#        'label'             => 'Mag aanvrager wijzigen',
#        'is_systeem_recht'  => 1,
#    },
#    'zaak_verlengen'            => {
#        'label'             => 'Mag een zaak verlengen',
#        'is_systeem_recht'  => 1,
#    },
#    'zaak_opschorten'           => {
#        'label'             => 'Mag een zaak opschorten/activeren',
#        'is_systeem_recht'  => 1,
#    },
#    'zaak_vroegtijdig_afhandelen' => {
#        'label'             => 'Mag een zaak vroegtijdig afhandelen',
#        'is_systeem_recht'  => 1,
#    },
#    'zaak_relatie_edit'         => {
#        'label'             => 'Mag een relatie aanbrengen',
#        'is_systeem_recht'  => 1,
#    },
#    'zaak_deelzaak_add'         => {
#        'label'             => 'Mag een deelzaak aanmaken',
#        'is_systeem_recht'  => 1,
#    },
};

use constant ZAAKSYSTEEM_STANDAARD_KOLOMMEN => {
    status                                      => sub {
        my  $zaak   = shift;

        return $zaak->status;
    },
    'me.id'                                     => sub {
        my  $zaak   = shift;

        return $zaak->id;
    },
    'me.days_perc'                              => sub {
        my  $zaak   = shift;

        return $zaak->get_column('days_perc');
    },
    'zaaktype_node_id.titel'                    => sub {
        my  $zaak   = shift;

        return $zaak->zaaktype_node_id->titel;
    },
    'me.onderwerp'                              => sub {
        my  $zaak   = shift;

        return $zaak->onderwerp;
    },
    'aanvrager'                                 => sub {
        my  $zaak   = shift;

        return $zaak->aanvrager->naam;
    },
    'dagen'                                     => sub {
        my  $zaak   = shift;

        return $zaak->get_column('days_left');
    }
};

use constant ZAAKSYSTEEM_BETROKKENE_KENMERK => {
    naam                => {
        'bedrijf'               => 'handelsnaam',
        'medewerker'            => 'naam',
        'natuurlijk_persoon'    => 'naam'
    },
    display_name        => {
        'bedrijf'               => 'display_name',
        'medewerker'            => 'display_name',
        'natuurlijk_persoon'    => 'display_name'
    },
    kvknummer           => {
        'bedrijf'               => 'dossiernummer',
    },
    burgerservicenummer => {
        'natuurlijk_persoon'    => 'burgerservicenummer',
    },
    login     => {
        'bedrijf'               => 'login',
    },
    password  => {
        'bedrijf'               => 'password',
    },
    'achternaam' => {
        'medewerker'            => 'geslachtsnaam',
        'natuurlijk_persoon'    => 'achternaam'
    },
    'volledigenaam' => {
        'medewerker'            => 'display_name',
        'natuurlijk_persoon'    => 'volledige_naam'
    },
    'geslachtsnaam' => {
        'medewerker'            => 'geslachtsnaam',
        'natuurlijk_persoon'    => 'geslachtsnaam'
    },
    'voorvoegsel' => {
        'natuurlijk_persoon'    => 'voorvoegsel'
    },
    'voornamen'   => {
        'natuurlijk_persoon'    => 'voornamen',
        'medewerker'            => 'voornamen',
    },
    'geslacht'    => {
        'natuurlijk_persoon'    => 'geslacht'
    },
    'aanhef'      => {
        'natuurlijk_persoon'    => 'aanhef'
    },
    'aanhef1'     => {
        'natuurlijk_persoon'    => 'aanhef1'
    },
    'aanhef2'     => {
        'natuurlijk_persoon'    => 'aanhef2'
    },
    'straat'      => {
        'natuurlijk_persoon'    => 'straatnaam',
        'bedrijf'               => 'straatnaam',
        'medewerker'            => 'straatnaam'
    },
    'huisnummer'  => {
        'natuurlijk_persoon'    => 'volledig_huisnummer',
        'bedrijf'               => 'volledig_huisnummer',
        'medewerker'            => 'huisnummer'
    },
    'postcode'    => {
        'natuurlijk_persoon'    => 'postcode',
        'bedrijf'               => 'postcode',
        'medewerker'            => 'postcode'
    },
    'woonplaats'  => {
        'natuurlijk_persoon'    => 'woonplaats',
        'bedrijf'               => 'woonplaats',
        'medewerker'            => 'woonplaats'
    },
    'tel'           => {
        'natuurlijk_persoon'    => 'telefoonnummer',
        'bedrijf'               => 'telefoonnummer',
        'medewerker'            => 'telefoonnummer'
    },
    'mobiel'       => {
        'natuurlijk_persoon'    => 'mobiel',
        'bedrijf'               => 'mobiel',
    },
    'email'       => {
        'natuurlijk_persoon'    => 'email',
        'bedrijf'               => 'email',
        'medewerker'            => 'email'
    },
    'afdeling'              => {
        'medewerker'            => 'afdeling'
    },
    'type'        => {
        'natuurlijk_persoon'    => 'human_type',
        'bedrijf'               => 'human_type',
        'medewerker'            => 'human_type'
    }
};

use constant ZAAKSYSTEEM_BETROKKENE_SUB     => sub {
    my $zaak        = shift || return;
    my $betrokkene  = shift || return;
    my $attr        = shift || return;
    my ($config, $sub);

    unless (
        ($config    = ZAAKSYSTEEM_BETROKKENE_KENMERK->{$attr}) &&
        ($config    = $config->{ $betrokkene->btype }) &&
        ($sub       = $betrokkene->can( $config ))
    ) {
        return;
    }

    return $sub->($betrokkene);
};

use constant ZAAKSYSTEEM_STANDAARD_KENMERKEN => {
    'sjabloon_aanmaakdatum'                => sub {
        my  $zaak   = shift;

        my $dt = DateTime->now;
        return $dt->dmy;
    },
    'zaaknummer'                => sub {
        my  $zaak   = shift;

        return $zaak->id;
    },
    'zaaktype'                  => sub {
        my  $zaak   = shift;

        return $zaak->zaaktype_node_id->titel;
    },
    'trigger'                   => sub {
        my  $zaak   = shift;

        return $zaak->zaaktype_node_id->trigger;
    },
    'handelingsinitiator'       => sub {
        my  $zaak   = shift;

        return $zaak->zaaktype_node_id->zaaktype_definitie_id->handelingsinitiator;
    },
    'generieke_categorie'       => sub {
        my  $zaak   = shift;

        return $zaak->zaaktype_id->bibliotheek_categorie_id->naam
            if $zaak->zaaktype_id->bibliotheek_categorie_id;
    },
    'iv3_categorie'             => sub {
        my  $zaak   = shift;

        return $zaak->zaaktype_node_id->zaaktype_definitie_id->iv3_categorie;
    },
    'grondslag'                 => sub {
        my  $zaak   = shift;

        return $zaak->zaaktype_node_id->zaaktype_definitie_id->grondslag;
    },
    'selectielijst'             => sub {
        my  $zaak   = shift;

        return $zaak->zaaktype_node_id->zaaktype_definitie_id->selectielijst;
    },
    'afhandeltermijn'           => sub {
        my  $zaak   = shift;

        return $zaak->zaaktype_node_id->zaaktype_definitie_id->afhandeltermijn;
    },
    'openbaarheid'              => sub {
        my  $zaak   = shift;

        return $zaak->zaaktype_node_id->zaaktype_definitie_id->openbaarheid;
    },
    'besluittype'               => sub {
        my  $zaak   = shift;

        return $zaak->zaaktype_node_id->zaaktype_definitie_id->besluittype;
    },
    'contactkanaal'             => sub {
        my  $zaak   = shift;

        return $zaak->contactkanaal;
    },
    'startdatum'                => sub {
        my  $zaak   = shift;

        return $zaak->registratiedatum->dmy
            if $zaak->registratiedatum;
    },
    'registratiedatum'                => sub {
        my  $zaak   = shift;

        return $zaak->registratiedatum->dmy
            if $zaak->registratiedatum;
    },
    'registratiedatum_volledig'       => sub {
        my  $zaak   = shift;

        return $zaak->registratiedatum->dmy
                . ' '
                . $zaak->registratiedatum->hms
            if $zaak->registratiedatum;
    },
    'afhandeldatum'                => sub {
        my  $zaak   = shift;

        return $zaak->afhandeldatum->dmy
            if $zaak->afhandeldatum;
    },
    'afhandeldatum_volledig'       => sub {
        my  $zaak   = shift;

        return $zaak->afhandeldatum->dmy
                . ' '
                . $zaak->afhandeldatum->hms
            if $zaak->afhandeldatum;
    },
    'streefafhandeldatum'       => sub {
        my  $zaak   = shift;

        return $zaak->streefafhandeldatum->dmy
            if $zaak->streefafhandeldatum
    },
    'besluit'                   => sub {
        my  $zaak   = shift;

        return $zaak->besluit;
    },
    'resultaat'                 => sub {
        my  $zaak   = shift;

        return $zaak->resultaat;
    },
    'uiterste_vernietigingsdatum' => sub {
        my  $zaak   = shift;

        return $zaak->vernietigingsdatum->dmy
            if $zaak->vernietigingsdatum;
    },
    'coordinator'               => sub {
        my  $zaak   = shift;

        return $zaak->coordinator_object->naam
            if $zaak->coordinator_object;
    },
    'coordinator_tel'           => sub {
        my  $zaak   = shift;

        return $zaak->coordinator_object->telefoonnummer
            if $zaak->coordinator_object;
    },
    'coordinator_email'         => sub {
        my  $zaak   = shift;

        return $zaak->coordinator_object->email
            if $zaak->coordinator_object;
    },
    'behandelaar'               => sub {
        my  $zaak   = shift;

        return $zaak->behandelaar_object->naam
            if $zaak->behandelaar_object;
    },
    'behandelaar_tel'           => sub {
        my  $zaak   = shift;

        return $zaak->behandelaar_object->telefoonnummer
            if $zaak->behandelaar_object;
    },
    'behandelaar_email'         => sub {
        my  $zaak   = shift;

        return $zaak->behandelaar_object->email
            if $zaak->behandelaar_object;
    },
    'behandelaar_afdeling'          => sub {
        my  $zaak   = shift;

        return unless $zaak->behandelaar_object;

        return $zaak->behandelaar_object->org_eenheid->naam
            if (
                $zaak->behandelaar_object->btype eq 'medewerker' &&
                $zaak->behandelaar_object->org_eenheid
            );

        return '';
    },
    'zaak_fase'                 => sub {
        my  $zaak   = shift;

        return $zaak->volgende_fase->fase
            if ($zaak->volgende_fase);
    },
    'zaak_mijlpaal'                 => sub {
        my  $zaak   = shift;

        return $zaak->huidige_fase->naam
            if ($zaak->huidige_fase);
    },
    'zaaknummer_hoofdzaak'          => sub {
        my  $zaak   = shift;

        return $zaak->id unless $zaak->pid;

        my $parent = $zaak->pid;
        while ($parent->pid) {
            $parent = $parent->pid;
        }

        return $parent->id;
    },
    'statusnummer'              => sub {
        my  $zaak   = shift;

        return $zaak->milestone;
    },
    ### 1. FASE
    ### 2. MIJLPAAL
    'aanvrager_naam'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'naam');
    },
    'aanvrager_kvknummer'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'kvknummer');
    },
    'aanvrager_burgerservicenummer'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'burgerservicenummer');
    },
    'aanvrager_login'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'login');
    },
    'aanvrager_password'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'password');
    },
    'aanvrager_achternaam'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'achternaam');
    },
    'aanvrager_volledigenaam'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'volledigenaam');
    },
    'aanvrager_geslachtsnaam'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'geslachtsnaam');
    },
    'aanvrager_voorvoegsel'       => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'voorvoegsel');
    },
    'aanvrager_voornamen'       => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'voornamen');
    },
    'aanvrager_geslacht'        => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'geslacht');
    },
    'aanvrager_aanhef'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'aanhef');
    },
    'aanvrager_aanhef1'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'aanhef1');
    },
    'aanvrager_aanhef2'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'aanhef2');
    },
    'aanvrager_straat'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'straat');
    },
    'aanvrager_huisnummer'              => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'huisnummer');
    },
    'aanvrager_postcode'        => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'postcode');
    },
    'aanvrager_woonplaats'      => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'woonplaats');
    },
    'aanvrager_tel'             => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'tel');
    },
    'aanvrager_mobiel'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'mobiel');
    },
    'aanvrager_email'             => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'email');
    },
    'aanvrager_afdeling'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'afdeling');
    },
    'aanvrager_type'             => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->aanvrager_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'type');
    },
    'ontvanger'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'display_name');
    },
    'ontvanger_naam'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'naam');
    },
    'ontvanger_kvknummer'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'kvknummer');
    },
    'ontvanger_burgerservicenummer'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'burgerservicenummer');
    },
    'ontvanger_achternaam'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'achternaam');
    },
    'ontvanger_volledigenaam'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'volledigenaam');
    },
    'ontvanger_geslachtsnaam'            => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'geslachtsnaam');
    },
    'ontvanger_voorvoegsel'       => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'voorvoegsel');
    },
    'ontvanger_voornamen'       => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'voornamen');
    },
    'ontvanger_geslacht'        => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'geslacht');
    },
    'ontvanger_aanhef'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'aanhef');
    },
    'ontvanger_aanhef1'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'aanhef1');
    },
    'ontvanger_aanhef2'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'aanhef2');
    },
    'ontvanger_straat'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'straat');
    },
    'ontvanger_huisnummer'              => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'huisnummer');
    },
    'ontvanger_postcode'        => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'postcode');
    },
    'ontvanger_woonplaats'      => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'woonplaats');
    },
    'ontvanger_tel'             => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'tel');
    },
    'ontvanger_mobiel'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'mobiel');
    },
    'ontvanger_email'             => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'email');
    },
    'ontvanger_afdeling'          => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'afdeling');
    },
    'ontvanger_type'             => sub {
        my  $zaak       = shift;
        my  $betrokkene = $zaak->ontvanger_object;

        return ZAAKSYSTEEM_BETROKKENE_SUB->($zaak, $betrokkene, 'type');
    },
    'pdc_tarief'             => sub {
        my  $zaak   = shift;

        return '' unless (
            $zaak->zaaktype_node_id->zaaktype_definitie_id->pdc_tarief &&
            $zaak->zaaktype_node_id->zaaktype_definitie_id->pdc_tarief
        );

        my $tarief =
            $zaak->zaaktype_node_id->zaaktype_definitie_id->pdc_tarief;

        $tarief    =~ s/\./,/g;

        return $tarief;
    },
    
    # Later toegevoegd ticket #1006
    'bedrijven_id'             => sub {
        my  $zaak   = shift;

        return unless $zaak->aanvrager_object;
        return unless $zaak->aanvrager_object->btype eq 'bedrijf';

        return $zaak->aanvrager_object->dossiernummer;
    },
    'dagen'             => sub {
        my  $zaak   = shift;

        return $zaak->get_column('days_left');
    },
    'voortgang'             => sub {
        my  $zaak   = shift;

        return $zaak->get_column('days_perc');
    },
    'afdeling'             => sub {
        my  $zaak   = shift;

        my $ou_object = $zaak->ou_object;

        return $ou_object->omschrijving
            if $ou_object;
    },
    'uname'                 => sub {
        my  $zaak   = shift;

        my $zaaksysteem_location    = $INC{'Zaaksysteem.pm'};

        my @file_information        = stat($zaaksysteem_location);

        my @uname   = (
            ZAAKSYSTEEM_NAAM,
            Zaaksysteem->config->{'SVN_VERSION'},
            ZAAKSYSTEEM_STARTDATUM,
            ZAAKSYSTEEM_LEVERANCIER,
            ZAAKSYSTEEM_LICENSE,
            'zaaksysteem.nl',
        );

        return join(', ', @uname);
    },
    'bewaartermijn'                 => sub {
        my $zaak        = shift;

        my $resultaat   = $zaak->resultaat
            or return;

        my $resultaten  = $zaak
            ->zaaktype_node_id
            ->zaaktype_resultaten
            ->search(
                {
                    resultaat   => $resultaat
                }
            );

        return unless $resultaten->count;

        my $bewaartermijn   = $resultaten->first->bewaartermijn;

        return ZAAKSYSTEEM_OPTIONS->{BEWAARTERMIJN}->{$bewaartermijn};
    }
};

use constant LDAP_DIV_MEDEWERKER             => 'Zaakbeheerder';

use constant ZAAKSYSTEEM_AUTHORIZATION_ROLES => {
    'admin'             => {
        'ldapname'          => 'Administrator',
        'rechten'       => {
            'global'        => {
                'admin'                     => 1,
                'gebruiker'                 => 1,
                'dashboard'                 => 1,
                'zaak_eigen'                => 1,
                'zaak_afdeling'             => 1,
                'documenten_intake'         => 1,
                'search'                    => 1,
                'plugin_mgmt'               => 1,
                'contact_search'            => 1,
                'beheer_kenmerken_admin'    => 1,
                'beheer_sjablonen_admin'    => 1,
                'beheer_gegevens_admin'     => 1,
                'beheer_zaaktype_admin'     => 1,
                'beheer_plugin_admin'       => 1,
                'vernietigingslijst'        => 1,
            }
        },
    },
    'beheerder'         => {
        'ldapname'          => 'Zaaksysteembeheerder',
        'rechten'       => {
            'global'        => {
                'admin'                     => 1,
                'gebruiker'                 => 1,
                'dashboard'                 => 1,
                'zaak_eigen'                => 1,
                'zaak_afdeling'             => 1,
                'zaak_beheer'               => 1,
                'documenten_intake'         => 1,
                'search'                    => 1,
                'plugin_mgmt'               => 1,
                'contact_nieuw'             => 1,
                'contact_search'            => 1,
                'beheer_kenmerken_admin'    => 1,
                'beheer_sjablonen_admin'    => 1,
                'beheer_zaaktype_admin'     => 1,
                'beheer_gegevens_admin'     => 1,
                'beheer_plugin_admin'       => 1,
                'vernietigingslijst'        => 1,
            }
        },
    },
    'zaaktypebeheerder' => {
        'ldapname'          => 'Zaaktypebeheerder',
        'rechten'       => {
            'global'        => {
                'gebruiker'                 => 1,
                'dashboard'                 => 1,
                'zaak_eigen'                => 1,
                'zaak_afdeling'             => 1,
                'search'                    => 1,
                'contact_search'            => 1,
                'beheer_kenmerken_admin'    => 1,
                'beheer_sjablonen_admin'    => 1,
                'beheer_zaaktype_admin'     => 1,
            }
        },
    },
    'contactbeheerder' => {
        'ldapname'          => 'Contactbeheerder',
        'rechten'       => {
            'global'        => {
                'contact_nieuw'             => 1,
            }
        },
    },
    'wethouder'    => {
        'ldapname'          => 'Wethouder',
        'rechten'       => {
            'global'        => {
                'gebruiker'                 => 1,
                'dashboard'                 => 1,
                'zaak_eigen'                => 1,
                'zaak_afdeling'             => 1,
                'search'                    => 1,
                'contact_search'            => 1,
                'plugin_mgmt'               => 1,
            }
        },
    },
    'directielid'    => {
        'ldapname'          => 'Directielid',
        'rechten'       => {
            'global'        => {
                'gebruiker'                 => 1,
                'dashboard'                 => 1,
                'zaak_eigen'                => 1,
                'zaak_afdeling'             => 1,
                'search'                    => 1,
                'contact_search'            => 1,
                'plugin_mgmt'               => 1,
            }
        },
    },
    'afdelingshoofd'    => {
        'ldapname'          => 'Afdelingshoofd',
        'rechten'       => {
            'global'        => {
                'gebruiker'                 => 1,
                'dashboard'                 => 1,
                'zaak_eigen'                => 1,
                'zaak_afdeling'             => 1,
                'search'                    => 1,
                'contact_search'            => 1,
                'plugin_mgmt'               => 1,
            }
        },
    },
    'div-medewerker'    => {
        'ldapname'          => LDAP_DIV_MEDEWERKER,
        'rechten'       => {
            'global'        => {
                'gebruiker'                 => 1,
                'dashboard'                 => 1,
                'zaak_eigen'                => 1,
                'zaak_beheer'               => 1,
                'zaak_afdeling'             => 1,
                'search'                    => 1,
                'contact_search'            => 1,
                'documenten_intake'         => 1,
                'plugin_mgmt'               => 1,
            }
        },
    },
    'kcc-medewerker'    => {
        'ldapname'          => 'Kcc-medewerker',
        'rechten'       => {
            'global'        => {
                'gebruiker'                 => 1,
                'dashboard'                 => 1,
                'zaak_intake'               => 1,
                'zaak_eigen'                => 1,
                'zaak_afdeling'             => 1,
                'contact_search'            => 1,
                'plugin_mgmt'               => 1,
            }
        },
    },
    'zaakverdeler'      => {
        'ldapname'          => 'Zaakverdeler',
        'rechten'       => {
            'global'        => {
                'gebruiker'                 => 1,
                'dashboard'                 => 1,
                'zaak_intake'               => 1,
                'zaak_eigen'                => 1,
                'zaak_afdeling'             => 1,
                'search'                    => 1,
                'contact_search'            => 1,
                'plugin_mgmt'               => 1,
            }
        },
    },
    'behandelaar'       => {
        'ldapname'          => 'Behandelaar',
        'rechten'       => {
            'global'        => {
                'gebruiker'                 => 1,
                'dashboard'                 => 1,
                'zaak_eigen'                => 1,
                'zaak_afdeling'             => 1,
                'search'                    => 1,
                'contact_search'            => 1,
            }
        },
    },
};

use constant PARAMS_PROFILE_DEFAULT_MSGS => sub {
    my $dfv     = shift;
    my $rv      = {};

    for my $missing ($dfv->missing) {
        $rv->{$missing}  = 'Veld is verplicht.';
    }
    for my $missing ($dfv->invalid) {
        $rv->{$missing}  = 'Veld is niet correct ingevuld.';
    }

    return $rv;
};


use constant DEFAULT_KENMERKEN_GROUP_DATA => {
    help        => 'Vul de benodigde velden in voor uw zaak',
    label       => 'Benodigde gegevens',
};

use constant SEARCH_QUERY_SESSION_VAR => 'SearchQuery_search_query_id'; 
use constant SEARCH_QUERY_TABLE_NAME  => 'DB::SearchQuery';

use constant VALIDATION_CONTACT_DATA    => {
    optional    => [qw/
        npc-telefoonnummer
        npc-email
        npc-mobiel
    /],
    constraint_methods  => {
        'npc-email'                 => qr/^.+?\@.+\.[a-z0-9]{2,}$/,
        'npc-telefoonnummer'        => qr/^[\d\+]{6,15}$/,
        'npc-mobiel'                => qr/^[\d\+]{6,15}$/,
    },
    msgs                => {
        'format'    => '%s',
        'missing'   => 'Veld is verplicht.',
        'invalid'   => 'Veld is niet correct ingevuld.',
        'constraints' => {
            '(?-xism:^\d{4}\w{2}$)' => 'Postcode zonder spatie (1000AA)',
            '(?-xism:^[\d\+]{6,15}$)' => 'Nummer zonder spatie (e.g: +312012345678)',
        }
    },
};

use constant ZAAK_CREATE_PROFILE_BETROKKENE => sub {
    my $val = pop;

    my $BETROKKENE_DEFAULT_HASH = {
        'betrokkene_type'   =>
            qr/^natuurlijk_persoon|medewerker|bedrijf|org_eenheid$/,
        'betrokkene_id'     => qr/^\d+$/,
        'betrokkene'        => qr/^[\w\d-]+$/,
        'verificatie'       => qr/^digid|medewerker$/,
    };

    my @betrokkenen;

    ### Single betrokkene, DEFAULT
    push(@betrokkenen, $val) if UNIVERSAL::isa($val, 'HASH');
    push(@betrokkenen, $val) if blessed($val);

    ### Multiple betrokken, FUTURE
    push(@betrokkenen, @{ $val }) if UNIVERSAL::isa($val, 'ARRAY');

    ### No betrokkene?
    return unless scalar(@betrokkenen);

    for my $betrokkene (@betrokkenen) {
        # Object? Assume betrokkene object
        next if blessed($betrokkene);

        unless (
            $betrokkene->{betrokkene} ||
            $betrokkene->{create}
        ) {
            for (qw/betrokkene_id betrokkene_type/) {
                return unless $betrokkene->{ $_ };
            }
        }

        ### Need type when creating betrokkene
        if ($betrokkene->{create}) {
            return unless $betrokkene->{ 'betrokkene_type' };
        }

        return unless $betrokkene->{verificatie};
    }

    return 1;
};

use constant ZAAK_CREATE_PROFILE        => {
    required        => [ qw/
        aanvraag_trigger

        aanvragers

        registratiedatum
        contactkanaal
    /],
    'optional'      => [ qw/
        status
        milestone

        onderwerp
        resultaat
        besluit

        route_ou
        route_role

        streefafhandeldatum
        afhandeldatum
        vernietigingsdatum

        coordinators
        behandelaars

        kenmerken

        created
        last_modified
        deleted

        id
        override_zaak_id

        locatie_zaak
        locatie_correspondentie

        relatie
        zaak

        actie_kopieren_kenmerken
        streefafhandeldatum_data

        ontvanger
        betrokkene_relaties
        bestemming
    /],
    'require_some'  => {
        'zaaktype_id_or_zaaktype_node_id'    => [
            1,
            'zaaktype_id',
            'zaaktype_node_id'
        ],
    },
    'constraint_methods'            => {
        'status'            => sub {
            my $val     = pop;

            return 1 unless $val;

            my $statussen = ZAKEN_STATUSSEN;

            return 1 if grep { $_ eq $val } @{ $statussen };
            return;
        },
        'milestone'         => qr/^\d+$/,
        'onderwerp'         => qr/^.{0,255}$/,
        'contactkanaal'     => qr/^\w{1,128}$/,
        'aanvragers'        => sub {
            my $val = pop;

            my $BETROKKENE_VERIFICATION = ZAAK_CREATE_PROFILE_BETROKKENE;
            return $BETROKKENE_VERIFICATION->($val);
        },
        'coordinators'     => sub {
            my $val = pop;

            my $BETROKKENE_VERIFICATION = ZAAK_CREATE_PROFILE_BETROKKENE;
            return $BETROKKENE_VERIFICATION->($val);
        },
        'behandelaars'      => sub {
            my $val = pop;

            my $BETROKKENE_VERIFICATION = ZAAK_CREATE_PROFILE_BETROKKENE;
            return $BETROKKENE_VERIFICATION->($val);
        },
        'ontvanger'         => sub {
            my $val = pop;

            return 1 if $val =~ /-/;
            return;
        },
        'betrokkene_relaties' => sub {
            my $val = pop;

            return 1 if UNIVERSAL::isa($val, 'HASH');
            return;
        }
    },
    dependencies            => {
        'aanvraag_trigger'   => sub {
            my ($dfv, $val) = @_;

            if (
                lc($val) eq 'intern' &&
                lc($dfv->get_filtered_data->{'bestemming'}) eq 'extern'
            ) {
                return ['ontvanger'];
            }

            return [];
        },
    },
    'dependency_groups'     => {
        'zaak_and_relatie'      => ['relatie','zaak'],
    },
    'defaults'                      => {
        'status'    => ZAKEN_STATUSSEN_DEFAULT,
        'milestone' => 1,
    },
    msgs                => sub {
        my $dfv     = shift;
        my $rv      = {};

        for my $missing ($dfv->missing) {
            $rv->{$missing}  = 'Veld is verplicht.';
        }
        for my $missing ($dfv->invalid) {
            $rv->{$missing}  = 'Veld is niet correct ingevuld.';
        }

        return $rv;
    }
};

#
# this is the configuration for importing zaaktypes from one system into another. the challenge
# is that configurations will differ, thus not every dependency is present on every system. at
# the same time, it is not helpful to just re-import any dependency that is missing, this will
# cause duplicate items. e.g. when importing a zaaktype it looks to re-link to all it's needed
# kenmerken. if one is not found, it will ask the user if the kenmerk must be imported, or that
# another kenmerk must be selected in it's place.
#
#
# when exporting, all dependencies are exported with the zaaktype.
#
# the 'match' subroutine tries to match these exported dependencies with items that are in the
# local database. it returns a filter that is used in a query.
#
#
use constant ZAAKTYPE_DEPENDENCY_IDS => {
    'zaaktype_id$'                      => 'Zaaktype',
    '_kenmerk$'                         => 'BibliotheekKenmerken',
    '^bibliotheek_kenmerken_id$'        => 'BibliotheekKenmerken',
    '^bibliotheek_sjablonen_id$'        => 'BibliotheekSjablonen',
    '^bibliotheek_categorie_id$'        => 'BibliotheekCategorie',
    '^role_id$'                         => 'LdapRole',
    '^ou_id$'                           => 'LdapOu',
    '^filestore_id$'                    => 'Filestore',
    '^checklist_vraag_status_id$'       => 'ChecklistVraagStatus',
};

use constant ZAAKTYPE_DEPENDENCIES => {
    ChecklistVraagStatus => {
        match => ['naam'],
        name  => 'naam',
        label => 'checklistvraag',
        title => 'Checklistvraag',
        letter_e => '',
    },
    Filestore => {
        match => ['md5sum'],
        name  => 'filename',
        label => 'bestand',
        title => 'Bestand',
        letter_e => '',
    },
    Zaaktype => {
        match => [],
        name  => 'zaaktype_titel',
        label => 'zaaktype',
        title => 'Zaaktype',
        letter_e => '',
        has_category => 1,
    },
    BibliotheekKenmerken => {
        match => [qw/naam deleted value_type value_mandatory value_length besluit type_multiple/],
        name  => 'naam',
        label => 'kenmerk',
        title => 'Kenmerken',
        letter_e => '',
        has_category => 1,
    },
    BibliotheekSjablonen         => {
        match => [qw/naam/],
        name  => 'naam',
        label => 'sjabloon',
        letter_e => 'e',
        has_category => 1,
    },
    LdapRole => {
        match => [qw/short_name/],
        name  => 'short_name',
        label => 'rol',
        title => 'Rol',
        letter_e => 'e',
    },
    LdapOu => {
        match => [qw/ou/],
        name  => 'ou',
        label => 'organisatorische eenheid',
        letter_e => 'e',
    },
    BibliotheekCategorie        => {
        match => [qw/naam/],
        name  => 'naam',
        label => 'categorie',
        letter_e => 'e',
    },
};

use constant BETROKKENE_RELATEREN_PROFILE => {
    required    => [qw/
        betrokkene_identifier
        magic_string_prefix
        rol
    /],
    msgs                => sub {
        my $dfv     = shift;
        my $rv      = {};

        for my $missing ($dfv->missing) {
            $rv->{$missing}  = 'Veld is verplicht.';
        }
        for my $missing ($dfv->invalid) {
            $rv->{$missing}  = 'Veld is niet correct ingevuld.';
        }

        return $rv;
    }
};

use constant BETROKKENE_RELATEREN_MAGIC_STRING_SUGGESTION => sub {
    my (@used_columns)              = @{ shift(@_) };
    my ($magic_string_prefix, $rol) = @_;

    my @ZAAKSYSTEEM_KENMERKEN   = (
        ZAAKSYSTEEM_STANDAARD_KOLOMMEN,
        ZAAKSYSTEEM_STANDAARD_KENMERKEN
    );

    push(
        @used_columns,
        keys %{ $_ }
    ) for @ZAAKSYSTEEM_KENMERKEN;

    ### make a suggestion or give back given string
    my $suggestion  = $magic_string_prefix || $rol;
    my $counter     = '';
    while (
        grep {
            $suggestion . $counter .'_naam' eq $_ ||
            $suggestion .  $counter eq $_
        } @used_columns
    ) {
        $counter = 0 if !$counter;
        $counter++;
    }

    $suggestion     .= $counter;

    return $suggestion;

};

use constant ZAAK_WIJZIG_VERNIETIGINGSDATUM_PROFILE         => {
    required            => [qw/
        vernietigingsdatum
    /],
    constraint_methods  => {
        vernietigingsdatum  => sub {
            my ($dfv, $val) = @_;

            if (UNIVERSAL::isa($val, 'DateTime')) {
                return 1;
            }

            if ($val =~ /^\d{2}\-\d{2}\-\d{4}$/) {
                return 1;
            }

            return;
        }
    },
    field_filters       => {
        vernietigingsdatum  => sub {
            my ($val) = @_;

            if (UNIVERSAL::isa($val, 'DateTime')) {
                return $val;
            }

            if (
                (my ($day, $month, $year) = $val =~
                    /^(\d{2})\-(\d{2})\-(\d{4})$/)
            ) {
                return DateTime->new(
                    year        => $year,
                    day         => $day,
                    month       => $month
                );
            }

            return $val;
        }
    },
    msgs                => PARAMS_PROFILE_MESSAGES_SUB,
};

1;



=head1 PROJECT FOUNDER

Mintlab B.V. <info@mintlab.nl>

=head1 CONTRIBUTORS

Arne de Boer

Nicolette Koedam

Marjolein Bryant

Peter Moen

Michiel Ootjers

Jonas Paarlberg

Jan-Willem Buitenhuis

Martin Kip

Gemeente Bussum

=head1 COPYRIGHT

Copyright (c) 2009, the above named PROJECT FOUNDER and CONTRIBUTORS.

=head1 LICENSE

The contents of this file and the complete zaaksysteem.nl distribution
are subject to the EUPL, Version 1.1 or - as soon they will be approved by the
European Commission - subsequent versions of the EUPL (the "Licence"); you may
not use this file except in compliance with the License. You may obtain a copy
of the License at
L<http://joinup.ec.europa.eu/software/page/eupl>

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

=cut

