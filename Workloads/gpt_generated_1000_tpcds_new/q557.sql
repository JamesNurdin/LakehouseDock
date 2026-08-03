/* goal: Identify return performance by reason categories that match a specific pattern, compare two reason subsets (including vs. excluding the word "price"), and combine this with a small sampled date dimension using string manipulations, set operations, and a cross‑join to produce a ranked list of combined keys. */
WITH sampled_returns AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
),
date_small AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_moy = 6
    LIMIT 5
),
reason_inc AS (
    SELECT r_reason_sk, r_reason_desc, r_reason_id
    FROM reason
    WHERE regexp_like(r_reason_desc, '^Found a better')
),
reason_exc AS (
    SELECT r_reason_sk
    FROM reason
    WHERE regexp_like(r_reason_desc, '^Found a better')
      AND NOT regexp_like(r_reason_desc, 'price')
),
reason_diff AS (
    SELECT r_reason_sk FROM reason_inc
    EXCEPT
    SELECT r_reason_sk FROM reason_exc
),
cross_set AS (
    SELECT d.d_date_sk,
           d.d_date,
           v.val
    FROM date_small d
    CROSS JOIN (VALUES 'Alpha', 'Beta') AS v(val)
),
union_agg AS (
    SELECT
        'diff' AS cat,
        COUNT(*) AS cnt,
        SUM(sr.sr_return_amt) AS total_amt,
        MIN(r.r_reason_desc) AS sample_desc
    FROM sampled_returns sr
    JOIN reason_diff rd ON sr.sr_reason_sk = rd.r_reason_sk
    JOIN reason r ON r.r_reason_sk = rd.r_reason_sk
    UNION
    SELECT
        'inc' AS cat,
        COUNT(*) AS cnt,
        SUM(sr.sr_return_amt) AS total_amt,
        MIN(r.r_reason_desc) AS sample_desc
    FROM sampled_returns sr
    JOIN reason_inc ri ON sr.sr_reason_sk = ri.r_reason_sk
    JOIN reason r ON r.r_reason_sk = ri.r_reason_sk
)
SELECT
    cs.d_date,
    cs.val,
    ua.cat,
    ua.cnt,
    ua.total_amt,
    concat(r.r_reason_id, '-', cs.val) AS combined_key,
    substring(r.r_reason_desc, 1, 10) AS desc_prefix,
    CASE
        WHEN regexp_like(r.r_reason_desc, 'price') THEN 'has_price'
        ELSE 'no_price'
    END AS price_flag
FROM union_agg ua
JOIN cross_set cs ON true
LEFT JOIN reason r ON (
    (ua.cat = 'diff' AND r.r_reason_sk IN (SELECT r_reason_sk FROM reason_diff))
    OR (ua.cat = 'inc' AND r.r_reason_sk IN (SELECT r_reason_sk FROM reason_inc))
)
WHERE cs.val LIKE '%a%'
ORDER BY ua.total_amt DESC
LIMIT 100
