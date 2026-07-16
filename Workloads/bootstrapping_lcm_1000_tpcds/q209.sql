SELECT
    d.d_date,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(cr.cr_return_ship_cost) AS total_catalog_ship_cost,
    SUM(cr.cr_fee) AS total_catalog_fee,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(wr.wr_return_ship_cost) AS total_web_ship_cost,
    SUM(wr.wr_fee) AS total_web_fee,
    AVG(cr.cr_return_tax) AS avg_catalog_return_tax,
    AVG(wr.wr_return_tax) AS avg_web_return_tax
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY
    d.d_date,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    s.s_state
ORDER BY d.d_date DESC
LIMIT 100
