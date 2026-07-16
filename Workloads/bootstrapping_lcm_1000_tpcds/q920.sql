SELECT
    d.d_year,
    d.d_quarter_name,
    s.s_market_desc,
    s.s_state,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    wp.wp_type,
    COUNT(*) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_fee) AS total_fees,
    AVG(hd_ret.hd_vehicle_count - hd_ref.hd_vehicle_count) AS avg_vehicle_diff,
    SUM(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_quantity ELSE 0 END) AS high_quantity_total
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
    AND wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1998 AND 2000
    AND s.s_market_desc IS NOT NULL
    AND wp.wp_type IS NOT NULL
GROUP BY
    d.d_year,
    d.d_quarter_name,
    s.s_market_desc,
    s.s_state,
    hd_ref.hd_buy_potential,
    hd_ret.hd_buy_potential,
    wp.wp_type
HAVING COUNT(*) > 20
ORDER BY total_net_loss DESC
LIMIT 100
