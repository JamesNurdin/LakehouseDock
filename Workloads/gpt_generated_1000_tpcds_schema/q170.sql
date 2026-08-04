WITH inventory_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        d.d_year,
        cp.cp_department,
        d.d_date,
        SUM(inv.inv_quantity_on_hand) AS total_qty,
        AVG(inv.inv_quantity_on_hand) AS avg_qty,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items
    FROM
        tpcds.inventory AS inv
        JOIN tpcds.date_dim AS d ON inv.inv_date_sk = d.d_date_sk
        JOIN tpcds.catalog_page AS cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE
        d.d_fy_week_seq = 7
        AND d.d_current_year = 'Y'
        AND inv.inv_warehouse_sk IN (1, 4, 13)
        AND cp.cp_catalog_number = 10
    GROUP BY
        inv.inv_warehouse_sk,
        d.d_year,
        cp.cp_department,
        d.d_date
)
SELECT
    agg.inv_warehouse_sk,
    agg.d_year,
    agg.cp_department,
    agg.total_qty,
    agg.avg_qty,
    agg.distinct_items,
    LAG(agg.total_qty) OVER (PARTITION BY agg.inv_warehouse_sk ORDER BY agg.d_date) AS prev_total_qty,
    SUM(agg.total_qty) OVER (PARTITION BY agg.inv_warehouse_sk ORDER BY agg.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_qty
FROM
    inventory_agg AS agg
ORDER BY
    agg.inv_warehouse_sk,
    agg.d_date
LIMIT 100
