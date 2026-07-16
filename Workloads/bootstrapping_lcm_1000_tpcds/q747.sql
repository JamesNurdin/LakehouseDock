SELECT
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    CASE
        WHEN d_ret.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_ret.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_ret.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter_label,
    p.p_promo_name,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    SUM(sr.sr_return_amt) AS total_return_amt,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(p.p_cost) AS total_promo_cost,
    ROUND(
        CASE
            WHEN SUM(p.p_cost) = 0 THEN NULL
            ELSE SUM(sr.sr_return_amt) / SUM(p.p_cost)
        END,
        2
    ) AS return_to_promo_cost_ratio,
    GROUPING(s.s_store_id) AS grp_store,
    GROUPING(p.p_promo_name) AS grp_promo
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p
    ON sr.sr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE (s.s_closed_date_sk IS NULL OR s.s_closed_date_sk > sr.sr_returned_date_sk)
GROUP BY ROLLUP(s.s_store_id, s.s_store_name, d_ret.d_year, d_ret.d_month_seq, p.p_promo_name)
ORDER BY s.s_store_id, d_ret.d_year, d_ret.d_month_seq, p.p_promo_name
