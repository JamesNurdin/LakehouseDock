WITH closed_by_year AS (
    SELECT
        s.s_state AS state,
        d.d_year AS year,
        COUNT(*) AS store_cnt,
        AVG(s.s_tax_percentage) AS avg_tax,
        'YearRange' AS source
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
    GROUP BY s.s_state, d.d_year
),
closed_on_weekend AS (
    SELECT
        s.s_state AS state,
        d.d_year AS year,
        COUNT(*) AS store_cnt,
        AVG(s.s_tax_percentage) AS avg_tax,
        'Weekend' AS source
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_weekend = 'Y'
    GROUP BY s.s_state, d.d_year
)
SELECT state,
       year,
       store_cnt,
       avg_tax,
       source
FROM closed_by_year
UNION ALL
SELECT state,
       year,
       store_cnt,
       avg_tax,
       source
FROM closed_on_weekend
ORDER BY state, year, source
LIMIT 100
