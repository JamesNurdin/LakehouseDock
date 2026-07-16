WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_state,
        w.w_state,
        p.p_promo_name,
        p.p_cost,
        d_start.d_date AS promo_start_date,
        d_end.d_date   AS promo_end_date
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
)
, agg AS (
    SELECT
        d_year,
        d_month_seq,
        s_state,
        w_state,
        p_promo_name,
        COUNT(*) AS cnt_returns,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss)      AS total_net_loss,
        AVG(cr_return_quantity) AS avg_return_quantity,
        SUM(p_cost)           AS total_promo_cost,
        DATE_DIFF('day', promo_start_date, promo_end_date) AS promo_duration_days
    FROM base
    WHERE d_year >= 2000
    GROUP BY
        d_year,
        d_month_seq,
        s_state,
        w_state,
        p_promo_name,
        promo_start_date,
        promo_end_date
    HAVING SUM(cr_return_amount) > 1000
)
SELECT
    d_year,
    d_month_seq,
    s_state,
    w_state,
    p_promo_name,
    cnt_returns,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    total_promo_cost,
    promo_duration_days,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank_by_year
FROM agg
ORDER BY d_year, net_loss_rank_by_year
LIMIT 100
