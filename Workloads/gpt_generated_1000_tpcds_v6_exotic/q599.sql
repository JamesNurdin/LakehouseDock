WITH catalog_part AS (
  SELECT
    d_sold.d_year AS year,
    i.i_category AS category,
    s.s_store_name AS store_name,
    SUM(cs.cs_net_profit) AS total_profit,
    'catalog' AS sales_channel
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_date_sk = d_sold.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_sold.d_date_sk
  JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
  JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
  JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
  JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
  JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
  JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
  WHERE d_sold.d_year BETWEEN 2000 AND 2002
    AND i.i_current_price > 50
    AND cc.cc_state = 'CA'
    AND s.s_number_employees > 200
    AND ib.ib_upper_bound >= 90000
    AND sm.sm_type = 'AIR'
  GROUP BY d_sold.d_year, i.i_category, s.s_store_name
),
web_part AS (
  SELECT
    d_sold.d_year AS year,
    i.i_category AS category,
    CAST(NULL AS varchar) AS store_name,
    SUM(ws.ws_net_profit) AS total_profit,
    'web' AS sales_channel
  FROM web_sales ws
  JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
  JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_sold.d_date_sk
  WHERE d_sold.d_year BETWEEN 2001 AND 2003
    AND i.i_current_price < 100
    AND wsite.web_state = 'CA'
    AND sm.sm_carrier = 'UPS'
    AND ib.ib_lower_bound <= 60000
  GROUP BY d_sold.d_year, i.i_category
),
combined_sales AS (
  SELECT * FROM catalog_part
  UNION ALL
  SELECT * FROM web_part
)
SELECT
  year,
  category,
  store_name,
  sales_channel,
  SUM(total_profit) AS total_profit,
  DENSE_RANK() OVER (PARTITION BY year ORDER BY SUM(total_profit) DESC) AS profit_rank
FROM combined_sales
GROUP BY GROUPING SETS (
  (year, category, store_name, sales_channel),
  (year, category, sales_channel),
  (year, sales_channel)
)
HAVING SUM(total_profit) > 10000
ORDER BY year, profit_rank
LIMIT 100
