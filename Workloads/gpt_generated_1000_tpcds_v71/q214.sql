WITH promo_costs AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        d.d_week_seq,
        p.p_cost
    FROM promotion p
    JOIN date_dim d
        ON p.p_start_date_sk = d.d_date_sk
    WHERE p.p_discount_active = 'Y'
)
SELECT
    'ClosedStoreReturn' AS return_type,
    s.s_store_id,
    d.d_date,
    SUM(wr.wr_return_amt) AS total_return_amount,
    (
        SELECT AVG(wr2.wr_return_amt)
        FROM web_returns wr2
    ) AS avg_return_amount_overall
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE s.s_state = 'CA'
  AND d.d_week_seq IN (4, 8, 14)
GROUP BY s.s_store_id, d.d_date

UNION ALL

SELECT
    'PromoReturn' AS return_type,
    p.p_promo_id,
    d2.d_date,
    SUM(wr2.wr_return_amt) AS total_return_amount,
    (
        SELECT AVG(wr3.wr_return_amt)
        FROM web_returns wr3
    ) AS avg_return_amount_overall
FROM web_returns wr2
JOIN date_dim d2
    ON wr2.wr_returned_date_sk = d2.d_date_sk
JOIN promotion p
    ON d2.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
WHERE p.p_channel_tv = 'Y'
  AND d2.d_current_quarter = 'Y'
GROUP BY p.p_promo_id, d2.d_date
HAVING SUM(wr2.wr_return_amt) > (
    SELECT AVG(wr4.wr_return_amt)
    FROM web_returns wr4
)

ORDER BY total_return_amount DESC
LIMIT 100
