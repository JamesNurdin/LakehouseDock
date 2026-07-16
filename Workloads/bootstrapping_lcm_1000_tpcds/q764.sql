WITH promo_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_ret.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        d_ret.d_date AS return_date,
        d_ret.d_year,
        d_ret.d_month_seq,
        date_diff('day', d_ret.d_date, d_end.d_date) AS promo_duration_days,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_count,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN cr.cr_return_amount ELSE 0 END) AS total_return_with_active_discount
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_ret.d_date <= d_end.d_date
      AND s.s_state = 'CA'
      AND d_ret.d_year >= 2010
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_ret.d_date,
        d_end.d_date,
        d_ret.d_year,
        d_ret.d_month_seq
    HAVING SUM(cr.cr_return_amount) > 500
)
SELECT
    pr.*,
    ROW_NUMBER() OVER (PARTITION BY pr.s_store_id ORDER BY pr.total_return_amount DESC) AS rank_within_store
FROM promo_returns pr
ORDER BY pr.total_return_amount DESC
LIMIT 100
