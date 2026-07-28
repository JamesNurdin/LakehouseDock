WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    d_sold.d_year,
    i.i_category,
    w.w_warehouse_name,
    SUM(cs.cs_net_paid)                AS total_net_paid,
    SUM(cs.cs_net_profit)              AS total_net_profit,
    SUM(COALESCE(cr.cr_return_quantity, 0))   AS total_return_qty,
    SUM(COALESCE(wr.wr_return_quantity, 0))   AS total_web_return_qty,
    SUM(inv_agg.total_on_hand)         AS total_inventory_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MAX(p.p_discount_active)           AS any_discount_active
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
  ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN store s
  ON s.s_closed_date_sk = d_sold.d_date_sk
LEFT JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
LEFT JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN inventory inv
  ON cs.cs_item_sk = inv.inv_item_sk
 AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
LEFT JOIN inv_agg
  ON cs.cs_item_sk = inv_agg.inv_item_sk
 AND cs.cs_warehouse_sk = inv_agg.inv_warehouse_sk
LEFT JOIN web_returns wr
  ON cs.cs_item_sk = wr.wr_item_sk
LEFT JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
LEFT JOIN reason r2
  ON wr.wr_reason_sk = r2.r_reason_sk
WHERE d_sold.d_year = 2001
  AND t_sold.t_meal_time = 'dinner'
  AND EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_number = cp.cp_catalog_number
          AND cp2.cp_catalog_page_number > cp.cp_catalog_page_number
    )
GROUP BY d_sold.d_year, i.i_category, w.w_warehouse_name
ORDER BY total_net_profit DESC
LIMIT 100
