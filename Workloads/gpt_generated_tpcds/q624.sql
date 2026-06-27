WITH returns_agg AS (
  SELECT
    wr.wr_order_number,
    wr.wr_item_sk,
    SUM(wr.wr_return_quantity) AS return_quantity,
    SUM(wr.wr_return_amt) AS return_amt
  FROM web_returns wr
  GROUP BY wr.wr_order_number, wr.wr_item_sk
)
SELECT
  p.p_promo_id,
  sm.sm_type,
  td.t_hour,
  hd.hd_buy_potential,
  COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit,
  SUM(ws.ws_quantity) AS total_quantity,
  SUM(COALESCE(ra.return_quantity, 0)) AS total_return_qty,
  SUM(COALESCE(ra.return_amt, 0)) AS total_return_amt,
  CASE WHEN SUM(ws.ws_quantity) = 0 THEN 0
       ELSE SUM(COALESCE(ra.return_quantity, 0)) / SUM(ws.ws_quantity) END AS return_quantity_rate,
  CASE WHEN SUM(ws.ws_ext_sales_price) = 0 THEN 0
       ELSE SUM(COALESCE(ra.return_amt, 0)) / SUM(ws.ws_ext_sales_price) END AS return_amount_rate
FROM web_sales ws
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN returns_agg ra ON ws.ws_order_number = ra.wr_order_number AND ws.ws_item_sk = ra.wr_item_sk
GROUP BY p.p_promo_id, sm.sm_type, td.t_hour, hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
