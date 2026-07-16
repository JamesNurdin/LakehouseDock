SELECT
    d_ret.d_year AS return_year,
    d_ret.d_quarter_name AS return_quarter,
    (cc.cc_state || '-' || s.s_state) AS region_pair,
    p.p_channel_tv,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_promo_count,
    AVG(cc.cc_gmt_offset) AS avg_cc_gmt_offset,
    SUM(s.s_floor_space) AS total_store_floor_space
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_ret.d_year = 2022
  AND d_cc_closed.d_year = 2022
  AND d_cc_open.d_year = 2022
  AND d_promo_end.d_year = 2022
GROUP BY
    d_ret.d_year,
    d_ret.d_quarter_name,
    (cc.cc_state || '-' || s.s_state),
    p.p_channel_tv
ORDER BY total_net_loss DESC
LIMIT 100
