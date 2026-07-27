WITH
sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_ext_sales_price) AS metric_value,
        CASE WHEN cd.cd_dep_count > 2 THEN 'LargeFamily' ELSE 'SmallFamily' END AS category
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    GROUP BY i.i_item_id, i.i_product_name, cd.cd_dep_count
),
sales_data AS (
    SELECT
        i_item_id,
        i_product_name,
        'sales' AS metric_type,
        metric_value,
        category,
        ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY metric_value DESC) AS rank
    FROM sales_agg
),
inventory_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(inv.inv_quantity_on_hand * i.i_current_price) AS metric_value,
        CASE WHEN w.w_suite_number LIKE 'Suite %' THEN 'Suite' ELSE 'NoSuite' END AS category
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_zip = '56098'
    GROUP BY i.i_item_id, i.i_product_name, w.w_suite_number
),
inventory_data AS (
    SELECT
        i_item_id,
        i_product_name,
        'inventory' AS metric_type,
        metric_value,
        category,
        ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY metric_value DESC) AS rank
    FROM inventory_agg
),
combined AS (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM inventory_data
)
SELECT DISTINCT *
FROM combined
ORDER BY metric_type, metric_value DESC, rank
