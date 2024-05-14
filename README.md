# Collection comparer
## Usage
This function serves the purpose of comparing two collections of various types, i.e collections of scalars, collections of objects, for equality, inclusion and stating which collection is larger/smaller.  
>[!NOTE]
>In this version of function only comparison of two collections of same type is allowed.  

>[!WARNING]
>Only schema-level or package-level types are allowed.  
>Collections of collections are not supported.
## Additional requirements
For this function to correctly work, the package called COLLECTION_COMPARE_HELP_PKG needs to be compiled in the same schema as our function.



## How to use function
We call the function by specifying two collection converted to anydata type, e.g.
```bash
call collection_comparer(AnyData.ConvertCollection('name of collection')
                        ,AnyData.ConvertCollection('name of collection'));
```
## Result
The function returns description of relation between two specified collections, like 'Nested table number 1 is superset of nested table number 2'.  
This can be easily customized by manipulating function _result_translator_ in package _COLLECTION_COMPARE_HELP_PKG_ .
