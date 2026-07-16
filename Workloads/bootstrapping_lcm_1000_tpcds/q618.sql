SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    dr.d_year AS return_year,
    hd.hd_buy_potential,
    hd.hd_income_band_sk,
    COUNT(*) AS total_returns,
    SUM(sr.sr_return_amt) AS sum_return_amount,
    SUM(sr.sr_net_loss) AS sum_net_loss,
    AVG(CAST(hd.hd_vehicle_count AS double)) AS avg_vehicle_count,
    MIN(dr.d_date) AS first_return_date,
    MAX(dr.d_date) AS last_return_date,
    CASE 
        WHEN SUM(sr.sr_return_amt) = 0 THEN 0
        ELSE SUM(sr.sr_net_loss) / SUM(sr.sr_return_amt)
    END AS net_loss_ratio
FROM store_returns sr
JOIN date_dim dr
    ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dc
    ON s.s_closed_date_sk = dc.d_date_sk
JOIN promotion p
    ON dr.d_date_sk = p.p_start_date_sk
JOIN date_dim de
    ON p.p_end_date_sk = de.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND dr.d_date <= dc.d_date
  AND dr.d_date <= de.d_date
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    p.p_promo_id,
    p.p_promo_name,
    dr.d_year,
    hd.hd_buy_potential,
    hd.hd_income_band_sk
ORDER BY sum_net_loss DESC
LIMIT 100
