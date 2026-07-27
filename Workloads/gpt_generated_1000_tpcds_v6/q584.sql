WITH sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_sold_time_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_call_center_sk,
    cs.cs_catalog_page_sk,
    cc.cc_name,
    cc.cc_mkt_id,
    cc.cc_employees,
    cp.cp_department,
    hd.hd_buy_potential,
    hd.hd_income_band_sk,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    td.t_hour AS sold_hour
  FROM catalog_sales cs
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
)
SELECT
  sales.cc_name,
  sales.cp_department,
  sales.ib_income_band_sk,
  SUM(sales.cs_net_paid) AS total_catalog_sales,
  SUM(cr.cr_net_loss) AS total_return_loss,
  SUM(ws.ws_net_paid) AS total_web_sales,
  COUNT(DISTINCT sales.cs_order_number) AS distinct_catalog_orders,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
FROM sales
JOIN catalog_returns cr
  ON cr.cr_order_number = sales.cs_order_number
 AND cr.cr_item_sk = sales.cs_item_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN time_dim td_ret
  ON cr.cr_returned_time_sk = td_ret.t_time_sk
JOIN web_sales ws
  ON ws.ws_sold_time_sk = sales.cs_sold_time_sk
 AND ws.ws_bill_hdemo_sk = sales.cs_bill_hdemo_sk
JOIN time_dim td_web
  ON ws.ws_sold_time_sk = td_web.t_time_sk
WHERE
  sales.cc_mkt_id = 5
  AND sales.cc_employees > 1000000
  AND sales.cp_department = 'Sports'
  AND sales.hd_buy_potential = '5001-10000'
  AND sales.ib_lower_bound >= 50000
  AND r.r_reason_desc LIKE '%damaged%'
  AND sales.sold_hour BETWEEN 9 AND 17
  AND ws.ws_quantity > 5
  AND sales.cs_quantity > 2
GROUP BY
  ROLLUP (sales.cc_name, sales.cp_department, sales.ib_income_band_sk)
HAVING
  SUM(sales.cs_net_paid) > 10000
LIMIT 100
