WITH sales_metrics AS (
    SELECT
        w.w_warehouse_name,
        cs.cs_sold_date_sk AS date_sk,
        SUM(cs.cs_ext_sales_price) AS metric_value,
        'sales' AS metric_type
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE i.i_category = 'Electronics'
      AND t.t_hour BETWEEN 6 AND 12
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp
          WHERE cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
            AND cp.cp_type = 'promo'
      )
    GROUP BY w.w_warehouse_name, cs.cs_sold_date_sk
),
inventory_metrics AS (
    SELECT
        w.w_warehouse_name,
        inv.inv_date_sk AS date_sk,
        CAST(SUM(inv.inv_quantity_on_hand) AS decimal(15,2)) AS metric_value,
        'inventory' AS metric_type
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
      AND inv.inv_quantity_on_hand > 500
    GROUP BY w.w_warehouse_name, inv.inv_date_sk
)
SELECT *
FROM sales_metrics
UNION ALL
SELECT *
FROM inventory_metrics
ORDER BY w_warehouse_name, date_sk, metric_type
LIMIT 100
