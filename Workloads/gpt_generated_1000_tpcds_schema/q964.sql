WITH
  diff_orders AS (
    SELECT cs_order_number FROM catalog_sales
    EXCEPT
    SELECT ws_order_number FROM web_sales
  ),
  max_income AS (
    SELECT MAX(ib_upper_bound) AS max_ub FROM income_band
  )
SELECT
  d_cs.d_year,
  st.s_store_name,
  COUNT(DISTINCT cs.cs_item_sk) AS distinct_catalog_items,
  COUNT(DISTINCT ws.ws_item_sk) AS distinct_web_items,
  SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
  SUM(ws.ws_ext_sales_price) AS total_web_sales,
  SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS catalog_profit_positive,
  SUM(CASE WHEN ws.ws_net_profit > 0 THEN ws.ws_net_profit ELSE 0 END) AS web_profit_positive,
  (SELECT COUNT(*) FROM diff_orders) AS catalog_only_order_count,
  (SELECT max_ub FROM max_income) AS max_income_upper_bound,
  COUNT(CASE WHEN cr_wr.cr_return_amount IS NOT NULL THEN 1 END) AS catalog_return_count,
  COUNT(CASE WHEN cr_wr.wr_return_amt IS NOT NULL THEN 1 END) AS web_return_count
FROM
  catalog_sales cs
  LEFT JOIN catalog_page pg
    ON cs.cs_catalog_page_sk = pg.cp_catalog_page_sk
  LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN item itm
    ON cs.cs_item_sk = itm.i_item_sk
  LEFT JOIN household_demographics hd_cs
    ON cs.cs_bill_hdemo_sk = hd_cs.hd_demo_sk
  LEFT JOIN income_band ib
    ON hd_cs.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN date_dim d_cs
    ON cs.cs_sold_date_sk = d_cs.d_date_sk
  LEFT JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
  LEFT JOIN (
    catalog_returns cr
    FULL OUTER JOIN web_returns wr
      ON cr.cr_order_number = wr.wr_order_number
     AND cr.cr_item_sk = wr.wr_item_sk
  ) AS cr_wr
    ON cr_wr.cr_order_number = cs.cs_order_number
  LEFT JOIN reason r
    ON COALESCE(cr_wr.cr_reason_sk, cr_wr.wr_reason_sk) = r.r_reason_sk
  LEFT JOIN store_sales ss
    ON ss.ss_sold_date_sk = d_cs.d_date_sk
   AND ss.ss_item_sk = itm.i_item_sk
  RIGHT JOIN store st
    ON ss.ss_store_sk = st.s_store_sk
  LEFT JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
  LEFT JOIN time_dim t_ss
    ON ss.ss_sold_time_sk = t_ss.t_time_sk
  LEFT JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  LEFT JOIN web_sales ws
    ON ws.ws_order_number = cs.cs_order_number
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
  LEFT JOIN date_dim d_ws
    ON ws.ws_sold_date_sk = d_ws.d_date_sk
  LEFT JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
  LEFT JOIN household_demographics hd_ws
    ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
  LEFT JOIN inventory inv
    ON inv.inv_item_sk = itm.i_item_sk
   AND inv.inv_date_sk = d_cs.d_date_sk
WHERE
  d_cs.d_year = 2001
  AND st.s_state = 'CA'
  AND ib.ib_upper_bound >= 50000
GROUP BY
  d_cs.d_year,
  st.s_store_name
ORDER BY
  total_catalog_sales DESC
LIMIT 100
