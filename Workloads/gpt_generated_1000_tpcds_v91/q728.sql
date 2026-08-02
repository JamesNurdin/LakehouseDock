/* goal: Compare net paid sales from catalog and web channels per warehouse and date (year 2000), enrich each row with the total return amount for that warehouse/date, keep only rows that have a high‑value return, and cross‑join the result with a small set of meal‑time periods for further analysis */
WITH
  /* a tiny time dimension (only lunch and dinner hours) */
  small_time AS (
    SELECT t_time_sk,
           t_hour,
           t_meal_time
    FROM   time_dim
    WHERE  t_hour IN (12, 18)
    LIMIT 5
  ),

  /* aggregate catalog sales per warehouse and sold date */
  catalog_sales_agg AS (
    SELECT cs.cs_warehouse_sk,
           cs.cs_sold_date_sk,
           SUM(cs.cs_net_paid) AS total_net_paid
    FROM   catalog_sales cs
    JOIN   date_dim d        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN   promotion p       ON cs.cs_promo_sk = p.p_promo_sk
    WHERE  d.d_year = 2000
    GROUP BY cs.cs_warehouse_sk,
             cs.cs_sold_date_sk
  ),

  /* aggregate web sales per warehouse and sold date */
  web_sales_agg AS (
    SELECT ws.ws_warehouse_sk,
           ws.ws_sold_date_sk,
           SUM(ws.ws_net_paid) AS total_net_paid
    FROM   web_sales ws
    JOIN   date_dim d        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN   promotion p       ON ws.ws_promo_sk = p.p_promo_sk
    WHERE  d.d_year = 2000
    GROUP BY ws.ws_warehouse_sk,
             ws.ws_sold_date_sk
  ),

  /* combine the two channel aggregates */
  union_sales AS (
    SELECT 'catalog' AS channel,
           ca.cs_warehouse_sk AS warehouse_sk,
           ca.cs_sold_date_sk AS date_sk,
           ca.total_net_paid   AS net_paid
    FROM   catalog_sales_agg ca
    UNION ALL
    SELECT 'web' AS channel,
           wa.ws_warehouse_sk AS warehouse_sk,
           wa.ws_sold_date_sk AS date_sk,
           wa.total_net_paid   AS net_paid
    FROM   web_sales_agg wa
  )
SELECT
  u.channel,
  w.w_warehouse_name,
  d.d_date,
  u.net_paid,
  st.t_hour,
  st.t_meal_time,
  (
    SELECT COALESCE(SUM(cr.cr_return_amount), 0)
    FROM   catalog_returns cr
    WHERE  cr.cr_warehouse_sk = w.w_warehouse_sk
      AND  cr.cr_returned_date_sk = u.date_sk
  ) AS total_return_amount
FROM   union_sales u
JOIN   warehouse w      ON u.warehouse_sk = w.w_warehouse_sk
JOIN   date_dim d       ON u.date_sk = d.d_date_sk
CROSS JOIN small_time st
WHERE  EXISTS (
    SELECT 1
    FROM   catalog_returns cr2
    WHERE  cr2.cr_warehouse_sk = w.w_warehouse_sk
      AND  cr2.cr_returned_date_sk = u.date_sk
      AND  cr2.cr_return_amount > 500
  )
ORDER BY u.channel,
         w.w_warehouse_name,
         d.d_date,
         st.t_hour
LIMIT 100
