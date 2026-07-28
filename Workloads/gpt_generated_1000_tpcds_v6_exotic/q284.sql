WITH
  ss_agg AS (
    SELECT
      ss.ss_customer_sk        AS customer_sk,
      ss.ss_sold_date_sk      AS date_sk,
      ss.ss_sold_time_sk      AS time_sk,
      d.d_year                AS year,
      p.p_promo_sk            AS promo_sk,
      p.p_promo_name          AS promo_name,
      SUM(ss.ss_net_paid)    AS sum_net_paid,
      SUM(ss.ss_quantity)    AS sum_quantity
    FROM store_sales ss
    JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p     ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY
      ss.ss_customer_sk,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      d.d_year,
      p.p_promo_sk,
      p.p_promo_name
  ),
  ws_agg AS (
    SELECT
      ws.ws_bill_customer_sk  AS customer_sk,
      ws.ws_sold_date_sk      AS date_sk,
      ws.ws_sold_time_sk      AS time_sk,
      d.d_year                AS year,
      sm.sm_ship_mode_sk      AS ship_mode_sk,
      sm.sm_type              AS ship_mode_type,
      ws.ws_web_page_sk       AS web_page_sk,
      ws.ws_web_site_sk       AS web_site_sk,
      SUM(ws.ws_net_paid)     AS sum_net_paid,
      SUM(ws.ws_quantity)     AS sum_quantity
    FROM web_sales ws
    JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY
      ws.ws_bill_customer_sk,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      d.d_year,
      sm.sm_ship_mode_sk,
      sm.sm_type,
      ws.ws_web_page_sk,
      ws.ws_web_site_sk
  ),
  inv_agg AS (
    SELECT
      i.inv_date_sk          AS date_sk,
      SUM(i.inv_quantity_on_hand) AS total_on_hand
    FROM inventory i
    GROUP BY i.inv_date_sk
  )
SELECT
  c.c_customer_id                         AS customer_id,
  d.d_year                                 AS year,
  SUM(ss_agg.sum_net_paid)                AS total_store_sales,
  SUM(ws_agg.sum_net_paid)                AS total_web_sales,
  SUM(inv_agg.total_on_hand)              AS total_inventory_on_hand,
  SUM(cr.cr_return_amount)                AS total_returns,
  MIN(p.p_promo_name)                     AS promo_name,
  MIN(sm.sm_type)                         AS ship_mode_type,
  MIN(cc.cc_name)                         AS call_center_name,
  MIN(cp.cp_department)                   AS catalog_department,
  MIN(wp.wp_type)                         AS web_page_type,
  MIN(w.web_name)                         AS web_site_name
FROM ss_agg
JOIN ws_agg
  ON ss_agg.customer_sk = ws_agg.customer_sk
 AND ss_agg.date_sk     = ws_agg.date_sk
JOIN inv_agg
  ON ss_agg.date_sk = inv_agg.date_sk
JOIN date_dim d
  ON ss_agg.date_sk = d.d_date_sk
JOIN customer c
  ON ss_agg.customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN promotion p
  ON ss_agg.promo_sk = p.p_promo_sk
JOIN ship_mode sm
  ON ws_agg.ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
  ON ws_agg.web_page_sk = wp.wp_web_page_sk
JOIN web_site w
  ON ws_agg.web_site_sk = w.web_site_sk
JOIN catalog_returns cr
  ON cr.cr_returning_customer_sk = c.c_customer_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN time_dim t
  ON ss_agg.time_sk = t.t_time_sk
WHERE d.d_year = 2000
  AND cc.cc_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND t.t_hour BETWEEN 9 AND 17
  AND ca.ca_country = 'United States'
GROUP BY c.c_customer_id, d.d_year
ORDER BY total_store_sales DESC
LIMIT 100
