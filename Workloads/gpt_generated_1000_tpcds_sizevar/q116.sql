WITH electronics_customers AS (
    SELECT DISTINCT c.c_customer_id,
                    c.c_first_name,
                    c.c_last_name
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cp.cp_department = 'Electronics'
      AND d.d_fy_year = 1914
),
air_ship_customers AS (
    SELECT DISTINCT c.c_customer_id,
                    c.c_first_name,
                    c.c_last_name
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
    WHERE sm.sm_type = 'AIR'
      AND d.d_fy_year = 1914
)
SELECT ec.c_customer_id,
       ec.c_first_name,
       ec.c_last_name
FROM electronics_customers ec
EXCEPT
SELECT asc.c_customer_id,
       asc.c_first_name,
       asc.c_last_name
FROM air_ship_customers asc
LIMIT 100
