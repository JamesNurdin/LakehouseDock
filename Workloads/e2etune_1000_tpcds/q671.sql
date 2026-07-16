WITH filtered_sales AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_net_paid
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 100000
),
page_ship_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_page_id,
        sm.sm_type,
        SUM(fs.cs_net_profit) AS total_net_profit,
        SUM(fs.cs_quantity) AS total_quantity,
        AVG(fs.cs_net_paid) AS avg_net_paid
    FROM filtered_sales fs
    JOIN catalog_page cp ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY cp.cp_department, cp.cp_catalog_page_id, sm.sm_type
),
ranked_pages AS (
    SELECT
        cp_department AS department,
        sm_type AS ship_mode_type,
        cp_catalog_page_id AS catalog_page_id,
        total_net_profit,
        total_quantity,
        avg_net_paid,
        ROW_NUMBER() OVER (PARTITION BY cp_department, sm_type ORDER BY total_net_profit DESC) AS profit_rank,
        SUM(total_net_profit) OVER (PARTITION BY cp_department, sm_type) AS dept_ship_total_net_profit
    FROM page_ship_agg
)
SELECT
    department,
    ship_mode_type,
    catalog_page_id,
    total_net_profit,
    total_quantity,
    avg_net_paid,
    profit_rank,
    ROUND(total_net_profit / NULLIF(dept_ship_total_net_profit, 0) * 100, 2) AS profit_pct_of_dept_ship
FROM ranked_pages
WHERE profit_rank <= 3
ORDER BY department, ship_mode_type, profit_rank
