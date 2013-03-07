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

ALTER TABLE ONLY public.zaaktype DROP CONSTRAINT zaaktype_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.zaaktype_status DROP CONSTRAINT zaaktype_status_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.zaaktype_sjablonen DROP CONSTRAINT zaaktype_sjablonen_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.zaaktype_sjablonen DROP CONSTRAINT zaaktype_sjablonen_zaak_status_id_fkey;
ALTER TABLE ONLY public.zaaktype_sjablonen DROP CONSTRAINT zaaktype_sjablonen_bibliotheek_sjablonen_id_fkey;
ALTER TABLE ONLY public.zaaktype_resultaten DROP CONSTRAINT zaaktype_resultaten_zaaktype_status_id_fkey;
ALTER TABLE ONLY public.zaaktype_resultaten DROP CONSTRAINT zaaktype_resultaten_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.zaaktype_relatie DROP CONSTRAINT zaaktype_relatie_zaaktype_status_id_fkey;
ALTER TABLE ONLY public.zaaktype_relatie DROP CONSTRAINT zaaktype_relatie_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.zaaktype_relatie DROP CONSTRAINT zaaktype_relatie_relatie_zaaktype_id_fkey;
ALTER TABLE ONLY public.zaaktype_regel DROP CONSTRAINT zaaktype_regel_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.zaaktype_regel DROP CONSTRAINT zaaktype_regel_zaak_status_id_fkey;
ALTER TABLE ONLY public.zaaktype_notificatie DROP CONSTRAINT zaaktype_notificatie_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.zaaktype_notificatie DROP CONSTRAINT zaaktype_notificatie_zaak_status_id_fkey;
ALTER TABLE ONLY public.zaaktype_node DROP CONSTRAINT zaaktype_node_zaaktype_id_fkey;
ALTER TABLE ONLY public.zaaktype_node DROP CONSTRAINT zaaktype_node_zaaktype_definitie_id_fkey;
ALTER TABLE ONLY public.zaaktype_kenmerken DROP CONSTRAINT zaaktype_kenmerken_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.zaaktype_kenmerken DROP CONSTRAINT zaaktype_kenmerken_zaak_status_id_fkey;
ALTER TABLE ONLY public.zaaktype_kenmerken DROP CONSTRAINT zaaktype_kenmerken_bibliotheek_kenmerken_id_fkey;
ALTER TABLE ONLY public.zaaktype DROP CONSTRAINT zaaktype_bibliotheek_categorie_id_fkey;
ALTER TABLE ONLY public.zaaktype_betrokkenen DROP CONSTRAINT zaaktype_betrokkenen_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.zaaktype_authorisation DROP CONSTRAINT zaaktype_authorisation_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.zaaktype_authorisation DROP CONSTRAINT zaaktype_authorisation_zaaktype_id_fkey;
ALTER TABLE ONLY public.zaak DROP CONSTRAINT zaak_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.zaak_onafgerond DROP CONSTRAINT zaak_zaaktype_id_fkey;
ALTER TABLE ONLY public.zaak DROP CONSTRAINT zaak_zaaktype_id_fkey;
ALTER TABLE ONLY public.zaak DROP CONSTRAINT zaak_vervolg_van_fkey;
ALTER TABLE ONLY public.zaak DROP CONSTRAINT zaak_relates_to_fkey;
ALTER TABLE ONLY public.zaak DROP CONSTRAINT zaak_pid_fkey;
ALTER TABLE ONLY public.zaak_meta DROP CONSTRAINT zaak_meta_zaak_id_fkey;
ALTER TABLE ONLY public.zaak DROP CONSTRAINT zaak_locatie_zaak_fkey;
ALTER TABLE ONLY public.zaak DROP CONSTRAINT zaak_locatie_correspondentie_fkey;
ALTER TABLE ONLY public.zaak_kenmerken DROP CONSTRAINT zaak_kenmerken_zaak_id_fkey;
ALTER TABLE ONLY public.zaak_kenmerken_values DROP CONSTRAINT zaak_kenmerken_values_zaak_kenmerken_id_fkey;
ALTER TABLE ONLY public.zaak_kenmerken_values DROP CONSTRAINT zaak_kenmerken_values_zaak_bag_id_fkey;
ALTER TABLE ONLY public.zaak_kenmerken_values DROP CONSTRAINT zaak_kenmerken_values_bibliotheek_kenmerken_id_fkey;
ALTER TABLE ONLY public.zaak_kenmerken DROP CONSTRAINT zaak_kenmerken_bibliotheek_kenmerken_id_fkey;
ALTER TABLE ONLY public.checklist_antwoord DROP CONSTRAINT zaak_id_fkey;
ALTER TABLE ONLY public.logging DROP CONSTRAINT zaak_id_fkey;
ALTER TABLE ONLY public.documents DROP CONSTRAINT zaak_id_fkey;
ALTER TABLE ONLY public.zaak DROP CONSTRAINT zaak_coordinator_fkey;
ALTER TABLE ONLY public.zaak_betrokkenen DROP CONSTRAINT zaak_betrokkenen_zaak_id_fkey;
ALTER TABLE ONLY public.zaak DROP CONSTRAINT zaak_behandelaar_fkey;
ALTER TABLE ONLY public.zaak_bag DROP CONSTRAINT zaak_bag_zaak_id_fkey;
ALTER TABLE ONLY public.zaak_bag DROP CONSTRAINT zaak_bag_pid_fkey;
ALTER TABLE ONLY public.zaak DROP CONSTRAINT zaak_aanvrager_fkey;
ALTER TABLE ONLY public.search_query_delen DROP CONSTRAINT search_query_delen_search_query_id_fkey;
ALTER TABLE ONLY public.sbus_logging DROP CONSTRAINT sbus_logging_sbus_traffic_id_fkey;
ALTER TABLE ONLY public.sbus_logging DROP CONSTRAINT sbus_logging_pid_fkey;
ALTER TABLE ONLY public.gm_natuurlijk_persoon DROP CONSTRAINT gm_natuurlijk_persoon_adres_id_fkey;
ALTER TABLE ONLY public.documents DROP CONSTRAINT documents_pid_fkey;
ALTER TABLE ONLY public.documents_mail DROP CONSTRAINT documents_mail_document_id_fkey;
ALTER TABLE ONLY public.checklist_vraag DROP CONSTRAINT checklist_vraag_zaaktype_status_id_fkey;
ALTER TABLE ONLY public.checklist_vraag DROP CONSTRAINT checklist_vraag_zaaktype_node_id_fkey;
ALTER TABLE ONLY public.bibliotheek_sjablonen_magic_string DROP CONSTRAINT bibliotheek_sjablonen_magic_strin_bibliotheek_sjablonen_id_fkey;
ALTER TABLE ONLY public.bibliotheek_sjablonen DROP CONSTRAINT bibliotheek_sjablonen_filestore_id_fkey;
ALTER TABLE ONLY public.bibliotheek_sjablonen DROP CONSTRAINT bibliotheek_sjablonen_bibliotheek_categorie_id_fkey;
ALTER TABLE ONLY public.bibliotheek_kenmerken_values DROP CONSTRAINT bibliotheek_kenmerken_values_bibliotheek_kenmerken_id_fkey;
ALTER TABLE ONLY public.bibliotheek_kenmerken DROP CONSTRAINT bibliotheek_kenmerken_bibliotheek_categorie_id_fkey;
ALTER TABLE ONLY public.bibliotheek_categorie DROP CONSTRAINT bibliotheek_categorie_pid_fkey;
ALTER TABLE ONLY public.beheer_import_log DROP CONSTRAINT beheer_import_log_import_id_fkey;
DROP INDEX public.zaaktype_status_idx_zaaktype_node_id;
DROP INDEX public.zaaktype_resultaten_idx_zaaktype_status_id;
DROP INDEX public.zaaktype_resultaten_idx_zaaktype_node_id;
DROP INDEX public.zaaktype_relatie_idx_zaaktype_status_id;
DROP INDEX public.zaaktype_relatie_idx_zaaktype_node_id;
DROP INDEX public.zaaktype_relatie_idx_relatie_zaaktype_id;
DROP INDEX public.zaaktype_node_idx_zaaktype_id;
DROP INDEX public.zaaktype_idx_zaaktype_node_id;
DROP INDEX public.zaaktype_betrokkenen_idx_zaaktype_node_id;
DROP INDEX public.zaaktype_authorisation_idx_zaaktype_node_id;
DROP INDEX public.zaak_betrokkenen_gegevens_magazijn_index;
DROP INDEX public.gm_natuurlijk_persoon_idx_adres_id;
DROP INDEX public.documents_mail_idx_document_id;
DROP INDEX public.documents_idx_pid;
DROP INDEX public.bibliotheek_kenmerken_values_idx_bibliotheek_kenmerken_id;
DROP INDEX public.beheer_import_log_idx_import_id;
ALTER TABLE ONLY public.zaaktype_status DROP CONSTRAINT zaaktype_status_pkey;
ALTER TABLE ONLY public.zaaktype_sjablonen DROP CONSTRAINT zaaktype_sjablonen_pkey;
ALTER TABLE ONLY public.zaaktype_resultaten DROP CONSTRAINT zaaktype_resultaten_pkey;
ALTER TABLE ONLY public.zaaktype_relatie DROP CONSTRAINT zaaktype_relatie_pkey;
ALTER TABLE ONLY public.zaaktype_regel DROP CONSTRAINT zaaktype_regel_pkey;
ALTER TABLE ONLY public.zaaktype DROP CONSTRAINT zaaktype_pkey;
ALTER TABLE ONLY public.zaaktype_notificatie DROP CONSTRAINT zaaktype_notificatie_pkey;
ALTER TABLE ONLY public.zaaktype_node DROP CONSTRAINT zaaktype_node_pkey;
ALTER TABLE ONLY public.zaaktype_kenmerken DROP CONSTRAINT zaaktype_kenmerken_pkey;
ALTER TABLE ONLY public.zaaktype_definitie DROP CONSTRAINT zaaktype_definitie_pkey;
ALTER TABLE ONLY public.zaaktype_betrokkenen DROP CONSTRAINT zaaktype_betrokkenen_pkey;
ALTER TABLE ONLY public.zaaktype_authorisation DROP CONSTRAINT zaaktype_authorisation_pkey;
ALTER TABLE ONLY public.zaak DROP CONSTRAINT zaak_pkey;
ALTER TABLE ONLY public.zaak_onafgerond DROP CONSTRAINT zaak_onafgerond_pkey;
ALTER TABLE ONLY public.zaak_meta DROP CONSTRAINT zaak_meta_pkey;
ALTER TABLE ONLY public.zaak_kenmerken_values DROP CONSTRAINT zaak_kenmerken_values_pkey;
ALTER TABLE ONLY public.zaak_kenmerken DROP CONSTRAINT zaak_kenmerken_pkey;
ALTER TABLE ONLY public.zaak_betrokkenen DROP CONSTRAINT zaak_betrokkenen_pkey;
ALTER TABLE ONLY public.zaak_bag DROP CONSTRAINT zaak_bag_pkey;
ALTER TABLE ONLY public.user_app_lock DROP CONSTRAINT user_app_lock_pkey;
ALTER TABLE ONLY public.search_query DROP CONSTRAINT search_query_pkey;
ALTER TABLE ONLY public.search_query_delen DROP CONSTRAINT search_query_delen_pkey;
ALTER TABLE ONLY public.sbus_traffic DROP CONSTRAINT sbus_traffic_pkey;
ALTER TABLE ONLY public.sbus_logging DROP CONSTRAINT sbus_logging_pkey;
ALTER TABLE ONLY public.logging DROP CONSTRAINT logging_pkey;
ALTER TABLE ONLY public.gm_natuurlijk_persoon DROP CONSTRAINT gm_natuurlijk_persoon_pkey;
ALTER TABLE ONLY public.gm_bedrijf DROP CONSTRAINT gm_bedrijf_pkey;
ALTER TABLE ONLY public.gm_adres DROP CONSTRAINT gm_adres_pkey;
ALTER TABLE ONLY public.filestore DROP CONSTRAINT filestore_pkey;
ALTER TABLE ONLY public.dropped_documents DROP CONSTRAINT dropped_documents_pkey;
ALTER TABLE ONLY public.documents DROP CONSTRAINT documents_pkey;
ALTER TABLE ONLY public.documents_mail DROP CONSTRAINT documents_mail_pkey;
ALTER TABLE ONLY public.contact_data DROP CONSTRAINT contact_data_pkey;
ALTER TABLE ONLY public.checklist_vraag DROP CONSTRAINT checklist_vraag_pkey;
ALTER TABLE ONLY public.checklist_antwoord DROP CONSTRAINT checklist_antwoord_pkey;
ALTER TABLE ONLY public.checklist_antwoord DROP CONSTRAINT checklist_antwoord_id_key;
ALTER TABLE ONLY public.bibliotheek_sjablonen DROP CONSTRAINT bibliotheek_sjablonen_pkey;
ALTER TABLE ONLY public.bibliotheek_sjablonen_magic_string DROP CONSTRAINT bibliotheek_sjablonen_magic_string_pkey;
ALTER TABLE ONLY public.bibliotheek_kenmerken_values DROP CONSTRAINT bibliotheek_kenmerken_values_pkey;
ALTER TABLE ONLY public.bibliotheek_kenmerken DROP CONSTRAINT bibliotheek_kenmerken_pkey;
ALTER TABLE ONLY public.bibliotheek_categorie DROP CONSTRAINT bibliotheek_categorie_pkey;
ALTER TABLE ONLY public.betrokkenen DROP CONSTRAINT betrokkenen_pkey;
ALTER TABLE ONLY public.betrokkene_notes DROP CONSTRAINT betrokkene_notes_pkey;
ALTER TABLE ONLY public.beheer_plugins DROP CONSTRAINT beheer_plugins_pkey;
ALTER TABLE ONLY public.beheer_import DROP CONSTRAINT beheer_import_pkey;
ALTER TABLE ONLY public.beheer_import_log DROP CONSTRAINT beheer_import_log_pkey;
ALTER TABLE ONLY public.bedrijf_authenticatie DROP CONSTRAINT bedrijf_authenticatie_pkey;
ALTER TABLE public.zaaktype_status ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaaktype_sjablonen ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaaktype_resultaten ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaaktype_relatie ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaaktype_regel ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaaktype_notificatie ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaaktype_node ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaaktype_kenmerken ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaaktype_definitie ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaaktype_betrokkenen ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaaktype_authorisation ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaaktype ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaak_meta ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaak_kenmerken_values ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaak_kenmerken ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaak_betrokkenen ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaak_bag ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.zaak ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.search_query_delen ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.search_query ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.sbus_traffic ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.sbus_logging ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.logging ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.gm_natuurlijk_persoon ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.gm_bedrijf ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.gm_adres ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.filestore ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.dropped_documents ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.documents_mail ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.documents ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.contact_data ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.checklist_vraag ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.bibliotheek_sjablonen_magic_string ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.bibliotheek_sjablonen ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.bibliotheek_kenmerken_values ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.bibliotheek_kenmerken ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.bibliotheek_categorie ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.betrokkenen ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.betrokkene_notes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.beheer_plugins ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.beheer_import_log ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.beheer_import ALTER COLUMN id DROP DEFAULT;
ALTER TABLE public.bedrijf_authenticatie ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE public.zaaktype_status_id_seq;
DROP TABLE public.zaaktype_status;
DROP SEQUENCE public.zaaktype_sjablonen_id_seq;
DROP TABLE public.zaaktype_sjablonen;
DROP SEQUENCE public.zaaktype_resultaten_id_seq;
DROP TABLE public.zaaktype_resultaten;
DROP SEQUENCE public.zaaktype_relatie_id_seq;
DROP TABLE public.zaaktype_relatie;
DROP SEQUENCE public.zaaktype_regel_id_seq;
DROP TABLE public.zaaktype_regel;
DROP SEQUENCE public.zaaktype_notificatie_id_seq;
DROP TABLE public.zaaktype_notificatie;
DROP SEQUENCE public.zaaktype_node_id_seq;
DROP TABLE public.zaaktype_node;
DROP SEQUENCE public.zaaktype_kenmerken_id_seq;
DROP TABLE public.zaaktype_kenmerken;
DROP SEQUENCE public.zaaktype_id_seq;
DROP SEQUENCE public.zaaktype_definitie_id_seq;
DROP TABLE public.zaaktype_definitie;
DROP SEQUENCE public.zaaktype_betrokkenen_id_seq;
DROP TABLE public.zaaktype_betrokkenen;
DROP SEQUENCE public.zaaktype_authorisation_id_seq;
DROP TABLE public.zaaktype_authorisation;
DROP TABLE public.zaaktype;
DROP TABLE public.zaak_onafgerond;
DROP SEQUENCE public.zaak_meta_id_seq;
DROP TABLE public.zaak_meta;
DROP SEQUENCE public.zaak_kenmerken_values_id_seq;
DROP TABLE public.zaak_kenmerken_values;
DROP SEQUENCE public.zaak_kenmerken_id_seq;
DROP TABLE public.zaak_kenmerken;
DROP SEQUENCE public.zaak_id_seq;
DROP SEQUENCE public.zaak_betrokkenen_id_seq;
DROP TABLE public.zaak_betrokkenen;
DROP SEQUENCE public.zaak_bag_id_seq;
DROP TABLE public.zaak_bag;
DROP TABLE public.zaak;
DROP TABLE public.user_app_lock;
DROP SEQUENCE public.search_query_id_seq;
DROP SEQUENCE public.search_query_delen_id_seq;
DROP TABLE public.search_query_delen;
DROP TABLE public.search_query;
DROP SEQUENCE public.sbus_traffic_id_seq;
DROP TABLE public.sbus_traffic;
DROP SEQUENCE public.sbus_logging_id_seq;
DROP TABLE public.sbus_logging;
DROP SEQUENCE public.logging_id_seq;
DROP TABLE public.logging;
DROP SEQUENCE public.gm_natuurlijk_persoon_id_seq;
DROP TABLE public.gm_natuurlijk_persoon;
DROP SEQUENCE public.gm_bedrijf_id_seq;
DROP TABLE public.gm_bedrijf;
DROP SEQUENCE public.gm_adres_id_seq;
DROP TABLE public.gm_adres;
DROP SEQUENCE public.filestore_id_seq;
DROP TABLE public.filestore;
DROP SEQUENCE public.dropped_documents_id_seq;
DROP TABLE public.dropped_documents;
DROP SEQUENCE public.documents_mail_id_seq;
DROP TABLE public.documents_mail;
DROP SEQUENCE public.documents_id_seq;
DROP TABLE public.documents;
DROP SEQUENCE public.contact_data_id_seq;
DROP TABLE public.contact_data;
DROP SEQUENCE public.checklist_vraag_id_seq;
DROP TABLE public.checklist_vraag;
DROP TABLE public.checklist_antwoord;
DROP SEQUENCE public.checklist_antwoord_id_seq;
DROP SEQUENCE public.bibliotheek_sjablonen_magic_string_id_seq;
DROP TABLE public.bibliotheek_sjablonen_magic_string;
DROP SEQUENCE public.bibliotheek_sjablonen_id_seq;
DROP TABLE public.bibliotheek_sjablonen;
DROP SEQUENCE public.bibliotheek_kenmerken_values_id_seq;
DROP TABLE public.bibliotheek_kenmerken_values;
DROP SEQUENCE public.bibliotheek_kenmerken_id_seq;
DROP TABLE public.bibliotheek_kenmerken;
DROP SEQUENCE public.bibliotheek_categorie_id_seq;
DROP TABLE public.bibliotheek_categorie;
DROP SEQUENCE public.betrokkenen_id_seq;
DROP TABLE public.betrokkenen;
DROP SEQUENCE public.betrokkene_notes_id_seq;
DROP TABLE public.betrokkene_notes;
DROP SEQUENCE public.beheer_plugins_id_seq;
DROP TABLE public.beheer_plugins;
DROP SEQUENCE public.beheer_import_log_id_seq;
DROP TABLE public.beheer_import_log;
DROP SEQUENCE public.beheer_import_id_seq;
DROP TABLE public.beheer_import;
DROP SEQUENCE public.bedrijf_authenticatie_id_seq;
DROP TABLE public.bedrijf_authenticatie;
DROP TYPE public.zaaksysteem_trigger;
DROP TYPE public.zaaksysteem_status;
DROP TYPE public.zaaksysteem_bag_types;
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

--
-- Name: zaaksysteem_bag_types; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE zaaksysteem_bag_types AS ENUM (
    'nummeraanduiding',
    'verblijfsobject',
    'pand',
    'openbareruimte'
);


--
-- Name: zaaksysteem_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE zaaksysteem_status AS ENUM (
    'new',
    'open',
    'resolved',
    'stalled',
    'deleted'
);


--
-- Name: zaaksysteem_trigger; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE zaaksysteem_trigger AS ENUM (
    'extern',
    'intern'
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: bedrijf_authenticatie; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bedrijf_authenticatie (
    id integer NOT NULL,
    gegevens_magazijn_id integer,
    login integer,
    password character varying(255),
    created timestamp without time zone,
    last_modified timestamp without time zone
);


--
-- Name: bedrijf_authenticatie_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bedrijf_authenticatie_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bedrijf_authenticatie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bedrijf_authenticatie_id_seq OWNED BY bedrijf_authenticatie.id;


--
-- Name: beheer_import; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE beheer_import (
    id integer NOT NULL,
    importtype character varying(256),
    succesvol integer,
    finished timestamp without time zone,
    import_create integer,
    import_update integer,
    error integer,
    error_message text,
    entries integer,
    created timestamp without time zone,
    last_modified timestamp without time zone
);


--
-- Name: beheer_import_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE beheer_import_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: beheer_import_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE beheer_import_id_seq OWNED BY beheer_import.id;


--
-- Name: beheer_import_log; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE beheer_import_log (
    id integer NOT NULL,
    import_id integer,
    old_data text,
    new_data text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    kolom text,
    identifier text,
    action character varying(255)
);


--
-- Name: beheer_import_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE beheer_import_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: beheer_import_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE beheer_import_log_id_seq OWNED BY beheer_import_log.id;


--
-- Name: beheer_plugins; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE beheer_plugins (
    id integer NOT NULL,
    label text,
    naam text,
    help text,
    versie text,
    actief integer,
    last_modified timestamp without time zone
);


--
-- Name: beheer_plugins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE beheer_plugins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: beheer_plugins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE beheer_plugins_id_seq OWNED BY beheer_plugins.id;


--
-- Name: betrokkene_notes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE betrokkene_notes (
    id integer NOT NULL,
    betrokkene_exid integer,
    betrokkene_type text,
    betrokkene_from text,
    ntype text,
    subject text,
    message text,
    created timestamp without time zone,
    last_modified timestamp without time zone
);


--
-- Name: betrokkene_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE betrokkene_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: betrokkene_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE betrokkene_notes_id_seq OWNED BY betrokkene_notes.id;


--
-- Name: betrokkenen; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE betrokkenen (
    id integer NOT NULL,
    btype integer,
    gm_natuurlijk_persoon_id integer,
    naam text
);


--
-- Name: betrokkenen_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE betrokkenen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: betrokkenen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE betrokkenen_id_seq OWNED BY betrokkenen.id;


--
-- Name: bibliotheek_categorie; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bibliotheek_categorie (
    id integer NOT NULL,
    naam character varying(256),
    label text,
    description text,
    help text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    system integer,
    pid integer
);


--
-- Name: bibliotheek_categorie_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bibliotheek_categorie_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bibliotheek_categorie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bibliotheek_categorie_id_seq OWNED BY bibliotheek_categorie.id;


--
-- Name: bibliotheek_kenmerken; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bibliotheek_kenmerken (
    id integer NOT NULL,
    naam character varying(256),
    value_type text,
    value_default text,
    label text,
    description text,
    help text,
    magic_string text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    bibliotheek_categorie_id integer,
    document_categorie text,
    system integer,
    type_multiple integer,
    deleted timestamp without time zone
);


--
-- Name: bibliotheek_kenmerken_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bibliotheek_kenmerken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bibliotheek_kenmerken_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bibliotheek_kenmerken_id_seq OWNED BY bibliotheek_kenmerken.id;


--
-- Name: bibliotheek_kenmerken_values; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bibliotheek_kenmerken_values (
    id integer NOT NULL,
    bibliotheek_kenmerken_id integer,
    value text
);


--
-- Name: bibliotheek_kenmerken_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bibliotheek_kenmerken_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bibliotheek_kenmerken_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bibliotheek_kenmerken_values_id_seq OWNED BY bibliotheek_kenmerken_values.id;


--
-- Name: bibliotheek_sjablonen; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bibliotheek_sjablonen (
    id integer NOT NULL,
    bibliotheek_categorie_id integer,
    naam character varying(256),
    label text,
    description text,
    help text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    filestore_id integer,
    deleted timestamp without time zone
);


--
-- Name: bibliotheek_sjablonen_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bibliotheek_sjablonen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bibliotheek_sjablonen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bibliotheek_sjablonen_id_seq OWNED BY bibliotheek_sjablonen.id;


--
-- Name: bibliotheek_sjablonen_magic_string; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE bibliotheek_sjablonen_magic_string (
    id integer NOT NULL,
    bibliotheek_sjablonen_id integer,
    value text
);


--
-- Name: bibliotheek_sjablonen_magic_string_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE bibliotheek_sjablonen_magic_string_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: bibliotheek_sjablonen_magic_string_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE bibliotheek_sjablonen_magic_string_id_seq OWNED BY bibliotheek_sjablonen_magic_string.id;


--
-- Name: checklist_antwoord_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE checklist_antwoord_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: checklist_antwoord; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE checklist_antwoord (
    zaak_id integer NOT NULL,
    mogelijkheid_id integer,
    antwoord text,
    vraag_id integer,
    id integer DEFAULT nextval('checklist_antwoord_id_seq'::regclass) NOT NULL
);


--
-- Name: checklist_vraag; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE checklist_vraag (
    id integer NOT NULL,
    nr integer,
    vraag text,
    vraagtype text,
    zaaktype_node_id integer,
    zaaktype_status_id integer
);


--
-- Name: checklist_vraag_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE checklist_vraag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: checklist_vraag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE checklist_vraag_id_seq OWNED BY checklist_vraag.id;


--
-- Name: contact_data; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contact_data (
    id integer NOT NULL,
    gegevens_magazijn_id integer,
    betrokkene_type integer,
    mobiel character varying(255),
    telefoonnummer character varying(255),
    email character varying(255),
    created timestamp without time zone,
    last_modified timestamp without time zone
);


--
-- Name: contact_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contact_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: contact_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contact_data_id_seq OWNED BY contact_data.id;


--
-- Name: documents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE documents (
    id integer NOT NULL,
    pid integer,
    zaak_id integer,
    betrokkene text,
    description text,
    filename text,
    filesize integer,
    mimetype text,
    documenttype text,
    category text,
    status integer,
    post_registratie character varying(255),
    verplicht integer,
    catalogus integer,
    zaakstatus integer,
    betrokkene_id text,
    ontvangstdatum timestamp without time zone,
    dagtekeningdatum timestamp without time zone,
    versie integer,
    help text,
    pip boolean,
    private boolean,
    md5 text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    deleted_on timestamp without time zone,
    option_order integer,
    zaaktype_kenmerken_id integer,
    queue integer
);


--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE documents_id_seq OWNED BY documents.id;


--
-- Name: documents_mail; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE documents_mail (
    id integer NOT NULL,
    document_id integer,
    rcpt text,
    message text,
    subject text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    option_order integer
);


--
-- Name: documents_mail_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE documents_mail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: documents_mail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE documents_mail_id_seq OWNED BY documents_mail.id;


--
-- Name: dropped_documents; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE dropped_documents (
    id integer NOT NULL,
    description text,
    filename text,
    filesize integer,
    mimetype text,
    betrokkene_id text,
    load_time timestamp without time zone,
    created timestamp without time zone,
    last_modified timestamp without time zone
);


--
-- Name: dropped_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE dropped_documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: dropped_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE dropped_documents_id_seq OWNED BY dropped_documents.id;


--
-- Name: filestore; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE filestore (
    id integer NOT NULL,
    filename character varying(256),
    mimetype character varying(256),
    label text,
    description text,
    help text,
    md5sum text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    filesize integer
);


--
-- Name: filestore_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE filestore_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: filestore_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE filestore_id_seq OWNED BY filestore.id;


--
-- Name: gm_adres; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gm_adres (
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
    import_datum timestamp(6) without time zone
);


--
-- Name: gm_adres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gm_adres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: gm_adres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gm_adres_id_seq OWNED BY gm_adres.id;


--
-- Name: gm_bedrijf; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gm_bedrijf (
    id integer NOT NULL,
    gegevens_magazijn_id integer,
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
    telefoonnummer character varying(15),
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
    import_datum timestamp(6) without time zone,
    verblijfsobject_id character varying(16)
);


--
-- Name: gm_bedrijf_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gm_bedrijf_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: gm_bedrijf_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gm_bedrijf_id_seq OWNED BY gm_bedrijf.id;


--
-- Name: gm_natuurlijk_persoon; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE gm_natuurlijk_persoon (
    id integer NOT NULL,
    gegevens_magazijn_id integer,
    betrokkene_type integer,
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
    authenticatedby text,
    authenticated smallint,
    datum_overlijden timestamp(6) without time zone,
    verblijfsobject_id character varying(16),
    aanduiding_naamgebruik character varying(1),
    onderzoek_persoon boolean,
    onderzoek_persoon_ingang timestamp without time zone,
    onderzoek_persoon_einde timestamp without time zone,
    onderzoek_persoon_onjuist character varying(1),
    onderzoek_huwelijk boolean,
    onderzoek_huwelijk_ingang timestamp without time zone,
    onderzoek_huwelijk_einde timestamp without time zone,
    onderzoek_huwelijk_onjuist character varying(1),
    onderzoek_overlijden boolean,
    onderzoek_overlijden_ingang timestamp without time zone,
    onderzoek_overlijden_einde timestamp without time zone,
    onderzoek_overlijden_onjuist character varying(1),
    onderzoek_verblijfplaats boolean,
    onderzoek_verblijfplaats_ingang timestamp without time zone,
    onderzoek_verblijfplaats_einde timestamp without time zone,
    onderzoek_verblijfplaats_onjuist character varying(1),
    partner_a_nummer character varying(50),
    partner_burgerservicenummer character varying(50),
    partner_voorvoegsel character varying(50),
    partner_geslachtsnaam character varying(50),
    datum_huwelijk timestamp without time zone,
    datum_huwelijk_ontbinding timestamp without time zone
);


--
-- Name: gm_natuurlijk_persoon_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gm_natuurlijk_persoon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: gm_natuurlijk_persoon_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gm_natuurlijk_persoon_id_seq OWNED BY gm_natuurlijk_persoon.id;


--
-- Name: logging; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE logging (
    id integer NOT NULL,
    loglevel character varying(32),
    zaak_id integer,
    betrokkene_id character varying(128),
    aanvrager_id character varying(128),
    is_bericht integer,
    component character varying(64),
    component_id integer,
    seen integer,
    onderwerp character varying(255),
    bericht text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    deleted_on timestamp without time zone
);


--
-- Name: logging_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE logging_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: logging_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE logging_id_seq OWNED BY logging.id;


--
-- Name: sbus_logging; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sbus_logging (
    id integer NOT NULL,
    sbus_traffic_id integer,
    pid integer,
    mutatie_type text,
    object text,
    params text,
    kerngegeven text,
    label text,
    changes text,
    error boolean,
    error_message text,
    created timestamp without time zone,
    modified timestamp without time zone
);


--
-- Name: sbus_logging_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sbus_logging_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sbus_logging_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sbus_logging_id_seq OWNED BY sbus_logging.id;


--
-- Name: sbus_traffic; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sbus_traffic (
    id integer NOT NULL,
    sbus_type text,
    object text,
    operation text,
    input text,
    input_raw text,
    output text,
    output_raw text,
    error boolean,
    error_message text,
    created timestamp without time zone,
    modified timestamp without time zone
);


--
-- Name: sbus_traffic_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sbus_traffic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: sbus_traffic_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sbus_traffic_id_seq OWNED BY sbus_traffic.id;


--
-- Name: search_query; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE search_query (
    id integer NOT NULL,
    settings text,
    ldap_id integer,
    name character varying(256),
    sort_index integer
);


--
-- Name: search_query_delen; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE search_query_delen (
    id integer NOT NULL,
    search_query_id integer,
    ou_id integer,
    role_id integer
);


--
-- Name: search_query_delen_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE search_query_delen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: search_query_delen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE search_query_delen_id_seq OWNED BY search_query_delen.id;


--
-- Name: search_query_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE search_query_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: search_query_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE search_query_id_seq OWNED BY search_query.id;


--
-- Name: user_app_lock; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_app_lock (
    type character(40) NOT NULL,
    type_id character(20) NOT NULL,
    create_unixtime integer NOT NULL,
    session_id character(40) NOT NULL,
    uidnumber integer NOT NULL
);


--
-- Name: zaak; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaak (
    id integer NOT NULL,
    pid integer,
    relates_to integer,
    zaaktype_id integer NOT NULL,
    zaaktype_node_id integer NOT NULL,
    status zaaksysteem_status NOT NULL,
    milestone integer NOT NULL,
    contactkanaal character varying(128) NOT NULL,
    aanvraag_trigger zaaksysteem_trigger NOT NULL,
    onderwerp character varying(256),
    resultaat text,
    besluit text,
    coordinator integer,
    behandelaar integer,
    aanvrager integer NOT NULL,
    route_ou integer,
    route_role integer,
    locatie_zaak integer,
    locatie_correspondentie integer,
    streefafhandeldatum timestamp(6) without time zone,
    registratiedatum timestamp(6) without time zone NOT NULL,
    afhandeldatum timestamp(6) without time zone,
    vernietigingsdatum timestamp(6) without time zone,
    created timestamp(6) without time zone NOT NULL,
    last_modified timestamp(6) without time zone NOT NULL,
    deleted timestamp(6) without time zone,
    vervolg_van integer,
    aanvrager_gm_id integer,
    behandelaar_gm_id integer,
    coordinator_gm_id integer
);


--
-- Name: zaak_bag; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaak_bag (
    id integer NOT NULL,
    pid integer,
    zaak_id integer,
    bag_type zaaksysteem_bag_types,
    bag_id character varying(255),
    bag_verblijfsobject_id character varying(255),
    bag_openbareruimte_id character varying(255),
    bag_nummeraanduiding_id character varying(255),
    bag_pand_id character varying(255),
    bag_standplaats_id character varying(255),
    bag_ligplaats_id character varying(255)
);


--
-- Name: zaak_bag_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaak_bag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaak_bag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaak_bag_id_seq OWNED BY zaak_bag.id;


--
-- Name: zaak_betrokkenen; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaak_betrokkenen (
    id integer NOT NULL,
    zaak_id integer,
    betrokkene_type character varying(128),
    betrokkene_id integer,
    gegevens_magazijn_id integer,
    verificatie character varying(128),
    naam character varying(255),
    rol text,
    magic_string_prefix text,
    deleted timestamp without time zone
);


--
-- Name: zaak_betrokkenen_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaak_betrokkenen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaak_betrokkenen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaak_betrokkenen_id_seq OWNED BY zaak_betrokkenen.id;


--
-- Name: zaak_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaak_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaak_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaak_id_seq OWNED BY zaak.id;


--
-- Name: zaak_kenmerken; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaak_kenmerken (
    id integer NOT NULL,
    zaak_id integer NOT NULL,
    bibliotheek_kenmerken_id integer NOT NULL,
    value_type character varying(128),
    naam character varying(128),
    multiple boolean
);


--
-- Name: zaak_kenmerken_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaak_kenmerken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaak_kenmerken_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaak_kenmerken_id_seq OWNED BY zaak_kenmerken.id;


--
-- Name: zaak_kenmerken_values; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaak_kenmerken_values (
    id integer NOT NULL,
    zaak_kenmerken_id integer NOT NULL,
    bibliotheek_kenmerken_id integer NOT NULL,
    value text,
    zaak_bag_id integer
);


--
-- Name: zaak_kenmerken_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaak_kenmerken_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaak_kenmerken_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaak_kenmerken_values_id_seq OWNED BY zaak_kenmerken_values.id;


--
-- Name: zaak_meta; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaak_meta (
    id integer NOT NULL,
    zaak_id integer,
    verlenging character varying(255),
    opschorten character varying(255),
    deel character varying(255),
    gerelateerd character varying(255),
    vervolg character varying(255),
    afhandeling character varying(255)
);


--
-- Name: zaak_meta_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaak_meta_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaak_meta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaak_meta_id_seq OWNED BY zaak_meta.id;


--
-- Name: zaak_onafgerond; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaak_onafgerond (
    zaaktype_id integer NOT NULL,
    betrokkene character(50) NOT NULL,
    json_string text NOT NULL,
    afronden boolean,
    create_unixtime integer
);


--
-- Name: zaaktype; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype (
    id integer NOT NULL,
    zaaktype_node_id integer,
    version integer,
    active integer,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    deleted timestamp without time zone,
    bibliotheek_categorie_id integer
);


--
-- Name: zaaktype_authorisation; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype_authorisation (
    id integer NOT NULL,
    zaaktype_node_id integer,
    recht text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    deleted timestamp without time zone,
    role_id integer,
    ou_id integer,
    zaaktype_id integer
);


--
-- Name: zaaktype_authorisation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_authorisation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_authorisation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_authorisation_id_seq OWNED BY zaaktype_authorisation.id;


--
-- Name: zaaktype_betrokkenen; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype_betrokkenen (
    id integer NOT NULL,
    zaaktype_node_id integer,
    betrokkene_type text,
    created timestamp without time zone,
    last_modified timestamp without time zone
);


--
-- Name: zaaktype_betrokkenen_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_betrokkenen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_betrokkenen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_betrokkenen_id_seq OWNED BY zaaktype_betrokkenen.id;


--
-- Name: zaaktype_definitie; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype_definitie (
    id integer NOT NULL,
    openbaarheid character varying(255),
    handelingsinitiator character varying(255),
    grondslag character varying(255),
    procesbeschrijving character varying(255),
    afhandeltermijn character varying(255),
    afhandeltermijn_type character varying(255),
    iv3_categorie character varying(255),
    besluittype character varying(255),
    selectielijst character varying(255),
    servicenorm character varying(255),
    servicenorm_type character varying(255),
    pdc_voorwaarden text,
    pdc_description text,
    pdc_meenemen text,
    pdc_tarief text,
    omschrijving_upl character varying(255),
    aard character varying(255),
    extra_informatie character varying(255),
    custom_webform character varying(255)
);


--
-- Name: zaaktype_definitie_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_definitie_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_definitie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_definitie_id_seq OWNED BY zaaktype_definitie.id;


--
-- Name: zaaktype_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_id_seq OWNED BY zaaktype.id;


--
-- Name: zaaktype_kenmerken; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype_kenmerken (
    id integer NOT NULL,
    bibliotheek_kenmerken_id integer,
    value_mandatory integer,
    label text,
    help text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    zaaktype_node_id integer,
    zaak_status_id integer,
    pip integer,
    zaakinformatie_view integer DEFAULT 1,
    bag_zaakadres integer,
    is_group integer,
    besluit integer,
    date_fromcurrentdate integer DEFAULT 0,
    value_default text
);


--
-- Name: zaaktype_kenmerken_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_kenmerken_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_kenmerken_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_kenmerken_id_seq OWNED BY zaaktype_kenmerken.id;


--
-- Name: zaaktype_node; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype_node (
    id integer NOT NULL,
    zaaktype_id integer,
    zaaktype_rt_queue text,
    code text,
    trigger text,
    titel character varying(128),
    version integer,
    active integer,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    deleted timestamp without time zone,
    webform_toegang integer,
    webform_authenticatie text,
    adres_relatie text,
    aanvrager_hergebruik integer,
    automatisch_aanvragen integer,
    automatisch_behandelen integer,
    toewijzing_zaakintake integer,
    toelichting character varying(128),
    online_betaling integer,
    zaaktype_definitie_id integer,
    adres_andere_locatie integer,
    adres_aanvrager integer,
    bedrijfid_wijzigen integer,
    zaaktype_vertrouwelijk integer,
    zaaktype_trefwoorden text,
    zaaktype_omschrijving text,
    extra_relaties_in_aanvraag boolean
);


--
-- Name: zaaktype_node_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_node_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_node_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_node_id_seq OWNED BY zaaktype_node.id;


--
-- Name: zaaktype_notificatie; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype_notificatie (
    id integer NOT NULL,
    zaaktype_node_id integer,
    zaak_status_id integer,
    label text,
    rcpt text,
    onderwerp text,
    bericht text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    intern_block integer,
    email character varying(128)
);


--
-- Name: zaaktype_notificatie_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_notificatie_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_notificatie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_notificatie_id_seq OWNED BY zaaktype_notificatie.id;


--
-- Name: zaaktype_regel; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype_regel (
    id integer NOT NULL,
    zaaktype_node_id integer,
    zaak_status_id integer,
    naam text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    settings text
);


--
-- Name: zaaktype_regel_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_regel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_regel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_regel_id_seq OWNED BY zaaktype_regel.id;


--
-- Name: zaaktype_relatie; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype_relatie (
    id integer NOT NULL,
    zaaktype_node_id integer,
    relatie_zaaktype_id integer,
    zaaktype_status_id integer,
    relatie_type text,
    eigenaar_type text,
    start_delay character varying(255),
    created timestamp without time zone,
    last_modified timestamp without time zone,
    status integer,
    kopieren_kenmerken integer,
    delay_type character varying(255),
    ou_id integer,
    role_id integer,
    automatisch_behandelen boolean
);


--
-- Name: zaaktype_relatie_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_relatie_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_relatie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_relatie_id_seq OWNED BY zaaktype_relatie.id;


--
-- Name: zaaktype_resultaten; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype_resultaten (
    id integer NOT NULL,
    zaaktype_node_id integer,
    zaaktype_status_id integer,
    resultaat text,
    ingang text,
    bewaartermijn integer,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    dossiertype character varying(50)
);


--
-- Name: zaaktype_resultaten_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_resultaten_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_resultaten_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_resultaten_id_seq OWNED BY zaaktype_resultaten.id;


--
-- Name: zaaktype_sjablonen; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype_sjablonen (
    id integer NOT NULL,
    zaaktype_node_id integer,
    bibliotheek_sjablonen_id integer,
    help text,
    zaak_status_id integer,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    automatisch_genereren integer
);


--
-- Name: zaaktype_sjablonen_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_sjablonen_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_sjablonen_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_sjablonen_id_seq OWNED BY zaaktype_sjablonen.id;


--
-- Name: zaaktype_status; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE zaaktype_status (
    id integer NOT NULL,
    zaaktype_node_id integer,
    status integer,
    status_type text,
    naam text,
    created timestamp without time zone,
    last_modified timestamp without time zone,
    ou_id integer,
    role_id integer,
    checklist integer,
    fase character varying(255),
    role_set integer
);


--
-- Name: zaaktype_status_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE zaaktype_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: zaaktype_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE zaaktype_status_id_seq OWNED BY zaaktype_status.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bedrijf_authenticatie ALTER COLUMN id SET DEFAULT nextval('bedrijf_authenticatie_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE beheer_import ALTER COLUMN id SET DEFAULT nextval('beheer_import_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE beheer_import_log ALTER COLUMN id SET DEFAULT nextval('beheer_import_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE beheer_plugins ALTER COLUMN id SET DEFAULT nextval('beheer_plugins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE betrokkene_notes ALTER COLUMN id SET DEFAULT nextval('betrokkene_notes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE betrokkenen ALTER COLUMN id SET DEFAULT nextval('betrokkenen_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bibliotheek_categorie ALTER COLUMN id SET DEFAULT nextval('bibliotheek_categorie_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bibliotheek_kenmerken ALTER COLUMN id SET DEFAULT nextval('bibliotheek_kenmerken_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bibliotheek_kenmerken_values ALTER COLUMN id SET DEFAULT nextval('bibliotheek_kenmerken_values_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bibliotheek_sjablonen ALTER COLUMN id SET DEFAULT nextval('bibliotheek_sjablonen_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE bibliotheek_sjablonen_magic_string ALTER COLUMN id SET DEFAULT nextval('bibliotheek_sjablonen_magic_string_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE checklist_vraag ALTER COLUMN id SET DEFAULT nextval('checklist_vraag_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE contact_data ALTER COLUMN id SET DEFAULT nextval('contact_data_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE documents ALTER COLUMN id SET DEFAULT nextval('documents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE documents_mail ALTER COLUMN id SET DEFAULT nextval('documents_mail_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE dropped_documents ALTER COLUMN id SET DEFAULT nextval('dropped_documents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE filestore ALTER COLUMN id SET DEFAULT nextval('filestore_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE gm_adres ALTER COLUMN id SET DEFAULT nextval('gm_adres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE gm_bedrijf ALTER COLUMN id SET DEFAULT nextval('gm_bedrijf_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE gm_natuurlijk_persoon ALTER COLUMN id SET DEFAULT nextval('gm_natuurlijk_persoon_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE logging ALTER COLUMN id SET DEFAULT nextval('logging_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sbus_logging ALTER COLUMN id SET DEFAULT nextval('sbus_logging_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE sbus_traffic ALTER COLUMN id SET DEFAULT nextval('sbus_traffic_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE search_query ALTER COLUMN id SET DEFAULT nextval('search_query_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE search_query_delen ALTER COLUMN id SET DEFAULT nextval('search_query_delen_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaak ALTER COLUMN id SET DEFAULT nextval('zaak_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaak_bag ALTER COLUMN id SET DEFAULT nextval('zaak_bag_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaak_betrokkenen ALTER COLUMN id SET DEFAULT nextval('zaak_betrokkenen_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaak_kenmerken ALTER COLUMN id SET DEFAULT nextval('zaak_kenmerken_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaak_kenmerken_values ALTER COLUMN id SET DEFAULT nextval('zaak_kenmerken_values_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaak_meta ALTER COLUMN id SET DEFAULT nextval('zaak_meta_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype ALTER COLUMN id SET DEFAULT nextval('zaaktype_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype_authorisation ALTER COLUMN id SET DEFAULT nextval('zaaktype_authorisation_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype_betrokkenen ALTER COLUMN id SET DEFAULT nextval('zaaktype_betrokkenen_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype_definitie ALTER COLUMN id SET DEFAULT nextval('zaaktype_definitie_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype_kenmerken ALTER COLUMN id SET DEFAULT nextval('zaaktype_kenmerken_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype_node ALTER COLUMN id SET DEFAULT nextval('zaaktype_node_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype_notificatie ALTER COLUMN id SET DEFAULT nextval('zaaktype_notificatie_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype_regel ALTER COLUMN id SET DEFAULT nextval('zaaktype_regel_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype_relatie ALTER COLUMN id SET DEFAULT nextval('zaaktype_relatie_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype_resultaten ALTER COLUMN id SET DEFAULT nextval('zaaktype_resultaten_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype_sjablonen ALTER COLUMN id SET DEFAULT nextval('zaaktype_sjablonen_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE zaaktype_status ALTER COLUMN id SET DEFAULT nextval('zaaktype_status_id_seq'::regclass);


--
-- Name: bedrijf_authenticatie_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bedrijf_authenticatie
    ADD CONSTRAINT bedrijf_authenticatie_pkey PRIMARY KEY (id);


--
-- Name: beheer_import_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY beheer_import_log
    ADD CONSTRAINT beheer_import_log_pkey PRIMARY KEY (id);


--
-- Name: beheer_import_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY beheer_import
    ADD CONSTRAINT beheer_import_pkey PRIMARY KEY (id);


--
-- Name: beheer_plugins_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY beheer_plugins
    ADD CONSTRAINT beheer_plugins_pkey PRIMARY KEY (id);


--
-- Name: betrokkene_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY betrokkene_notes
    ADD CONSTRAINT betrokkene_notes_pkey PRIMARY KEY (id);


--
-- Name: betrokkenen_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY betrokkenen
    ADD CONSTRAINT betrokkenen_pkey PRIMARY KEY (id);


--
-- Name: bibliotheek_categorie_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bibliotheek_categorie
    ADD CONSTRAINT bibliotheek_categorie_pkey PRIMARY KEY (id);


--
-- Name: bibliotheek_kenmerken_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bibliotheek_kenmerken
    ADD CONSTRAINT bibliotheek_kenmerken_pkey PRIMARY KEY (id);


--
-- Name: bibliotheek_kenmerken_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bibliotheek_kenmerken_values
    ADD CONSTRAINT bibliotheek_kenmerken_values_pkey PRIMARY KEY (id);


--
-- Name: bibliotheek_sjablonen_magic_string_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bibliotheek_sjablonen_magic_string
    ADD CONSTRAINT bibliotheek_sjablonen_magic_string_pkey PRIMARY KEY (id);


--
-- Name: bibliotheek_sjablonen_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bibliotheek_sjablonen
    ADD CONSTRAINT bibliotheek_sjablonen_pkey PRIMARY KEY (id);


--
-- Name: checklist_antwoord_id_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY checklist_antwoord
    ADD CONSTRAINT checklist_antwoord_id_key UNIQUE (id);


--
-- Name: checklist_antwoord_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY checklist_antwoord
    ADD CONSTRAINT checklist_antwoord_pkey PRIMARY KEY (id);


--
-- Name: checklist_vraag_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY checklist_vraag
    ADD CONSTRAINT checklist_vraag_pkey PRIMARY KEY (id);


--
-- Name: contact_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contact_data
    ADD CONSTRAINT contact_data_pkey PRIMARY KEY (id);


--
-- Name: documents_mail_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY documents_mail
    ADD CONSTRAINT documents_mail_pkey PRIMARY KEY (id);


--
-- Name: documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: dropped_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dropped_documents
    ADD CONSTRAINT dropped_documents_pkey PRIMARY KEY (id);


--
-- Name: filestore_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY filestore
    ADD CONSTRAINT filestore_pkey PRIMARY KEY (id);


--
-- Name: gm_adres_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gm_adres
    ADD CONSTRAINT gm_adres_pkey PRIMARY KEY (id);


--
-- Name: gm_bedrijf_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gm_bedrijf
    ADD CONSTRAINT gm_bedrijf_pkey PRIMARY KEY (id);


--
-- Name: gm_natuurlijk_persoon_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY gm_natuurlijk_persoon
    ADD CONSTRAINT gm_natuurlijk_persoon_pkey PRIMARY KEY (id);


--
-- Name: logging_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY logging
    ADD CONSTRAINT logging_pkey PRIMARY KEY (id);


--
-- Name: sbus_logging_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sbus_logging
    ADD CONSTRAINT sbus_logging_pkey PRIMARY KEY (id);


--
-- Name: sbus_traffic_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sbus_traffic
    ADD CONSTRAINT sbus_traffic_pkey PRIMARY KEY (id);


--
-- Name: search_query_delen_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY search_query_delen
    ADD CONSTRAINT search_query_delen_pkey PRIMARY KEY (id);


--
-- Name: search_query_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY search_query
    ADD CONSTRAINT search_query_pkey PRIMARY KEY (id);


--
-- Name: user_app_lock_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_app_lock
    ADD CONSTRAINT user_app_lock_pkey PRIMARY KEY (uidnumber, type, type_id);


--
-- Name: zaak_bag_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaak_bag
    ADD CONSTRAINT zaak_bag_pkey PRIMARY KEY (id);


--
-- Name: zaak_betrokkenen_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaak_betrokkenen
    ADD CONSTRAINT zaak_betrokkenen_pkey PRIMARY KEY (id);


--
-- Name: zaak_kenmerken_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaak_kenmerken
    ADD CONSTRAINT zaak_kenmerken_pkey PRIMARY KEY (id);


--
-- Name: zaak_kenmerken_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaak_kenmerken_values
    ADD CONSTRAINT zaak_kenmerken_values_pkey PRIMARY KEY (id);


--
-- Name: zaak_meta_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaak_meta
    ADD CONSTRAINT zaak_meta_pkey PRIMARY KEY (id);


--
-- Name: zaak_onafgerond_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaak_onafgerond
    ADD CONSTRAINT zaak_onafgerond_pkey PRIMARY KEY (zaaktype_id, betrokkene);


--
-- Name: zaak_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaak
    ADD CONSTRAINT zaak_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_authorisation_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype_authorisation
    ADD CONSTRAINT zaaktype_authorisation_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_betrokkenen_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype_betrokkenen
    ADD CONSTRAINT zaaktype_betrokkenen_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_definitie_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype_definitie
    ADD CONSTRAINT zaaktype_definitie_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_kenmerken_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype_kenmerken
    ADD CONSTRAINT zaaktype_kenmerken_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_node_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype_node
    ADD CONSTRAINT zaaktype_node_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_notificatie_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype_notificatie
    ADD CONSTRAINT zaaktype_notificatie_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype
    ADD CONSTRAINT zaaktype_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_regel_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype_regel
    ADD CONSTRAINT zaaktype_regel_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_relatie_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype_relatie
    ADD CONSTRAINT zaaktype_relatie_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_resultaten_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype_resultaten
    ADD CONSTRAINT zaaktype_resultaten_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_sjablonen_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype_sjablonen
    ADD CONSTRAINT zaaktype_sjablonen_pkey PRIMARY KEY (id);


--
-- Name: zaaktype_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY zaaktype_status
    ADD CONSTRAINT zaaktype_status_pkey PRIMARY KEY (id);


--
-- Name: beheer_import_log_idx_import_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX beheer_import_log_idx_import_id ON beheer_import_log USING btree (import_id);


--
-- Name: bibliotheek_kenmerken_values_idx_bibliotheek_kenmerken_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX bibliotheek_kenmerken_values_idx_bibliotheek_kenmerken_id ON bibliotheek_kenmerken_values USING btree (bibliotheek_kenmerken_id);


--
-- Name: documents_idx_pid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX documents_idx_pid ON documents USING btree (pid);


--
-- Name: documents_mail_idx_document_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX documents_mail_idx_document_id ON documents_mail USING btree (document_id);


--
-- Name: gm_natuurlijk_persoon_idx_adres_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX gm_natuurlijk_persoon_idx_adres_id ON gm_natuurlijk_persoon USING btree (adres_id);


--
-- Name: zaak_betrokkenen_gegevens_magazijn_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX zaak_betrokkenen_gegevens_magazijn_index ON zaak_betrokkenen USING btree (gegevens_magazijn_id);


--
-- Name: zaaktype_authorisation_idx_zaaktype_node_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX zaaktype_authorisation_idx_zaaktype_node_id ON zaaktype_authorisation USING btree (zaaktype_node_id);


--
-- Name: zaaktype_betrokkenen_idx_zaaktype_node_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX zaaktype_betrokkenen_idx_zaaktype_node_id ON zaaktype_betrokkenen USING btree (zaaktype_node_id);


--
-- Name: zaaktype_idx_zaaktype_node_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX zaaktype_idx_zaaktype_node_id ON zaaktype USING btree (zaaktype_node_id);


--
-- Name: zaaktype_node_idx_zaaktype_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX zaaktype_node_idx_zaaktype_id ON zaaktype_node USING btree (zaaktype_id);


--
-- Name: zaaktype_relatie_idx_relatie_zaaktype_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX zaaktype_relatie_idx_relatie_zaaktype_id ON zaaktype_relatie USING btree (relatie_zaaktype_id);


--
-- Name: zaaktype_relatie_idx_zaaktype_node_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX zaaktype_relatie_idx_zaaktype_node_id ON zaaktype_relatie USING btree (zaaktype_node_id);


--
-- Name: zaaktype_relatie_idx_zaaktype_status_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX zaaktype_relatie_idx_zaaktype_status_id ON zaaktype_relatie USING btree (zaaktype_status_id);


--
-- Name: zaaktype_resultaten_idx_zaaktype_node_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX zaaktype_resultaten_idx_zaaktype_node_id ON zaaktype_resultaten USING btree (zaaktype_node_id);


--
-- Name: zaaktype_resultaten_idx_zaaktype_status_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX zaaktype_resultaten_idx_zaaktype_status_id ON zaaktype_resultaten USING btree (zaaktype_status_id);


--
-- Name: zaaktype_status_idx_zaaktype_node_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX zaaktype_status_idx_zaaktype_node_id ON zaaktype_status USING btree (zaaktype_node_id);


--
-- Name: beheer_import_log_import_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY beheer_import_log
    ADD CONSTRAINT beheer_import_log_import_id_fkey FOREIGN KEY (import_id) REFERENCES beheer_import(id);


--
-- Name: bibliotheek_categorie_pid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bibliotheek_categorie
    ADD CONSTRAINT bibliotheek_categorie_pid_fkey FOREIGN KEY (pid) REFERENCES bibliotheek_categorie(id);


--
-- Name: bibliotheek_kenmerken_bibliotheek_categorie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bibliotheek_kenmerken
    ADD CONSTRAINT bibliotheek_kenmerken_bibliotheek_categorie_id_fkey FOREIGN KEY (bibliotheek_categorie_id) REFERENCES bibliotheek_categorie(id);


--
-- Name: bibliotheek_kenmerken_values_bibliotheek_kenmerken_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bibliotheek_kenmerken_values
    ADD CONSTRAINT bibliotheek_kenmerken_values_bibliotheek_kenmerken_id_fkey FOREIGN KEY (bibliotheek_kenmerken_id) REFERENCES bibliotheek_kenmerken(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: bibliotheek_sjablonen_bibliotheek_categorie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bibliotheek_sjablonen
    ADD CONSTRAINT bibliotheek_sjablonen_bibliotheek_categorie_id_fkey FOREIGN KEY (bibliotheek_categorie_id) REFERENCES bibliotheek_categorie(id);


--
-- Name: bibliotheek_sjablonen_filestore_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bibliotheek_sjablonen
    ADD CONSTRAINT bibliotheek_sjablonen_filestore_id_fkey FOREIGN KEY (filestore_id) REFERENCES filestore(id);


--
-- Name: bibliotheek_sjablonen_magic_strin_bibliotheek_sjablonen_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY bibliotheek_sjablonen_magic_string
    ADD CONSTRAINT bibliotheek_sjablonen_magic_strin_bibliotheek_sjablonen_id_fkey FOREIGN KEY (bibliotheek_sjablonen_id) REFERENCES bibliotheek_sjablonen(id);


--
-- Name: checklist_vraag_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY checklist_vraag
    ADD CONSTRAINT checklist_vraag_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id) DEFERRABLE;


--
-- Name: checklist_vraag_zaaktype_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY checklist_vraag
    ADD CONSTRAINT checklist_vraag_zaaktype_status_id_fkey FOREIGN KEY (zaaktype_status_id) REFERENCES zaaktype_status(id) DEFERRABLE;


--
-- Name: documents_mail_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY documents_mail
    ADD CONSTRAINT documents_mail_document_id_fkey FOREIGN KEY (document_id) REFERENCES documents(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: documents_pid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY documents
    ADD CONSTRAINT documents_pid_fkey FOREIGN KEY (pid) REFERENCES documents(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: gm_natuurlijk_persoon_adres_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gm_natuurlijk_persoon
    ADD CONSTRAINT gm_natuurlijk_persoon_adres_id_fkey FOREIGN KEY (adres_id) REFERENCES gm_adres(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: sbus_logging_pid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sbus_logging
    ADD CONSTRAINT sbus_logging_pid_fkey FOREIGN KEY (pid) REFERENCES sbus_logging(id);


--
-- Name: sbus_logging_sbus_traffic_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sbus_logging
    ADD CONSTRAINT sbus_logging_sbus_traffic_id_fkey FOREIGN KEY (sbus_traffic_id) REFERENCES sbus_traffic(id);


--
-- Name: search_query_delen_search_query_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY search_query_delen
    ADD CONSTRAINT search_query_delen_search_query_id_fkey FOREIGN KEY (search_query_id) REFERENCES search_query(id);


--
-- Name: zaak_aanvrager_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak
    ADD CONSTRAINT zaak_aanvrager_fkey FOREIGN KEY (aanvrager) REFERENCES zaak_betrokkenen(id);


--
-- Name: zaak_bag_pid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak_bag
    ADD CONSTRAINT zaak_bag_pid_fkey FOREIGN KEY (pid) REFERENCES zaak_bag(id);


--
-- Name: zaak_bag_zaak_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak_bag
    ADD CONSTRAINT zaak_bag_zaak_id_fkey FOREIGN KEY (zaak_id) REFERENCES zaak(id);


--
-- Name: zaak_behandelaar_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak
    ADD CONSTRAINT zaak_behandelaar_fkey FOREIGN KEY (behandelaar) REFERENCES zaak_betrokkenen(id);


--
-- Name: zaak_betrokkenen_zaak_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak_betrokkenen
    ADD CONSTRAINT zaak_betrokkenen_zaak_id_fkey FOREIGN KEY (zaak_id) REFERENCES zaak(id);


--
-- Name: zaak_coordinator_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak
    ADD CONSTRAINT zaak_coordinator_fkey FOREIGN KEY (coordinator) REFERENCES zaak_betrokkenen(id);


--
-- Name: zaak_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY documents
    ADD CONSTRAINT zaak_id_fkey FOREIGN KEY (zaak_id) REFERENCES zaak(id);


--
-- Name: zaak_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY logging
    ADD CONSTRAINT zaak_id_fkey FOREIGN KEY (zaak_id) REFERENCES zaak(id);


--
-- Name: zaak_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY checklist_antwoord
    ADD CONSTRAINT zaak_id_fkey FOREIGN KEY (zaak_id) REFERENCES zaak(id);


--
-- Name: zaak_kenmerken_bibliotheek_kenmerken_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak_kenmerken
    ADD CONSTRAINT zaak_kenmerken_bibliotheek_kenmerken_id_fkey FOREIGN KEY (bibliotheek_kenmerken_id) REFERENCES bibliotheek_kenmerken(id);


--
-- Name: zaak_kenmerken_values_bibliotheek_kenmerken_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak_kenmerken_values
    ADD CONSTRAINT zaak_kenmerken_values_bibliotheek_kenmerken_id_fkey FOREIGN KEY (bibliotheek_kenmerken_id) REFERENCES bibliotheek_kenmerken(id);


--
-- Name: zaak_kenmerken_values_zaak_bag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak_kenmerken_values
    ADD CONSTRAINT zaak_kenmerken_values_zaak_bag_id_fkey FOREIGN KEY (zaak_bag_id) REFERENCES zaak_bag(id);


--
-- Name: zaak_kenmerken_values_zaak_kenmerken_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak_kenmerken_values
    ADD CONSTRAINT zaak_kenmerken_values_zaak_kenmerken_id_fkey FOREIGN KEY (zaak_kenmerken_id) REFERENCES zaak_kenmerken(id);


--
-- Name: zaak_kenmerken_zaak_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak_kenmerken
    ADD CONSTRAINT zaak_kenmerken_zaak_id_fkey FOREIGN KEY (zaak_id) REFERENCES zaak(id);


--
-- Name: zaak_locatie_correspondentie_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak
    ADD CONSTRAINT zaak_locatie_correspondentie_fkey FOREIGN KEY (locatie_correspondentie) REFERENCES zaak_bag(id);


--
-- Name: zaak_locatie_zaak_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak
    ADD CONSTRAINT zaak_locatie_zaak_fkey FOREIGN KEY (locatie_zaak) REFERENCES zaak_bag(id);


--
-- Name: zaak_meta_zaak_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak_meta
    ADD CONSTRAINT zaak_meta_zaak_id_fkey FOREIGN KEY (zaak_id) REFERENCES zaak(id);


--
-- Name: zaak_pid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak
    ADD CONSTRAINT zaak_pid_fkey FOREIGN KEY (pid) REFERENCES zaak(id);


--
-- Name: zaak_relates_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak
    ADD CONSTRAINT zaak_relates_to_fkey FOREIGN KEY (relates_to) REFERENCES zaak(id);


--
-- Name: zaak_vervolg_van_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak
    ADD CONSTRAINT zaak_vervolg_van_fkey FOREIGN KEY (vervolg_van) REFERENCES zaak(id);


--
-- Name: zaak_zaaktype_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak
    ADD CONSTRAINT zaak_zaaktype_id_fkey FOREIGN KEY (zaaktype_id) REFERENCES zaaktype(id);


--
-- Name: zaak_zaaktype_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak_onafgerond
    ADD CONSTRAINT zaak_zaaktype_id_fkey FOREIGN KEY (zaaktype_id) REFERENCES zaaktype(id);


--
-- Name: zaak_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaak
    ADD CONSTRAINT zaak_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id);


--
-- Name: zaaktype_authorisation_zaaktype_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_authorisation
    ADD CONSTRAINT zaaktype_authorisation_zaaktype_id_fkey FOREIGN KEY (zaaktype_id) REFERENCES zaaktype(id);


--
-- Name: zaaktype_authorisation_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_authorisation
    ADD CONSTRAINT zaaktype_authorisation_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: zaaktype_betrokkenen_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_betrokkenen
    ADD CONSTRAINT zaaktype_betrokkenen_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: zaaktype_bibliotheek_categorie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype
    ADD CONSTRAINT zaaktype_bibliotheek_categorie_id_fkey FOREIGN KEY (bibliotheek_categorie_id) REFERENCES bibliotheek_categorie(id) DEFERRABLE;


--
-- Name: zaaktype_kenmerken_bibliotheek_kenmerken_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_kenmerken
    ADD CONSTRAINT zaaktype_kenmerken_bibliotheek_kenmerken_id_fkey FOREIGN KEY (bibliotheek_kenmerken_id) REFERENCES bibliotheek_kenmerken(id);


--
-- Name: zaaktype_kenmerken_zaak_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_kenmerken
    ADD CONSTRAINT zaaktype_kenmerken_zaak_status_id_fkey FOREIGN KEY (zaak_status_id) REFERENCES zaaktype_status(id);


--
-- Name: zaaktype_kenmerken_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_kenmerken
    ADD CONSTRAINT zaaktype_kenmerken_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id);


--
-- Name: zaaktype_node_zaaktype_definitie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_node
    ADD CONSTRAINT zaaktype_node_zaaktype_definitie_id_fkey FOREIGN KEY (zaaktype_definitie_id) REFERENCES zaaktype_definitie(id) DEFERRABLE;


--
-- Name: zaaktype_node_zaaktype_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_node
    ADD CONSTRAINT zaaktype_node_zaaktype_id_fkey FOREIGN KEY (zaaktype_id) REFERENCES zaaktype(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: zaaktype_notificatie_zaak_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_notificatie
    ADD CONSTRAINT zaaktype_notificatie_zaak_status_id_fkey FOREIGN KEY (zaak_status_id) REFERENCES zaaktype_status(id);


--
-- Name: zaaktype_notificatie_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_notificatie
    ADD CONSTRAINT zaaktype_notificatie_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id);


--
-- Name: zaaktype_regel_zaak_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_regel
    ADD CONSTRAINT zaaktype_regel_zaak_status_id_fkey FOREIGN KEY (zaak_status_id) REFERENCES zaaktype_status(id);


--
-- Name: zaaktype_regel_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_regel
    ADD CONSTRAINT zaaktype_regel_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id);


--
-- Name: zaaktype_relatie_relatie_zaaktype_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_relatie
    ADD CONSTRAINT zaaktype_relatie_relatie_zaaktype_id_fkey FOREIGN KEY (relatie_zaaktype_id) REFERENCES zaaktype(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: zaaktype_relatie_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_relatie
    ADD CONSTRAINT zaaktype_relatie_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: zaaktype_relatie_zaaktype_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_relatie
    ADD CONSTRAINT zaaktype_relatie_zaaktype_status_id_fkey FOREIGN KEY (zaaktype_status_id) REFERENCES zaaktype_status(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: zaaktype_resultaten_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_resultaten
    ADD CONSTRAINT zaaktype_resultaten_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: zaaktype_resultaten_zaaktype_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_resultaten
    ADD CONSTRAINT zaaktype_resultaten_zaaktype_status_id_fkey FOREIGN KEY (zaaktype_status_id) REFERENCES zaaktype_status(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: zaaktype_sjablonen_bibliotheek_sjablonen_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_sjablonen
    ADD CONSTRAINT zaaktype_sjablonen_bibliotheek_sjablonen_id_fkey FOREIGN KEY (bibliotheek_sjablonen_id) REFERENCES bibliotheek_sjablonen(id);


--
-- Name: zaaktype_sjablonen_zaak_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_sjablonen
    ADD CONSTRAINT zaaktype_sjablonen_zaak_status_id_fkey FOREIGN KEY (zaak_status_id) REFERENCES zaaktype_status(id);


--
-- Name: zaaktype_sjablonen_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_sjablonen
    ADD CONSTRAINT zaaktype_sjablonen_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id);


--
-- Name: zaaktype_status_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype_status
    ADD CONSTRAINT zaaktype_status_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- Name: zaaktype_zaaktype_node_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY zaaktype
    ADD CONSTRAINT zaaktype_zaaktype_node_id_fkey FOREIGN KEY (zaaktype_node_id) REFERENCES zaaktype_node(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;


--
-- PostgreSQL database dump complete
--

