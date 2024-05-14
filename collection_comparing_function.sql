CREATE OR REPLACE NONEDITIONABLE FUNCTION "COLLECTION_COMPARER" (coll_1 IN ANYDATA,coll_2 IN ANYDATA) return varchar2
IS
    atype ANYTYPE;
    incompatible_types EXCEPTION;
    not_a_collection EXCEPTION;
    empty_or_null_collection EXCEPTION;
    retval varchar2(250);
    comparison_result BOOLEAN;
    coll_type VARCHAR2(100);
    coll_owner VARCHAR2(100);
    relation_btw_colls VARCHAR2(100);
    coll_elem_details collection_compare_help_pkg.collection_element_rt;
    base_types collection_compare_help_pkg.varchar2_100_ntt:=collection_compare_help_pkg.varchar2_100_ntt('BINARY_DOUBLE','BINARY_FLOAT','CHAR','DATE','INTERVAL DAY TO SECOND','INTERVAL YEAR TO MONTH','NUMBER','NVARCHAR2','NCHAR','RAW','TIMESTAMP',
                                                'TIMESTAMP WITH TZ','TIMESTAMP WITH LOCAL TZ','VARCHAR2');
BEGIN
    IF coll_1.GetType(atype) != DBMS_TYPES.TYPECODE_NAMEDCOLLECTION OR coll_2.GetType(atype) != DBMS_TYPES.TYPECODE_NAMEDCOLLECTION THEN
        RAISE not_a_collection;
    ELSIF coll_1.GetTypeName != coll_2.GetTypeName THEN
        RAISE incompatible_types;
    END IF;
    coll_type:=SUBSTR(coll_1.GetTypeName, INSTR(coll_1.GetTypeName,'.')+1);
    coll_owner:=SUBSTR(coll_1.GetTypeName,1, INSTR(coll_1.GetTypeName,'.')-1);
    coll_elem_details:=collection_compare_help_pkg.element_check(coll_type,coll_owner);

    IF coll_elem_details.type_pkg_name IS NOT NULL THEN
        coll_type:=coll_owner || '.' || coll_elem_details.type_pkg_name || '.' || coll_type;
    ELSE
        coll_type:=coll_owner || '.' || coll_type;
    END IF;
    relation_btw_colls:=collection_compare_help_pkg.relation_check(coll_1,coll_2,coll_type);

    IF relation_btw_colls IN('null collection','empty collection') THEN
        RAISE empty_or_null_collection;
    END IF;

    IF coll_elem_details.coll_elem MEMBER OF base_types THEN
        IF relation_btw_colls='coll_1 bigger than coll_2' THEN
            retval:=collection_compare_help_pkg.result_translator(collection_compare_help_pkg.compare_scalar_collections(coll_2,coll_1,coll_type),relation_btw_colls);
        ELSE
            retval:=collection_compare_help_pkg.result_translator(collection_compare_help_pkg.compare_scalar_collections(coll_1,coll_2,coll_type),relation_btw_colls);
        END IF;
    ELSE
        IF relation_btw_colls='coll_1 bigger than coll_2' THEN
            retval:=collection_compare_help_pkg.result_translator(collection_compare_help_pkg.compare_composite_collections(coll_2,coll_1,coll_type,coll_elem_details),relation_btw_colls);
        ELSE
            retval:=collection_compare_help_pkg.result_translator(collection_compare_help_pkg.compare_composite_collections(coll_1,coll_2,coll_type,coll_elem_details),relation_btw_colls);
        END IF;
    END IF;
    return retval;
EXCEPTION
    WHEN not_a_collection THEN
        RAISE_APPLICATION_ERROR(-20100,'At least one item is not a collection. Cannot compare');
    WHEN incompatible_types THEN
        RAISE_APPLICATION_ERROR(-20101,'The collections are of incompatible types. They cannot be equal.');
    WHEN empty_or_null_collection THEN
        RAISE_APPLICATION_ERROR(-20102,'At least one collection is null or empty.');
END;

/
