WITH sales_agg AS (
    SELECT
        d.d_year,
        cc.cc_state,
        SUM(cs.cs_ext_sales_price) AS metric_amount,
        'SALES' AS metric_type,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS category,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rn
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY GROUPING SETS ((d.d_year, cc.cc_state), (d.d_year), ())
),
returns_agg AS (
    SELECT
        d.d_year,
        cc.cc_state,
        SUM(cr.cr_return_amount) AS metric_amount,
        'RETURNS' AS metric_type,
        CASE WHEN SUM(cr.cr_net_loss) > 5000 THEN 'HIGH_LOSS' ELSE 'LOW_LOSS' END AS category,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP BY GROUPING SETS ((d.d_year, cc.cc_state), (d.d_year), ())
)
SELECT *
FROM (
    SELECT d_year, cc_state, metric_amount, metric_type, category, rn
    FROM sales_agg
    UNION ALL
    SELECT d_year, cc_state, metric_amount, metric_type, category, rn
    FROM returns_agg
) combined
ORDER BY d_year DESC, metric_amount DESC
LIMIT 100
