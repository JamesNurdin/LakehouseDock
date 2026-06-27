WITH cs_agg AS (
    SELECT
        cs.cs_warehouse_sk AS warehouse_sk,
        COUNT(*) AS total_orders,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_ext_discount_amt) AS total_discount
    FROM catalog_sales cs
    GROUP BY cs.cs_warehouse_sk
),
inv_agg AS (
    SELECT
        inv.inv_warehouse_sk AS warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
        COUNT(*) AS inventory_item_count
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    COALESCE(cs_agg.total_orders, 0) AS total_orders,
    COALESCE(cs_agg.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(cs_agg.total_sales, 0) AS total_sales,
    COALESCE(cs_agg.total_profit, 0) AS total_profit,
    COALESCE(cs_agg.avg_sales_price, 0) AS avg_sales_price,
    COALESCE(inv_agg.total_inventory_quantity, 0) AS total_inventory_quantity,
    CASE
        WHEN COALESCE(cs_agg.total_sales, 0) = 0 THEN 0
        ELSE ROUND(cs_agg.total_profit / cs_agg.total_sales, 4)
    END AS profit_margin
FROM warehouse w
LEFT JOIN cs_agg ON cs_agg.warehouse_sk = w.w_warehouse_sk
LEFT JOIN inv_agg ON inv_agg.warehouse_sk = w.w_warehouse_sk
ORDER BY total_sales DESC
LIMIT 20
