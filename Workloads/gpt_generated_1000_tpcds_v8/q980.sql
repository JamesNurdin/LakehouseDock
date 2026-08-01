WITH full_join AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        sr.sr_return_amt,
        sr.sr_store_credit,
        sr.sr_return_ship_cost
    FROM customer c
    FULL OUTER JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year >= 1950
      AND c.c_birth_year <= 1990
      AND (sr.sr_store_credit IS NOT NULL AND sr.sr_store_credit > 30)
      AND (sr.sr_return_ship_cost IS NOT NULL AND sr.sr_return_ship_cost < 80)
),
per_customer AS (
    SELECT
        c_customer_sk,
        COUNT(*) AS txn_cnt,
        COALESCE(SUM(sr_return_amt), 0) AS sum_return
    FROM full_join
    GROUP BY c_customer_sk
),
union_set AS (
    SELECT c_customer_sk, sum_return FROM per_customer WHERE txn_cnt >= 3
    UNION
    SELECT c_customer_sk, sum_return FROM per_customer WHERE sum_return > 200
),
outer_agg AS (
    SELECT
        AVG(sum_return) AS avg_sum_return,
        MAX(sum_return) AS max_sum_return
    FROM union_set
    WHERE sum_return > (
        SELECT MIN(min_sum) FROM (
            SELECT SUM(sr_return_amt) AS min_sum
            FROM store_returns
            GROUP BY sr_customer_sk
        ) t
    )
)
SELECT
    u.c_customer_sk,
    u.sum_return,
    (
        SELECT SUM(sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = u.c_customer_sk
    ) AS correlated_total_return,
    oa.avg_sum_return,
    oa.max_sum_return
FROM union_set u
JOIN outer_agg oa ON u.sum_return = oa.max_sum_return
ORDER BY u.sum_return DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
