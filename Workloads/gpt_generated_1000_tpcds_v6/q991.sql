/*
  Goal:  Compute total net profit from store, catalog, and web sales broken down by store, year, and promotion, with subtotal rows for each store and overall totals. The query joins all 12 selected tables using the permitted join rules, re‑uses the DATE_DIM table under many aliases, re‑uses the PROMOTION table in a scalar EXISTS sub‑query, and demonstrates deep analytical aggregation via GROUPING SETS.
*/
WITH
  -- Aliases for the DATE_DIM table used for different surrogate keys
  d_sold           AS (SELECT * FROM date_dim),
  d_cs_sold        AS (SELECT * FROM date_dim),
  d_cs_ship        AS (SELECT * FROM date_dim),
  d_cr_returned    AS (SELECT * FROM date_dim),
  d_ws_sold        AS (SELECT * FROM date_dim),
  d_ws_ship        AS (SELECT * FROM date_dim),
  d_wp_creation    AS (SELECT * FROM date_dim),
  d_web_open       AS (SELECT * FROM date_dim),
  d_web_close      AS (SELECT * FROM date_dim),
  d_store_closed   AS (SELECT * FROM date_dim),
  d_promo_start    AS (SELECT * FROM date_dim),
  d_promo_end      AS (SELECT * FROM date_dim)
SELECT
  s.s_store_name,
  d_sold.d_year,
  p.p_promo_name,
  SUM(ss.ss_net_profit)          AS store_sales_profit,
  SUM(cs.cs_net_profit)          AS catalog_sales_profit,
  SUM(ws.ws_net_profit)          AS web_sales_profit,
  COUNT(DISTINCT cs.cs_order_number) AS total_orders,
  COUNT(*) FILTER (WHERE cr.cr_return_quantity > 0) AS total_returns
FROM store_sales ss
JOIN store s                     ON ss.ss_store_sk = s.s_store_sk
JOIN d_sold d_sold               ON ss.ss_sold_date_sk   = d_sold.d_date_sk
JOIN promotion p                 ON ss.ss_promo_sk      = p.p_promo_sk
JOIN customer c                  ON ss.ss_customer_sk   = c.c_customer_sk

JOIN catalog_sales cs            ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN d_cs_sold d_cs_sold         ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN d_cs_ship d_cs_ship         ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN ship_mode sm                ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk

LEFT JOIN catalog_returns cr    ON cr.cr_order_number = cs.cs_order_number
JOIN d_cr_returned d_cr_returned ON cr.cr_returned_date_sk = d_cr_returned.d_date_sk
JOIN ship_mode sm_cr            ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk

JOIN web_sales ws               ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN d_ws_sold d_ws_sold         ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN d_ws_ship d_ws_ship         ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp                ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN d_wp_creation d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN web_site webs              ON ws.ws_web_site_sk = webs.web_site_sk
JOIN d_web_open d_web_open       ON webs.web_open_date_sk  = d_web_open.d_date_sk
JOIN d_web_close d_web_close     ON webs.web_close_date_sk = d_web_close.d_date_sk

JOIN d_store_closed d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN d_promo_start d_promo_start   ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN d_promo_end d_promo_end       ON p.p_end_date_sk   = d_promo_end.d_date_sk
WHERE d_sold.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = p.p_promo_sk
          AND p2.p_cost > 1000
      )
GROUP BY GROUPING SETS (
    (s.s_store_name, d_sold.d_year, p.p_promo_name),
    (s.s_store_name, d_sold.d_year),
    (s.s_store_name),
    ()
)
ORDER BY s.s_store_name, d_sold.d_year, p.p_promo_name
