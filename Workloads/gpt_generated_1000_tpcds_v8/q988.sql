WITH sampled_returns AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
),

intersect_keys AS (
    SELECT sr_store_sk
    FROM sampled_returns
    WHERE sr_return_amt_inc_tax > 500
    INTERSECT
    SELECT s_store_sk
    FROM store
    WHERE s_tax_percentage > 5.00
),

joined_data AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_refunded_cash,
        d.d_year,
        d.d_quarter_seq,
        s.s_state,
        s.s_market_manager
    FROM sampled_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT *
        FROM store s
        WHERE s.s_store_sk = sr.sr_store_sk
    ) s
    WHERE sr.sr_store_sk IN (SELECT sr_store_sk FROM intersect_keys)
      AND EXISTS (
          SELECT 1
          FROM store s2
          WHERE s2.s_store_sk = sr.sr_store_sk
            AND s2.s_market_manager = 'Dean Morrison'
      )
      AND d.d_year BETWEEN 1999 AND 2001
      AND d.d_quarter_seq IN (5, 8, 12, 16)
      AND sr.sr_return_amt_inc_tax IS NOT NULL
),

expanded AS (
    SELECT
        jd.*,
        state_val
    FROM joined_data jd
    CROSS JOIN LATERAL (
        SELECT ARRAY[jd.s_state, concat('Region-', jd.s_state)] AS state_arr
    ) arr
    CROSS JOIN UNNEST(arr.state_arr) AS t(state_val)
),

cube_agg AS (
    SELECT
        d_year,
        d_quarter_seq,
        state_val,
        SUM(sr_return_amt_inc_tax) AS sum_return_amt,
        AVG(sr_refunded_cash) AS avg_refunded_cash,
        COUNT(*) AS cnt_returns
    FROM expanded
    GROUP BY CUBE (d_year, d_quarter_seq, state_val)
),

final_agg AS (
    SELECT
        d_year,
        d_quarter_seq,
        state_val,
        sum_return_amt,
        avg_refunded_cash,
        cnt_returns,
        sum_return_amt / NULLIF(cnt_returns, 0) AS avg_return_per_txn
    FROM cube_agg
    WHERE sum_return_amt > 1000
)

SELECT
    d_year,
    d_quarter_seq,
    state_val,
    sum_return_amt,
    avg_refunded_cash,
    cnt_returns,
    avg_return_per_txn
FROM final_agg
ORDER BY d_year DESC, d_quarter_seq, state_val
LIMIT 100
