WITH joined AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    sm.sm_carrier,
    w.w_warehouse_name,
    cs.cs_ext_sales_price AS cs_sales,
    cs.cs_net_profit AS cs_profit,
    ws.ws_ext_sales_price AS ws_sales,
    ws.ws_net_profit AS ws_profit,
    sr.sr_return_amt AS return_amt,
    sr.sr_net_loss AS return_loss,
    inv.inv_quantity_on_hand AS inv_qty,
    CASE WHEN sm.sm_carrier = 'UPS' THEN 1 ELSE 0 END AS is_ups
  FROM date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_sold_time_sk = t.t_time_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_promo_sk = p.p_promo_sk
  JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_return_time_sk = t.t_time_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2002
    AND sm.sm_carrier = 'UPS'
    AND w.w_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND cc.cc_state = 'CA'
    AND t.t_hour BETWEEN 8 AND 12
    AND inv.inv_quantity_on_hand > 0
)
SELECT
  d_year,
  d_month_seq,
  sm_carrier,
  w_warehouse_name,
  SUM(cs_sales) AS total_catalog_sales,
  SUM(ws_sales) AS total_web_sales,
  SUM(return_amt) AS total_return_amount,
  SUM(cs_profit) + SUM(ws_profit) - SUM(return_loss) AS net_profit,
  CASE
    WHEN SUM(cs_profit) + SUM(ws_profit) - SUM(return_loss) > 0 THEN 'POSITIVE'
    ELSE 'NON_POSITIVE'
  END AS profit_status,
  AVG(is_ups) AS ups_ratio
FROM joined
GROUP BY d_year, d_month_seq, sm_carrier, w_warehouse_name
HAVING SUM(cs_sales) > 10000
ORDER BY total_catalog_sales DESC
LIMIT 100
