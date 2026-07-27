WITH sales_agg AS (
    SELECT 
        d.d_year AS year,
        cd.cd_education_status AS education_status,
        SUM(ss.ss_net_profit) AS metric_amount,
        'sales' AS source
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_weekend = 'Y'
      AND cd.cd_education_status = 'College'
    GROUP BY d.d_year, cd.cd_education_status
),
returns_agg AS (
    SELECT 
        d.d_year AS year,
        cd.cd_education_status AS education_status,
        SUM(cr.cr_net_loss) AS metric_amount,
        'returns' AS source
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_weekend = 'Y'
      AND cd.cd_education_status = 'College'
    GROUP BY d.d_year, cd.cd_education_status
)
SELECT year,
       education_status,
       metric_amount,
       source
FROM sales_agg
UNION ALL
SELECT year,
       education_status,
       metric_amount,
       source
FROM returns_agg
ORDER BY year DESC, source ASC, metric_amount DESC
LIMIT 100
