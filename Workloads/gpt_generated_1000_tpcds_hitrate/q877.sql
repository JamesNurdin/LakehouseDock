WITH
c AS (
  SELECT
    cs.cs_order_number,
    cc.cc_division_name,
    p.p_promo_name,
    p.p_promo_sk,
    sm.sm_type,
    hd_bill.hd_buy_potential,
    td.t_hour,
    cs.cs_net_profit,
    cs.cs_ext_sales_price,
    cr.cr_refunded_cash
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_call_center_sk = cc.cc_call_center_sk
    AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
),
s AS (
  SELECT
    p.p_promo_name,
    p.p_promo_sk,
    sm.sm_type,
    hd.hd_buy_potential,
    td.t_hour,
    ss.ss_net_profit,
    ss.ss_ext_sales_price,
    sr.sr_refunded_cash,
    NULL AS cc_division_name
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN ship_mode sm ON 1 = 0          -- placeholder, not used in this side
  LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_hdemo_sk = hd.hd_demo_sk
),
full_data AS (
  SELECT
    COALESCE(c.cc_division_name, s.cc_division_name) AS division_name,
    COALESCE(c.p_promo_name, s.p_promo_name) AS promo_name,
    COALESCE(c.sm_type, s.sm_type) AS ship_type,
    COALESCE(c.hd_buy_potential, s.hd_buy_potential) AS buy_potential,
    COALESCE(c.t_hour, s.t_hour) AS hour,
    COALESCE(c.cs_net_profit, 0) + COALESCE(s.ss_net_profit, 0) AS net_profit,
    COALESCE(c.cs_ext_sales_price, 0) + COALESCE(s.ss_ext_sales_price, 0) AS sales,
    COALESCE(c.cr_refunded_cash, 0) + COALESCE(s.sr_refunded_cash, 0) AS refunded,
    COALESCE(c.p_promo_sk, s.p_promo_sk) AS promo_sk
  FROM c
  FULL OUTER JOIN s ON c.p_promo_sk = s.p_promo_sk
)
SELECT
  division_name,
  promo_name,
  ship_type,
  buy_potential,
  hour,
  SUM(net_profit) AS sum_net_profit,
  SUM(sales) AS sum_sales,
  SUM(refunded) AS sum_refunded,
  CASE WHEN SUM(net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
  RANK() OVER (PARTITION BY division_name ORDER BY SUM(net_profit) DESC) AS profit_rank
FROM full_data
GROUP BY ROLLUP (division_name, promo_name, ship_type, buy_potential, hour)
HAVING SUM(net_profit) > 1000
ORDER BY sum_net_profit DESC
LIMIT 100
