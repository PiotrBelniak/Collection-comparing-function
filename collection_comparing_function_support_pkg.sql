CREATE OR REPLACE NONEDITIONABLE PACKAGE "C##TRG_USER"."TRG_COLL_COMPARE_HELP_PKG" ACCESSIBLE BY (function TRG_COLLECTION_COMPARER)
IS
    type collection_element_rt IS RECORD(
        coll_elem VARCHAR2(100)
       ,coll_elem_owner VARCHAR2(100)
       ,coll_elem_ref_mod VARCHAR2(10)
       ,type_pkg_name VARCHAR2(100)
       ,coll_elem_pkg_name VARCHAR2(100));

    function element_check(typename IN VARCHAR2,ownername IN VARCHAR2) return collection_element_rt;
    function compare_scalar_collections(coll_1 IN ANYDATA,coll_2 IN ANYDATA, full_type_name IN VARCHAR2) return BOOLEAN;
    function compare_composite_collections(coll_1 IN ANYDATA,coll_2 IN ANYDATA, full_type_name IN VARCHAR2, elem_details IN collection_element_rt) return BOOLEAN;
    function result_translator(compare_result IN BOOLEAN, relation IN VARCHAR2) return varchar2;
    function relation_check(coll_1 IN ANYDATA,coll_2 IN ANYDATA, full_type_name IN VARCHAR2) return varchar2;

END trg_coll_compare_help_pkg;

/
