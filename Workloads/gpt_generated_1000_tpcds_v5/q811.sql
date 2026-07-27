WITH warehouse_metrics AS (
    /* Profit per warehouse for Bronx County, only for orders billed to customers with salutation 'Mrs.' */
    SELECT
        w.w_warehouse_id,
        w.w_city,
        'profit' AS metric_type,
        SUM(cs.cs_net_profit) AS metric_value
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_county = 'Bronx County'
      AND EXISTS (
          SELECT 1
          FROM customer c
          WHERE c.c_customer_sk = cs.cs_bill_customer_sk
            AND c.c_salutation = 'Mrs.'
      )
    GROUP BY w.w_warehouse_id, w.w_city

    UNION ALL

    /* Total on‑hand inventory for the same warehouses, limited to items of a specific brand and sufficient stock */
    SELECT
        w.w_warehouse_id,
        w.w_city,
        'inventory_qty' AS metric_type,
        SUM(i.inv_quantity_on_hand) AS metric_value
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN item it ON i.inv_item_sk = it.i_item_sk
    WHERE w.w_county = 'Bronx County'
      AND it.i_brand = 'Brand#12'
      AND i.inv_quantity_on_hand > 700
    GROUP BY w.w_warehouse_id, w.w_city
)
SELECT DISTINCT
    wm.w_warehouse_id,
    wm.w_city,
    wm.metric_type,
    wm.metric_value
FROM warehouse_metrics wm
ORDER BY wm.metric_value DESC
LIMIT 100
