WITH store_monthly_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_ret.d_year,
        d_ret.d_current_month,
        d_closed.d_current_month AS store_closed_month,
        d_end.d_current_month AS promo_end_month,
        COUNT(*) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(t.t_hour + t.t_minute / 60.0) AS avg_return_hour,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_active_promo_cost,
        MAX(p.p_promo_name) FILTER (WHERE p.p_discount_active = 'Y') AS any_active_promo_name
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d_ret.d_year,
        d_ret.d_current_month,
        d_closed.d_current_month,
        d_end.d_current_month
)
SELECT
    smr.s_store_id,
    smr.s_store_name,
    smr.s_city,
    smr.s_state,
    smr.d_year,
    smr.d_current_month,
    smr.total_returns,
    smr.total_return_amount,
    smr.total_net_loss,
    smr.avg_return_hour,
    smr.total_active_promo_cost,
    smr.any_active_promo_name,
    smr.store_closed_month,
    smr.promo_end_month,
    ROW_NUMBER() OVER (PARTITION BY smr.d_year, smr.d_current_month ORDER BY smr.total_net_loss DESC) AS rank_by_net_loss
FROM store_monthly_returns smr
ORDER BY smr.d_year, smr.d_current_month, rank_by_net_loss
LIMIT 100
