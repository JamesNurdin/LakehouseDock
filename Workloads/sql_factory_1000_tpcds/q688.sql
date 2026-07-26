WITH sales_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        COUNT(*) AS sales_transactions
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk, cs.cs_call_center_sk
),
inventory_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        MAX(inv.inv_quantity_on_hand) AS max_inventory_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
),
joined AS (
    SELECT
        s.cs_item_sk AS item_sk,
        s.cs_warehouse_sk AS warehouse_sk,
        s.cs_call_center_sk AS call_center_sk,
        s.total_quantity_sold,
        s.sales_transactions,
        i.avg_inventory_on_hand,
        i.max_inventory_on_hand
    FROM sales_agg s
    LEFT JOIN inventory_agg i
        ON s.cs_item_sk = i.inv_item_sk
       AND s.cs_warehouse_sk = i.inv_warehouse_sk
)
SELECT
    cc.cc_call_center_id,
    w.w_warehouse_id,
    w.w_warehouse_name,
    j.item_sk,
    j.total_quantity_sold,
    j.avg_inventory_on_hand,
    CASE
        WHEN j.avg_inventory_on_hand = 0 OR j.avg_inventory_on_hand IS NULL THEN NULL
        ELSE ROUND(j.total_quantity_sold / j.avg_inventory_on_hand, 2)
    END AS turnover_ratio,
    DENSE_RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY CASE
        WHEN j.avg_inventory_on_hand = 0 OR j.avg_inventory_on_hand IS NULL THEN 0
        ELSE j.total_quantity_sold / j.avg_inventory_on_hand
    END DESC) AS turnover_rank
FROM joined j
JOIN call_center cc
    ON j.call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON j.warehouse_sk = w.w_warehouse_sk
ORDER BY cc.cc_call_center_id, w.w_warehouse_id, turnover_rank
LIMIT 100
