WITH sales_agg AS (
    SELECT
        w.w_warehouse_sk,
        concat(w.w_city, ', ', w.w_state) AS warehouse_location,
        sum(cs.cs_net_profit) AS total_net_profit,
        count(*) AS orders_count
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(sm.sm_contract, '^A.*')
      AND ca.ca_city LIKE 'San%'
    GROUP BY w.w_warehouse_sk, concat(w.w_city, ', ', w.w_state)
)
SELECT
    sa.warehouse_location,
    sa.total_net_profit,
    sa.orders_count,
    (
        SELECT max(inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_warehouse_sk = sa.w_warehouse_sk
          AND inv.inv_quantity_on_hand > 500
    ) AS max_qty_over_500
FROM sales_agg sa
WHERE EXISTS (
    SELECT 1
    FROM inventory inv2
    WHERE inv2.inv_warehouse_sk = sa.w_warehouse_sk
      AND inv2.inv_quantity_on_hand > 800
)
ORDER BY sa.total_net_profit DESC
LIMIT 100
