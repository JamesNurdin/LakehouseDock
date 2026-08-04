WITH sales_union AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    d_sold.d_date AS sale_date,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_paid_inc_tax,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_mode_type,
    hd_bill.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    inv.inv_quantity_on_hand,
    cr_ret.total_return_amount,
    v.n AS dummy_val
  FROM catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
   AND inv.inv_item_sk = cs.cs_item_sk
  LEFT JOIN LATERAL (
      SELECT sum(cr.cr_return_amount) AS total_return_amount
      FROM catalog_returns cr
      WHERE cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
  ) cr_ret ON TRUE
  CROSS JOIN (VALUES (1), (2)) AS v(n)
  WHERE d_sold.d_year = 2001
    AND ib.ib_lower_bound >= 20000
),
web_union AS (
  SELECT
    ws.ws_order_number AS cs_order_number,
    ws.ws_sold_date_sk AS cs_sold_date_sk,
    d_sold.d_date AS sale_date,
    ws.ws_item_sk AS cs_item_sk,
    ws.ws_quantity AS cs_quantity,
    ws.ws_net_paid_inc_tax AS cs_net_paid_inc_tax,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    NULL AS call_center_name,
    sm.sm_type AS ship_mode_type,
    hd_bill.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    inv.inv_quantity_on_hand,
    0.0 AS total_return_amount,
    v.n AS dummy_val
  FROM web_sales ws
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN date_dim d_open
    ON ws_site.web_open_date_sk = d_open.d_date_sk
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
   AND inv.inv_item_sk = ws.ws_item_sk
  CROSS JOIN (VALUES (1), (2)) AS v(n)
  WHERE d_sold.d_year = 2001
    AND ib.ib_upper_bound <= 50000
)
SELECT
  sale_date,
  profit_flag,
  count(DISTINCT cs_order_number) AS orders_cnt,
  sum(cs_quantity) AS total_quantity,
  sum(cs_net_paid_inc_tax) AS total_paid,
  sum(total_return_amount) AS total_returns,
  avg(inv_quantity_on_hand) AS avg_inventory_on_hand
FROM (
  SELECT * FROM sales_union
  UNION
  SELECT * FROM web_union
) u
GROUP BY sale_date, profit_flag
ORDER BY sale_date DESC, profit_flag
LIMIT 100
