SELECT
    s.s_store_id,
    s.s_store_name,
    p.p_promo_name,
    d_start.d_year AS promo_start_year,
    d_end.d_year AS promo_end_year,
    d_return.d_year AS return_year,
    COUNT(*) AS num_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    MIN(d_return.d_date) AS earliest_return_date,
    MAX(d_return.d_date) AS latest_return_date
FROM promotion p
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    p.p_promo_name,
    d_start.d_year,
    d_end.d_year,
    d_return.d_year
ORDER BY total_net_loss DESC
LIMIT 100
