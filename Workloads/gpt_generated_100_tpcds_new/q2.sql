WITH catalog_buyers AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'monthly'
      AND d.d_year = 2020
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
return_customers AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2020
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT cb.c_customer_id,
       cb.c_first_name,
       cb.c_last_name
FROM catalog_buyers cb
EXCEPT
SELECT rc.c_customer_id,
       rc.c_first_name,
       rc.c_last_name
FROM return_customers rc
ORDER BY c_customer_id
LIMIT 100
