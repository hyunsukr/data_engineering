USE ROLE ACCOUNTADMIN;
USE DATABASE DS5559_DATA;
USE SCHEMA PUBLIC;

-- Show warehouses available, just an example of a sql command that is snowflake specific... this 
-- shoud show you the warehouses available, to start it is only the default, COMPUTE_WH
SHOW WAREHOUSES;

-- Another snowflake specific command. Note how much metadata is related to the table
-- The 'information_schema' contains info about all the tables available
SELECT * FROM information_schema.columns;

-- This should narrow it down to the PUBLIC schema
SELECT * FROM information_schema.columns WHERE "TABLE_SCHEMA" = 'PUBLIC';

-- To get just the columns from our table you have to get really specific....
SELECT "COLUMN_NAME"
FROM information_schema.columns
WHERE "TABLE_SCHEMA" = 'PUBLIC'
    AND "TABLE_NAME" = 'IRIS_DATA';
    
-- This version will FAIL... because of the specific syntax, which varies from say pyspark and snowflake...
-- Note that IRIS_DATA has double quotes... you'll see the error message "...Invalid Identifier IRIS_DATA"
SELECT "COLUMN_NAME"
FROM information_schema.columns
WHERE "TABLE_SCHEMA" = 'PUBLIC'
    AND "TABLE_NAME" = "IRIS_DATA";


--  AND NOW FOR A SHORT PROCEDURE
-- Show the procedures available under this schema, initially should only contain two defaults unrelated to user
SHOW PROCEDURES;


-- THIS is the procedure, note the first part is straight SQL followed by javascript encircled by $$
-- Place your cursor anywhere in the statement and hit <CTL>-ENTER
-- Aside from the SQL header note the following lines
--    snowflake.createStatement({sqlText: validations[idx].sql_statement}), // this is the snowflake API to LOAD a sql statement.
--                                                                          // and store it in a javascript object
--
--          res = stmt.execute();                                           // This is where we RUN the statement
--
--          row_count = res.getRowCount();                                  // As mentioned in class, one standard used for tests is 'no rows means good'
--                                                                          // so in this case we get the row count...
-- The rest of the javascript is setup and processing.  While this example is a validation, you can do just about any work
--    you want.  As mentioned in class, it is now possible to use python for these procedures too.
CREATE OR REPLACE PROCEDURE udf1()
    RETURNS string
    LANGUAGE JAVASCRIPT
    COMMENT = 'sample udf'
    EXECUTE AS CALLER
AS
$$
var validations = [
{name: `_AUDIT_DBT_TESTS_--DbtTestsPassed`, sql_statement: `SELECT * FROM IRIS_DATA WHERE 'CLASS' IS NOT NULL;`}
];
    var return_results = {};
    return_results["validation_failures"] = 0;

    return_results["fail_num"] = 0;
    return_results["pass_num"] = 0;
    return_results["exce_num"] = 0;

    return_results["total_num"] = 0;

    return_results["fail_queries"] = [];
    return_results["exce_queries"] = [];

    return_results["pass_names"] = [];
    return_results["fail_names"] = [];
    return_results["exce_names"] = [];

    return_results["exce_err_messages"] = [];

    for (idx in validations) {
        stmt = snowflake.createStatement({sqlText: validations[idx].sql_statement})
        return_results["total_num"] += 1;

        try {
            res = stmt.execute();
            row_count = res.getRowCount();
            if (row_count === 0) {
                return_results["pass_names"].push(validations[idx].name);
                return_results["pass_num"] += 1;
            } else {
                return_results["fail_queries"].push(validations[idx].sql_statement);
                return_results["fail_names"].push(validations[idx].name);
                return_results["fail_num"] += 1;
                return_results["validation_failures"] += 1;
            }
        } catch(err) {
                return_results["exce_queries"].push(validations[idx].sql_statement);
                return_results["exce_err_messages"].push(err.message);
                return_results["exce_names"].push(validations[idx].name);
                return_results["exce_num"] += 1;
                return_results["validation_failures"] += 1;
        }
    }
    return JSON.stringify(return_results);
$$;

-- You should now see the procedure listed
SHOW PROCEDURES;

-- Call it and you should see the result of the return from javascript
CALL udf1();

-- This should get you the text, run this and click on the last rows value for 'body'
DESCRIBE PROCEDURE udf1();


SELECT COUNT(*) as count, CLASS FROM IRIS_DATA GROUP BY CLASS;

SELECT AVG(SEPAL_LENGTH) as Average_Sepal_Length, 
       AVG(SEPAL_WIDTH) as Average_Sepal_width,
       AVG(petal_length) AS Average_petal_length,
       AVG(petal_width) AS Average_petal_width,
       class
       FROM IRIS_DATA GROUP BY CLASS;

SELECT AVG(SEPAL_LENGTH) as Average_Sepal_Length, 
       AVG(SEPAL_WIDTH) as Average_Sepal_width,
       AVG(petal_length) AS Average_petal_length,
       AVG(petal_width) AS Average_petal_width,
       COUNT(*) as count,
       class
       FROM IRIS_DATA GROUP BY CLASS;
         
SELECT MAX(SEPAL_LENGTH) as Max_Sepal_Length, 
       MAX(SEPAL_WIDTH) as Max_Sepal_width,
       MAX(petal_length) AS Max_petal_length,
       MAX(petal_width) AS Max_petal_width,
       class
       FROM IRIS_DATA GROUP BY CLASS;
       
 -- Create procedure in javascript
 -- Doc used https://docs.snowflake.com/en/sql-reference/stored-procedures-javascript
CREATE OR REPLACE PROCEDURE get_count_and_average(COL_NAMES ARRAY)
      RETURNS VARIANT NOT NULL
      LANGUAGE JAVASCRIPT
      AS
      $$
      var row_as_json = {};
      var array_of_rows = [];
      var table_as_json = {};

      // Run SQL statement(s) and get a resultSet.
      var command = "SELECT AVG(SEPAL_LENGTH) as Average_Sepal_Length, \
       AVG(SEPAL_WIDTH) as Average_Sepal_width, \
       AVG(petal_length) AS Average_petal_length, \
       AVG(petal_width) AS Average_petal_width, \
       COUNT(*) as count, \
       class \
       FROM IRIS_DATA GROUP BY CLASS";
       
      var cmd1_dict = {sqlText: command};
      var stmt = snowflake.createStatement(cmd1_dict);
      var rs = stmt.execute();

      var row_num = 1;
      while (rs.next())  {
        row_as_json = {};
        for (var col_num = 0; col_num < COL_NAMES.length; col_num = col_num + 1) {
          var col_name = COL_NAMES[col_num];
          row_as_json[col_name] = rs.getColumnValue(col_num + 1);
          }
        array_of_rows.push(row_as_json);
        ++row_num;
        }
      table_as_json = { "result" : array_of_rows };
      return table_as_json;
      $$
      ;

CALL get_count_and_average(ARRAY_CONSTRUCT('AVERAGE_SEPAL_LENGTH', 'AVERAGE_SEPAL_WIDTH', 'AVERAGE_PETAL_LENGTH', 'AVERAGE_PETAL_WIDTH', 'COUNT', 'CLASS'));

SELECT VALUE:AVERAGE_SEPAL_LENGTH AS AVERAGE_SEPAL_WIDTH, 
       VALUE:AVERAGE_SEPAL_WIDTH AS AVERAGE_SEPAL_WIDTH,
       VALUE:AVERAGE_PETAL_LENGTH AS AVERAGE_PETAL_LENGTH, 
       VALUE:AVERAGE_PETAL_WIDTH AS AVERAGE_PETAL_WIDTH,
       VALUE:COUNT AS COUNT, 
       VALUE:CLASS AS CLASS
  FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) AS res, LATERAL FLATTEN(input => res.$1:result);

-- Procedure for python
-- Doc used https://interworks.com/blog/2022/08/16/a-definitive-guide-to-python-stored-procedures-in-the-snowflake-ui/
CREATE OR REPLACE PROCEDURE get_count_and_average_python()
returns VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.8'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'compute_metrics'
AS
$$
from snowflake.snowpark.functions import col

def compute_metrics(snowpark_session):
   results_df = snowpark_session.sql('SELECT AVG(SEPAL_LENGTH) as Average_Sepal_Length, \
       AVG(SEPAL_WIDTH) as Average_Sepal_width, \
       AVG(petal_length) AS Average_petal_length, \
       AVG(petal_width) AS Average_petal_width, \
       COUNT(*) as count, \
       class \
       FROM IRIS_DATA GROUP BY CLASS')
   result = []
   for i in results_df.collect():
       json_format = {
                        "Average_Sepal_Length": i[0], \
                        "Average_Sepal_width": i[1], \
                        "Average_petal_length": i[2], \
                        "Average_petal_width": i[3], \
                        "count": i[4], \
                        "class": i[5], \
                     }
       result.append(json_format)
   table_as_json = { "result" : result };
   return table_as_json
$$;
CALL get_count_and_average_python();
SELECT VALUE:Average_Sepal_Length AS AVERAGE_SEPAL_WIDTH, 
       VALUE:Average_Sepal_width AS AVERAGE_SEPAL_WIDTH,
       VALUE:Average_petal_length AS AVERAGE_PETAL_LENGTH, 
       VALUE:Average_petal_width AS AVERAGE_PETAL_WIDTH,
       VALUE:count AS COUNT, 
       VALUE:class AS CLASS
  FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) AS res, LATERAL FLATTEN(input => res.$1:result);
