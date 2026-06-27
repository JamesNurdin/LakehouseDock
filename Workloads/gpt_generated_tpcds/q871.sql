WITH sales_and_returns AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        d.d_month_seq,
        ss.ss_net_profit,
        sr.sr_net_loss
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN date_dim dr
        ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d.d_date BETWEEN d_start.d_date AND d_end.d_date
)
SELECT
    p_promo_id,
    d_year,
    d_month_seq,
    sum(ss_net_profit) AS total_store_profit,
    sum(COALESCE(sr_net_loss, 0)) AS total_store_return_loss,
    sum(ss_net_profit) - sum(COALESCE(sr_net_loss, 0)) AS net_contribution
FROM sales_and_returns
GROUP BY p_promo_id, d_year, d_month_seq
ORDER BY d_year, d_month_seq, p_promo_id
