WITH sales_agg AS (
    SELECT
        d.d_date AS trans_date,
        i.i_item_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        'sales' AS source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_date, i.i_item_id
),
inventory_agg AS (
    SELECT
        d.d_date AS trans_date,
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        NULL AS total_sales,
        NULL AS unique_customers,
        'inventory' AS source
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_date, i.i_item_id
)
SELECT DISTINCT
    u.trans_date,
    u.i_item_id,
    u.total_sales,
    u.total_quantity,
    u.unique_customers,
    u.source
FROM (
    SELECT trans_date, i_item_id, total_sales, NULL AS total_quantity, unique_customers, source
    FROM sales_agg
    UNION ALL
    SELECT trans_date, i_item_id, NULL AS total_sales, total_quantity, NULL AS unique_customers, source
    FROM inventory_agg
) u
ORDER BY u.trans_date DESC
LIMIT 100
