WITH sales_agg AS (
    SELECT
        dd.d_year,
        dd.d_month_seq,
        SUM(ss.ss_net_paid) AS total_sales,
        CAST(NULL AS INTEGER) AS total_inventory
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2021
    GROUP BY dd.d_year, dd.d_month_seq
),
inventory_agg AS (
    SELECT
        dd.d_year,
        dd.d_month_seq,
        CAST(NULL AS DECIMAL(15,2)) AS total_sales,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN date_dim dd ON inv.inv_date_sk = dd.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city = 'Ash Center'
      AND EXISTS (
            SELECT 1
            FROM inventory i2
            WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
              AND i2.inv_quantity_on_hand > 0
        )
    GROUP BY dd.d_year, dd.d_month_seq
)
SELECT
    d_year,
    d_month_seq,
    total_sales,
    total_inventory
FROM sales_agg
UNION ALL
SELECT
    d_year,
    d_month_seq,
    total_sales,
    total_inventory
FROM inventory_agg
ORDER BY d_year DESC, d_month_seq DESC, total_sales DESC
LIMIT 100
