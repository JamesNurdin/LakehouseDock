WITH sales_agg AS (
    SELECT
        w.w_warehouse_name,
        i.i_category,
        SUM(cs.cs_net_profit) AS metric_value,
        'SalesProfit' AS metric_type
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 12
      AND cs.cs_list_price > 50.00
    GROUP BY w.w_warehouse_name, i.i_category
),
inventory_agg AS (
    SELECT
        w.w_warehouse_name,
        i.i_category,
        CAST(SUM(inv.inv_quantity_on_hand) AS decimal(12,2)) AS metric_value,
        'OnHandQty' AS metric_type
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_date_sk = 2451067
      AND inv.inv_quantity_on_hand > 100
    GROUP BY w.w_warehouse_name, i.i_category
)
SELECT w_warehouse_name, i_category, metric_value, metric_type
FROM sales_agg
UNION ALL
SELECT w_warehouse_name, i_category, metric_value, metric_type
FROM inventory_agg
ORDER BY metric_value DESC
LIMIT 100
