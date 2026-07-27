WITH
  sales_agg AS (
    SELECT
      cs_call_center_sk,
      cs_ship_mode_sk,
      cs_sold_time_sk,
      cs_bill_customer_sk,
      cs_bill_hdemo_sk,
      SUM(cs_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_ship_date_sk BETWEEN 2450830 AND 2450908
      AND cs_coupon_amt > 1000
      AND cs_quantity >= 1
    GROUP BY cs_call_center_sk, cs_ship_mode_sk, cs_sold_time_sk, cs_bill_customer_sk, cs_bill_hdemo_sk
  ),
  returns_agg AS (
    SELECT
      cr_call_center_sk,
      cr_ship_mode_sk,
      cr_returned_time_sk,
      SUM(cr_net_loss) AS total_loss,
      COUNT(*) AS returns_cnt
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_fee > 0
      AND cr_return_amount > 50
    GROUP BY cr_call_center_sk, cr_ship_mode_sk, cr_returned_time_sk
  ),
  web_agg AS (
    SELECT
      ws_ship_mode_sk,
      ws_sold_time_sk,
      SUM(ws_net_paid) AS total_revenue,
      COUNT(*) AS web_cnt
    FROM web_sales
    WHERE ws_quantity > 0
      AND ws_sales_price > 100
    GROUP BY ws_ship_mode_sk, ws_sold_time_sk
  )
SELECT
  cc.cc_name,
  sm.sm_type,
  t.t_hour,
  hd.hd_buy_potential,
  c.c_first_name,
  c.c_last_name,
  sales_agg.total_profit,
  returns_agg.total_loss,
  web_agg.total_revenue,
  CASE WHEN sales_agg.total_profit > COALESCE(returns_agg.total_loss, 0) THEN 'Profit' ELSE 'Loss' END AS profit_indicator
FROM sales_agg
JOIN call_center cc
  ON sales_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON sales_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t
  ON sales_agg.cs_sold_time_sk = t.t_time_sk
JOIN customer c
  ON sales_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON sales_agg.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN returns_agg
  ON returns_agg.cr_call_center_sk = cc.cc_call_center_sk
  AND returns_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
  AND returns_agg.cr_returned_time_sk = t.t_time_sk
LEFT JOIN web_agg
  ON web_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
  AND web_agg.ws_sold_time_sk = t.t_time_sk
WHERE cc.cc_state = 'CA'
  AND sm.sm_carrier = 'UPS'
  AND t.t_hour BETWEEN 8 AND 18
  AND c.c_preferred_cust_flag = 'Y'
ORDER BY sales_agg.total_profit DESC
LIMIT 100
