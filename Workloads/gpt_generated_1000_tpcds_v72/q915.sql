WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        sm.sm_type AS activity,
        SUM(cs.cs_net_paid) AS total_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE sm.sm_type = 'OVERNIGHT'
      AND cs.cs_net_paid > 1000
      AND EXISTS (
          SELECT 1
          FROM store s
          JOIN date_dim d_clos ON s.s_closed_date_sk = d_clos.d_date_sk
          WHERE d_clos.d_year = d.d_year
            AND s.s_state = 'CA'
      )
    GROUP BY d.d_year, sm.sm_type
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        'RETURN' AS activity,
        SUM(wr.wr_return_amt) AS total_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_return_tax > 50
    GROUP BY d.d_year
)
SELECT *
FROM (
    SELECT year, activity, total_amount FROM sales_agg
    UNION ALL
    SELECT year, activity, total_amount FROM returns_agg
) AS combined
ORDER BY year DESC, total_amount DESC
LIMIT 100
