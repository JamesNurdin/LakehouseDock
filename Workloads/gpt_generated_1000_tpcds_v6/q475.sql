WITH agg_returns AS (
    SELECT
        sr_store_sk,
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_cdemo_sk,
        sr_reason_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
    GROUP BY sr_store_sk, sr_returned_date_sk, sr_return_time_sk, sr_cdemo_sk, sr_reason_sk
)
SELECT
    s.s_store_id,
    d_ret.d_year,
    d_closed.d_year AS closed_year,
    t.t_meal_time,
    cd.cd_education_status,
    r.r_reason_desc,
    agg.total_return_amt,
    agg.return_cnt,
    CASE
        WHEN agg.total_return_amt > (SELECT AVG(total_return_amt) FROM agg_returns) THEN 'High'
        ELSE 'Low'
    END AS return_level,
    RANK() OVER (PARTITION BY s.s_division_name ORDER BY agg.total_return_amt DESC) AS division_rank,
    ROW_NUMBER() OVER (ORDER BY agg.total_return_amt DESC) AS overall_rank
FROM agg_returns agg
JOIN store s
    ON agg.sr_store_sk = s.s_store_sk
JOIN date_dim d_ret
    ON agg.sr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON agg.sr_return_time_sk = t.t_time_sk
JOIN customer_demographics cd
    ON agg.sr_cdemo_sk = cd.cd_demo_sk
JOIN reason r
    ON agg.sr_reason_sk = r.r_reason_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_ret.d_year = 2001                         -- predicate 1
  AND t.t_meal_time = 'dinner'                    -- predicate 2
  AND cd.cd_education_status = 'Advanced Degree' -- predicate 3
  AND r.r_reason_desc = 'Damaged'                 -- predicate 4
  AND s.s_state = 'CA'                            -- predicate 5
  AND s.s_rec_start_date >= DATE '1999-01-01'    -- predicate 6
ORDER BY overall_rank
LIMIT 100
