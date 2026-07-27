WITH distinct_edu AS (
    SELECT DISTINCT cd.cd_education_status
    FROM customer_demographics cd
    WHERE regexp_like(cd.cd_education_status, '^A')
),
sales_agg AS (
    SELECT
        cd.cd_education_status,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN distinct_edu de ON cd.cd_education_status = de.cd_education_status
    WHERE d.d_year = 2000
      AND cd.cd_education_status LIKE '%Degree'
    GROUP BY cd.cd_education_status
),
returns_agg AS (
    SELECT
        cd.cd_education_status,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_returns
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN distinct_edu de ON cd.cd_education_status = de.cd_education_status
    WHERE d2.d_year = 2000
      AND regexp_like(cd.cd_education_status, 'Degree$')
    GROUP BY cd.cd_education_status
)
SELECT
    s.cd_education_status,
    SUBSTR(s.cd_education_status, 1, 3) AS edu_prefix,
    s.total_profit,
    r.total_return_loss,
    (s.total_profit - COALESCE(r.total_return_loss, 0)) AS net_contribution,
    s.distinct_orders,
    COALESCE(r.distinct_returns, 0) AS distinct_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cd_education_status = r.cd_education_status
ORDER BY net_contribution DESC
LIMIT 100
