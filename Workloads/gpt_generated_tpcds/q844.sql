WITH sales_by_warehouse AS (
    SELECT
        cs_warehouse_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        AVG(cs_ext_discount_amt) AS avg_discount_amount,
        AVG(cs_ext_tax) AS avg_tax_amount
    FROM catalog_sales
    GROUP BY cs_warehouse_sk
),
latest_inventory AS (
    SELECT
        inv_warehouse_sk,
        inv_item_sk,
        inv_quantity_on_hand,
        inv_date_sk,
        ROW_NUMBER() OVER (PARTITION BY inv_warehouse_sk, inv_item_sk ORDER BY inv_date_sk DESC) AS rn
    FROM inventory
),
inventory_by_warehouse AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM latest_inventory
    WHERE rn = 1
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    s.total_quantity_sold,
    s.total_sales,
    s.total_profit,
    s.avg_discount_amount,
    s.avg_tax_amount,
    i.total_inventory_on_hand,
    CASE
        WHEN i.total_inventory_on_hand > 0 THEN s.total_quantity_sold / i.total_inventory_on_hand
        ELSE NULL
    END AS inventory_turnover_ratio
FROM warehouse w
LEFT JOIN sales_by_warehouse s ON s.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inventory_by_warehouse i ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE s.total_sales IS NOT NULL
ORDER BY s.total_sales DESC
LIMIT 20
