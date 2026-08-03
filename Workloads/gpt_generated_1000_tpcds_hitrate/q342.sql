WITH filtered_returns AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
    WHERE sr_return_amt > 100
)
SELECT activity_date,
       category,
       total_amount
FROM (
    -- Store returns aggregated by date and shift
    SELECT
        d.d_date AS activity_date,
        t.t_shift AS category,
        SUM(fr.sr_return_amt) AS total_amount
    FROM filtered_returns fr
    JOIN date_dim d ON fr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON fr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_shift = 'second'
      AND d.d_year = 2001
    GROUP BY d.d_date, t.t_shift
    HAVING SUM(fr.sr_return_amt) > 500

    UNION ALL

    -- Call centre employee totals aggregated by date and division
    SELECT
        d.d_date AS activity_date,
        cc.cc_division_name AS category,
        SUM(cc.cc_employees) AS total_amount
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE cc.cc_employees > 50
      AND d.d_year = 2001
      AND cc.cc_suite_number = 'Suite 310'
    GROUP BY d.d_date, cc.cc_division_name
    HAVING SUM(cc.cc_employees) > 500
) AS combined
ORDER BY total_amount DESC
LIMIT 100
