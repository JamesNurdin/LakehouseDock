WITH web_rev AS (
    SELECT
        d.d_year AS year,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        CAST('web' AS VARCHAR) AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
),
store_rev AS (
    SELECT
        d.d_year AS year,
        SUM(ss.ss_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        CAST('store' AS VARCHAR) AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
)
SELECT * FROM web_rev
UNION ALL
SELECT * FROM store_rev
ORDER BY year, channel
