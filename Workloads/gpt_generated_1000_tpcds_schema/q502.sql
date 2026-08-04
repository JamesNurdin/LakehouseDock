WITH combined_sales AS (
   SELECT
       ss.ss_customer_sk AS customer_sk,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
   GROUP BY ss.ss_customer_sk
   UNION
   SELECT
       ws.ws_bill_customer_sk AS customer_sk,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
   GROUP BY ws.ws_bill_customer_sk
),
catalog_customers AS (
   SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
),
intersect_customers AS (
   SELECT customer_sk FROM combined_sales
   INTERSECT
   SELECT customer_sk FROM catalog_customers
)
SELECT
   c.c_customer_id,
   c.c_first_name,
   c.c_last_name,
   ic.customer_sk,
   cs.total_sales,
   cs.profit_flag,
   CASE
       WHEN cd.cd_purchase_estimate >= 6000 THEN 'High'
       WHEN cd.cd_purchase_estimate >= 4000 THEN 'Medium'
       ELSE 'Low'
   END AS purchase_category,
   (SELECT COUNT(*)
        FROM store_returns sr
        WHERE sr.sr_customer_sk = ic.customer_sk
          AND sr.sr_returned_date_sk = (
                SELECT MAX(d2.d_date_sk)
                FROM date_dim d2
                WHERE d2.d_year = 2002
          )
   ) AS returns_in_year
FROM intersect_customers ic
JOIN combined_sales cs ON ic.customer_sk = cs.customer_sk
JOIN customer c ON ic.customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LIMIT 100
