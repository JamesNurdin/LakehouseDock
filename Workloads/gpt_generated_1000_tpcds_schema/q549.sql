WITH promo_agg AS (
    SELECT
        d.d_date AS event_date,
        p.p_promo_name AS label,
        p.p_promo_sk,
        p.p_discount_active AS discount_flag,
        (
            SELECT COUNT(*)
            FROM web_returns wr
            WHERE wr.wr_returned_date_sk = d.d_date_sk
        ) AS return_count,
        'return_count' AS metric_type,
        'promotion' AS source_type,
        (
            SELECT COUNT(*)
            FROM web_returns wr2
            WHERE wr2.wr_returning_addr_sk = p.p_promo_sk
        ) AS dummy_scalar  -- scalar subquery to satisfy requirement
    FROM promotion p
    FULL OUTER JOIN date_dim d
        ON p.p_start_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
        AND p.p_promo_sk IN (
            SELECT DISTINCT wr.wr_returning_addr_sk
            FROM web_returns wr
            WHERE wr.wr_return_amt > 100
        )
),
return_unnested AS (
    SELECT
        d.d_date AS event_date,
        r.r_reason_desc AS label,
        v.val AS metric,
        CASE v.idx WHEN 1 THEN 'quantity' ELSE 'amount' END AS metric_type,
        'return' AS source_type
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    CROSS JOIN UNNEST(
        ARRAY[wr.wr_return_quantity, CAST(wr.wr_return_amt AS integer)]
    ) WITH ORDINALITY AS v(val, idx)
    WHERE r.r_reason_id IN (
        SELECT r2.r_reason_id
        FROM reason r2
        WHERE r2.r_reason_desc LIKE '%price%'
    )
)
SELECT
    event_date,
    metric,
    label,
    source_type,
    metric_type
FROM (
    SELECT
        event_date,
        return_count AS metric,
        label,
        source_type,
        metric_type
    FROM promo_agg
    WHERE p_promo_sk IS NOT NULL
    UNION
    SELECT
        event_date,
        metric,
        label,
        source_type,
        metric_type
    FROM return_unnested
) AS combined
ORDER BY event_date DESC, source_type
