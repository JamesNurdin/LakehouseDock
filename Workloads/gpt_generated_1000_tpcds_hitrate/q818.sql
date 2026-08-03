WITH web_data AS (
   SELECT
       ws.ws_sold_date_sk,
       ws.ws_net_paid_inc_ship,
       ws.ws_ext_tax,
       ws.ws_quantity,
       ws.ws_bill_customer_sk,
       c.c_customer_sk,
       c.c_customer_id,
       c.c_birth_year,
       i.i_item_id,
       i.i_category,
       i.i_manufact_id,
       wsite.web_name AS web_site_name,
       wsite.web_state
   FROM web_sales ws
   RIGHT OUTER JOIN web_site wsite
       ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN item i
       ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c
       ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE wsite.web_state = 'CA'
     AND i.i_rec_start_date >= DATE '2000-01-01'
     AND i.i_manufact_id IN (167, 995)
     AND ws.ws_ext_tax > 50
     AND c.c_birth_year BETWEEN 1950 AND 1970
     AND i.i_category = 'Sports'
),
store_customers AS (
   SELECT DISTINCT c.c_customer_sk
   FROM store_sales ss
   JOIN customer c
       ON ss.ss_customer_sk = c.c_customer_sk
   JOIN item i
       ON ss.ss_item_sk = i.i_item_sk
   WHERE i.i_category = 'Sports'
     AND i.i_manufact_id IN (167, 995)
     AND c.c_birth_year BETWEEN 1950 AND 1970
),
web_customers AS (
   SELECT DISTINCT ws.ws_bill_customer_sk AS c_customer_sk
   FROM web_sales ws
   JOIN item i
       ON ws.ws_item_sk = i.i_item_sk
   WHERE i.i_category = 'Sports'
     AND i.i_manufact_id IN (167, 995)
)
SELECT
    wd.c_customer_id,
    wd.i_item_id,
    wd.i_category,
    wd.i_manufact_id,
    wd.ws_net_paid_inc_ship,
    wd.ws_ext_tax,
    wd.web_site_name,
    RANK() OVER (PARTITION BY wd.web_site_name ORDER BY wd.ws_net_paid_inc_ship DESC) AS sales_rank,
    lt.recent_ws_cnt
FROM web_data wd
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS recent_ws_cnt
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = wd.c_customer_sk
      AND ws2.ws_sold_date_sk >= wd.ws_sold_date_sk - 30
) lt ON true
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_customer_sk = wd.c_customer_sk
)
AND wd.c_customer_sk NOT IN (
    SELECT c_customer_sk FROM store_customers
    EXCEPT
    SELECT c_customer_sk FROM web_customers
)
ORDER BY wd.web_site_name, sales_rank, wd.ws_net_paid_inc_ship DESC
LIMIT 100
