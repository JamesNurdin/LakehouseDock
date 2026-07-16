WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        d_ret.d_year,
        COUNT(DISTINCT wr.wr_order_number) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(p.p_cost) AS avg_promo_cost
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_ret.d_year BETWEEN 2020 AND 2022
    GROUP BY
        s.s_store_id,
        s.s_city,
        s.s_state,
        p.p_promo_id,
        p.p_promo_name,
        d_start.d_date,
        d_end.d_date,
        d_ret.d_year
    HAVING SUM(wr.wr_return_amt) > 500
)
SELECT
    agg.s_store_id,
    agg.s_city,
    agg.s_state,
    agg.p_promo_id,
    agg.p_promo_name,
    agg.promo_start_date,
    agg.promo_end_date,
    agg.d_year,
    agg.num_returns,
    agg.total_return_amount,
    agg.total_net_loss,
    agg.avg_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY agg.s_store_id ORDER BY agg.total_net_loss DESC) AS loss_rank_per_store
FROM agg
ORDER BY agg.total_net_loss DESC
LIMIT 100
