WITH profit_by_cc_wh AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name AS call_center_name,
        cc.cc_division,
        cc.cc_division_name,
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_division,
        cc.cc_division_name,
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name
),
inventory_stats AS (
    SELECT
        cs.cs_call_center_sk AS inv_call_center_sk,
        cs.cs_warehouse_sk AS inv_warehouse_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM catalog_sales cs
    JOIN inventory inv
        ON cs.cs_sold_date_sk = inv.inv_date_sk
        AND cs.cs_item_sk = inv.inv_item_sk
        AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY cs.cs_call_center_sk, cs.cs_warehouse_sk
)
SELECT
    p.cc_division_name,
    p.cc_call_center_id,
    p.call_center_name,
    p.w_warehouse_id,
    p.w_warehouse_name,
    p.total_profit,
    p.total_net_paid,
    p.order_cnt,
    COALESCE(i.avg_inventory_on_hand, 0) AS avg_inventory_on_hand,
    DENSE_RANK() OVER (PARTITION BY p.cc_call_center_id ORDER BY p.total_profit DESC) AS warehouse_profit_rank,
    CASE
        WHEN COALESCE(i.avg_inventory_on_hand, 0) = 0 THEN NULL
        ELSE ROUND(p.total_profit / i.avg_inventory_on_hand, 2)
    END AS profit_per_inventory
FROM profit_by_cc_wh p
LEFT JOIN inventory_stats i
    ON p.cc_call_center_sk = i.inv_call_center_sk
   AND p.w_warehouse_sk = i.inv_warehouse_sk
ORDER BY p.cc_division_name, p.cc_call_center_id, warehouse_profit_rank
LIMIT 100
