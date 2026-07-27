WITH sales_data AS (
    SELECT
        cc.cc_country AS country,
        'sales' AS source,
        SUM(cs.cs_net_paid) AS total_amount,
        COUNT(DISTINCT cs.cs_order_number) AS unique_orders,
        CASE
            WHEN SUM(cs.cs_net_paid) > 100000 THEN 'high'
            ELSE 'normal'
        END AS revenue_category
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cc.cc_country = 'United States'
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_returning_customer_sk = c.c_customer_sk
            AND wr.wr_net_loss > 0
      )
    GROUP BY cc.cc_country
),
returns_data AS (
    SELECT
        r.r_reason_desc AS country,
        'returns' AS source,
        SUM(wr.wr_net_loss) AS total_amount,
        COUNT(DISTINCT wr.wr_order_number) AS unique_orders,
        CASE
            WHEN SUM(wr.wr_net_loss) > 50000 THEN 'high'
            ELSE 'normal'
        END AS revenue_category
    FROM web_returns wr
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE r.r_reason_desc IN (
        SELECT DISTINCT r2.r_reason_desc
        FROM reason r2
        JOIN web_returns wr2 ON wr2.wr_reason_sk = r2.r_reason_sk
        WHERE wr2.wr_net_loss > 0
    )
    GROUP BY r.r_reason_desc
)
SELECT DISTINCT *
FROM (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM returns_data
) combined
ORDER BY country, source
