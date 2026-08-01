WITH sales_agg AS (
    SELECT
        dd.d_year AS year,
        dd.d_quarter_seq AS quarter,
        sm.sm_type AS ship_type,
        SUM(cs.cs_net_paid_inc_tax) AS total_amount,
        CASE WHEN SUM(cs.cs_net_paid_inc_tax) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
        'Sales' AS metric
    FROM catalog_sales cs
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE dd.d_year = 2001
      AND sm.sm_type = 'AIR'
    GROUP BY dd.d_year, dd.d_quarter_seq, sm.sm_type
),
returns_agg AS (
    SELECT
        dd.d_year AS year,
        dd.d_quarter_seq AS quarter,
        sm.sm_type AS ship_type,
        SUM(cr.cr_net_loss) AS total_amount,
        CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'Zero' END AS profit_flag,
        'Returns' AS metric
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE dd.d_year = 2001
      AND sm.sm_type = 'AIR'
    GROUP BY dd.d_year, dd.d_quarter_seq, sm.sm_type
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY year, quarter, ship_type, metric
LIMIT 100
