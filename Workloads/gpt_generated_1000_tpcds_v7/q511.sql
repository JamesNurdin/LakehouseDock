WITH sales_metrics AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        SUM(cs.cs_ext_sales_price) AS metric,
        'sales' AS source
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_catalog_page_number BETWEEN 10 AND 20
      AND cs.cs_sold_date_sk BETWEEN 2450900 AND 2451100
    GROUP BY i.i_item_id, i.i_product_name
),
inventory_metrics AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        SUM(inv.inv_quantity_on_hand * i.i_current_price) AS metric,
        'inventory' AS source
    FROM tpcds.inventory inv
    JOIN tpcds.item i
        ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_warehouse_sk = 7
      AND inv.inv_date_sk = 2451046
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT item_id, product_name, metric, source
FROM sales_metrics
UNION ALL
SELECT item_id, product_name, metric, source
FROM inventory_metrics
ORDER BY metric DESC
LIMIT 100
