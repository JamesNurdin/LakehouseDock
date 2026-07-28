WITH sales_enriched AS (
    SELECT
        dm.d_year,
        cp.cp_department AS cp_department,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_net_paid,
        CASE
            WHEN cs.cs_net_profit > 1000 THEN 'HIGH'
            WHEN cs.cs_net_profit > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category,
        sm.sm_type,
        hd.hd_vehicle_count,
        s.s_city,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN date_dim dm ON cs.cs_sold_date_sk = dm.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = dm.d_date_sk
    WHERE dm.d_year = 2002
      AND cs.cs_quantity >= 2
      AND sm.sm_type = 'AIR'
      AND hd.hd_vehicle_count >= 1
      AND s.s_city = 'Springfield'
),
agg AS (
    SELECT
        d_year,
        cp_department,
        profit_category,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM sales_enriched
    GROUP BY ROLLUP (d_year, cp_department, profit_category)
)
SELECT
    d_year,
    cp_department,
    profit_category,
    total_profit,
    order_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
WHERE d_year IS NOT NULL
ORDER BY d_year DESC, profit_rank
LIMIT 100
