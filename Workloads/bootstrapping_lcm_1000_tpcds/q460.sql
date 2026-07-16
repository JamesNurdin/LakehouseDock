SELECT
    d.d_year,
    CASE 
        WHEN d.d_moy IN (12, 1, 2) THEN 'Winter'
        WHEN d.d_moy IN (3, 4, 5) THEN 'Spring'
        WHEN d.d_moy IN (6, 7, 8) THEN 'Summer'
        WHEN d.d_moy IN (9, 10, 11) THEN 'Fall'
    END AS season,
    s.s_division_name,
    hd.hd_buy_potential,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
    SUM(p.p_cost) AS total_promo_cost,
    SUM(p.p_cost) / NULLIF(SUM(wr.wr_return_amt), 0) AS promo_cost_to_return_ratio,
    CASE WHEN SUM(wr.wr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = wr.wr_refunded_hdemo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year >= 2000
GROUP BY
    d.d_year,
    CASE 
        WHEN d.d_moy IN (12, 1, 2) THEN 'Winter'
        WHEN d.d_moy IN (3, 4, 5) THEN 'Spring'
        WHEN d.d_moy IN (6, 7, 8) THEN 'Summer'
        WHEN d.d_moy IN (9, 10, 11) THEN 'Fall'
    END,
    s.s_division_name,
    hd.hd_buy_potential
ORDER BY total_net_loss DESC
LIMIT 100
