WITH male_sales AS (
    SELECT
        d.d_year AS year,
        cd.cd_gender AS segment,
        SUM(ss.ss_ext_sales_price) AS metric_value
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND d.d_year = 2001
    GROUP BY d.d_year, cd.cd_gender
),
closed_cc AS (
    SELECT
        d.d_year AS year,
        cc.cc_state AS segment,
        CAST(COUNT(*) AS decimal(12,2)) AS metric_value
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE cc.cc_state = 'CA'
      AND d.d_year = 2001
    GROUP BY d.d_year, cc.cc_state
)
SELECT year, segment, metric_value
FROM male_sales
UNION ALL
SELECT year, segment, metric_value
FROM closed_cc
ORDER BY year DESC, metric_value DESC
LIMIT 100
