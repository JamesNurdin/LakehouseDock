SELECT
    s.s_store_id,
    cc.cc_name,
    p.p_promo_name,
    d.d_year,
    d.d_month_seq,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    AVG(cr.cr_return_quantity) AS avg_return_qty,
    SUM(CASE WHEN cr.cr_return_amt_inc_tax > 200 THEN cr.cr_return_amt_inc_tax ELSE 0 END) AS high_value_return_amt,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND cc.cc_state = 'CA'
GROUP BY
    s.s_store_id,
    cc.cc_name,
    p.p_promo_name,
    d.d_year,
    d.d_month_seq,
    CASE WHEN d.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END
ORDER BY total_return_amount DESC
LIMIT 100
