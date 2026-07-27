WITH ship_customers AS (
   SELECT
       c.c_customer_id,
       c.c_last_name,
       d.d_date AS relevant_date,
       hd.hd_buy_potential,
       hd.hd_dep_count,
       'ship' AS src
   FROM tpcds.customer c
   JOIN tpcds.date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
   JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2022
     AND hd.hd_buy_potential IN ('5001-10000', '>10000')
     AND EXISTS (
         SELECT 1
         FROM tpcds.date_dim d2
         WHERE d2.d_date_sk = c.c_first_shipto_date_sk
           AND d2.d_dow = 5
     )
),
sales_customers AS (
   SELECT
       c.c_customer_id,
       c.c_last_name,
       d.d_date AS relevant_date,
       hd.hd_buy_potential,
       hd.hd_dep_count,
       'sales' AS src
   FROM tpcds.customer c
   JOIN tpcds.date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
   JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2022
     AND hd.hd_buy_potential = '>10000'
     AND (
         SELECT max(hd2.hd_dep_count)
         FROM tpcds.household_demographics hd2
         WHERE hd2.hd_income_band_sk = hd.hd_income_band_sk
     ) > 2
)
SELECT *
FROM ship_customers
UNION ALL
SELECT *
FROM sales_customers
ORDER BY c_last_name, relevant_date DESC
LIMIT 100
