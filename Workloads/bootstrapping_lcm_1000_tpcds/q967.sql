WITH aggregated AS (
    SELECT
        cc.cc_name AS cc_name,
        cc.cc_gmt_offset AS cc_gmt_offset,
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        p.p_promo_name AS p_promo_name,
        d_ret.d_date AS d_date,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
        AVG(p.p_cost) AS avg_promotion_cost
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_ret.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE d_ret.d_year = 2022
    GROUP BY
        cc.cc_name,
        cc.cc_gmt_offset,
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        d_ret.d_date
)
SELECT
    cc_name,
    cc_gmt_offset,
    s_store_name,
    s_state,
    p_promo_name,
    d_date,
    total_return_amount,
    total_net_loss,
    distinct_returns,
    avg_promotion_cost,
    RANK() OVER (PARTITION BY d_date ORDER BY total_return_amount DESC) AS return_rank
FROM aggregated
ORDER BY total_return_amount DESC
LIMIT 100
