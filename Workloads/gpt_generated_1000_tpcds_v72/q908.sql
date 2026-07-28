WITH per_customer_city AS (
   SELECT
       c.c_customer_sk,
       ca.ca_city,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(*) AS sales_cnt,
       AVG(cs.cs_ext_discount_amt) AS avg_discount
   FROM catalog_sales cs
   JOIN customer c
       ON cs.cs_bill_customer_sk = c.c_customer_sk
   CROSS JOIN LATERAL (
       SELECT t.t_hour, t.t_am_pm
       FROM time_dim t
       WHERE t.t_time_sk = cs.cs_sold_time_sk
   ) td
   JOIN customer_address ca
       ON cs.cs_bill_addr_sk = ca.ca_address_sk
   WHERE
       ca.ca_state = 'CA'
       AND ca.ca_county IN ('Chelan County', 'York County', 'Barry County')
       AND c.c_preferred_cust_flag = 'Y'
       AND c.c_birth_year BETWEEN 1970 AND 1990
       AND cs.cs_ext_list_price > 1000
   GROUP BY
       c.c_customer_sk,
       ca.ca_city
)
SELECT
    pc.c_customer_sk,
    pc.ca_city,
    pc.total_sales,
    pc.sales_cnt,
    pc.avg_discount,
    (
        SELECT MAX(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = pc.c_customer_sk
    ) AS max_sales_price,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM catalog_sales cs3
            WHERE cs3.cs_bill_customer_sk = pc.c_customer_sk
              AND cs3.cs_ext_sales_price > 3000
        ) THEN 'HIGH'
        ELSE 'NORMAL'
    END AS sales_category
FROM per_customer_city pc
WHERE pc.total_sales > (
    SELECT AVG(total_sales) FROM per_customer_city
)
ORDER BY pc.total_sales DESC, pc.sales_cnt DESC
LIMIT 100
