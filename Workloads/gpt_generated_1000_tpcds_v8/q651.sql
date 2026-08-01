WITH
  inv_agg AS (
    SELECT
      inv_warehouse_sk,
      inv_item_sk,
      SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_warehouse_sk, inv_item_sk
  ),
  order_numbers AS (
    SELECT ws_order_number AS order_number FROM web_sales
    EXCEPT
    SELECT cr_order_number AS order_number FROM catalog_returns
  )
SELECT
  w_ret.w_warehouse_id,
  w_ret.w_city,
  w_ret.w_state,
  SUM(ws.ws_ext_sales_price)                                 AS total_sales,
  SUM(cr.cr_return_amount)                                  AS total_returns,
  SUM(inv_agg.total_qty)                                    AS total_inventory_qty,
  CASE
    WHEN SUM(ws.ws_ext_sales_price) > 1000000 THEN 'HIGH'
    ELSE 'NORMAL'
  END                                                        AS sales_category,
  -- running total of sales per city ordered by warehouse id
  SUM(SUM(ws.ws_ext_sales_price)) OVER (
    PARTITION BY w_ret.w_city
    ORDER BY w_ret.w_warehouse_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  )                                                          AS running_city_sales,
  -- correlated sub‑query counting returns for the same warehouse
  (SELECT COUNT(*)
   FROM catalog_returns cr_corr
   WHERE cr_corr.cr_warehouse_sk = w_ret.w_warehouse_sk) AS returns_per_warehouse
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd_refunded
  ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN ship_mode sm_ret
  ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
FULL OUTER JOIN warehouse w_ret
  ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
JOIN web_sales ws
  ON cr.cr_order_number = ws.ws_order_number
JOIN ship_mode sm_sales
  ON ws.ws_ship_mode_sk = sm_sales.sm_ship_mode_sk
JOIN warehouse w_sales
  ON ws.ws_warehouse_sk = w_sales.w_warehouse_sk
JOIN web_site web
  ON ws.ws_web_site_sk = web.web_site_sk
JOIN inv_agg
  ON inv_agg.inv_warehouse_sk = w_ret.w_warehouse_sk
CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2 AS dummy) AS cross_tbl
WHERE NOT EXISTS (
        SELECT 1
        FROM web_sales ws_check
        WHERE ws_check.ws_order_number = cr.cr_order_number
          AND ws_check.ws_quantity > 0
      )
  AND cr.cr_order_number IN (SELECT order_number FROM order_numbers)
GROUP BY
  w_ret.w_warehouse_id,
  w_ret.w_city,
  w_ret.w_state,
  w_ret.w_warehouse_sk
HAVING SUM(ws.ws_ext_sales_price) > 0
ORDER BY total_sales DESC
LIMIT 100
