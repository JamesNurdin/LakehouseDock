WITH morning_returns AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_category AS category,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'morning'
      AND EXISTS (
          SELECT 1 FROM store s2
          WHERE s2.s_store_sk = s.s_store_sk
            AND s2.s_number_employees > 50
      )
    GROUP BY s.s_store_name, i.i_category
),

evening_color_returns AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_category AS category,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE t.t_sub_shift = 'evening'
      AND r.r_reason_desc LIKE '%color%'
    GROUP BY s.s_store_name, i.i_category
),

combined AS (
    SELECT store_name, category, total_return_amt FROM morning_returns
    UNION ALL
    SELECT store_name, category, total_return_amt FROM evening_color_returns
)
SELECT DISTINCT
    c.store_name,
    c.category,
    c.total_return_amt,
    (SELECT AVG(sr2.sr_return_amt) FROM store_returns sr2) AS avg_return_amt_all
FROM combined c
ORDER BY c.total_return_amt DESC
LIMIT 100
