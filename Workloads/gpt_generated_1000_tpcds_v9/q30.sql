WITH recent_store_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2022
      AND d.d_current_year = 'Y'
    GROUP BY s.s_store_id, s.s_store_name, d.d_year
),
closed_store_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY s.s_store_id, s.s_store_name, d.d_year
)
SELECT DISTINCT
    store_id,
    store_name,
    year,
    total_return_amt
FROM (
    SELECT
        s_store_id AS store_id,
        s_store_name AS store_name,
        d_year AS year,
        total_return_amt
    FROM recent_store_returns
    UNION ALL
    SELECT
        s_store_id,
        s_store_name,
        d_year,
        total_return_amt
    FROM closed_store_returns
) AS combined
WHERE total_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns)
ORDER BY total_return_amt DESC
LIMIT 100
