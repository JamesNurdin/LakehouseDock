WITH
    sampled_returns AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    joined_base AS (
        SELECT
            sr.sr_customer_sk,
            sr.sr_return_amt_inc_tax,
            sr.sr_reason_sk,
            sr.sr_return_time_sk,
            sr.sr_return_quantity,
            t.t_time_id,
            t.t_shift,
            t.t_second,
            c.c_birth_month,
            c.c_first_name,
            c.c_last_name
        FROM sampled_returns sr
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        WHERE t.t_time_id = 'AAAAAAAACAAAAAAA'
          AND t.t_shift = 'first'
          AND t.t_second BETWEEN 5 AND 20
          AND c.c_birth_month IN (5, 6, 8)
          AND sr.sr_reason_sk IN (10, 41)
    ),
    expanded AS (
        SELECT
            jb.*, 
            reason_code
        FROM joined_base jb
        CROSS JOIN UNNEST(ARRAY[
            jb.sr_reason_sk,
            jb.sr_reason_sk + 10
        ]) AS t(reason_code)
    ),
    agg_high AS (
        SELECT
            c_birth_month,
            t_shift,
            COUNT(*) AS cnt,
            SUM(sr_return_amt_inc_tax) AS total_amt
        FROM expanded
        WHERE sr_return_amt_inc_tax > 200
        GROUP BY c_birth_month, t_shift
        HAVING COUNT(*) > 2
    ),
    agg_low AS (
        SELECT
            c_birth_month,
            t_shift,
            COUNT(*) AS cnt,
            SUM(sr_return_amt_inc_tax) AS total_amt
        FROM expanded
        WHERE sr_return_amt_inc_tax <= 200
        GROUP BY c_birth_month, t_shift
        HAVING COUNT(*) > 2
    ),
    unioned AS (
        SELECT c_birth_month, t_shift, cnt FROM agg_high
        UNION
        SELECT c_birth_month, t_shift, cnt FROM agg_low
    ),
    agg_all AS (
        SELECT
            c_birth_month,
            t_shift,
            COUNT(*) AS total_groups,
            SUM(cnt) AS sum_cnt
        FROM unioned
        GROUP BY c_birth_month, t_shift
    )
SELECT *
FROM (
    SELECT c_birth_month, t_shift FROM agg_all
) a
INTERSECT
SELECT c_birth_month, t_shift FROM agg_high
LIMIT 100
