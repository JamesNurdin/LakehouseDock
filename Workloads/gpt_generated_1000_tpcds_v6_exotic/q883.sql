WITH catalog_agg AS (
    SELECT
        d.d_date_sk,
        w.w_warehouse_name AS label,
        d.d_year AS year,
        SUM(cs.cs_net_profit) AS total_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_gmt_offset = -5.00
      AND d.d_year = 2000
    GROUP BY d.d_date_sk, w.w_warehouse_name, d.d_year
),
store_agg AS (
    SELECT
        d.d_date_sk,
        CAST(hd.hd_income_band_sk AS VARCHAR) AS label,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 50000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2000
      AND hd.hd_vehicle_count >= 2
    GROUP BY d.d_date_sk, hd.hd_income_band_sk, d.d_year
),
combined AS (
    SELECT * FROM catalog_agg
    UNION ALL
    SELECT * FROM store_agg
)
SELECT
    c.label,
    c.year,
    c.total_profit,
    c.profit_category
FROM combined c
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory inv
    WHERE inv.inv_date_sk = c.d_date_sk
      AND inv.inv_quantity_on_hand = 0
)
ORDER BY c.total_profit DESC
LIMIT 100
