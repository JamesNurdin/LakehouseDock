SELECT
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    hd.hd_income_band_sk,
    p.p_promo_name,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN sr.sr_net_loss ELSE 0 END) AS discount_active_net_loss,
    MIN(d_ret.d_date) AS first_return_date,
    MAX(d_ret.d_date) AS last_return_date
FROM store_returns AS sr
JOIN date_dim AS d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics AS hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN store AS s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim AS d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion AS p
    ON p.p_start_date_sk <= d_ret.d_date_sk
   AND p.p_end_date_sk >= d_ret.d_date_sk
JOIN date_dim AS d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim AS d_end
    ON p.p_end_date_sk = d_end.d_date_sk
WHERE d_ret.d_year = 2022
  AND d_closed.d_date IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    hd.hd_income_band_sk,
    p.p_promo_name
HAVING SUM(sr.sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 50
