WITH
  sample_inv AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  inv_warehouses AS (
    SELECT inv_warehouse_sk FROM sample_inv
  ),
  ws_warehouses AS (
    SELECT ws_warehouse_sk FROM web_sales
  ),
  common_warehouses AS (
    SELECT inv_warehouse_sk AS w_warehouse_sk FROM inv_warehouses
    INTERSECT
    SELECT ws_warehouse_sk FROM ws_warehouses
  )
SELECT
  w.w_warehouse_name,
  d.d_year,
  we.web_name,
  SUM(cs.cs_net_paid) AS total_net_paid,
  AVG(cs.cs_net_profit) AS avg_net_profit,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  SUM(t.val) AS total_unnested,
  CASE WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
  SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount
FROM
  catalog_sales cs
  FULL OUTER JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  LEFT JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN web_sales ws
    ON ws.ws_order_number = cs.cs_order_number
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
  JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics sr_cd
    ON sr.sr_cdemo_sk = sr_cd.cd_demo_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  JOIN date_dim wr_date
    ON wr.wr_returned_date_sk = wr_date.d_date_sk
  JOIN customer_demographics wr_cd
    ON wr.wr_refunded_cdemo_sk = wr_cd.cd_demo_sk
  JOIN sample_inv inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim inv_date
    ON inv.inv_date_sk = inv_date.d_date_sk
  CROSS JOIN UNNEST(ARRAY[cs.cs_quantity, cs.cs_ext_sales_price]) AS t(val)
WHERE
  d.d_year BETWEEN 2000 AND 2002
  AND we.web_open_date_sk IS NOT NULL
  AND cc.cc_gmt_offset > -5.00
  AND cp.cp_type = 'PROMO'
  AND w.w_warehouse_sq_ft > 100000
  AND w.w_warehouse_sk IN (SELECT w_warehouse_sk FROM common_warehouses)
GROUP BY
  ROLLUP (w.w_warehouse_name, d.d_year, we.web_name)
HAVING
  SUM(cs.cs_net_paid) > 50000
ORDER BY
  total_net_paid DESC
LIMIT 100
