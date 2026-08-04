WITH
sampled_returns AS (
    SELECT *
    FROM web_returns TABLESAMPLE BERNOULLI (10)
),
reason_keys AS (
    SELECT r_reason_sk FROM reason WHERE r_reason_sk BETWEEN 1 AND 20
),
returns_keys AS (
    SELECT wr_reason_sk FROM web_returns WHERE wr_return_amt > 0
),
intersect_keys AS (
    SELECT r_reason_sk FROM reason_keys
    INTERSECT
    SELECT wr_reason_sk FROM returns_keys
),
except_keys AS (
    SELECT r_reason_sk FROM reason_keys
    EXCEPT
    SELECT wr_reason_sk FROM returns_keys
),
agg AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        COUNT(*) AS cnt_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_tax) AS total_tax,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_id ORDER BY SUM(wr.wr_return_amt) DESC) AS rn
    FROM reason r
    JOIN sampled_returns wr
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
        r.r_reason_desc LIKE '%Package%'
        AND r.r_reason_id LIKE 'AAAAAAA%'
        AND wr.wr_return_quantity > 0
        AND wr.wr_return_amt BETWEEN 10 AND 1000
        AND wr.wr_return_tax IS NOT NULL
    GROUP BY r.r_reason_id, r.r_reason_desc
    HAVING COUNT(*) > 5
),
agg_enhanced AS (
    SELECT
        a.r_reason_id,
        a.r_reason_desc,
        a.cnt_returns,
        a.total_return_amt,
        a.total_tax,
        a.avg_return_inc_tax,
        a.rn,
        CASE WHEN a.total_return_amt > 5000 THEN 'HIGH' ELSE 'LOW' END AS amt_category,
        EXISTS (SELECT 1 FROM intersect_keys ik WHERE ik.r_reason_sk = a.rn) AS is_in_intersect,
        NOT EXISTS (SELECT 1 FROM except_keys ek WHERE ek.r_reason_sk = a.rn) AS not_in_except
    FROM agg a
),
full_joined AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        CAST(NULL AS integer) AS cnt_returns,
        CAST(NULL AS decimal(7,2)) AS total_return_amt,
        CAST(NULL AS decimal(7,2)) AS total_tax,
        CAST(NULL AS decimal(7,2)) AS avg_return_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_id ORDER BY r.r_reason_id) AS rn,
        NULL AS amt_category,
        FALSE AS is_in_intersect,
        FALSE AS not_in_except
    FROM reason r
    FULL OUTER JOIN sampled_returns wr
        ON wr.wr_reason_sk = r.r_reason_sk
),
right_joined AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        CAST(NULL AS integer) AS cnt_returns,
        CAST(NULL AS decimal(7,2)) AS total_return_amt,
        CAST(NULL AS decimal(7,2)) AS total_tax,
        CAST(NULL AS decimal(7,2)) AS avg_return_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY r.r_reason_id ORDER BY r.r_reason_id) AS rn,
        NULL AS amt_category,
        FALSE AS is_in_intersect,
        FALSE AS not_in_except
    FROM sampled_returns wr
    RIGHT OUTER JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
)
SELECT *
FROM (
    SELECT * FROM agg_enhanced
    UNION ALL
    SELECT * FROM full_joined
    UNION ALL
    SELECT * FROM right_joined
) final_result
ORDER BY total_return_amt DESC NULLS LAST, rn
LIMIT 100
