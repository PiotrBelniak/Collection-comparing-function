CREATE OR REPLACE NONEDITIONABLE PACKAGE BODY "COLLECTION_COMPARE_HELP_PKG" 
IS

    function element_check(typename IN VARCHAR2,ownername IN VARCHAR2) return collection_element_rt
    IS
        retval collection_element_rt;
    BEGIN
        BEGIN
            SELECT elem_type_name,elem_type_owner,elem_type_mod INTO retval.coll_elem,retval.coll_elem_owner,retval.coll_elem_ref_mod from all_coll_types where type_name= typename AND owner=ownername;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            retval.coll_elem:='';
        END;
        IF retval.coll_elem IS NULL THEN
            BEGIN
                SELECT elem_type_name,package_name,elem_type_package,elem_type_owner,elem_type_mod 
                INTO retval.coll_elem,retval.type_pkg_name,retval.coll_elem_pkg_name,retval.coll_elem_owner,retval.coll_elem_ref_mod from all_plsql_coll_types where type_name= typename AND owner=ownername;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20991,'Unknown collection');
            END;
        END IF;   
        return retval;
    END;

    function compare_scalar_collections(coll_1 IN ANYDATA,coll_2 IN ANYDATA, full_type_name IN VARCHAR2) return BOOLEAN
    IS
        retval BOOLEAN;
        sql_string VARCHAR2(32767);
    BEGIN
        sql_string:='DECLARE ' || 
            '  myobj1 ' || full_type_name || '; ' ||
            '  myobj2 ' || full_type_name || '; ' ||
            '  myad1 anydata := :ad1; ' ||
            '  myad2 anydata := :ad2; ' ||
            '  res_code PLS_INTEGER; ' ||
            '  retval BOOLEAN; ' ||
            '  common_count INTEGER; ' ||
            'BEGIN ' ||
            '  res_code :=myad1.GetCollection(myobj1); ' ||
            '  res_code :=myad2.GetCollection(myobj2); ' ||   
            '  SELECT COUNT(*) INTO common_count FROM TABLE(myobj1) a JOIN TABLE(myobj2) b ON a.COLUMN_VALUE=b.COLUMN_VALUE; ' ||
            '  IF common_count = myobj1.COUNT THEN ' ||
            '    retval:=TRUE; ' ||
            '  ELSE ' ||
            '    retval:=FALSE; ' ||
            '  END IF; ' ||
            '  :ret :=retval; ' ||
            'END;' ;     
        EXECUTE IMMEDIATE sql_string USING IN coll_1, IN coll_2, OUT retval;  
        return retval;
    END;
    function compare_composite_collections(coll_1 IN ANYDATA,coll_2 IN ANYDATA, full_type_name IN VARCHAR2,elem_details IN collection_element_rt) return BOOLEAN
    IS
        retval BOOLEAN;
        sql_string VARCHAR2(32767);
        type loc_ntt IS TABLE OF VARCHAR2(1000);
        list_of_columns loc_ntt:=loc_ntt();
        join_var_string VARCHAR2(32767):=' ON ';
    BEGIN
        IF elem_details.type_pkg_name IS NOT NULL THEN
            select attr_name BULK COLLECT INTO list_of_columns
                from all_plsql_type_attrs where type_name = elem_details.coll_elem and owner=elem_details.coll_elem_owner and package_name = elem_details.coll_elem_pkg_name;               
        ELSE
            select attr_name BULK COLLECT INTO list_of_columns
                from all_type_attrs where type_name  = elem_details.coll_elem and owner=elem_details.coll_elem_owner;   
        END IF;     
        FOR indx IN list_of_columns.FIRST..list_of_columns.LAST LOOP
            join_var_string:=join_var_string || 'a.' || list_of_columns(indx) || '=b.' || list_of_columns(indx) || ' AND ';
        END LOOP;
        join_var_string:=SUBSTR(join_var_string,1,LENGTH(join_var_string)-3);
        sql_string:='DECLARE ' || 
            '  myobj1 ' || full_type_name || '; ' ||
            '  myobj2 ' || full_type_name || '; ' ||
            '  myad1 anydata := :ad1; ' ||
            '  myad2 anydata := :ad2; ' ||
            '  res_code PLS_INTEGER; ' ||
            '  retval BOOLEAN; ' ||
            '  common_count INTEGER; ' ||
            'BEGIN ' ||
            '  res_code :=myad1.GetCollection(myobj1); ' ||
            '  res_code :=myad2.GetCollection(myobj2); ' ||   
            '  SELECT COUNT(*) INTO common_count FROM TABLE(myobj1) a JOIN TABLE(myobj2) b ' || join_var_string || ';' ||
            '  IF common_count = myobj1.COUNT THEN ' ||
            '    retval:=TRUE; ' ||
            '  ELSE ' ||
            '    retval:=FALSE; ' ||
            '  END IF; ' ||
            '  :ret :=retval; ' ||
            'END;' ;     
        EXECUTE IMMEDIATE sql_string USING IN coll_1, IN coll_2, OUT retval;  
        return retval;
    END;

    function result_translator(compare_result IN BOOLEAN, relation IN VARCHAR2) return varchar2
    IS
        retval VARCHAR2(250);
    BEGIN
        IF relation = 'coll_1 smaller than coll_2' THEN
            IF compare_result THEN
                retval:='Nested table number 1 is subset of nested table number 2';
            ELSE
                retval:='Nested table number 1 is smaller than nested table number 2 and is not a subset of nested table number 2.';
            END IF;
        ELSIF relation = 'coll_1 bigger than coll_2' THEN
            IF compare_result THEN
                retval:='Nested table number 1 is superset of nested table number 2';
            ELSE
                retval:='Nested table number 1 is bigger than nested table number 2 and is not a superset of nested table number 2.';
            END IF;    
        ELSIF relation = 'equal in size' THEN
            IF compare_result THEN
                retval:='Nested tables are equal.';
            ELSE
                retval:='Nested tabls are of the same size, but are not equal.';
            END IF;
        END IF;
        return retval;
    END;    

    function relation_check(coll_1 IN ANYDATA,coll_2 IN ANYDATA, full_type_name IN VARCHAR2) return varchar2
    IS
        retval VARCHAR2(250);
        sql_string VARCHAR2(32767);
    BEGIN
        EXECUTE IMMEDIATE 'DECLARE ' || '  myobj1 ' || full_type_name || '; ' ||
            '  myobj2 ' || full_type_name || '; ' ||
            '  myad1 anydata := :ad1; ' ||
            '  myad2 anydata := :ad2; ' ||
            '  res_code PLS_INTEGER; ' ||
            '  retval VARCHAR2(100); ' ||
            'BEGIN ' ||
            '  res_code :=myad1.GetCollection(myobj1); ' ||
            '  res_code :=myad2.GetCollection(myobj2); ' ||
            '  IF myobj1 IS NULL OR myobj2 IS NULL THEN ' ||
            '  retval:=''null collection''; ' ||
            '  ELSIF myobj1.COUNT=0 OR myobj2.COUNT=0 THEN ' ||
            '  retval:=''empty collection''; ' ||
            '  ELSIF myobj1.COUNT<myobj2.COUNT THEN ' ||
            '  retval:=''coll_1 smaller than coll_2''; ' ||
            '  ELSIF myobj1.COUNT>myobj2.COUNT THEN ' ||
            '  retval:=''coll_1 bigger than coll_2''; ' ||  
            '  ELSIF myobj1.COUNT=myobj2.COUNT THEN ' ||
            '  retval:=''equal in size''; ' ||  
            '  END IF; ' ||
            '  :ret :=retval; ' ||
            'END;' USING IN coll_1, IN coll_2, OUT retval;        
        return retval;
    END;   
END trg_coll_compare_help_pkg;

/
