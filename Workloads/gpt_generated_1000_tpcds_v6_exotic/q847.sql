WITH web_data AS (
   SELECT
       c.c_customer_id,
       SUM(ws.ws_net_paid) AS total_net_paid,
       'web' AS source,
       regexp_extract(ws_site.web_name, '(\\d{3})', 1) AS extra_info
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
   WHERE d.d_year = 2021
     AND regexp_like(ws_site.web_name, '\\d{3}')
     AND EXISTS (
         SELECT 1
         FROM catalog_returns cr
         JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
         WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
           AND regexp_like(w.w_city, '^A')
     )
   GROUP BY c.c_customer_id, ws_site.web_name
),
store_data AS (
   SELECT
       c.c_customer_id,
       SUM(ss.ss_net_paid) AS total_net_paid,
       'store' AS source,
       substr(c.c_last_name, 1, 1) AS extra_info
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2021
     AND c.c_last_name LIKE 'S%'
     AND regexp_like(c.c_last_name, '^S')
   GROUP BY c.c_customer_id, c.c_last_name
),
combined AS (
   SELECT * FROM web_data
   UNION ALL
   SELECT * FROM store_data
)
SELECT
   c_customer_id,
   total_net_paid,
   source,
   extra_info,
   rank() OVER (PARTITION BY source ORDER BY total_net_paid DESC) AS revenue_rank
FROM combined
ORDER BY total_net_paid DESC, source
LIMIT 100
