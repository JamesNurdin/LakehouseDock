SELECT
    agg.s_store_id,
    agg.s_store_name,
    agg.p_promo_name,
    agg.r_reason_desc,
    agg.return_year,
    agg.return_month_seq,
    agg.total_returns,
    agg.total_quantity,
    agg.total_net_loss,
    agg.total_return_amount,
    RANK() OVER (PARTITION BY agg.s_store_id, agg.return_year, agg.return_month_seq ORDER BY agg.total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        p.p_promo_name,
        r.r_reason_desc,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    CROSS JOIN promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk IS NOT NULL
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_ret.d_date BETWEEN d_start.d_date AND d_end.d_date
      AND d_ret.d_date <= d_closed.d_date
      AND p.p_discount_active = 'Y'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        p.p_promo_name,
        r.r_reason_desc,
        d_ret.d_year,
        d_ret.d_month_seq
) agg
ORDER BY agg.s_store_id, agg.return_year, agg.return_month_seq, net_loss_rank
