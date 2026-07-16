SELECT
    agg.d_date,
    agg.store_id,
    agg.city,
    agg.state,
    agg.promo_name,
    agg.discount_active,
    agg.total_store_return_amt,
    agg.total_store_return_qty,
    agg.total_web_return_amt,
    agg.total_web_return_qty,
    agg.total_net_loss,
    agg.promo_start_year,
    agg.promo_end_year,
    agg.store_closure_date,
    ROW_NUMBER() OVER (ORDER BY agg.total_net_loss DESC) AS rank
FROM (
    SELECT
        d_ret.d_date,
        s.s_store_id AS store_id,
        s.s_city AS city,
        s.s_state AS state,
        p.p_promo_name AS promo_name,
        p.p_discount_active AS discount_active,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
        d_start.d_year AS promo_start_year,
        d_end.d_year AS promo_end_year,
        d_closure.d_date AS store_closure_date
    FROM date_dim d_ret
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_closure ON s.s_closed_date_sk = d_closure.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d_ret.d_date_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_ret.d_year = 2022
    GROUP BY
        d_ret.d_date,
        s.s_store_id,
        s.s_city,
        s.s_state,
        p.p_promo_name,
        p.p_discount_active,
        d_start.d_year,
        d_end.d_year,
        d_closure.d_date
) agg
ORDER BY rank
LIMIT 100
