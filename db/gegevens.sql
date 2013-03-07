--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

ALTER TABLE ONLY public.natuurlijk_persoon DROP CONSTRAINT natuurlijk_persoon_adres_id_fkey;
DROP INDEX public.natuurlijk_persoon_idx_adres_id;
DROP INDEX public.natuurlijk_persoon_burgerservicenummer;
ALTER TABLE ONLY public.bag_woonplaats DROP CONSTRAINT pk_woonplaats;
ALTER TABLE ONLY public.bag_verblijfsobject_pand DROP CONSTRAINT pk_verblijfsobject_pand;
ALTER TABLE ONLY public.bag_verblijfsobject_gebruiksdoel DROP CONSTRAINT pk_verblijfsobject_gebrdoel;
ALTER TABLE ONLY public.bag_verblijfsobject DROP CONSTRAINT pk_verblijfsobject;
ALTER TABLE ONLY public.bag_standplaats DROP CONSTRAINT pk_standplaats;
ALTER TABLE ONLY public.bag_pand DROP CONSTRAINT pk_pand;
ALTER TABLE ONLY public.bag_openbareruimte DROP CONSTRAINT pk_openbareruimte;
ALTER TABLE ONLY public.bag_nummeraanduiding DROP CONSTRAINT pk_nummeraanduiding;
ALTER TABLE ONLY public.bag_ligplaats_nevenadres DROP CONSTRAINT pk_ligplaats_nevenadres;
ALTER TABLE ONLY public.bag_ligplaats DROP CONSTRAINT pk_ligplaats;
ALTER TABLE ONLY public.parkeergebied DROP CONSTRAINT parkeergebied_pkey;
ALTER TABLE ONLY public.parkeergebied_kosten DROP CONSTRAINT parkeergebied_kosten_pkey;
ALTER TABLE ONLY public.natuurlijk_persoon DROP CONSTRAINT natuurlijk_persoon_pkey;
ALTER TABLE ONLY public.bedrijf DROP CONSTRAINT bedrijf_pkey;
ALTER TABLE ONLY public.adres DROP CONSTRAINT adres_pkey;
ALTER TABLE public.parkeergebied_kosten ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.parkeergebied ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.natuurlijk_persoon ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.bedrijf ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.adres ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE public.parkeergebied_kosten_id_seq;
DROP TABLE public.parkeergebied_kosten;
DROP SEQUENCE public.parkeergebied_id_seq;
DROP TABLE public.parkeergebied;
DROP SEQUENCE public.natuurlijk_persoon_id_seq;
DROP TABLE public.natuurlijk_persoon;
DROP SEQUENCE public.bedrijf_id_seq;
DROP TABLE public.bedrijf;
DROP TABLE public.bag_woonplaats;
DROP TABLE public.bag_verblijfsobject_pand;
DROP TABLE public.bag_verblijfsobject_gebruiksdoel;
DROP TABLE public.bag_verblijfsobject;
DROP TABLE public.bag_standplaats;
DROP TABLE public.bag_pand;
DROP TABLE public.bag_openbareruimte;
DROP TABLE public.bag_nummeraanduiding;
DROP TABLE public.bag_ligplaats_nevenadres;
DROP TABLE public.bag_ligplaats;
DROP SEQUENCE public.adres_id_seq;
DROP TABLE public.adres;
DROP SCHEMA public;
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: adres; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE adres (
    id integer NOT NULL,
    straatnaam character varying(80),
    huisnummer smallint,
    huisletter character(1),
    huisnummertoevoeging character varying(4),
    nadere_aanduiding character varying(35),
    postcode character varying(6),
    woonplaats character varying(75),
    gemeentedeel character varying(75),
    functie_adres character(1),
    datum_aanvang_bewoning date,
    woonplaats_id character varying(32),
    gemeente_code smallint,
    hash character varying(32),
    import_datum timestamp(6) without time zone,
    deleted_on timestamp(6) without time zone
);


--
-- Name: adres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE adres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: adres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE adres_id_seq OWNED BY adres.id;


--
-- Name: bag_ligplaats; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bag_ligplaats (
    identificatie character varying(16) NOT NULL,
    begindatum character varying(14) NOT NULL,
    einddatum character varying(14),
    officieel character varying(1) NOT NULL,
    status character varying(80) NOT NULL,
    hoofdadres character varying(16) NOT NULL,
    inonderzoek character varying(1) NOT NULL,
    documentdatum character varying(14) NOT NULL,
    documentnummer character varying(20) NOT NULL,
    correctie character varying(1) NOT NULL
);


--
-- Name: TABLE bag_ligplaats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE bag_ligplaats IS '55 : een ligplaats is een formeel door de gemeenteraad als zodanig aangewezen plaats in het water, al dan niet aangevuld met een op de oever aanwezig terrein of een gedeelte daarvan, dat bestemd is voor het permanent afmeren van een voor woon-, bedrijfsmatige- of recreatieve doeleinden geschikt vaartuig.';


--
-- Name: COLUMN bag_ligplaats.identificatie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats.identificatie IS '58.01 : de unieke aanduiding van een ligplaats.';


--
-- Name: COLUMN bag_ligplaats.begindatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats.begindatum IS '58.91 : de begindatum van een periode waarin een of meer gegevens die worden bijgehouden over een ligplaats een wijziging hebben ondergaan.';


--
-- Name: COLUMN bag_ligplaats.einddatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats.einddatum IS '58.92 : de einddatum van een periode waarin er geen wijzigingen hebben plaatsgevonden in de gegevens die worden bijgehouden over een ligplaats.';


--
-- Name: COLUMN bag_ligplaats.officieel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats.officieel IS '58.02 : een aanduiding waarmee kan worden aangegeven dat een object in de registratie is opgenomen als gevolg van een feitelijke constatering, zonder dat er op het moment van opname sprake is van een formele grondslag voor deze opname.';


--
-- Name: COLUMN bag_ligplaats.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats.status IS '58.03 : de fase van de levenscyclus van een ligplaats, waarin de betreffende ligplaats zich bevindt.';


--
-- Name: COLUMN bag_ligplaats.hoofdadres; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats.hoofdadres IS '58:10 : de identificatiecode nummeraanduiding waaronder het hoofdadres van een ligplaats, dat in het kader van de basis gebouwen registratie als zodanig is aangemerkt, is opgenomen in de basis registratie adressen.';


--
-- Name: COLUMN bag_ligplaats.inonderzoek; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats.inonderzoek IS '58.93 : een aanduiding waarmee wordt aangegeven dat een onderzoek wordt uitgevoerd naar de juistheid van een of meerdere gegevens van het betreffende object.';


--
-- Name: COLUMN bag_ligplaats.documentdatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats.documentdatum IS '58.97 : de datum waarop het brondocument is vastgesteld, op basis waarvan een opname, mutatie of een in de historie plaatsen van gegevens ten aanzien van een ligplaats heeft plaatsgevonden.';


--
-- Name: COLUMN bag_ligplaats.documentnummer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats.documentnummer IS '58.98 : de unieke aanduiding van het brondocument op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een ligplaats heeft plaatsgevonden, binnen een gemeente.';


--
-- Name: COLUMN bag_ligplaats.correctie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats.correctie IS 'het gegeven is gecorrigeerd.';


--
-- Name: bag_ligplaats_nevenadres; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bag_ligplaats_nevenadres (
    identificatie character varying(16) NOT NULL,
    begindatum character varying(14) NOT NULL,
    nevenadres character varying(16) NOT NULL,
    correctie character varying(1) NOT NULL
);


--
-- Name: TABLE bag_ligplaats_nevenadres; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE bag_ligplaats_nevenadres IS 'koppeltabel voor nevenadressen bij ligplaats';


--
-- Name: COLUMN bag_ligplaats_nevenadres.identificatie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats_nevenadres.identificatie IS '58.01 : de unieke aanduiding van een ligplaats.';


--
-- Name: COLUMN bag_ligplaats_nevenadres.begindatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats_nevenadres.begindatum IS '58.91 : de begindatum van een periode waarin een of meer gegevens die worden bijgehouden over een ligplaats een wijziging hebben ondergaan.';


--
-- Name: COLUMN bag_ligplaats_nevenadres.nevenadres; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats_nevenadres.nevenadres IS '58.11 : de identificatiecodes nummeraanduiding waaronder nevenadressen van een ligplaats, die in het kader van de basis gebouwen registratie als zodanig zijn aangemerkt, zijn opgenomen in de basis registratie adressen.';


--
-- Name: COLUMN bag_ligplaats_nevenadres.correctie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_ligplaats_nevenadres.correctie IS 'het gegeven is gecorrigeerd.';


--
-- Name: bag_nummeraanduiding; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bag_nummeraanduiding (
    identificatie character varying(16) NOT NULL,
    begindatum character varying(14) NOT NULL,
    einddatum character varying(14),
    huisnummer integer NOT NULL,
    officieel character varying(1) NOT NULL,
    huisletter character varying(1),
    huisnummertoevoeging character varying(4),
    postcode character varying(6),
    woonplaats character varying(4),
    inonderzoek character varying(1) NOT NULL,
    openbareruimte character varying(16) NOT NULL,
    type character varying(20) NOT NULL,
    documentdatum character varying(14) NOT NULL,
    documentnummer character varying(20) NOT NULL,
    status character varying(80) NOT NULL,
    correctie character varying(1) NOT NULL
);


--
-- Name: TABLE bag_nummeraanduiding; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE bag_nummeraanduiding IS '11.2 : een nummeraanduiding is een door de gemeenteraad als zodanig toegekende aanduiding van een adresseerbaar object.';


--
-- Name: COLUMN bag_nummeraanduiding.identificatie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.identificatie IS '11.02 : de unieke aanduiding van een nummeraanduiding.';


--
-- Name: COLUMN bag_nummeraanduiding.begindatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.begindatum IS '11.62 : de begindatum van een periode waarin een of meer gegevens die worden bijgehouden over een nummeraanduiding een wijziging hebben ondergaan.';


--
-- Name: COLUMN bag_nummeraanduiding.einddatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.einddatum IS '11.63 : de einddatum van een periode waarin er geen wijzigingen hebben plaatsgevonden in de gegevens die worden bijgehouden over een nummeraanduiding.';


--
-- Name: COLUMN bag_nummeraanduiding.huisnummer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.huisnummer IS '11.20 : een door of namens het gemeentebestuur ten aanzien van een adresseerbaar object toegekende nummering.';


--
-- Name: COLUMN bag_nummeraanduiding.officieel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.officieel IS '11.21 : een aanduiding waarmee kan worden aangegeven dat een object in de registratie is opgenomen als gevolg van een feitelijke constatering, zonder dat er op het moment van opname sprake is van een formele grondslag voor deze opname.';


--
-- Name: COLUMN bag_nummeraanduiding.huisletter; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.huisletter IS '11.30 : een door of namens het gemeentebestuur ten aanzien van  een adresseerbaar object toegekende toevoeging aan een huisnummer in de vorm van een alfanumeriek teken.';


--
-- Name: COLUMN bag_nummeraanduiding.huisnummertoevoeging; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.huisnummertoevoeging IS '11.40 : een door of namens het gemeentebestuur ten aanzien van  een adresseerbaar object toegekende nadere toevoeging aan een huisnummer of een combinatie van huisnummer en huisletter.';


--
-- Name: COLUMN bag_nummeraanduiding.postcode; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.postcode IS '11.60 : de door tnt post vastgestelde code behorende bij een bepaalde combinatie van een straatnaam en een huisnummer.';


--
-- Name: COLUMN bag_nummeraanduiding.woonplaats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.woonplaats IS '11.61 : unieke aanduiding van de woonplaats waarbinnen het object waaraan de nummeraanduiding is toegekend is gelegen.';


--
-- Name: COLUMN bag_nummeraanduiding.inonderzoek; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.inonderzoek IS '11.64 : een aanduiding waarmee wordt aangegeven dat een onderzoek wordt uitgevoerd naar de juistheid van een of meerdere gegevens van het betreffende object.';


--
-- Name: COLUMN bag_nummeraanduiding.openbareruimte; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.openbareruimte IS '11.65 : de unieke aanduiding van een openbare ruimte waaraan een adresseerbaar object is gelegen.';


--
-- Name: COLUMN bag_nummeraanduiding.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.type IS '11.66 : de aard van een als zodanig benoemde nummeraanduiding.';


--
-- Name: COLUMN bag_nummeraanduiding.documentdatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.documentdatum IS '11.67 : de datum waarop het brondocument is vastgesteld, op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een nummeraanduiding heeft plaatsgevonden.';


--
-- Name: COLUMN bag_nummeraanduiding.documentnummer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.documentnummer IS '11.68 : de unieke aanduiding van het brondocument op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een nummeraanduiding heeft plaatsgevonden, binnen een gemeente.';


--
-- Name: COLUMN bag_nummeraanduiding.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.status IS '11.69 : de fase van de levenscyclus van een nummeraanduiding, waarin de betreffende nummeraanduiding zich bevindt.';


--
-- Name: COLUMN bag_nummeraanduiding.correctie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_nummeraanduiding.correctie IS 'het gegeven is gecorrigeerd.';


--
-- Name: bag_openbareruimte; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bag_openbareruimte (
    identificatie character varying(16) NOT NULL,
    begindatum character varying(14) NOT NULL,
    einddatum character varying(14),
    naam character varying(80) NOT NULL,
    officieel character varying(1) NOT NULL,
    woonplaats character varying(4),
    type character varying(40) NOT NULL,
    inonderzoek character varying(1) NOT NULL,
    documentdatum character varying(14) NOT NULL,
    documentnummer character varying(20) NOT NULL,
    status character varying(80) NOT NULL,
    correctie character varying(1) NOT NULL
);


--
-- Name: TABLE bag_openbareruimte; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE bag_openbareruimte IS '11.1 : een openbare ruimte is een door de gemeenteraad als zodanig aangewezen benaming van een binnen een woonplaats gelegen buitenruimte.';


--
-- Name: COLUMN bag_openbareruimte.identificatie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.identificatie IS '11.01 : de unieke aanduiding van een openbare ruimte.';


--
-- Name: COLUMN bag_openbareruimte.begindatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.begindatum IS '11.12 : de begindatum van een periode waarin een of meer gegevens die worden bijgehouden over een openbare ruimte een wijziging hebben ondergaan.';


--
-- Name: COLUMN bag_openbareruimte.einddatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.einddatum IS '11.13 : de einddatum van een periode waarin er geen wijzigingen hebben plaatsgevonden in de gegevens die worden bijgehouden over een openbare ruimte.';


--
-- Name: COLUMN bag_openbareruimte.naam; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.naam IS '11.10 : een naam die aan een openbare ruimte is toegekend in een daartoe strekkend formeel gemeentelijk besluit.';


--
-- Name: COLUMN bag_openbareruimte.officieel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.officieel IS '11.11 : een aanduiding waarmee kan worden aangegeven dat een object in de registratie is opgenomen als gevolg van een feitelijke constatering, zonder dat er op het moment van opname sprake is van een formele grondslag voor deze opname.';


--
-- Name: COLUMN bag_openbareruimte.woonplaats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.woonplaats IS '11.15 : unieke aanduiding van de woonplaats waarbinnen een openbare ruimte is gelegen.';


--
-- Name: COLUMN bag_openbareruimte.type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.type IS '11.16 : de aard van de als zodanig benoemde openbare ruimte.';


--
-- Name: COLUMN bag_openbareruimte.inonderzoek; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.inonderzoek IS '11.14 : een aanduiding waarmee wordt aangegeven dat een onderzoek wordt uitgevoerd naar de juistheid van een of meerdere gegevens van het betreffende object.';


--
-- Name: COLUMN bag_openbareruimte.documentdatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.documentdatum IS '11.17 : de datum waarop het brondocument is vastgesteld, op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een openbare ruimte heeft plaatsgevonden.';


--
-- Name: COLUMN bag_openbareruimte.documentnummer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.documentnummer IS '11.18 : de unieke aanduiding van het brondocument op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een openbare ruimte heeft plaatsgevonden, binnen een gemeente.';


--
-- Name: COLUMN bag_openbareruimte.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.status IS '11.19 : de fase van de levenscyclus van een openbare ruimte, waarin de betreffende openbare ruimte zich bevindt.';


--
-- Name: COLUMN bag_openbareruimte.correctie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_openbareruimte.correctie IS 'het gegeven is gecorrigeerd.';


--
-- Name: bag_pand; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bag_pand (
    identificatie character varying(16) NOT NULL,
    begindatum character varying(14) NOT NULL,
    einddatum character varying(14),
    officieel character varying(1) NOT NULL,
    bouwjaar integer NOT NULL,
    status character varying(80) NOT NULL,
    inonderzoek character varying(1) NOT NULL,
    documentdatum character varying(14) NOT NULL,
    documentnummer character varying(20) NOT NULL,
    correctie character varying(1) NOT NULL
);


--
-- Name: TABLE bag_pand; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE bag_pand IS '55 : een pand is de kleinste, bij de totstandkoming functioneel en bouwkundig constructief zelfstandige eenheid, die direct en duurzaam met de aarde is verbonden.';


--
-- Name: COLUMN bag_pand.identificatie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_pand.identificatie IS '55.01 : de unieke aanduiding van een pand';


--
-- Name: COLUMN bag_pand.begindatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_pand.begindatum IS '55.91 : de begindatum van een periode waarin een of meer gegevens die worden bijgehouden over een pand een wijziging hebben ondergaan.';


--
-- Name: COLUMN bag_pand.einddatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_pand.einddatum IS '55.92 : de einddatum van een periode waarin er geen wijzigingen hebben plaatsgevonden in de gegevens die worden bijgehouden over een pand.';


--
-- Name: COLUMN bag_pand.officieel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_pand.officieel IS '55.02 : een aanduiding waarmee kan worden aangegeven dat een object in de registratie is opgenomen als gevolg van een feitelijke constatering, zonder dat er op het moment van opname sprake is van een formele grondslag voor deze opname';


--
-- Name: COLUMN bag_pand.bouwjaar; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_pand.bouwjaar IS '55.30 : de aanduiding van het jaar waarin een pand oorspronkelijk als bouwkundig gereed is opgeleverd.';


--
-- Name: COLUMN bag_pand.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_pand.status IS '55.31 : de fase van de levenscyclus van een pand, waarin het betreffende pand zich bevindt.';


--
-- Name: COLUMN bag_pand.inonderzoek; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_pand.inonderzoek IS '55.93 : een aanduiding waarmee wordt aangegeven dat een onderzoek wordt uitgevoerd naar de juistheid van een of meerdere gegevens van het betreffende object.';


--
-- Name: COLUMN bag_pand.documentdatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_pand.documentdatum IS '55.97 : de datum waarop het brondocument is vastgesteld, op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een pand heeft plaatsgevonden.';


--
-- Name: COLUMN bag_pand.documentnummer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_pand.documentnummer IS '55.98 : de unieke aanduiding van het brondocument op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een pand heeft plaatsgevonden, binnen een gemeente.';


--
-- Name: COLUMN bag_pand.correctie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_pand.correctie IS 'het gegeven is gecorrigeerd.';


--
-- Name: bag_standplaats; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bag_standplaats (
    identificatie character varying(16) NOT NULL,
    begindatum character varying(14) NOT NULL,
    einddatum character varying(14),
    officieel character varying(1) NOT NULL,
    status character varying(80) NOT NULL,
    hoofdadres character varying(16) NOT NULL,
    inonderzoek character varying(1) NOT NULL,
    documentdatum character varying(14) NOT NULL,
    documentnummer character varying(20) NOT NULL,
    correctie character varying(1) NOT NULL
);


--
-- Name: TABLE bag_standplaats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE bag_standplaats IS '57 : een standplaats is een formeel door de gemeenteraad als zodanig aangewezen terrein of een gedeelte daarvan, dat bestemd is voor het permanent plaatsen van een niet direct en duurzaam met de aarde verbonden en voor woon -, bedrijfsmatige - of recreatieve doeleinden geschikte ruimte.';


--
-- Name: COLUMN bag_standplaats.identificatie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_standplaats.identificatie IS '57.01 : de unieke aanduiding van een standplaats.';


--
-- Name: COLUMN bag_standplaats.begindatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_standplaats.begindatum IS '57.91 : de begindatum van een periode waarin een of meer gegevens die worden bijgehouden over een standplaats een wijziging hebben ondergaan.';


--
-- Name: COLUMN bag_standplaats.einddatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_standplaats.einddatum IS '57.92 : de einddatum van een periode waarin er geen wijzigingen hebben plaatsgevonden in de gegevens die worden bijgehouden over een standplaats.';


--
-- Name: COLUMN bag_standplaats.officieel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_standplaats.officieel IS '57.02 : een aanduiding waarmee kan worden aangegeven dat een object in de registratie is opgenomen als gevolg van een feitelijke constatering, zonder dat er op het moment van opname sprake is van een formele grondslag voor deze opname.';


--
-- Name: COLUMN bag_standplaats.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_standplaats.status IS '57.03 : de fase van de levenscyclus van een standplaats, waarin de betreffende standplaats zich bevindt.';


--
-- Name: COLUMN bag_standplaats.hoofdadres; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_standplaats.hoofdadres IS '57:10 : de identificatiecode nummeraanduiding waaronder het hoofdadres van een standplaats, dat in het kader van de basis gebouwen registratie als zodanig is aangemerkt, is opgenomen in de basis registratie adressen.';


--
-- Name: COLUMN bag_standplaats.inonderzoek; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_standplaats.inonderzoek IS '57.93 : een aanduiding waarmee wordt aangegeven dat een onderzoek wordt uitgevoerd naar de juistheid van een of meerdere gegevens van het betreffende object.';


--
-- Name: COLUMN bag_standplaats.documentdatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_standplaats.documentdatum IS '57.97 : de datum waarop het brondocument is vastgesteld, op basis waarvan een opname, mutatie of een in de historie plaatsen van gegevens ten aanzien van een standplaats heeft plaatsgevonden.';


--
-- Name: COLUMN bag_standplaats.documentnummer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_standplaats.documentnummer IS '57.98 : de unieke aanduiding van het brondocument op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een standplaats heeft plaatsgevonden, binnen een gemeente.';


--
-- Name: COLUMN bag_standplaats.correctie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_standplaats.correctie IS 'het gegeven is gecorrigeerd.';


--
-- Name: bag_verblijfsobject; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bag_verblijfsobject (
    identificatie character varying(16) NOT NULL,
    begindatum character varying(14) NOT NULL,
    einddatum character varying(14),
    officieel character varying(1) NOT NULL,
    hoofdadres character varying(16) NOT NULL,
    oppervlakte integer NOT NULL,
    status character varying(80) NOT NULL,
    inonderzoek character varying(1) NOT NULL,
    documentdatum character varying(14) NOT NULL,
    documentnummer character varying(20) NOT NULL,
    correctie character varying(1) NOT NULL
);


--
-- Name: TABLE bag_verblijfsobject; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE bag_verblijfsobject IS '56 : een verblijfsobject is de kleinste binnen een of meerdere panden gelegen en voor woon -, bedrijfsmatige - of recreatieve doeleinden geschikte eenheid van gebruik, die ontsloten wordt via een eigen toegang vanaf de openbare weg, een erf of een gedeelde verkeersruimte en die onderwerp kan zijn van rechtshandelingen.';


--
-- Name: COLUMN bag_verblijfsobject.identificatie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject.identificatie IS '56.01 : de unieke aanduiding van een verblijfsobject';


--
-- Name: COLUMN bag_verblijfsobject.begindatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject.begindatum IS '56.91 : de begindatum van een periode waarin een of meer gegevens die worden bijgehouden over een verblijfsobject een wijziging hebben ondergaan.';


--
-- Name: COLUMN bag_verblijfsobject.einddatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject.einddatum IS '56.92 : de einddatum van een periode waarin er geen wijzigingen hebben plaatsgevonden in de gegevens die worden bijgehouden over een verblijfsobject.';


--
-- Name: COLUMN bag_verblijfsobject.officieel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject.officieel IS '56.02 : een aanduiding waarmee kan worden aangegeven dat een object in de registratie is opgenomen als gevolg van een feitelijke constatering, zonder dat er op het moment van opname sprake is van een formele grondslag voor deze opname';


--
-- Name: COLUMN bag_verblijfsobject.hoofdadres; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject.hoofdadres IS '56:10 : de identificatiecode nummeraanduiding waaronder het hoofdadres van een verblijfsobject, dat in het kader van de basis gebouwen registratie als zodanig is aangemerkt, is opgenomen in de basis registratie adressen.';


--
-- Name: COLUMN bag_verblijfsobject.oppervlakte; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject.oppervlakte IS '56.31 : de gebruiksoppervlakte van een verblijfsobject in gehele vierkante meters.';


--
-- Name: COLUMN bag_verblijfsobject.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject.status IS '56.32 : de fase van de levenscyclus van een verblijfsobject, waarin het betreffende verblijfsobject zich bevindt.';


--
-- Name: COLUMN bag_verblijfsobject.inonderzoek; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject.inonderzoek IS '56.93 : een aanduiding waarmee wordt aangegeven dat een onderzoek wordt uitgevoerd naar de juistheid van een of meerdere gegevens van het betreffende object.';


--
-- Name: COLUMN bag_verblijfsobject.documentdatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject.documentdatum IS '56.97 : de datum waarop het brondocument is vastgesteld, op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een verblijfsobject heeft plaatsgevonden.';


--
-- Name: COLUMN bag_verblijfsobject.documentnummer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject.documentnummer IS '56.98 : de unieke aanduiding van het brondocument op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een verblijfsobject heeft plaatsgevonden, binnen een gemeente.';


--
-- Name: COLUMN bag_verblijfsobject.correctie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject.correctie IS 'het gegeven is gecorrigeerd.';


--
-- Name: bag_verblijfsobject_gebruiksdoel; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bag_verblijfsobject_gebruiksdoel (
    identificatie character varying(16) NOT NULL,
    begindatum character varying(14) NOT NULL,
    gebruiksdoel character varying(80) NOT NULL,
    correctie character varying(1) NOT NULL
);


--
-- Name: TABLE bag_verblijfsobject_gebruiksdoel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE bag_verblijfsobject_gebruiksdoel IS 'koppeltabel voor gebruiksdoelen bij verblijfsobject';


--
-- Name: COLUMN bag_verblijfsobject_gebruiksdoel.identificatie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject_gebruiksdoel.identificatie IS '56.01 : de unieke aanduiding van een verblijfsobject';


--
-- Name: COLUMN bag_verblijfsobject_gebruiksdoel.begindatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject_gebruiksdoel.begindatum IS '56.91 : de begindatum van een periode waarin een of meer gegevens die worden bijgehouden over een verblijfsobject een wijziging hebben ondergaan.';


--
-- Name: COLUMN bag_verblijfsobject_gebruiksdoel.gebruiksdoel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject_gebruiksdoel.gebruiksdoel IS '56.30 : een categorisering van de gebruiksdoelen van het betreffende verblijfsobject, zoals dit  formeel door de overheid als zodanig is toegestaan.';


--
-- Name: COLUMN bag_verblijfsobject_gebruiksdoel.correctie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject_gebruiksdoel.correctie IS 'het gegeven is gecorrigeerd.';


--
-- Name: bag_verblijfsobject_pand; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bag_verblijfsobject_pand (
    identificatie character varying(16) NOT NULL,
    begindatum character varying(14) NOT NULL,
    pand character varying(16) NOT NULL,
    correctie character varying(1) NOT NULL
);


--
-- Name: TABLE bag_verblijfsobject_pand; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE bag_verblijfsobject_pand IS 'koppeltabel voor panden bij verblijfsobject';


--
-- Name: COLUMN bag_verblijfsobject_pand.identificatie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject_pand.identificatie IS '56.01 : de unieke aanduiding van een verblijfsobject';


--
-- Name: COLUMN bag_verblijfsobject_pand.begindatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject_pand.begindatum IS '56.91 : de begindatum van een periode waarin een of meer gegevens die worden bijgehouden over een verblijfsobject een wijziging hebben ondergaan.';


--
-- Name: COLUMN bag_verblijfsobject_pand.pand; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject_pand.pand IS '56.90 : de unieke aanduidingen van de panden waarvan het verblijfsobject onderdeel uitmaakt.';


--
-- Name: COLUMN bag_verblijfsobject_pand.correctie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_verblijfsobject_pand.correctie IS 'het gegeven is gecorrigeerd.';


--
-- Name: bag_woonplaats; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bag_woonplaats (
    identificatie character varying(16) NOT NULL,
    begindatum character varying(14) NOT NULL,
    einddatum character varying(14),
    officieel character varying(1) NOT NULL,
    naam character varying(80) NOT NULL,
    status character varying(80) NOT NULL,
    inonderzoek character varying(1) NOT NULL,
    documentdatum character varying(14) NOT NULL,
    documentnummer character varying(20) NOT NULL,
    correctie character varying(1) NOT NULL
);


--
-- Name: TABLE bag_woonplaats; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE bag_woonplaats IS '11.7 : een woonplaats is een door de gemeenteraad als zodanig aangewezen gedeelte van het gemeentelijk grondgebied.';


--
-- Name: COLUMN bag_woonplaats.identificatie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_woonplaats.identificatie IS '11.03 : de landelijk unieke aanduiding van een woonplaats, zoals vastgesteld door de beheerder van de landelijke tabel voor woonplaatsen.';


--
-- Name: COLUMN bag_woonplaats.begindatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_woonplaats.begindatum IS '11.73 : de begindatum van een periode waarin een of meer gegevens die worden bijgehouden over een woonplaats een wijziging hebben ondergaan.';


--
-- Name: COLUMN bag_woonplaats.einddatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_woonplaats.einddatum IS '11.74 : de einddatum van een periode waarin er geen wijzigingen hebben plaatsgevonden in de gegevens die worden bijgehouden over een woonplaats.';


--
-- Name: COLUMN bag_woonplaats.officieel; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_woonplaats.officieel IS '11.72 : een aanduiding waarmee kan worden aangegeven dat een object in de registratie is opgenomen als gevolg van een feitelijke constatering, zonder dat er op het moment van opname sprake is van een formele grondslag voor deze opname.';


--
-- Name: COLUMN bag_woonplaats.naam; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_woonplaats.naam IS '11.70 : de benaming van een door het gemeentebestuur aangewezen woonplaats.';


--
-- Name: COLUMN bag_woonplaats.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_woonplaats.status IS '11.79 : de fase van de levenscyclus van een woonplaats, waarin de betreffende woonplaats zich bevindt.';


--
-- Name: COLUMN bag_woonplaats.inonderzoek; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_woonplaats.inonderzoek IS '11.75 : een aanduiding waarmee wordt aangegeven dat een onderzoek wordt uitgevoerd naar de juistheid van een of meerdere gegevens van het betreffende object.';


--
-- Name: COLUMN bag_woonplaats.documentdatum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_woonplaats.documentdatum IS '11.77 : de datum waarop het brondocument is vastgesteld, op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een woonplaats heeft plaatsgevonden.';


--
-- Name: COLUMN bag_woonplaats.documentnummer; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_woonplaats.documentnummer IS '11.78 : de unieke aanduiding van het brondocument op basis waarvan een opname, mutatie of een verwijdering van gegevens ten aanzien van een woonplaats heeft plaatsgevonden, binnen een gemeente.';


--
-- Name: COLUMN bag_woonplaats.correctie; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN bag_woonplaats.correctie IS 'het gegeven is gecorrigeerd.';


--
-- Name: bedrijf; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bedrijf (
    id integer NOT NULL,
    dossiernummer character varying(8),
    subdossiernummer character varying(4),
    hoofdvestiging_dossiernummer character varying(8),
    hoofdvestiging_subdossiernummer character varying(4),
    vorig_dossiernummer character varying(8),
    vorig_subdossiernummer character varying(4),
    handelsnaam character varying(45),
    rechtsvorm smallint,
    kamernummer smallint,
    faillisement smallint,
    surseance smallint,
    telefoonnummer character varying(10),
    email character varying(128),
    vestiging_adres character varying(30),
    vestiging_straatnaam character varying(25),
    vestiging_huisnummer character varying(6),
    vestiging_huisnummertoevoeging character varying(12),
    vestiging_postcodewoonplaats character varying(30),
    vestiging_postcode character varying(6),
    vestiging_woonplaats character varying(24),
    correspondentie_adres character varying(30),
    correspondentie_straatnaam character varying(25),
    correspondentie_huisnummer character varying(6),
    correspondentie_huisnummertoevoeging character varying(12),
    correspondentie_postcodewoonplaats character varying(30),
    correspondentie_postcode character varying(6),
    correspondentie_woonplaats character varying(24),
    hoofdactiviteitencode integer,
    nevenactiviteitencode1 integer,
    nevenactiviteitencode2 integer,
    werkzamepersonen integer,
    contact_naam character varying(64),
    contact_aanspreektitel character varying(45),
    contact_voorletters character varying(19),
    contact_voorvoegsel character varying(8),
    contact_geslachtsnaam character varying(95),
    contact_geslachtsaanduiding character varying(1),
    authenticated smallint,
    authenticatedby text,
    fulldossiernummer text,
    import_datum timestamp(6) without time zone,
    deleted_on timestamp(6) without time zone,
    verblijfsobject_id character varying(16)
);


--
-- Name: bedrijf_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bedrijf_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bedrijf_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bedrijf_id_seq OWNED BY bedrijf.id;


--
-- Name: natuurlijk_persoon; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE natuurlijk_persoon (
    id integer NOT NULL,
    burgerservicenummer character varying(9),
    a_nummer character varying(10),
    voorletters character varying(10),
    voornamen character varying(200),
    geslachtsnaam character varying(200),
    voorvoegsel character varying(50),
    geslachtsaanduiding character varying(3),
    nationaliteitscode1 smallint,
    nationaliteitscode2 smallint,
    nationaliteitscode3 smallint,
    geboortegemeente character varying(75),
    geboorteplaats character varying(75),
    geboortegemeente_omschrijving character varying(150),
    geboorteregio character varying(150),
    geboorteland character varying(75),
    geboortedatum timestamp without time zone,
    aanhef_aanschrijving character varying(10),
    voorletters_aanschrijving character varying(20),
    voornamen_aanschrijving character varying(200),
    naam_aanschrijving character varying(200),
    voorvoegsel_aanschrijving character varying(50),
    burgerlijke_staat character(1),
    indicatie_gezag character varying(2),
    indicatie_curatele character(1),
    indicatie_geheim character(1),
    aanduiding_verblijfsrecht smallint,
    datum_aanvang_verblijfsrecht date,
    datum_einde_verblijfsrecht date,
    aanduiding_soort_vreemdeling character varying(10),
    land_vanwaar_ingeschreven smallint,
    land_waarnaar_vertrokken smallint,
    adres_buitenland1 character varying(35),
    adres_buitenland2 character varying(35),
    adres_buitenland3 character varying(35),
    nnp_ts character varying(32),
    hash character varying(32),
    import_datum timestamp(6) without time zone,
    adres_id integer,
    email character varying(32),
    telefoon character varying(32),
    authenticated boolean,
    authenticatedby text,
    deleted_on timestamp(6) without time zone,
    verblijfsobject_id character varying(16),
    datum_overlijden timestamp without time zone,
    aanduiding_naamgebruik character varying(1),
    onderzoek_persoon boolean,
    onderzoek_persoon_ingang timestamp without time zone,
    onderzoek_persoon_einde timestamp without time zone,
    onderzoek_persoon_onjuist boolean,
    onderzoek_huwelijk boolean,
    onderzoek_huwelijk_ingang timestamp without time zone,
    onderzoek_huwelijk_einde timestamp without time zone,
    onderzoek_huwelijk_onjuist boolean,
    onderzoek_overlijden boolean,
    onderzoek_overlijden_ingang timestamp without time zone,
    onderzoek_overlijden_einde timestamp without time zone,
    onderzoek_overlijden_onjuist boolean,
    onderzoek_verblijfplaats boolean,
    onderzoek_verblijfplaats_ingang timestamp without time zone,
    onderzoek_verblijfplaats_einde timestamp without time zone,
    onderzoek_verblijfplaats_onjuist boolean,
    partner_a_nummer character varying(50),
    partner_burgerservicenummer character varying(50),
    partner_voorvoegsel character varying(50),
    partner_geslachtsnaam character varying(50),
    datum_huwelijk timestamp without time zone,
    datum_huwelijk_ontbinding timestamp without time zone
);


--
-- Name: natuurlijk_persoon_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE natuurlijk_persoon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: natuurlijk_persoon_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE natuurlijk_persoon_id_seq OWNED BY natuurlijk_persoon.id;


--
-- Name: parkeergebied; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE parkeergebied (
    id integer NOT NULL,
    bag_hoofdadres bigint,
    postcode character varying(6) NOT NULL,
    straatnaam character varying(255) NOT NULL,
    huisnummer integer,
    huisletter character varying(1),
    huisnummertoevoeging character varying(4),
    parkeergebied_id integer,
    parkeergebied character varying(255),
    created timestamp without time zone,
    last_modified timestamp without time zone
);


--
-- Name: parkeergebied_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE parkeergebied_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: parkeergebied_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE parkeergebied_id_seq OWNED BY parkeergebied.id;


--
-- Name: parkeergebied_kosten; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE parkeergebied_kosten (
    id integer NOT NULL,
    betrokkene_type character varying(128),
    parkeergebied character varying(255),
    parkeergebied_id integer,
    aanvraag_soort integer,
    geldigheid integer,
    prijs real,
    created timestamp without time zone,
    last_modified timestamp without time zone
);


--
-- Name: parkeergebied_kosten_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE parkeergebied_kosten_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: parkeergebied_kosten_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE parkeergebied_kosten_id_seq OWNED BY parkeergebied_kosten.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE adres ALTER COLUMN id SET DEFAULT nextval('adres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bedrijf ALTER COLUMN id SET DEFAULT nextval('bedrijf_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE natuurlijk_persoon ALTER COLUMN id SET DEFAULT nextval('natuurlijk_persoon_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE parkeergebied ALTER COLUMN id SET DEFAULT nextval('parkeergebied_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE parkeergebied_kosten ALTER COLUMN id SET DEFAULT nextval('parkeergebied_kosten_id_seq'::regclass);


--
-- Name: adres_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY adres
    ADD CONSTRAINT adres_pkey PRIMARY KEY (id);


--
-- Name: bedrijf_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bedrijf
    ADD CONSTRAINT bedrijf_pkey PRIMARY KEY (id);


--
-- Name: natuurlijk_persoon_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY natuurlijk_persoon
    ADD CONSTRAINT natuurlijk_persoon_pkey PRIMARY KEY (id);


--
-- Name: parkeergebied_kosten_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY parkeergebied_kosten
    ADD CONSTRAINT parkeergebied_kosten_pkey PRIMARY KEY (id);


--
-- Name: parkeergebied_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY parkeergebied
    ADD CONSTRAINT parkeergebied_pkey PRIMARY KEY (id);


--
-- Name: pk_ligplaats; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bag_ligplaats
    ADD CONSTRAINT pk_ligplaats PRIMARY KEY (identificatie, begindatum, correctie);


--
-- Name: pk_ligplaats_nevenadres; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bag_ligplaats_nevenadres
    ADD CONSTRAINT pk_ligplaats_nevenadres PRIMARY KEY (identificatie, begindatum, correctie, nevenadres);


--
-- Name: pk_nummeraanduiding; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bag_nummeraanduiding
    ADD CONSTRAINT pk_nummeraanduiding PRIMARY KEY (identificatie, begindatum, correctie);


--
-- Name: pk_openbareruimte; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bag_openbareruimte
    ADD CONSTRAINT pk_openbareruimte PRIMARY KEY (identificatie, begindatum, correctie);


--
-- Name: pk_pand; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bag_pand
    ADD CONSTRAINT pk_pand PRIMARY KEY (identificatie, begindatum, correctie);


--
-- Name: pk_standplaats; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bag_standplaats
    ADD CONSTRAINT pk_standplaats PRIMARY KEY (identificatie, begindatum, correctie);


--
-- Name: pk_verblijfsobject; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bag_verblijfsobject
    ADD CONSTRAINT pk_verblijfsobject PRIMARY KEY (identificatie, begindatum, correctie);


--
-- Name: pk_verblijfsobject_gebrdoel; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bag_verblijfsobject_gebruiksdoel
    ADD CONSTRAINT pk_verblijfsobject_gebrdoel PRIMARY KEY (identificatie, begindatum, correctie, gebruiksdoel);


--
-- Name: pk_verblijfsobject_pand; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bag_verblijfsobject_pand
    ADD CONSTRAINT pk_verblijfsobject_pand PRIMARY KEY (identificatie, begindatum, correctie, pand);


--
-- Name: pk_woonplaats; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bag_woonplaats
    ADD CONSTRAINT pk_woonplaats PRIMARY KEY (identificatie, begindatum, correctie);


--
-- Name: natuurlijk_persoon_burgerservicenummer; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX natuurlijk_persoon_burgerservicenummer ON natuurlijk_persoon USING btree (burgerservicenummer);


--
-- Name: natuurlijk_persoon_idx_adres_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX natuurlijk_persoon_idx_adres_id ON natuurlijk_persoon USING btree (adres_id);


--
-- Name: natuurlijk_persoon_adres_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY natuurlijk_persoon
    ADD CONSTRAINT natuurlijk_persoon_adres_id_fkey FOREIGN KEY (adres_id) REFERENCES adres(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- PostgreSQL database dump complete
--

