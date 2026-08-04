WITH catalog_cust AS (
   SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2020
),
web_cust AS (
   SELECT DISTINCT ws.ws_bill_customer_sk AS customer_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2020
),
store_agg AS (
   SELECT d.d_date_sk,
          SUM(ss.ss_ext_sales_price) AS store_sales_total
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY d.d_date_sk
),
web_site_agg AS (
   SELECT d.d_date_sk,
          COUNT(ws.ws_web_site_sk) AS web_visits
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   GROUP BY d.d_date_sk
),
full_join AS (
   SELECT COALESCE(sa.d_date_sk, wa.d_date_sk) AS date_sk,
          sa.store_sales_total,
          wa.web_visits
   FROM store_agg sa
   FULL OUTER JOIN web_site_agg wa ON sa.d_date_sk = wa.d_date_sk
)
SELECT c.customer_sk,
       cust.c_first_name,
       cust.c_last_name,
       (SELECT avg(ws2.ws_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_bill_customer_sk = c.customer_sk) AS avg_ws_price,
       fj.store_sales_total,
       fj.web_visits
FROM catalog_cust c
JOIN customer cust ON cust.c_customer_sk = c.customer_sk
LEFT JOIN full_join fj
     ON fj.date_sk = (SELECT d_date_sk
                      FROM date_dim
                      WHERE d_year = 2020
                      ORDER BY d_date_sk
                      LIMIT 1)
EXCEPT
SELECT w.customer_sk,
       cust2.c_first_name,
       cust2.c_last_name,
       (SELECT avg(ws3.ws_sales_price)
        FROM web_sales ws3
        WHERE ws3.ws_bill_customer_sk = w.customer_sk) AS avg_ws_price,
       fj2.store_sales_total,
       fj2.web_visits
FROM web_cust w
JOIN customer cust2 ON cust2.c_customer_sk = w.customer_sk
LEFT JOIN full_join fj2
     ON fj2.date_sk = (SELECT d_date_sk
                       FROM date_dim
                       WHERE d_year = 2020
                       ORDER BY d_date_sk
                       LIMIT 1)
ORDER BY customer_sk
OFFSET 0
LIMIT 100
