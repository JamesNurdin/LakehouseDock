WITH agg_returns AS (
    SELECT
        sr_store_sk,
        sr_return_time_sk,
        COUNT(*) AS cnt_returns,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_qty
    FROM store_returns
    WHERE sr_return_quantity > 1
      AND sr_fee > 20
      AND sr_reversed_charge < 30
    GROUP BY sr_store_sk, sr_return_time_sk
),
expanded AS (
    SELECT
        ar.sr_store_sk,
        ar.sr_return_time_sk,
        ar.cnt_returns,
        ar.total_return_amt,
        val AS metric_value,
        CASE 
            WHEN val > 50 THEN 'high'
            WHEN val BETWEEN 20 AND 50 THEN 'medium'
            ELSE 'low'
        END AS metric_level
    FROM agg_returns ar
    CROSS JOIN UNNEST(array[ ar.total_return_amt, ar.avg_qty * 10 ]) AS t(val)
),
joined AS (
    SELECT
        e.sr_store_sk,
        e.sr_return_time_sk,
        e.cnt_returns,
        e.total_return_amt,
        e.metric_value,
        e.metric_level,
        t.t_time_id,
        t.t_minute,
        t.t_second,
        ROW_NUMBER() OVER (PARTITION BY e.sr_store_sk ORDER BY e.total_return_amt DESC) AS rn
    FROM expanded e
    JOIN time_dim t
        ON e.sr_return_time_sk = t.t_time_sk
    WHERE t.t_minute BETWEEN 0 AND 20
      AND t.t_second < 10
      AND t.t_am_pm = 'AM'
),
keys_a AS (
    SELECT sr_store_sk FROM joined WHERE rn <= 5
),
keys_b AS (
    SELECT sr_store_sk FROM joined WHERE metric_level = 'high'
),
intersect_keys AS (
    SELECT sr_store_sk FROM keys_a
    INTERSECT
    SELECT sr_store_sk FROM keys_b
),
except_keys AS (
    SELECT sr_store_sk FROM keys_a
    EXCEPT
    SELECT sr_store_sk FROM keys_b
)
SELECT
    j.sr_store_sk,
    j.t_time_id,
    j.cnt_returns,
    j.total_return_amt,
    j.metric_value,
    j.metric_level,
    j.rn,
    CASE
        WHEN ik.sr_store_sk IS NOT NULL THEN 'in_both'
        WHEN ek.sr_store_sk IS NOT NULL THEN 'only_a'
        ELSE 'other'
    END AS membership
FROM joined j
LEFT JOIN intersect_keys ik ON j.sr_store_sk = ik.sr_store_sk
LEFT JOIN except_keys ek ON j.sr_store_sk = ek.sr_store_sk
WHERE ik.sr_store_sk IS NOT NULL OR ek.sr_store_sk IS NOT NULL
ORDER BY j.total_return_amt DESC, j.sr_store_sk
