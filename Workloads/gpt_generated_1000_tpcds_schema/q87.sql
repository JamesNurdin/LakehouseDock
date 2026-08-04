WITH
  ss_agg AS (
    SELECT
      ss_sold_date_sk,
      ss_store_sk,
      ss_ticket_number,
      SUM(ss_net_paid) AS store_sales_total,
      COUNT(*) AS store_sales_cnt
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_store_sk, ss_ticket_number
  ),
  sr_agg AS (
    SELECT
      sr_returned_date_sk,
      sr_store_sk,
      sr_ticket_number,
      sr_reason_sk,
      SUM(sr_net_loss) AS store_return_loss,
      COUNT(*) AS store_return_cnt
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_store_sk, sr_ticket_number, sr_reason_sk
  ),
  cs_agg AS (
    SELECT
      cs_sold_date_sk,
      cs_call_center_sk,
      cs_ship_mode_sk,
      cs_promo_sk,
      cs_bill_customer_sk,
      cs_bill_hdemo_sk,
      cs_ship_customer_sk,
      cs_ship_hdemo_sk,
      SUM(cs_net_paid) AS catalog_sales_total,
      COUNT(*) AS catalog_sales_cnt
    FROM catalog_sales
    WHERE cs_net_paid > 1000
    GROUP BY cs_sold_date_sk, cs_call_center_sk, cs_ship_mode_sk, cs_promo_sk,
             cs_bill_customer_sk, cs_bill_hdemo_sk, cs_ship_customer_sk, cs_ship_hdemo_sk
  ),
  ws_agg AS (
    SELECT
      ws_sold_date_sk,
      ws_order_number,
      ws_web_site_sk,
      ws_ship_mode_sk,
      ws_promo_sk,
      ws_ship_customer_sk,
      ws_ship_hdemo_sk,
      SUM(ws_net_paid) AS web_sales_total,
      COUNT(*) AS web_sales_cnt
    FROM web_sales
    WHERE ws_net_paid > 500
    GROUP BY ws_sold_date_sk, ws_order_number, ws_web_site_sk,
             ws_ship_mode_sk, ws_promo_sk, ws_ship_customer_sk, ws_ship_hdemo_sk
  ),
  wr_agg AS (
    SELECT
      wr_returned_date_sk,
      wr_order_number,
      wr_reason_sk,
      SUM(wr_net_loss) AS web_return_loss,
      COUNT(*) AS web_return_cnt
    FROM web_returns
    GROUP BY wr_returned_date_sk, wr_order_number, wr_reason_sk
  ),
  inv_agg AS (
    SELECT
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory
    GROUP BY inv_date_sk
  )
SELECT
  d.d_year,
  d.d_month_seq,
  s.s_store_name,
  cc.cc_name,
  sm_cs.sm_type AS cs_ship_mode,
  sm_ws.sm_type AS ws_ship_mode,
  p_cs.p_promo_name AS cs_promo,
  p_ws.p_promo_name AS ws_promo,
  ws_agg.web_sales_total,
  cs_agg.catalog_sales_total,
  ss_agg.store_sales_total,
  sr_agg.store_return_loss,
  wr_agg.web_return_loss,
  inv_agg.total_inventory_qty,
  COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
  ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss_agg.store_sales_total DESC) AS store_sales_rank
FROM ss_agg
JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d
  ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN cs_agg
  ON cs_agg.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
  ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cs
  ON cs_agg.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN promotion p_cs
  ON cs_agg.cs_promo_sk = p_cs.p_promo_sk
JOIN customer c
  ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON cs_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ws_agg
  ON ws_agg.ws_sold_date_sk = d.d_date_sk
JOIN ship_mode sm_ws
  ON ws_agg.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN promotion p_ws
  ON ws_agg.ws_promo_sk = p_ws.p_promo_sk
JOIN web_site wsite
  ON ws_agg.ws_web_site_sk = wsite.web_site_sk
JOIN sr_agg
  ON sr_agg.sr_ticket_number = ss_agg.ss_ticket_number
 AND sr_agg.sr_store_sk = s.s_store_sk
JOIN reason r_sr
  ON sr_agg.sr_reason_sk = r_sr.r_reason_sk
JOIN wr_agg
  ON wr_agg.wr_order_number = ws_agg.ws_order_number
JOIN reason r_wr
  ON wr_agg.wr_reason_sk = r_wr.r_reason_sk
JOIN inv_agg
  ON inv_agg.inv_date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND ib.ib_lower_bound >= 60000
  AND cc.cc_gmt_offset BETWEEN -5 AND 0
  AND p_cs.p_discount_active = 'Y'
GROUP BY d.d_year, d.d_month_seq, s.s_store_name, cc.cc_name,
         sm_cs.sm_type, sm_ws.sm_type,
         p_cs.p_promo_name, p_ws.p_promo_name,
         ws_agg.web_sales_total, cs_agg.catalog_sales_total,
         ss_agg.store_sales_total, sr_agg.store_return_loss,
         wr_agg.web_return_loss, inv_agg.total_inventory_qty,
         s.s_store_id
ORDER BY ss_agg.store_sales_total DESC
LIMIT 100
