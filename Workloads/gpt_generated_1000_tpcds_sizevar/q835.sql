WITH
    sampled_returns AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    reason_filtered AS (
        SELECT
            r_reason_sk,
            r_reason_id,
            regexp_extract(r_reason_desc, '(\\w+)', 1) AS extracted_word,
            r_reason_desc
        FROM reason
        WHERE r_reason_desc LIKE '%customer%'
          AND regexp_like(r_reason_id, '^A{8}C')
    ),
    store_keys_a AS (
        SELECT DISTINCT sr_store_sk
        FROM sampled_returns
        WHERE sr_return_amt_inc_tax > 200
    ),
    store_keys_b AS (
        SELECT DISTINCT sr_store_sk
        FROM sampled_returns
        WHERE sr_return_quantity > 5
    ),
    intersected_stores AS (
        SELECT sr_store_sk
        FROM store_keys_a
        INTERSECT
        SELECT sr_store_sk
        FROM store_keys_b
    ),
    small_time AS (
        SELECT DISTINCT t_hour, t_minute
        FROM time_dim
        WHERE t_hour BETWEEN 9 AND 12
    ),
    computed_numbers AS (
        SELECT 1 AS num UNION ALL SELECT 2 UNION ALL SELECT 3
    ),
    cross_join_set AS (
        SELECT t_hour, t_minute, num
        FROM small_time
        CROSS JOIN computed_numbers
    ),
    final AS (
        SELECT
            s.s_store_sk,
            concat(s.s_store_name, ' - ', s.s_city) AS store_full_name,
            r.r_reason_desc,
            r.extracted_word,
            SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
            AVG(sr.sr_reversed_charge) AS avg_reversed_charge,
            COUNT(*) AS return_count
        FROM sampled_returns sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN reason_filtered r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
        JOIN intersected_stores isr ON sr.sr_store_sk = isr.sr_store_sk
        JOIN cross_join_set cjs ON td.t_hour = cjs.t_hour
        WHERE s.s_store_name LIKE '%Store%'
          AND cjs.num = 2
          AND sr.sr_store_sk IN (SELECT s_store_sk FROM store WHERE s_state = 'CA')
        GROUP BY
            s.s_store_sk,
            s.s_store_name,
            s.s_city,
            r.r_reason_desc,
            r.extracted_word
    )
SELECT *
FROM final
ORDER BY total_return_inc_tax DESC
LIMIT 100
