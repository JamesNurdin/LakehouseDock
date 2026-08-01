WITH
  rs_agg AS (
    SELECT
      sr_ticket_number,
      SUM(sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_amt > 0
    GROUP BY sr_ticket_number
  ),
  ss_agg AS (
    SELECT
      ss_customer_sk,
      SUM(ss_net_paid) AS total_store_net_paid,
      SUM(ss_net_profit) AS total_store_profit,
      SUM(ss_quantity) AS total_store_qty,
      MAX(ss_ticket_number) AS sample_ticket_number
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2452100 AND 2452199
    GROUP BY ss_customer_sk
  ),
  cs_agg AS (
    SELECT
      cs_bill_customer_sk AS customer_sk,
      SUM(cs_net_paid_inc_ship_tax) AS total_catalog_net_paid,
      SUM(cs_net_profit) AS total_catalog_profit,
      COUNT(*) AS catalog_orders,
      MIN(cs_promo_sk) AS promo_sk,
      MIN(cs_ship_mode_sk) AS ship_mode_sk,
      MIN(cs_warehouse_sk) AS warehouse_sk
    FROM catalog_sales
    WHERE cs_list_price > 20
    GROUP BY cs_bill_customer_sk
  ),
  ws_agg AS (
    SELECT
      ws_bill_customer_sk AS customer_sk,
      SUM(ws_net_paid_inc_ship_tax) AS total_web_net_paid,
      SUM(ws_net_profit) AS total_web_profit,
      COUNT(*) AS web_orders,
      MIN(ws_web_site_sk) AS web_site_sk,
      MIN(ws_ship_mode_sk) AS ws_ship_mode_sk,
      MIN(ws_warehouse_sk) AS ws_warehouse_sk
    FROM web_sales
    WHERE ws_web_site_sk IS NOT NULL
    GROUP BY ws_bill_customer_sk
  )
SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  ib.ib_lower_bound,
  ib.ib_upper_bound,
  p.p_promo_name,
  sm.sm_type AS ship_mode_type,
  w.w_warehouse_name,
  ws.web_state,
  ss_agg.total_store_net_paid,
  cs_agg.total_catalog_net_paid,
  ws_agg.total_web_net_paid,
  (COALESCE(ss_agg.total_store_net_paid, 0) + COALESCE(cs_agg.total_catalog_net_paid, 0) + COALESCE(ws_agg.total_web_net_paid, 0)) AS total_sales_net_paid,
  COALESCE(rs_agg.total_return_amt, 0) AS total_return_amount,
  (COALESCE(ss_agg.total_store_net_paid, 0) + COALESCE(cs_agg.total_catalog_net_paid, 0) + COALESCE(ws_agg.total_web_net_paid, 0) - COALESCE(rs_agg.total_return_amt, 0)) AS net_amount,
  RANK() OVER (ORDER BY (COALESCE(ss_agg.total_store_net_paid, 0) + COALESCE(cs_agg.total_catalog_net_paid, 0) + COALESCE(ws_agg.total_web_net_paid, 0) - COALESCE(rs_agg.total_return_amt, 0)) DESC) AS sales_rank
FROM customer c
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN ss_agg ON ss_agg.ss_customer_sk = c.c_customer_sk
LEFT JOIN cs_agg ON cs_agg.customer_sk = c.c_customer_sk
LEFT JOIN ws_agg ON ws_agg.customer_sk = c.c_customer_sk
LEFT JOIN rs_agg ON rs_agg.sr_ticket_number = ss_agg.sample_ticket_number
LEFT JOIN promotion p ON p.p_promo_sk = cs_agg.promo_sk
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs_agg.ship_mode_sk
LEFT JOIN warehouse w ON w.w_warehouse_sk = cs_agg.warehouse_sk
LEFT JOIN web_site ws ON ws.web_site_sk = ws_agg.web_site_sk
WHERE ib.ib_lower_bound >= 50000
  AND p.p_discount_active = 'Y'
  AND ws.web_state = 'TX'
ORDER BY sales_rank
LIMIT 100
