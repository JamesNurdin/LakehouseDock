WITH warehouse_sales AS (
    SELECT
        cc.cc_state,
        w.w_warehouse_id,
        w.w_city,
        w.w_warehouse_sq_ft,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        MAX(inv.inv_quantity_on_hand) AS max_inventory_qty
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE cc.cc_state IN ('TN', 'GA')
      AND cc.cc_rec_end_date >= DATE '2000-12-31'
      AND cs.cs_sold_date_sk BETWEEN 20000101 AND 20001231
    GROUP BY cc.cc_state, w.w_warehouse_id, w.w_city, w.w_warehouse_sq_ft
    HAVING SUM(cs.cs_net_profit) > 10000
)
SELECT
    ws.cc_state,
    ws.w_warehouse_id,
    ws.w_city,
    ws.total_net_profit,
    ws.total_sales,
    ws.avg_discount,
    ws.max_inventory_qty,
    ws.total_net_profit / ws.w_warehouse_sq_ft AS profit_per_sqft,
    RANK() OVER (PARTITION BY ws.cc_state ORDER BY ws.total_net_profit DESC) AS warehouse_state_rank
FROM warehouse_sales ws
ORDER BY ws.cc_state, warehouse_state_rank
LIMIT 20
