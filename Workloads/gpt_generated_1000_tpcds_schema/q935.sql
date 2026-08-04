WITH sampled_items AS (
    SELECT i_item_sk, i_category, i_brand, i_units
    FROM item TABLESAMPLE BERNOULLI (10)
    WHERE i_rec_start_date >= DATE '1999-01-01'
),
intersect_items AS (
    SELECT inv.inv_item_sk AS i_item_sk
    FROM inventory inv
    JOIN sampled_items si ON inv.inv_item_sk = si.i_item_sk
    WHERE inv.inv_quantity_on_hand > 600

    INTERSECT

    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_catalog_number = 14
      AND cs.cs_ext_discount_amt > 500
),
avg_quantity AS (
    SELECT AVG(ss_quantity) AS avg_qty
    FROM store_sales
)
SELECT
    ii.i_item_sk,
    ii.i_category,
    ii.i_brand,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    CASE
        WHEN SUM(ss.ss_quantity) > (SELECT avg_qty FROM avg_quantity) THEN 'HIGH_DEMAND'
        ELSE 'NORMAL_DEMAND'
    END AS demand_category,
    (SELECT COUNT(*) FROM store_sales WHERE ss_quantity > 0) AS total_store_transactions
FROM
    sampled_items ii
    JOIN intersect_items it ON ii.i_item_sk = it.i_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = ii.i_item_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = ii.i_item_sk
WHERE
    ii.i_item_sk NOT IN (
        SELECT DISTINCT ss2.ss_item_sk
        FROM store_sales ss2
        WHERE ss2.ss_quantity > 2000
    )
GROUP BY
    ii.i_item_sk, ii.i_category, ii.i_brand

UNION ALL

SELECT
    ii.i_item_sk,
    ii.i_category,
    ii.i_brand,
    0.0 AS total_catalog_sales,
    'NO_CATALOG_SALES' AS demand_category,
    (SELECT COUNT(*) FROM store_sales WHERE ss_quantity > 0) AS total_store_transactions
FROM
    sampled_items ii
WHERE
    ii.i_item_sk IN (
        SELECT inv.inv_item_sk
        FROM inventory inv
        WHERE inv.inv_quantity_on_hand > 600
    )
    AND ii.i_item_sk NOT IN (
        SELECT cs.cs_item_sk
        FROM catalog_sales cs
    )
ORDER BY total_catalog_sales DESC
LIMIT 100
