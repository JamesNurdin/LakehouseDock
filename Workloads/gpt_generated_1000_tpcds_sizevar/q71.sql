WITH aggregated AS (
  SELECT
    ws_site.web_name AS web_name,
    cc.cc_name AS call_center_name,
    cd.cd_gender AS gender,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
  FROM tpcds.catalog_returns cr
  LEFT JOIN tpcds.item i
    ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN tpcds.customer cust_ref
    ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
  LEFT JOIN tpcds.customer cust_ret
    ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
  LEFT JOIN tpcds.customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN tpcds.household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN tpcds.customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  LEFT JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  LEFT JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
  RIGHT JOIN tpcds.web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
  LEFT JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN tpcds.web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  WHERE NOT EXISTS (
      SELECT 1 FROM tpcds.web_returns wr2
      WHERE wr2.wr_order_number = cr.cr_order_number
  )
  GROUP BY
    ws_site.web_name,
    cc.cc_name,
    cd.cd_gender
)
SELECT
  web_name,
  call_center_name,
  gender,
  total_return_amount,
  total_net_loss,
  return_cnt,
  CASE WHEN total_net_loss > 0 THEN 'LOSS' ELSE 'PROFIT' END AS loss_flag,
  ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn
FROM aggregated
ORDER BY rn
LIMIT 100
