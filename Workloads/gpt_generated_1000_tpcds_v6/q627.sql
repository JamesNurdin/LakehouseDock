WITH catalog_agg AS (
    SELECT
        d.d_year AS year,
        'CATALOG' AS source,
        sm.sm_ship_mode_id AS ship_mode_id,
        COUNT(*) AS sales_cnt,
        SUM(cs.cs_net_paid) AS total_net_paid,
        CASE WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        (
            SELECT AVG(cs3.cs_net_profit)
            FROM catalog_sales cs3
            JOIN date_dim d3 ON cs3.cs_sold_date_sk = d3.d_date_sk
            WHERE d3.d_year = d.d_year
        ) AS avg_yearly_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND sm.sm_code = 'AIR'
    GROUP BY d.d_year, sm.sm_ship_mode_id
),
store_agg AS (
    SELECT
        d.d_year AS year,
        'STORE' AS source,
        NULL AS ship_mode_id,
        COUNT(*) AS sales_cnt,
        SUM(ss.ss_net_paid) AS total_net_paid,
        CASE WHEN SUM(ss.ss_net_profit) > 50000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        (
            SELECT AVG(ss3.ss_net_profit)
            FROM store_sales ss3
            JOIN date_dim d3 ON ss3.ss_sold_date_sk = d3.d_date_sk
            WHERE d3.d_year = d.d_year
        ) AS avg_yearly_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND EXISTS (
            SELECT 1
            FROM catalog_returns cr
            JOIN date_dim dcr ON cr.cr_returned_date_sk = dcr.d_date_sk
            WHERE cr.cr_order_number = ss.ss_ticket_number
              AND dcr.d_year = d.d_year
              AND cr.cr_return_quantity > 0
        )
    GROUP BY d.d_year
)
SELECT * FROM catalog_agg
UNION ALL
SELECT * FROM store_agg
ORDER BY year, total_net_paid DESC
LIMIT 100
