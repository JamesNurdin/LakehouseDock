SELECT
    d_cr.d_fy_year AS fy_year,
    cc.cc_state AS state,
    p.p_promo_name AS promo_name,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory
FROM catalog_returns cr
JOIN date_dim d_cr
  ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN item i_cr
  ON cr.cr_item_sk = i_cr.i_item_sk
JOIN promotion p
  ON p.p_item_sk = i_cr.i_item_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer cust_refund
  ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
JOIN customer_demographics cd_refund
  ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer cust_return
  ON cr.cr_returning_customer_sk = cust_return.c_customer_sk
JOIN customer_demographics cd_return
  ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
JOIN customer_address ca_return
  ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
CROSS JOIN web_returns wr
JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN item i_wr
  ON wr.wr_item_sk = i_wr.i_item_sk
JOIN inventory inv
  ON inv.inv_item_sk = i_cr.i_item_sk
  AND inv.inv_date_sk = d_cr.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_cr.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_cr.d_date_sk
JOIN date_dim d_cc_open
  ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
  ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
GROUP BY GROUPING SETS (
    (d_cr.d_fy_year, cc.cc_state, p.p_promo_name),
    (d_cr.d_fy_year, cc.cc_state),
    (d_cr.d_fy_year),
    ()
)
ORDER BY fy_year, state, promo_name
LIMIT 100
