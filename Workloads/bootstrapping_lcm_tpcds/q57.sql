WITH agg AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p_start.p_promo_id,
        p_start.p_promo_name,
        p_end.p_promo_id AS p_end_id,
        d_closed.d_date AS store_closed_date,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN s.s_closed_date_sk IS NOT NULL THEN 1 ELSE 0 END AS is_store_closed
    FROM date_dim d
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN promotion p_start ON p_start.p_start_date_sk = d.d_date_sk
    LEFT JOIN promotion p_end ON p_end.p_end_date_sk = d.d_date_sk
    LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        p_start.p_promo_id,
        p_start.p_promo_name,
        p_end.p_promo_id,
        d_closed.d_date,
        s.s_closed_date_sk
)
SELECT
    a.d_date,
    a.d_year,
    a.d_month_seq,
    a.d_day_name,
    a.s_store_id,
    a.s_store_name,
    a.s_state,
    a.p_promo_id,
    a.p_promo_name,
    a.p_end_id,
    a.store_closed_date,
    a.total_store_return_amt,
    a.total_web_return_amt,
    a.total_return_amt,
    a.total_store_net_loss,
    a.total_web_net_loss,
    a.total_net_loss,
    a.is_store_closed,
    ROW_NUMBER() OVER (PARTITION BY a.p_promo_id ORDER BY a.total_return_amt DESC) AS rank_within_promo
FROM agg a
ORDER BY a.total_return_amt DESC
LIMIT 100
