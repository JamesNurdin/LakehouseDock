WITH
  agg_cs AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_warehouse_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_ship_hdemo_sk,
      SUM(cs.cs_ext_sales_price)          AS total_sales,
      SUM(cs.cs_net_profit)               AS total_profit
    FROM catalog_sales cs
    GROUP BY
      cs.cs_item_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_warehouse_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_ship_hdemo_sk
  ),
  intersect_items AS (
    SELECT i_item_sk FROM item WHERE i_class_id IN (3, 14)
    INTERSECT
    SELECT sr_item_sk FROM store_returns
  )
SELECT
  cc.cc_name,
  i.i_brand,
  SUM(a.total_sales)   AS sum_sales,
  SUM(a.total_profit)  AS sum_profit,
  COUNT(DISTINCT i.i_item_sk) AS item_cnt
FROM agg_cs a
FULL OUTER JOIN catalog_returns cr
  ON a.cs_item_sk = cr.cr_item_sk
JOIN item i
  ON COALESCE(a.cs_item_sk, cr.cr_item_sk) = i.i_item_sk
JOIN call_center cc
  ON a.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON a.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
  ON a.cs_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd_bill
  ON a.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
  ON a.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN time_dim t_ws
  ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
CROSS JOIN (
  SELECT 1 AS multiplier UNION ALL SELECT 2 UNION ALL SELECT 3
) AS mult
WHERE i.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
  AND a.total_sales > (SELECT AVG(cs_ext_sales_price) FROM catalog_sales)
GROUP BY GROUPING SETS (
  (cc.cc_name, i.i_brand),
  (cc.cc_name),
  ()
)
ORDER BY sum_sales DESC
LIMIT 100
