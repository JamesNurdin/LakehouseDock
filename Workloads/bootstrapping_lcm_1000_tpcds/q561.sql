SELECT
    cc.cc_market_manager,
    s.s_state,
    cd_ref.cd_gender,
    EXTRACT(year FROM dr.d_date) AS return_year,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    SUM(CASE WHEN cr.cr_return_quantity > 1 THEN cr.cr_return_quantity ELSE 0 END) AS total_multi_item_returns,
    SUM(CASE WHEN cd_ref.cd_marital_status = 'M' THEN cr.cr_return_amount ELSE 0 END) AS marital_m_return_amount,
    SUM(CASE WHEN cd_ret.cd_marital_status = 'S' THEN cr.cr_return_amount ELSE 0 END) AS marital_s_return_amount
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = dr.d_date_sk
JOIN date_dim dcc
    ON cc.cc_closed_date_sk = dcc.d_date_sk
JOIN date_dim dco
    ON cc.cc_open_date_sk = dco.d_date_sk
GROUP BY
    cc.cc_market_manager,
    s.s_state,
    cd_ref.cd_gender,
    EXTRACT(year FROM dr.d_date)
ORDER BY total_net_loss DESC
LIMIT 100
