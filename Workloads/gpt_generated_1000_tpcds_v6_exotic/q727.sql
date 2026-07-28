WITH store_aggs AS (
   SELECT
       ca.ca_state AS state,
       i.i_category AS category,
       SUM(ss.ss_net_paid) AS total_sales,
       (
          SELECT AVG(p.p_cost)
          FROM promotion p
          WHERE p.p_promo_sk = ss.ss_promo_sk
       ) AS avg_promo_cost,
       'store' AS sales_channel
   FROM store_sales ss
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND EXISTS (
         SELECT 1
         FROM promotion p
         WHERE p.p_promo_sk = ss.ss_promo_sk
           AND p.p_discount_active = 'Y'
     )
   GROUP BY ca.ca_state, i.i_category, ss.ss_promo_sk
),
web_aggs AS (
   SELECT
       ca.ca_state AS state,
       i.i_category AS category,
       SUM(ws.ws_net_paid) AS total_sales,
       (
          SELECT AVG(p.p_cost)
          FROM promotion p
          WHERE p.p_promo_sk = ws.ws_promo_sk
       ) AS avg_promo_cost,
       'web' AS sales_channel
   FROM web_sales ws
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   WHERE td.t_hour BETWEEN 9 AND 17
     AND EXISTS (
         SELECT 1
         FROM promotion p
         WHERE p.p_promo_sk = ws.ws_promo_sk
           AND p.p_discount_active = 'Y'
     )
   GROUP BY ca.ca_state, i.i_category, ws.ws_promo_sk
)
SELECT
    state,
    category,
    total_sales,
    avg_promo_cost,
    sales_channel
FROM store_aggs
UNION ALL
SELECT
    state,
    category,
    total_sales,
    avg_promo_cost,
    sales_channel
FROM web_aggs
ORDER BY state, category, total_sales DESC
LIMIT 100
