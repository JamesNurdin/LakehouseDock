WITH joined AS (
  SELECT
    cp.cp_department,
    i.i_brand,
    sm.sm_carrier,
    w.w_state,
    w.w_warehouse_id,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_order_number
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
  JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
  WHERE sm.sm_ship_mode_id = 'AAAAAAAAIAAAAAAA'
    AND sm.sm_carrier = 'ORIENTAL'
    AND cp.cp_department = 'Electronics'
    AND i.i_brand = 'BrandX'
),
agg AS (
  SELECT
    cp_department,
    i_brand,
    sm_carrier,
    w_state,
    w_warehouse_id,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT cr_order_number) AS distinct_orders,
    MIN(cr_return_quantity) AS min_return_qty,
    MAX(cr_return_quantity) AS max_return_qty
  FROM joined
  GROUP BY cp_department, i_brand, sm_carrier, w_state, w_warehouse_id
)
SELECT
  cp_department,
  i_brand,
  sm_carrier,
  w_state,
  w_warehouse_id,
  total_return_amount,
  avg_return_qty,
  distinct_orders,
  min_return_qty,
  max_return_qty,
  ROW_NUMBER() OVER (PARTITION BY w_warehouse_id ORDER BY total_return_amount DESC) AS warehouse_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
