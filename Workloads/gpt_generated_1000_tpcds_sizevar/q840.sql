WITH sales_agg AS (
    SELECT
        i.i_item_id,
        d.d_year,
        SUM(ss.ss_quantity) AS total_qty_sold,
        SUM(ss.ss_net_paid) AS total_sales,
        CASE WHEN SUM(ss.ss_quantity) > 100 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM store_sales ss
    JOIN date_dim d        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i            ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, d.d_year
),
returns_agg AS (
    SELECT
        i.i_item_id,
        d.d_year,
        SUM(cr.cr_return_quantity) AS total_qty_returned,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CASE WHEN SUM(cr.cr_return_quantity) > 50 THEN 'HIGH' ELSE 'LOW' END AS return_category
    FROM catalog_returns cr
    JOIN date_dim d        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i            ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_item_id, d.d_year
),
sales_returns_full AS (
    SELECT
        COALESCE(sa.i_item_id, ra.i_item_id) AS item_id,
        COALESCE(sa.d_year, ra.d_year)       AS year,
        sa.total_qty_sold,
        ra.total_qty_returned,
        CASE
            WHEN sa.total_qty_sold IS NULL THEN 'NO_SALES'
            WHEN ra.total_qty_returned IS NULL THEN 'NO_RETURNS'
            ELSE 'BOTH'
        END AS presence
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.i_item_id = ra.i_item_id AND sa.d_year = ra.d_year
),
inventory_keys AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year    AS year
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i     ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
)
SELECT *
FROM (
    SELECT *
    FROM sales_returns_full
    INTERSECT
    SELECT *
    FROM sales_returns_full sr
    WHERE EXISTS (
        SELECT 1 FROM inventory_keys ik
        WHERE ik.item_id = sr.item_id AND ik.year = sr.year
    )
) AS intersect_part
UNION ALL
SELECT *
FROM (
    SELECT
        ik.item_id,
        ik.year,
        CAST(NULL AS BIGINT) AS total_qty_sold,
        CAST(NULL AS BIGINT) AS total_qty_returned,
        'INVENTORY_ONLY' AS presence
    FROM inventory_keys ik
    EXCEPT
    SELECT
        sr.item_id,
        sr.year,
        CAST(NULL AS BIGINT),
        CAST(NULL AS BIGINT),
        'INVENTORY_ONLY'
    FROM sales_returns_full sr
) AS except_part
ORDER BY item_id, year
LIMIT 100
