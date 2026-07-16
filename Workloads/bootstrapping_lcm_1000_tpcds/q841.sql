SELECT
    p.p_promo_id,
    p.p_promo_name,
    d_start.d_year AS promo_start_year,
    d_end.d_year AS promo_end_year,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_closed.d_year AS store_closed_year,
    CASE WHEN d_start.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS promo_start_day_type,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_txns,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(sr.sr_net_loss) AS store_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_txns,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(p.p_cost) AS total_promotion_cost,
    CASE 
        WHEN SUM(p.p_cost) = 0 THEN NULL
        ELSE (SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt)) / SUM(p.p_cost)
    END AS return_to_promo_cost_ratio
FROM promotion p
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_start.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_end.d_date_sk
WHERE d_start.d_year = 2020
  AND d_end.d_year = 2020
  AND s.s_state = 'TX'
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    d_start.d_year,
    d_end.d_year,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_closed.d_year,
    d_start.d_weekend
ORDER BY store_return_amount DESC
LIMIT 100
