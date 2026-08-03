WITH sales_yearly AS (
    SELECT
        d.d_year,
        SUM(cs.cs_net_profit) AS metric_value,
        COUNT(*) AS record_cnt,
        'sales' AS source
    FROM catalog_sales cs
    RIGHT JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND cs.cs_quantity > 1
    GROUP BY d.d_year
    HAVING SUM(cs.cs_net_profit) > (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_quantity > 0
    )
),
returns_yearly AS (
    SELECT
        d.d_year,
        -SUM(sr.sr_net_loss) AS metric_value,
        COUNT(*) AS record_cnt,
        'returns' AS source
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%did not like%'
      AND d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year
)
SELECT * FROM sales_yearly
UNION ALL
SELECT * FROM returns_yearly
ORDER BY d_year, metric_value DESC
LIMIT 100
