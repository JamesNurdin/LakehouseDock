WITH
  store_sales_agg AS (
    SELECT
      ss_sold_date_sk,
      ss_sold_time_sk,
      ss_hdemo_sk,
      ss_promo_sk,
      SUM(ss_net_profit) AS total_store_profit,
      SUM(ss_quantity)   AS total_store_qty
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_sold_time_sk, ss_hdemo_sk, ss_promo_sk
  ),
  catalog_sales_agg AS (
    SELECT
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_promo_sk,
      cs_call_center_sk,
      cs_ship_mode_sk,
      cs_warehouse_sk,
      cs_catalog_page_sk,
      SUM(cs_net_profit) AS total_catalog_profit,
      SUM(cs_quantity)   AS total_catalog_qty
    FROM catalog_sales
    GROUP BY cs_sold_date_sk, cs_sold_time_sk, cs_promo_sk, cs_call_center_sk, cs_ship_mode_sk, cs_warehouse_sk, cs_catalog_page_sk
  ),
  web_sales_agg AS (
    SELECT
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_promo_sk,
      ws_ship_mode_sk,
      ws_warehouse_sk,
      SUM(ws_net_profit) AS total_web_profit,
      SUM(ws_quantity)   AS total_web_qty
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_sold_time_sk, ws_promo_sk, ws_ship_mode_sk, ws_warehouse_sk
  ),
  store_returns_agg AS (
    SELECT
      sr_returned_date_sk,
      sr_reason_sk,
      SUM(sr_net_loss)      AS total_return_loss,
      SUM(sr_return_quantity) AS total_return_qty
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_reason_sk
  )
SELECT
  d_sold.d_year,
  d_sold.d_month_seq,
  p.p_promo_name,
  hd.hd_buy_potential,
  cc.cc_name               AS call_center_name,
  cp.cp_description        AS catalog_page_desc,
  sm_cs.sm_type            AS catalog_ship_type,
  sm_ws.sm_type            AS web_ship_type,
  r.r_reason_desc,
  ss.total_store_profit,
  cs.total_catalog_profit,
  ws.total_web_profit,
  sr.total_return_loss
FROM store_sales_agg ss
JOIN catalog_sales_agg cs
  ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
 AND ss.ss_promo_sk    = cs.cs_promo_sk
JOIN web_sales_agg ws
  ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
 AND ss.ss_promo_sk    = ws.ws_promo_sk
JOIN store_returns_agg sr
  ON ss.ss_sold_date_sk = sr.sr_returned_date_sk
JOIN date_dim d_sold
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_ss
  ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cs
  ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_cs
  ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
ORDER BY d_sold.d_year DESC, d_sold.d_month_seq, p.p_promo_name
LIMIT 100
