SELECT
    d_return.d_date AS return_date,
    s.s_store_name,
    s.s_city,
    cr.cr_return_amount,
    sr.sr_return_amt,
    (cr.cr_net_loss + sr.sr_net_loss) AS total_net_loss,
    p_start.p_promo_name AS promo_started,
    p_end.p_promo_name AS promo_ended,
    d_closed.d_year AS store_closed_year,
    COUNT(*) OVER (PARTITION BY s.s_store_sk) AS store_return_count,
    SUM(cr.cr_return_quantity) OVER (PARTITION BY s.s_store_sk) AS total_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY d_return.d_date DESC) AS rn
FROM date_dim d_return
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN promotion p_start
    ON p_start.p_start_date_sk = d_return.d_date_sk
LEFT JOIN promotion p_end
    ON p_end.p_end_date_sk = d_return.d_date_sk
WHERE d_return.d_year = 2020
  AND s.s_state = 'CA'
  AND cr.cr_return_amount > 0
ORDER BY total_net_loss DESC
LIMIT 100
