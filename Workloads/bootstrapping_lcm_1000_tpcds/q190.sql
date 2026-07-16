SELECT
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    s.s_state,
    hd_refunded.hd_buy_potential AS refunded_buy_potential,
    hd_returning.hd_buy_potential AS returning_buy_potential,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_value_returns,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MAX(cr.cr_returned_date_sk) AS max_return_date_sk
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND sm.sm_type IN ('AIR', 'GROUND')
GROUP BY
    d.d_year,
    d.d_month_seq,
    sm.sm_type,
    s.s_state,
    hd_refunded.hd_buy_potential,
    hd_returning.hd_buy_potential
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
