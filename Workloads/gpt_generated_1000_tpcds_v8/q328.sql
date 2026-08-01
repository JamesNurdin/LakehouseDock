WITH sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_warehouse_sk,
    cs.cs_call_center_sk,
    cs.cs_ship_mode_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_sold_date_sk,
    i.i_category,
    i.i_class_id,
    cc.cc_gmt_offset,
    sm.sm_type,
    w.w_warehouse_name
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE i.i_category = 'Furniture'
    AND cc.cc_gmt_offset = -6.00
    AND cs.cs_quantity > 5
    AND sm.sm_type = 'AIR'
),

returns AS (
  SELECT
    cr.cr_order_number,
    cr.cr_item_sk,
    cr.cr_warehouse_sk,
    cr.cr_call_center_sk,
    cr.cr_ship_mode_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_returned_date_sk,
    i.i_category,
    cc.cc_gmt_offset,
    sm.sm_type,
    w.w_warehouse_name
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  WHERE i.i_category = 'Furniture'
    AND cc.cc_gmt_offset = -6.00
    AND cr.cr_return_quantity > 0
    AND sm.sm_type = 'AIR'
),

inventory_cte AS (
  SELECT
    inv.inv_date_sk,
    inv.inv_item_sk,
    inv.inv_warehouse_sk,
    inv.inv_quantity_on_hand,
    i.i_category,
    w.w_warehouse_name
  FROM inventory inv
  JOIN item i ON inv.inv_item_sk = i.i_item_sk
  JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE i.i_category = 'Furniture'
    AND inv.inv_quantity_on_hand > 0
),

high_activity_items AS (
  SELECT cs_item_sk AS item_sk FROM catalog_sales WHERE cs_quantity > 20
  INTERSECT
  SELECT cr_item_sk FROM catalog_returns WHERE cr_return_quantity > 5
),

combined AS (
  SELECT
    COALESCE(s.cs_order_number, r.cr_order_number) AS order_number,
    COALESCE(s.cs_item_sk, r.cr_item_sk) AS item_sk,
    COALESCE(s.cs_warehouse_sk, r.cr_warehouse_sk) AS warehouse_sk,
    COALESCE(s.cs_call_center_sk, r.cr_call_center_sk) AS call_center_sk,
    COALESCE(s.cs_ship_mode_sk, r.cr_ship_mode_sk) AS ship_mode_sk,
    s.cs_quantity,
    r.cr_return_quantity,
    s.cs_net_paid,
    r.cr_return_amount,
    s.i_category,
    s.w_warehouse_name,
    ROW_NUMBER() OVER (
      PARTITION BY COALESCE(s.cs_warehouse_sk, r.cr_warehouse_sk)
      ORDER BY COALESCE(s.cs_net_paid, 0) DESC
    ) AS warehouse_rank
  FROM sales s
  FULL OUTER JOIN returns r
    ON s.cs_order_number = r.cr_order_number
  WHERE COALESCE(s.cs_item_sk, r.cr_item_sk) IN (SELECT item_sk FROM high_activity_items)
),

final AS (
  SELECT
    c.*, 
    NOT EXISTS (
      SELECT 1 FROM inventory_cte inv
      WHERE inv.inv_item_sk = c.item_sk
        AND inv.inv_warehouse_sk = c.warehouse_sk
        AND inv.inv_date_sk = 2451067
    ) AS no_inventory_on_date
  FROM combined c
)
SELECT
  order_number,
  item_sk,
  warehouse_sk,
  call_center_sk,
  ship_mode_sk,
  cs_quantity,
  cr_return_quantity,
  cs_net_paid,
  cr_return_amount,
  i_category,
  w_warehouse_name,
  warehouse_rank,
  no_inventory_on_date
FROM final
WHERE no_inventory_on_date = TRUE
ORDER BY warehouse_rank ASC, cs_net_paid DESC
LIMIT 100
