/* Goal: Compare store and web return amounts by year, categorize them, and include a count of New York stores for context */
WITH ny_store_cte AS (
    SELECT COUNT(*) AS ny_store_cnt
    FROM store
    WHERE s_state = 'NY'
)
SELECT *
FROM (
    SELECT 
        d.d_year AS return_year,
        s.s_store_name AS store_name,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(sr.sr_return_amt_inc_tax) > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_category,
        (SELECT ny_store_cnt FROM ny_store_cte) AS ny_store_count
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, s.s_store_name

    UNION ALL

    SELECT 
        d.d_year AS return_year,
        'WEB' AS store_name,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(wr.wr_return_amt_inc_tax) > 5000 THEN 'HIGH' ELSE 'LOW' END AS return_category,
        (SELECT ny_store_cnt FROM ny_store_cte) AS ny_store_count
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
) AS combined
ORDER BY return_year DESC, total_return_inc_tax DESC
LIMIT 100
