--
-- PostgreSQL database dump
--

-- Dumped from database version 15.10
-- Dumped by pg_dump version 17.0

SET statement_timeout = '5min';
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: river_topo; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA river_topo;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: edge_data; Type: TABLE; Schema: river_topo; Owner: -
--

CREATE TABLE river_topo.edge_data (
    edge_id integer NOT NULL,
    start_node integer NOT NULL,
    end_node integer NOT NULL,
    next_left_edge integer NOT NULL,
    abs_next_left_edge integer NOT NULL,
    next_right_edge integer NOT NULL,
    abs_next_right_edge integer NOT NULL,
    left_face integer NOT NULL,
    right_face integer NOT NULL,
    geom postgis.geometry(LineString,27700)
);


--
-- Name: edge; Type: VIEW; Schema: river_topo; Owner: -
--

CREATE VIEW river_topo.edge AS
 SELECT edge_data.edge_id,
    edge_data.start_node,
    edge_data.end_node,
    edge_data.next_left_edge,
    edge_data.next_right_edge,
    edge_data.left_face,
    edge_data.right_face,
    edge_data.geom
   FROM river_topo.edge_data;


--
-- Name: VIEW edge; Type: COMMENT; Schema: river_topo; Owner: -
--

COMMENT ON VIEW river_topo.edge IS 'Contains edge topology primitives';


--
-- Name: COLUMN edge.edge_id; Type: COMMENT; Schema: river_topo; Owner: -
--

COMMENT ON COLUMN river_topo.edge.edge_id IS 'Unique identifier of the edge';


--
-- Name: COLUMN edge.start_node; Type: COMMENT; Schema: river_topo; Owner: -
--

COMMENT ON COLUMN river_topo.edge.start_node IS 'Unique identifier of the node at the start of the edge';


--
-- Name: COLUMN edge.end_node; Type: COMMENT; Schema: river_topo; Owner: -
--

COMMENT ON COLUMN river_topo.edge.end_node IS 'Unique identifier of the node at the end of the edge';


--
-- Name: COLUMN edge.next_left_edge; Type: COMMENT; Schema: river_topo; Owner: -
--

COMMENT ON COLUMN river_topo.edge.next_left_edge IS 'Unique identifier of the next edge of the face on the left (when looking in the direction from START_NODE to END_NODE), moving counterclockwise around the face boundary';


--
-- Name: COLUMN edge.next_right_edge; Type: COMMENT; Schema: river_topo; Owner: -
--

COMMENT ON COLUMN river_topo.edge.next_right_edge IS 'Unique identifier of the next edge of the face on the right (when looking in the direction from START_NODE to END_NODE), moving counterclockwise around the face boundary';


--
-- Name: COLUMN edge.left_face; Type: COMMENT; Schema: river_topo; Owner: -
--

COMMENT ON COLUMN river_topo.edge.left_face IS 'Unique identifier of the face on the left side of the edge when looking in the direction from START_NODE to END_NODE';


--
-- Name: COLUMN edge.right_face; Type: COMMENT; Schema: river_topo; Owner: -
--

COMMENT ON COLUMN river_topo.edge.right_face IS 'Unique identifier of the face on the right side of the edge when looking in the direction from START_NODE to END_NODE';


--
-- Name: COLUMN edge.geom; Type: COMMENT; Schema: river_topo; Owner: -
--

COMMENT ON COLUMN river_topo.edge.geom IS 'The geometry of the edge';


--
-- Name: edge_data_edge_id_seq; Type: SEQUENCE; Schema: river_topo; Owner: -
--

CREATE SEQUENCE river_topo.edge_data_edge_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: edge_data_edge_id_seq; Type: SEQUENCE OWNED BY; Schema: river_topo; Owner: -
--

ALTER SEQUENCE river_topo.edge_data_edge_id_seq OWNED BY river_topo.edge_data.edge_id;


--
-- Name: face; Type: TABLE; Schema: river_topo; Owner: -
--

CREATE TABLE river_topo.face (
    face_id integer NOT NULL,
    mbr postgis.geometry(Polygon,27700)
);


--
-- Name: TABLE face; Type: COMMENT; Schema: river_topo; Owner: -
--

COMMENT ON TABLE river_topo.face IS 'Contains face topology primitives';


--
-- Name: face_face_id_seq; Type: SEQUENCE; Schema: river_topo; Owner: -
--

CREATE SEQUENCE river_topo.face_face_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: face_face_id_seq; Type: SEQUENCE OWNED BY; Schema: river_topo; Owner: -
--

ALTER SEQUENCE river_topo.face_face_id_seq OWNED BY river_topo.face.face_id;


--
-- Name: layer_id_seq; Type: SEQUENCE; Schema: river_topo; Owner: -
--

CREATE SEQUENCE river_topo.layer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: node; Type: TABLE; Schema: river_topo; Owner: -
--

CREATE TABLE river_topo.node (
    node_id integer NOT NULL,
    containing_face integer,
    geom postgis.geometry(Point,27700)
);


--
-- Name: TABLE node; Type: COMMENT; Schema: river_topo; Owner: -
--

COMMENT ON TABLE river_topo.node IS 'Contains node topology primitives';


--
-- Name: node_node_id_seq; Type: SEQUENCE; Schema: river_topo; Owner: -
--

CREATE SEQUENCE river_topo.node_node_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: node_node_id_seq; Type: SEQUENCE OWNED BY; Schema: river_topo; Owner: -
--

ALTER SEQUENCE river_topo.node_node_id_seq OWNED BY river_topo.node.node_id;


--
-- Name: relation; Type: TABLE; Schema: river_topo; Owner: -
--

CREATE TABLE river_topo.relation (
    topogeo_id integer NOT NULL,
    layer_id integer NOT NULL,
    element_id integer NOT NULL,
    element_type integer NOT NULL
);


--
-- Name: rivers; Type: TABLE; Schema: river_topo; Owner: -
--

CREATE TABLE river_topo.rivers (
    identifier character varying(38) NOT NULL,
    topo topology.topogeometry,
    CONSTRAINT check_topogeom_topo CHECK ((((topo).topology_id = 9) AND ((topo).layer_id = 1) AND ((topo).type = 2)))
);


--
-- Name: stations; Type: TABLE; Schema: river_topo; Owner: -
--

CREATE TABLE river_topo.stations (
    rloi_id integer,
    qualifier text,
    topo topology.topogeometry,
    CONSTRAINT check_topogeom_topo CHECK ((((topo).topology_id = 9) AND ((topo).layer_id = 2) AND ((topo).type = 1)))
);


--
-- Name: topogeo_s_1; Type: SEQUENCE; Schema: river_topo; Owner: -
--

CREATE SEQUENCE river_topo.topogeo_s_1
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: topogeo_s_2; Type: SEQUENCE; Schema: river_topo; Owner: -
--

CREATE SEQUENCE river_topo.topogeo_s_2
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: edge_data edge_id; Type: DEFAULT; Schema: river_topo; Owner: -
--

ALTER TABLE ONLY river_topo.edge_data ALTER COLUMN edge_id SET DEFAULT nextval('river_topo.edge_data_edge_id_seq'::regclass);


--
-- Name: face face_id; Type: DEFAULT; Schema: river_topo; Owner: -
--

ALTER TABLE ONLY river_topo.face ALTER COLUMN face_id SET DEFAULT nextval('river_topo.face_face_id_seq'::regclass);


--
-- Name: node node_id; Type: DEFAULT; Schema: river_topo; Owner: -
--

ALTER TABLE ONLY river_topo.node ALTER COLUMN node_id SET DEFAULT nextval('river_topo.node_node_id_seq'::regclass);

