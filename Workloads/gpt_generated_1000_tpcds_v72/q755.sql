WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory i
        WHERE i.inv_date_sk = cs.cs_sold_date_sk
          AND i.inv_warehouse_sk = cs.cs_warehouse_sk
          AND i.inv_quantity_on_hand > 0
    )
)
SELECT
    year,
    month_seq,
    ship_type,
    total_sales,
    total_profit,
    profit_category
FROM (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        sm.sm_type AS ship_type,
        SUM(fs.cs_ext_sales_price) AS total_sales,
        SUM(fs.cs_net_profit) AS total_profit,
        CASE
            WHEN SUM(fs.cs_net_profit) / NULLIF(SUM(fs.cs_ext_sales_price), 0) > 0.2 THEN 'HIGH'
            ELSE 'LOW'
        END AS profit_category
    FROM filtered_sales fs
    JOIN date_dim d ON fs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR' AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, sm.sm_type

    UNION ALL

    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        sm.sm_type AS ship_type,
        SUM(fs.cs_ext_sales_price) AS total_sales,
        SUM(fs.cs_net_profit) AS total_profit,
        CASE
            WHEN SUM(fs.cs_net_profit) / NULLIF(SUM(fs.cs_ext_sales_price), 0) > 0.2 THEN 'HIGH'
            ELSE 'LOW'
        END AS profit_category
    FROM filtered_sales fs
    JOIN date_dim d ON fs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'RAIL' AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, sm.sm_type
) AS combined
ORDER BY year DESC, month_seq, ship_type
LIMIT 100
