WITH returns_agg AS (
    SELECT
        d.d_date AS event_date,
        'web_return' AS event_type,
        SUM(wr.wr_return_amt) AS total_return_amount,
        CAST(NULL AS BIGINT) AS closed_store_count,
        SUM(CASE WHEN wr.wr_return_amt > 100 THEN wr.wr_return_amt ELSE 0 END) AS high_return_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_fy_year = 1915
    GROUP BY d.d_date
),
store_closures_agg AS (
    SELECT
        d.d_date AS event_date,
        'store_closure' AS event_type,
        CAST(NULL AS decimal(7,2)) AS total_return_amount,
        COUNT(s.s_store_sk) AS closed_store_count,
        CAST(NULL AS decimal(7,2)) AS high_return_amount
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1915
    GROUP BY d.d_date
)
SELECT DISTINCT
    event_date,
    event_type,
    COALESCE(total_return_amount, CAST(0 AS decimal(7,2))) AS total_return_amount,
    COALESCE(closed_store_count, 0) AS closed_store_count,
    COALESCE(high_return_amount, CAST(0 AS decimal(7,2))) AS high_return_amount,
    CASE
        WHEN COALESCE(total_return_amount, 0) > 5000 OR COALESCE(closed_store_count, 0) > 10 THEN 'high'
        ELSE 'low'
    END AS impact_flag
FROM (
    SELECT
        event_date,
        event_type,
        total_return_amount,
        closed_store_count,
        high_return_amount
    FROM returns_agg
    UNION ALL
    SELECT
        event_date,
        event_type,
        total_return_amount,
        closed_store_count,
        high_return_amount
    FROM store_closures_agg
) AS combined
ORDER BY event_date DESC
LIMIT 100
